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
	if [[ -d $dest/.git ]]; then
		echo "fly-bake: already cloned $dest"
		return 0
	fi
	echo "fly-bake: clone $url -> $dest"
	rm -rf "$dest"
	git clone --depth=1 "$url" "$dest"
}

fly_web_release() {
	local url=$1 dest=$2 zip
	if [[ -f $dest/index.html ]]; then
		echo "fly-bake: already have web UI $dest"
		return 0
	fi
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
