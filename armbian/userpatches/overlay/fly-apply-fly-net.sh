#!/bin/sh
# Apply FLY-SETUP/fly-start.txt: Wi-Fi after 8189fs, plus first-run accounts
# when the user replaced the Your… placeholders. Image ships placeholders
# only — never a baked daily user. Leave /root/.not_logged_in_yet alone
# unless root + user are both filled.
# Accepts legacy fly-net.txt if fly-start.txt is absent.
set -eu

SSID_PLACEHOLDER=YourNetwork
LOGTAG=fly-first-setup

log() {
	logger -t "$LOGTAG" -- "$1" 2>/dev/null || printf '%s\n' "$1"
}

FILE=""
for cand in \
	/boot/fly-start.txt \
	/usr/share/fly-debian/first-boot/fly-start.txt \
	/boot/fly-net.txt \
	/usr/share/fly-debian/first-boot/fly-net.txt
do
	if [ -f "$cand" ]; then
		FILE=$cand
		break
	fi
done

if [ -z "${FILE}" ] || [ ! -f "$FILE" ]; then
	for mp in /mnt/FLY-SETUP /media/FLY-SETUP; do
		if [ -f "$mp/fly-start.txt" ]; then
			FILE=$mp/fly-start.txt
			break
		fi
		if [ -f "$mp/fly-net.txt" ]; then
			FILE=$mp/fly-net.txt
			break
		fi
	done
fi

if [ -z "${FILE}" ] || [ ! -f "$FILE" ]; then
	exit 0
fi

# Notepad CRLF: strip CRs into a temp copy we can grep.
WORK=$(mktemp)
tr -d '\r' <"$FILE" >"$WORK"
FILE=$WORK
trap 'rm -f "$WORK"' EXIT

get() {
	key=$1
	line=$(grep -E "^${key}=" "$FILE" | tail -n 1 || true)
	val=${line#*=}
	val=${val%\"}
	val=${val#\"}
	val=${val%\'}
	val=${val#\'}
	printf '%s' "$val"
}

is_placeholder() {
	v=$1
	[ -z "$v" ] && return 0
	case "$v" in
		YourNetwork|YourPassword|YourRootPassword|YourUser|YourUserPassword|YourLocale|YourTimezone|"Your Name"|YourName|YourRealName)
			return 0
			;;
	esac
	return 1
}

bash_quote() {
	printf '%s' "$1" | sed 's/[\\"]/\\&/g'
}

enabled=$(get WIFI_ENABLED)
ssid=$(get WIFI_SSID)
psk=$(get WIFI_PSK)
country=$(get WIFI_COUNTRY)
use_static=$(get USE_STATIC)
static_ip=$(get STATIC_IP)
static_mask=$(get STATIC_MASK)
static_gateway=$(get STATIC_GATEWAY)
static_dns=$(get STATIC_DNS)
locale=$(get LOCALE)
timezone=$(get TIMEZONE)
root_pw=$(get ROOT_PASSWORD)
root_key=$(get ROOT_SSH_KEY)
user_name=$(get USER_NAME)
user_pw=$(get USER_PASSWORD)
user_real=$(get USER_REALNAME)
user_shell=$(get USER_SHELL)
user_key=$(get USER_SSH_KEY)

wifi_ready=0
if [ "${enabled:-1}" = 1 ] && ! is_placeholder "$ssid"; then
	wifi_ready=1
fi

accounts_ready=0
if ! is_placeholder "$root_pw" && ! is_placeholder "$user_name" && ! is_placeholder "$user_pw"; then
	accounts_ready=1
fi

install_ssh_key() {
	home=$1
	owner=$2
	key=$3
	[ -n "$key" ] || return 0
	mkdir -p "$home/.ssh"
	auth=$home/.ssh/authorized_keys
	if printf '%s' "$key" | grep -qE '^https?://'; then
		if command -v curl >/dev/null 2>&1; then
			curl --retry 5 --connect-timeout 3 -fsSL "$key" -o "$auth" || return 1
		else
			return 1
		fi
	else
		printf '%s\n' "$key" >"$auth"
	fi
	chown -R "$owner:$owner" "$home/.ssh"
	chmod 700 "$home/.ssh"
	chmod 600 "$auth"
}

wait_wlan0() {
	i=0
	while [ "$i" -lt 60 ]; do
		if [ -d /sys/class/net/wlan0 ]; then
			return 0
		fi
		i=$((i + 1))
		sleep 1
	done
	return 1
}

disable_wlan1() {
	# 8189fs also creates wlan1 on the same radio; dual LAN IPs break reachability.
	if [ -x /usr/local/sbin/fly-disable-wlan1.sh ]; then
		/usr/local/sbin/fly-disable-wlan1.sh || true
	else
		ip addr flush dev wlan1 2>/dev/null || true
		ip link set wlan1 down 2>/dev/null || true
	fi
}

mask_to_prefix() {
	case "${1:-}" in
		255.255.255.0) printf '24' ;;
		255.255.0.0) printf '16' ;;
		255.0.0.0) printf '8' ;;
		255.255.255.128) printf '25' ;;
		255.255.255.192) printf '26' ;;
		*) printf '24' ;;
	esac
}

