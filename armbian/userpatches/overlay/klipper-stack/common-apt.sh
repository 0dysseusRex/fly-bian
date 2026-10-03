# Shared apt set for Simple-AF and KIAUH images. Sourced from bake.sh
# inside customize-image.sh (nspawn). Do not create a daily user here.
fly_klipper_stack_apt() {
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends \
		git wget curl ca-certificates make crudini rsync unzip \
		python3 python3-venv python3-dev python3-pip python3-virtualenv python3-wheel \
		python3-numpy python3-matplotlib python3-scipy python3-contourpy \
		python3-pil python3-kiwisolver \
		build-essential libffi-dev libncurses-dev \
		libusb-dev libusb-1.0-0-dev \
		libjpeg-dev libopenjp2-7 zlib1g-dev libsodium-dev \
		libopenblas-dev \
		nginx \
		avrdude gcc-avr binutils-avr avr-libc \
		stm32flash dfu-util pkg-config \
		libnewlib-arm-none-eabi gcc-arm-none-eabi binutils-arm-none-eabi \
		v4l-utils \
		ustreamer \
		plymouth plymouth-themes
	apt-get remove --purge -y brltty modemmanager 2>/dev/null || true
}

fly_git_clone() {
	local url=$1 dest=$2
	# Always take latest tip — rootfs cache / prior bake must not pin an old SHA.
	if [[ -d $dest/.git ]]; then
		echo "fly-bake: updating $dest"
		git -C "$dest" fetch --depth=1 origin HEAD 2>/dev/null \
			|| git -C "$dest" fetch --depth=1 origin 2>/dev/null \
			|| true
		# Prefer origin/HEAD, then origin/main, then origin/master.
		local ref
		ref=$(git -C "$dest" rev-parse --verify origin/HEAD 2>/dev/null || true)
		[[ -n $ref ]] || ref=$(git -C "$dest" rev-parse --verify origin/main 2>/dev/null || true)
		[[ -n $ref ]] || ref=$(git -C "$dest" rev-parse --verify origin/master 2>/dev/null || true)
		if [[ -n $ref ]]; then
			git -C "$dest" reset --hard "$ref" >/dev/null
			echo "fly-bake: $dest @ $(git -C "$dest" rev-parse --short=7 HEAD)"
			return 0
		fi
		echo "fly-bake: fetch failed for $dest; recloning"
	fi
	echo "fly-bake: clone $url -> $dest"
	rm -rf "$dest"
	git clone --depth=1 "$url" "$dest"
	echo "fly-bake: $dest @ $(git -C "$dest" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)"
}

fly_web_release() {
	local url=$1 dest=$2 zip
	# Always refresh Fluidd/Mainsail zips so image tracks upstream latest.
	echo "fly-bake: fetch $url -> $dest"
	rm -rf "$dest"
	mkdir -p "$dest"
	zip=$(mktemp --suffix=.zip)
	curl -fL "$url" -o "$zip"
	unzip -qd "$dest" "$zip"
	rm -f "$zip"
}

# Isolated venvs force qemu-armhf source builds of numpy/matplotlib on
# Python 3.13 (no armhf wheels). Use Debian's packages instead.
fly_venv() {
	local dest=$1
	echo "fly-bake: venv --system-site-packages $dest"
	python3 -m venv --system-site-packages "$dest"
	"$dest/bin/pip" install --upgrade pip wheel
}

fly_pip_reqs() {
	local venv=$1
	shift
	local req filtered
	# pip would still upgrade these past Debian and compile contourpy/numpy.
	local skip='^(numpy|matplotlib|scipy|contourpy|pillow|kiwisolver|Pillow)([<>=!~ ].*)?$'
	for req in "$@"; do
		[[ -f $req ]] || continue
		filtered=$(mktemp)
		# Keep comments/blanks; drop science packages provided by apt.
		grep -viE "$skip" "$req" >"$filtered" || true
		echo "fly-bake: pip --prefer-binary -r $req (Debian numpy/matplotlib/scipy)"
		# No moonraker-speedups / uvloop source builds on this 512 MB target.
		"$venv/bin/pip" install --prefer-binary -r "$filtered"
		rm -f "$filtered"
	done
}

# After flavor bake: record stack identity for filenames / fly-help.
# Simple-AF → pellcorp short SHA; KIAUH → git describe (tag) or short SHA.
# Updates /etc/fly-debian/flybian-image and a host-visible meta file for staging.
fly_sanitize_token() {
	printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | sed -E 's/-+/-/g; s/^-+//; s/-+$//'
}

fly_set_stack_identity() {
	local flavor=$1 repo=${2:-}
	local ver device flavor_token rev stem meta
	install -d /etc/fly-debian /boot
	ver=$(tr -d '[:space:]' </etc/fly-debian/flybian-version 2>/dev/null || true)
	[[ -n $ver ]] || ver=$(tr -d '[:space:]' <"${OVERLAY:-/tmp/overlay}/FLYBIAN_VERSION" 2>/dev/null || true)
	[[ -n $ver ]] || ver=0.0
	device=Fly-Lite-2.1
	case "$flavor" in
		simpleaf) flavor_token=Simple-AF ;;
		kiauh) flavor_token=KIAUH ;;
		*) flavor_token=Base ;;
	esac

	rev=""
	if [[ -n $repo && -d $repo/.git ]]; then
		if [[ $flavor == kiauh ]]; then
			git -C "$repo" fetch --tags --depth=1 >/dev/null 2>&1 || true
			rev=$(git -C "$repo" describe --tags --always 2>/dev/null || true)
		fi
		[[ -n $rev ]] || rev=$(git -C "$repo" rev-parse --short=7 HEAD 2>/dev/null || true)
	fi
	rev=$(fly_sanitize_token "${rev:-unknown}")

	printf '%s\n' "$rev" >/etc/fly-debian/stack-rev
	printf '%s\n' "$flavor" >/etc/fly-debian/stack-flavor
	if [[ $flavor_token == Base ]]; then
		stem="Fly-bian-${ver}_${device}_${flavor_token}"
	else
		stem="Fly-bian-${ver}_${device}_${flavor_token}-${rev}"
	fi
	printf '%s\n' "$stem" >/etc/fly-debian/flybian-image
	printf '%s\n' "$stem" >/boot/flybian-image.txt

	meta="flavor=${flavor}
stack_rev=${rev}
stem=${stem}
"
	for d in /armbian/output/images /output/images; do
		if [[ -d $d ]]; then
			printf '%s' "$meta" >"$d/flybian-meta-${flavor}.txt"
			echo "fly-bake: wrote $d/flybian-meta-${flavor}.txt ($stem)"
			break
		fi
	done
	echo "fly-bake: stack identity $stem"
}
