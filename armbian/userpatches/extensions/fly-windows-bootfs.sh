# Windows will not auto-mount Armbian's default 0xea XBOOTLDR type.
# Armbian formats p1 as FAT labelled armbi_boot. Product name is FLY-SETUP
# with fly-start.txt + README.txt in the volume root (Windows/macOS/Linux).

# Full `sync` can hang forever under Docker/WSL after loop-mounted image writes
# (Pi V3 0.70 bake: stuck >15 min on bare sync after FLY-SETUP). Prefer a
# filesystem flush with a hard timeout; umount still persists dirty data.
function fly_windows_bootfs_flush() {
	local target="${1:-}"
	display_alert "FLY-SETUP" "flush ${target:-fs} (bounded)" "info"
	if [[ -n ${target} ]]; then
		if command -v timeout >/dev/null; then
			timeout 20 sync -f "${target}" 2>/dev/null ||
				timeout 20 sync --file-system "${target}" 2>/dev/null || true
		else
			sync -f "${target}" 2>/dev/null || true
		fi
		if [[ -b ${target} ]] && command -v blockdev >/dev/null; then
			timeout 10 blockdev --flushbufs "${target}" 2>/dev/null || true
		fi
	elif command -v timeout >/dev/null; then
		timeout 20 sync 2>/dev/null || true
	fi
}

function post_build_image__fly_windows_fat() {
	local img="${FINAL_IMAGE_FILE}"
	# 0x0c = FAT32 LBA (matches Armbian's vfat). 0x0e (FAT16 LBA) confused
	# dosfsck / systemd-fsck on Pi V3 and hung first boot.
	display_alert "FLY-SETUP partition type" "set p1 to 0x0c (FAT32 LBA) so Windows can mount it" "info"
	run_host_command_logged sfdisk --part-type "${img}" 1 0c
	display_alert "FLY-SETUP" "sfdisk part-type done; attaching loop" "info"

	local loop p1 mnt src start_src readme_src
	loop=$(losetup -f --show -P "${img}")
	p1="${loop}p1"
	if [[ ! -b ${p1} ]]; then
		partprobe "${loop}" || true
		sleep 1
	fi
	if [[ ! -b ${p1} ]]; then
		display_alert "FLY-SETUP" "loop p1 missing after losetup -P (${loop})" "err"
		losetup -d "${loop}" || true
		return 1
	fi

	if command -v fatlabel >/dev/null; then
		run_host_command_logged fatlabel "${p1}" FLY-SETUP
	elif command -v dosfslabel >/dev/null; then
		run_host_command_logged dosfslabel "${p1}" FLY-SETUP
	else
		display_alert "FLY-SETUP" "fatlabel not installed; volume stays armbi_boot" "wrn"
	fi

	src="${SRC}/userpatches/overlay/first-boot"
	start_src="${src}/fly-start.txt"
	readme_src="${src}/README.txt"
	# Base fly-start is Wi-Fi/accounts/serial. Simple-AF and KIAUH replace it.
	case "${BOARD:-}" in
		*kiauh*)
			if [[ -f ${SRC}/userpatches/overlay/kiauh/fly-start.txt ]]; then
				start_src="${SRC}/userpatches/overlay/kiauh/fly-start.txt"
			fi
			;;
		*simpleaf*)
			if [[ -f ${SRC}/userpatches/overlay/simpleaf/fly-start.txt ]]; then
				start_src="${SRC}/userpatches/overlay/simpleaf/fly-start.txt"
			fi
			;;
	esac

	mnt=$(mktemp -d)
	# FAT cannot store Unix ownership; cp -a fails with EPERM.
	if ! mount -o rw "${p1}" "${mnt}"; then
		losetup -d "${loop}" || true
		rmdir "${mnt}" || true
		return 1
	fi
	if [[ -f ${start_src} ]]; then
		install -m 0644 "${start_src}" "${mnt}/fly-start.txt"
	elif [[ -f ${src}/fly-net.txt ]]; then
		install -m 0644 "${src}/fly-net.txt" "${mnt}/fly-start.txt"
	fi
	if [[ -f ${readme_src} ]]; then
		install -m 0644 "${readme_src}" "${mnt}/README.txt"
		# Append flavor notes so FLY-SETUP matches the baked card.
		case "${BOARD:-}" in
			*kiauh*)
				if [[ -f ${SRC}/userpatches/overlay/kiauh/README.fragment ]]; then
					cat "${SRC}/userpatches/overlay/kiauh/README.fragment" >>"${mnt}/README.txt"
				fi
				;;
			*simpleaf*)
				if [[ -f ${SRC}/userpatches/overlay/simpleaf/README.fragment ]]; then
					cat "${SRC}/userpatches/overlay/simpleaf/README.fragment" >>"${mnt}/README.txt"
				fi
				;;
		esac
	fi
	# Ensure cmdline skip survives even if rootfs armbianEnv was stale.
	if [[ -f ${mnt}/armbianEnv.txt ]] && ! grep -q 'fsck.mode=skip' "${mnt}/armbianEnv.txt"; then
		if grep -q '^extraargs=' "${mnt}/armbianEnv.txt"; then
			sed -i 's/^extraargs=\(.*\)/extraargs=\1 fsck.mode=skip/' "${mnt}/armbianEnv.txt"
		else
			echo 'extraargs=fsck.mode=skip' >>"${mnt}/armbianEnv.txt"
		fi
		display_alert "FLY-SETUP" "appended fsck.mode=skip to armbianEnv.txt" "info"
	fi
	fly_windows_bootfs_flush "${mnt}"
	umount "${mnt}" || umount -l "${mnt}" || true
	rmdir "${mnt}" || true
	display_alert "FLY-SETUP" "boot FAT labelled; patching rootfs" "info"

	# Patch rootfs fstab after Armbian wrote it (customize-image runs too early).
	# Skip pass for vfat /boot so systemd-fsck@ is never pulled for FLY-SETUP.
	local p2 rootmnt
	p2="${loop}p2"
	if [[ -b ${p2} ]]; then
		rootmnt=$(mktemp -d)
		if mount -o rw "${p2}" "${rootmnt}"; then
			if [[ -f ${rootmnt}/etc/fstab ]]; then
				awk '
					BEGIN { OFS = "\t" }
					/^[[:space:]]*#/ || NF < 4 { print; next }
					$3 ~ /^(vfat|msdos|fat)$/ {
						opts = $4
						gsub(/(^|,)auto(,|$)/, ",", opts)
						gsub(/(^|,)x-systemd\.automount(,|$)/, ",", opts)
						gsub(/(^|,)x-systemd\.idle-timeout=[^,]+/, "", opts)
						gsub(/,,+/, ",", opts)
						gsub(/^,|,$/, "", opts)
						if (opts !~ /(^|,)noauto(,|$)/) opts = (opts == "" ? "noauto" : opts ",noauto")
						if (opts !~ /(^|,)nofail(,|$)/) opts = opts ",nofail"
						if (opts !~ /x-systemd\.device-timeout=/) opts = opts ",x-systemd.device-timeout=10s"
						if (opts !~ /x-systemd\.mount-timeout=/) opts = opts ",x-systemd.mount-timeout=10s"
						dump = (NF >= 5 ? $5 : 0)
						print $1, $2, $3, opts, dump, 0
						next
					}
					{ print }
				' "${rootmnt}/etc/fstab" >"${rootmnt}/etc/fstab.fly.new" &&
					mv "${rootmnt}/etc/fstab.fly.new" "${rootmnt}/etc/fstab"
				display_alert "FLY-SETUP" "fstab: vfat noauto (no automount) pass=0 (post-image)" "info"
			fi
			# Belt-and-suspenders: short timeout if any fsck unit still runs.
			install -d "${rootmnt}/etc/systemd/system/systemd-fsck@.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-fsck@.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=30