write_wpa_wlan0() {
	umask 077
	install -d /etc/wpa_supplicant
	conf=/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
	{
		printf 'ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev\n'
		printf 'update_config=1\n'
		if [ -n "$country" ] && ! is_placeholder "$country"; then
			printf 'country=%s\n' "$country"
		fi
		if command -v wpa_passphrase >/dev/null 2>&1 && [ "${#psk}" -ge 8 ]; then
			wpa_passphrase "$ssid" "$psk" | grep -v '^[[:space:]]*#psk='
		else
			printf 'network={\n\tssid="%s"\n' "$ssid"
			if [ -n "$psk" ] && ! is_placeholder "$psk"; then
				printf '\tpsk="%s"\n}\n' "$psk"
			else
				printf '\tkey_mgmt=NONE\n}\n'
			fi
		fi
	} >"$conf"
	chmod 600 "$conf"
}

write_networkd_wlan0() {
	install -d /etc/systemd/network
	net=/etc/systemd/network/30-wlan0.network
	{
		printf '[Match]\nName=wlan0\n\n[Network]\n'
		if [ "${use_static:-0}" = 1 ] && [ -n "$static_ip" ]; then
			printf 'Address=%s/%s\n' "$static_ip" "$(mask_to_prefix "$static_mask")"
			[ -n "$static_gateway" ] && printf 'Gateway=%s\n' "$static_gateway"
			[ -n "$static_dns" ] && printf 'DNS=%s\n' "$static_dns"
		else
			printf 'DHCP=yes\n'
		fi
	} >"$net"
	# networkd runs as systemd-network and refuses mode 600.
	chown root:systemd-network "$net" 2>/dev/null || true
	chmod 640 "$net"
}

apply_wifi_networkd() {
	command -v wpa_supplicant >/dev/null 2>&1 || {
		log "wpa_supplicant missing; skip Wi-Fi"
		return 0
	}
	write_wpa_wlan0
	write_networkd_wlan0
	if [ -n "$country" ] && ! is_placeholder "$country" && command -v iw >/dev/null 2>&1; then
		iw reg set "$country" 2>/dev/null || true
	fi
	ip link set wlan0 up 2>/dev/null || true
	systemctl enable wpa_supplicant@wlan0.service >/dev/null 2>&1 || true
	if ! systemctl restart wpa_supplicant@wlan0.service >/dev/null 2>&1; then
		wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant-wlan0.conf >/dev/null 2>&1 || true
	fi
	if command -v networkctl >/dev/null 2>&1; then
		networkctl reload >/dev/null 2>&1 || true
		networkctl reconfigure wlan0 >/dev/null 2>&1 || true
		networkctl up wlan0 >/dev/null 2>&1 || true
	fi
	systemctl try-restart systemd-networkd.service >/dev/null 2>&1 || true
}

apply_wifi_nmcli() {
	nmcli radio wifi on 2>/dev/null || true
	if [ -n "$country" ] && ! is_placeholder "$country"; then
		nmcli general wifi country "$country" 2>/dev/null || true
	fi

	n=0
	connected=0
	while [ "$n" -lt 5 ]; do
		if nmcli -t -f DEVICE,STATE dev status 2>/dev/null | grep -q '^wlan0:connected'; then
			connected=1
			break
		fi
		if nmcli device wifi connect "$ssid" password "$psk" ifname wlan0 >/dev/null 2>&1; then
			connected=1
			break
		fi
		n=$((n + 1))
		sleep 3
	done

	if [ "$connected" != 1 ]; then
		nmcli connection add type wifi ifname wlan0 con-name fly-net ssid "$ssid" \
			wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$psk" autoconnect yes >/dev/null 2>&1 || true
		nmcli connection up fly-net >/dev/null 2>&1 || true
	fi

	if [ "${use_static:-0}" = 1 ] && [ -n "$static_ip" ]; then
		con=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | awk -F: '$2=="wlan0"{print $1; exit}')
		[ -n "$con" ] || con=fly-net
		nmcli connection modify "$con" \
			ipv4.method manual \
			ipv4.addresses "${static_ip}/$(mask_to_prefix "$static_mask")" \
			ipv4.gateway "${static_gateway}" \
			ipv4.dns "${static_dns}" >/dev/null 2>&1 || true
		nmcli connection up "$con" >/dev/null 2>&1 || true
	fi
}

