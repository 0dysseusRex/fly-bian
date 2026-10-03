# Windows will not auto-mount Armbian's default 0xea XBOOTLDR type.
# Armbian formats p1 as FAT labelled armbi_boot. Product name is FLY-SETUP
# with fly-start.txt + README.txt in the volume root (Windows/macOS/Linux).
function post_build_image__fly_windows_fat() {
	local img="${FINAL_IMAGE_FILE}"
	display_alert "FLY-SETUP partition type" "set p1 to 0x0e (FAT16 LBA) so Windows can mount it" "info"
	run_host_command_logged sfdisk --part-type "${img}" 1 0e

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
	# Flavor-specific fly-start.txt (KIAUH is Wi-Fi/accounts only).
	case "${BOARD:-}" in
		*kiauh*)
			if [[ -f ${SRC}/userpatches/overlay/kiauh/fly-start.txt ]]; then
				start_src="${SRC}/userpatches/overlay/kiauh/fly-start.txt"
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
	sync
	umount "${mnt}"
	rmdir "${mnt}"
	losetup -d "${loop}"
	display_alert "FLY-SETUP volume" "labelled FLY-SETUP; fly-start.txt + README.txt on p1 (${BOARD:-})" "info"
}
