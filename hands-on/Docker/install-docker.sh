#!/bin/bash
# ------------------------------------------------------------------------------------------------
# Installing Docker (latest stable release) on Debian Server via Official Repo
# Created by allexBR | https://github.com/allexBR
# Source: https://docs.docker.com/engine/install/debian/
# Last review date: Fri Feb 27 10:38:32 UTC 2026
# ------------------------------------------------------------------------------------------------

# Validating privileges and re-executing as root
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges."
    # Check if sudo is available, otherwise try su -
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    else
        echo "Enter the root password to continue."
        exec su -c "bash $0 $@"
    fi
    exit $?
fi

echo "Checking for existing Docker installations..."

# Check and remove existing Docker
if dpkg -l | grep -q docker; then
    echo "Existing Docker installation found. Removing it to ensure a clean install..."
    apt remove -y $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
    echo "Previous version removed."
else
    echo "No existing Docker installation detected. Proceeding..."
fi

echo "Starting the new Docker installation. Please wait..."

# Initial System repositories update/upgrade
apt clean ; apt update ; apt upgrade -y

# Install required dependencies
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo "Docker's official GPG key added..."

# Set up the apt repository
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "Docker repository to Apt sources added..."

# Final System repositories update
apt update

# Start Docker installation
apt install -y docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

# Reload System daemon
systemctl daemon-reload

# Enable automatic Docker service startup
systemctl enable docker

# Start Docker service
systemctl start docker

# Check Docker service status
systemctl status docker

echo "Installation completed successfully!"

# Check Docker installed version
#/usr/sbin/
docker --version || true

docker compose version

docker info

# Verify that the installation is successful by running the hello-world image
docker run hello-world