apply_wifi() {
	[ "$wifi_ready" = 1 ] || return 0
	if ! wait_wlan0; then
		log "wlan0 never appeared (8189fs?); skip Wi-Fi"
		return 0
	fi
	disable_wlan1
	rfkill unblock wifi 2>/dev/null || true
	if command -v nmcli >/dev/null 2>&1 && systemctl is-active NetworkManager >/dev/null 2>&1; then
		apply_wifi_nmcli
	else
		apply_wifi_networkd
	fi
	log "Wi-Fi apply attempted for SSID (name omitted from log)"
}

apply_location() {
	if ! is_placeholder "$timezone"; then
		if [ -e "/usr/share/zoneinfo/$timezone" ]; then
			timedatectl set-timezone "$timezone" 2>/dev/null || \
				ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
			log "timezone $timezone"
		else
			log "unknown TIMEZONE $timezone"
		fi
	fi
	if ! is_placeholder "$locale"; then
		if [ -f /etc/locale.gen ]; then
			# Debian lines look like: "# en_US.UTF-8 UTF-8"
			sed -i -E "s/^#\\s*(${locale}([[:space:]].*)?)$/\\1/" /etc/locale.gen || true
			if ! grep -qE "^${locale}([[:space:]]|$)" /etc/locale.gen 2>/dev/null; then
				printf '%s UTF-8\n' "$locale" >>/etc/locale.gen
			fi
		fi
		if command -v locale-gen >/dev/null 2>&1; then
			locale-gen "$locale" >/dev/null 2>&1 || locale-gen >/dev/null 2>&1 || true
		fi
		if command -v update-locale >/dev/null 2>&1; then
			update-locale "LANG=$locale" "LANGUAGE=$locale" >/dev/null 2>&1 || true
		else
			printf 'LANG=%s\n' "$locale" >/etc/default/locale
		fi
		log "locale $locale"
	fi
}

write_preset_fallback() {
	[ -f /root/.not_logged_in_yet ] || return 0
	# So a later serial login can finish any remaining firstlogin prompts.
	{
		printf '%s\n' '# generated from fly-start.txt — do not bake this into the image'
		if [ "$wifi_ready" = 1 ]; then
			printf 'PRESET_NET_CHANGE_DEFAULTS="1"\n'
			printf 'PRESET_NET_WIFI_ENABLED="1"\n'
			printf 'PRESET_NET_ETHERNET_ENABLED="0"\n'
			printf 'PRESET_CONNECT_WIRELESS="n"\n'
			printf 'PRESET_NET_WIFI_SSID="%s"\n' "$(bash_quote "$ssid")"
			printf 'PRESET_NET_WIFI_KEY="%s"\n' "$(bash_quote "$psk")"
			if [ -n "$country" ] && ! is_placeholder "$country"; then
				printf 'PRESET_NET_WIFI_COUNTRYCODE="%s"\n' "$(bash_quote "$country")"
			fi
			if [ "${use_static:-0}" = 1 ]; then
				printf 'PRESET_NET_USE_STATIC="1"\n'
				printf 'PRESET_NET_STATIC_IP="%s"\n' "$(bash_quote "$static_ip")"
				printf 'PRESET_NET_STATIC_MASK="%s"\n' "$(bash_quote "$static_mask")"
				printf 'PRESET_NET_STATIC_GATEWAY="%s"\n' "$(bash_quote "$static_gateway")"
				printf 'PRESET_NET_STATIC_DNS="%s"\n' "$(bash_quote "$static_dns")"
			fi
		fi
		if ! is_placeholder "$locale"; then
			printf 'SET_LANG_BASED_ON_LOCATION="n"\n'
			printf 'PRESET_LOCALE="%s"\n' "$(bash_quote "$locale")"
		fi
		if ! is_placeholder "$timezone"; then
			printf 'PRESET_TIMEZONE="%s"\n' "$(bash_quote "$timezone")"
		fi
		if ! is_placeholder "$root_pw"; then
			printf 'PRESET_ROOT_PASSWORD="%s"\n' "$(bash_quote "$root_pw")"
		fi
		if [ -n "$root_key" ]; then
			printf 'PRESET_ROOT_KEY="%s"\n' "$(bash_quote "$root_key")"
		fi
		if ! is_placeholder "$user_name"; then
			printf 'PRESET_USER_NAME="%s"\n' "$(bash_quote "$user_name")"
		fi
		if ! is_placeholder "$user_pw"; then
			printf 'PRESET_USER_PASSWORD="%s"\n' "$(bash_quote "$user_pw")"
		fi
		if ! is_placeholder "$user_real"; then
			printf 'PRESET_DEFAULT_REALNAME="%s"\n' "$(bash_quote "$user_real")"
		fi
		if [ -n "$user_shell" ]; then
			printf 'PRESET_USER_SHELL="%s"\n' "$(bash_quote "$user_shell")"
		fi
		if [ -n "$user_key" ]; then
			printf 'PRESET_USER_KEY="%s"\n' "$(bash_quote "$user_key")"
		fi
	} >/root/.not_logged_in_yet
	chmod 600 /root/.not_logged_in_yet
}

