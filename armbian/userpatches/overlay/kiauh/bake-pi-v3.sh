# Sourced from customize-image.sh when BOARD=fly-pi-v3-kiauh.
# KIAUH only. Do not clone Klipper, Moonraker, Fluidd, Mainsail, or Crowsnest.
set -euo pipefail

echo "Fly Pi V3 customize-image: KIAUH installer only"

# shellcheck source=/dev/null
source "$OVERLAY/klipper-stack/common-apt.sh"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends git wget curl ca-certificates unzip

STACK=/opt/fly-kiauh
install -d "$STACK" /etc/fly-debian
printf 'kiauh\n' >/etc/fly-debian/stack-flavor

fly_git_clone https://github.com/dw-0/kiauh.git "$STACK/kiauh"

if [[ -f $OVERLAY/tools/fly-kiauh ]]; then
	install -m 0755 "$OVERLAY/tools/fly-kiauh" /usr/local/bin/fly-kiauh
fi
if [[ -f $OVERLAY/kiauh/fly-bind-kiauh-installer.sh ]]; then
	install -m 0755 "$OVERLAY/kiauh/fly-bind-kiauh-installer.sh" \
		/usr/local/sbin/fly-bind-kiauh-installer
	install -m 0644 "$OVERLAY/kiauh/fly-bind-kiauh-installer.service" \
		/etc/systemd/system/fly-bind-kiauh-installer.service
	systemctl enable fly-bind-kiauh-installer.service 2>/dev/null || \
		ln -sf /etc/systemd/system/fly-bind-kiauh-installer.service \
			/etc/systemd/system/multi-user.target.wants/fly-bind-kiauh-installer.service
fi

# Simple-AF helpers are not on this image.
rm -f /usr/local/bin/fly-boot-display \
	/usr/local/bin/fly-grumpy-rotate \
	/usr/local/bin/fly-ensure-shaketune \
	/usr/local/bin/fly-start

if [[ -f /boot/README.txt && -f $OVERLAY/pi-v3/README-kiauh.fragment ]]; then
	cat "$OVERLAY/pi-v3/README-kiauh.fragment" >>/boot/README.txt
	cp -a /boot/README.txt /usr/share/fly-debian/first-boot/README.txt 2>/dev/null || true
fi

if [[ -x /usr/share/fly-debian/motd/patch-armbian-commands.py ]]; then
	python3 /usr/share/fly-debian/motd/patch-armbian-commands.py \
		/etc/update-motd.d/41-commands kiauh || true
fi

chmod -R a+rX "$STACK"
fly_set_stack_identity kiauh "$STACK/kiauh"
echo "fly-bake: KIAUH installer ready in $STACK (no Klipper stack)"
