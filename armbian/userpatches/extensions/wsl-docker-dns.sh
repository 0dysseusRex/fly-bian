# Docker Desktop + WSL: Armbian passes host nameservers into the compile
# container. WSL's 10.255.255.254 (and similar) is not reachable from
# Docker Desktop, so git/curl to GitHub fail. Replace with public DNS.
function host_pre_docker_launch__wsl_dns() {
	declare -a filtered=()
	declare skip_next=0
	declare a
	for a in "${DOCKER_ARGS[@]}"; do
		if [[ ${skip_next} -eq 1 ]]; then
			skip_next=0
			continue
		fi
		if [[ "${a}" == "--dns" ]]; then
			skip_next=1
			continue
		fi
		filtered+=("${a}")
	done
	DOCKER_ARGS=("${filtered[@]}")
	DOCKER_EXTRA_ARGS+=("--dns" "8.8.8.8" "--dns" "1.1.1.1")
}