apply_accounts() {
	user=$(printf '%s' "$user_name" | tr '[:upper:]' '[:lower:]' | tr -d -c 'a-z0-9-')
	case "$user" in
		[a-z]*) ;;
		*)
			log "USER_NAME is not a valid Linux login; leave wizard"
			return 1
			;;
	esac
	real=$user_real
	if is_placeholder "$real"; then
		real=$use
	fi

	printf '%s:%s\n' root "$root_pw" | chpasswd

	if ! id "$user" >/dev/null 2>&1; then
		adduser --quiet --disabled-password --home "/home/$user" --gecos "$real" "$user"
	fi
	printf '%s:%s\n' "$user" "$user_pw" | chpasswd

	for g in sudo netdev audio video disk tty users games dialout plugdev input bluetooth systemd-journal ssh; do
		usermod -aG "$g" "$user" 2>/dev/null || true
	done

	shell_path=/bin/bash
	if [ "${user_shell}" = zsh ] && [ -x /bin/zsh ]; then
		shell_path=/bin/zsh
	fi
	chsh -s "$shell_path" "$user" 2>/dev/null || true
	chsh -s "$shell_path" root 2>/dev/null || true

	install_ssh_key /root root "$root_key" || log "root SSH key skipped"
	install_ssh_key "/home/$user" "$user" "$user_key" || log "user SSH key skipped"

	if ! is_placeholder "$locale"; then
		for rc in "/home/$user/.bashrc" "/home/$user/.xsessionrc"; do
			touch "$rc"
			if ! grep -q "export LANG=$locale" "$rc" 2>/dev/null; then
				{
					printf 'export LC_ALL=%s\n' "$locale"
					printf 'export LANG=%s\n' "$locale"
					printf 'export LANGUAGE=%s\n' "$locale"
				} >>"$rc"
			fi
			chown "$user:$user" "$rc"
		done
	fi

	log "created sudo user $user"
}

finish_firstlogin() {
	rm -f /etc/systemd/system/getty@.service.d/override.conf
	rm -f /etc/systemd/system/getty@tty1.service.d/override.conf
	rm -f /etc/systemd/system/serial-getty@.service.d/override.conf
	rm -f /etc/systemd/system/serial-getty@ttyGS0.service.d/override.conf
	chmod +x /etc/update-motd.d/* 2>/dev/null || true
	rm -f /root/.not_logged_in_yet
	sync -f /root 2>/dev/null || sync
	systemctl enable ssh.service >/dev/null 2>&1 || true
	systemctl restart ssh.service >/dev/null 2>&1 || \
		systemctl restart sshd.service >/dev/null 2>&1 || true
	# Avoid daemon-reload here on first boot: it re-runs generators
	# (fly-klipper-cpu-affinity) while CPUs may still be hotplugging and
	# RAM is tight after resize/swap — that correlated with a 6.18.x
	# __bitmap_clear oops. Units we touch above do not need a reload.
	log "first-run complete; SSH should accept USER_NAME"
}

apply_wifi
if [ -f /root/.not_logged_in_yet ]; then
	write_preset_fallback
	apply_location
	if [ "$accounts_ready" = 1 ]; then
		if apply_accounts; then
			finish_firstlogin
		else
			log "account apply failed; wizard marker kept"
		fi
	else
		log "user/root still placeholders; wizard will run on serial or HDMI"
	fi
fi
exit 0