EOF
			install -d "${rootmnt}/etc/systemd/system/boot.mount.d"
			cat >"${rootmnt}/etc/systemd/system/boot.mount.d/fly-timeout.conf" <<'EOF'
[Mount]
TimeoutSec=10
EOF
			# Mask console-setup / ldconfig / random-seed / machine-id-commit /
			# update-done / networkd+resolved if customize masks lost.
			# Pi V3: do not re-apply the 0.70 emergency peel masks (legacy 6.12
			# bring-up). Keep user_overlays and the TFT module list.
			if [[ -d ${rootmnt}/etc/systemd/system ]]; then
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/console-setup.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/ldconfig.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-random-seed.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-machine-id-commit.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-update-done.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-networkd.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-resolved.service"
				ln -sfn /dev/null "${rootmnt}/etc/systemd/system/systemd-networkd-wait-online.service"
			fi
			install -d "${rootmnt}/etc/systemd/system/systemd-random-seed.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-random-seed.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=10
EOF
			install -d "${rootmnt}/etc/systemd/system/systemd-tmpfiles-setup.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-tmpfiles-setup.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=30
EOF
			install -d "${rootmnt}/etc/systemd/system/systemd-update-done.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-update-done.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=10
EOF
			install -d "${rootmnt}/etc/systemd/system/systemd-networkd.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-networkd.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=15
EOF
			install -d "${rootmnt}/etc/systemd/system/systemd-resolved.service.d"
			cat >"${rootmnt}/etc/systemd/system/systemd-resolved.service.d/fly-timeout.conf" <<'EOF'
[Service]
TimeoutStartSec=15
EOF
			# Skip qemu-chroot ldconfig here: host chroot of aarch64 under WSL
			# can stall; customize-image already masks ldconfig for first boot.
			# Commit machine-id in-image when still uninitialized (file write only).
			if [[ ! -s ${rootmnt}/etc/machine-id ]] ||
				grep -qxE 'uninitialized|0+' "${rootmnt}/etc/machine-id" 2>/dev/null; then
				if command -v uuidgen >/dev/null; then
					uuidgen | tr -d '-' >"${rootmnt}/etc/machine-id"
				elif [[ -r /proc/sys/kernel/random/uuid ]]; then
					tr -d '-' </proc/sys/kernel/random/uuid >"${rootmnt}/etc/machine-id"
				fi
			fi
			# Last write: correct ConditionNeedsUpdate marker paths.
			mkdir -p "${rootmnt}/etc" "${rootmnt}/var"
			touch "${rootmnt}/etc/.updated" "${rootmnt}/var/.updated" 2>/dev/null || true
			fly_windows_bootfs_flush "${rootmnt}"
			umount "${rootmnt}" || umount -l "${rootmnt}" || true
		fi
		rmdir "${rootmnt}" || true
	fi

	fly_windows_bootfs_flush "${p1}"
	[[ -b ${p2} ]] && fly_windows_bootfs_flush "${p2}"
	losetup -d "${loop}" || losetup -D || true
	display_alert "FLY-SETUP volume" "labelled FLY-SETUP; fly-start.txt + README.txt on p1 (${BOARD:-})" "info"
}
