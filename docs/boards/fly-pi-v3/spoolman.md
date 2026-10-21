# Fly Pi V3 — Spoolman needs Docker first

KIAUH’s Spoolman extension is a container. It runs `docker compose` as the login user (`fly` on the KIAUH image). The Pi V3 image does not install Docker. Install Docker Engine, then add that user to the `docker` group, before choosing Spoolman in `fly-kiauh`.

KIAUH only checks that `docker --version` and `docker compose version` succeed. The socket is `root:docker` mode `0660`. A user who is not in `docker` still gets past that check, then `docker compose up` fails with `permission denied` on `unix:///var/run/docker.sock`.

These steps follow [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/) (apt repository) and the [non-root post-install](https://docs.docker.com/engine/install/linux-postinstall/) group step. This image is Debian Trixie, arm64. The suite and architecture lines below read that from the board.

## 1. Remove conflicting packages

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

`apt` reporting that none of those packages are installed is the expected result on a fresh card. Images and containers under `/var/lib/docker/` are left in place.

## 2. Add Docker’s apt repository

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

## 3. Install Docker Engine and Compose

Spoolman uses `docker compose` (the plugin), so install the Compose package with the engine.

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Confirm the service is up, then run the test image as root:

```bash
sudo systemctl status docker
sudo docker run hello-world
```

If the service is not running: `sudo systemctl start docker`.

## 4. Add the login user to the `docker` group

The package creates the `docker` group with no members. Add the user that will run KIAUH. `$USER` is that account when you are logged in as them.

```bash
sudo groupadd --force docker
sudo usermod -aG docker "$USER"
```

Group membership is fixed at login. Log out of SSH and log back in. `newgrp docker` updates the current shell only; KIAUH in another session still needs the new login.

Check the group, then run the test image without `sudo`:

```bash
id -nG
docker run hello-world
```

`id` must list `docker`. If `~/.docker` was created earlier by `sudo docker` and the user-level command says it cannot read `~/.docker/config.json`:

```bash
sudo chown "$USER":"$USER" "$HOME/.docker" -R
sudo chmod g+rwx "$HOME/.docker" -R
```

The `docker` group can start containers as root. That is the access KIAUH’s Spoolman install needs.

## 5. Install Spoolman

```bash
fly-kiauh
```

Install the Spoolman extension from the KIAUH menu. It writes `~/spoolman/docker-compose.yml`, pulls `ghcr.io/donkie/spoolman:latest`, and starts the container. The default publish port is `7912`.

Do not let KIAUH upgrade the kernel, DTB, or U-Boot.
