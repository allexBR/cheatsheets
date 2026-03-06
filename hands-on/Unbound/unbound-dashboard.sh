#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Fri Mar 06 15:59:01 UTC 2026
# -----------------------------------------------------------------------------------

# Validating privileges and re-executing as root
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges!"
    # Try 'su -' first (Debian default)
    if command -v su >/dev/null 2>&1; then
        echo "Enter the root password to continue."
        exec su -c "bash \"$0\" $*"
    # If 'su -' fails or doesn't exist, try 'sudo'
    elif command -v sudo >/dev/null 2>&1; then
        echo "SUDO: Enter your password to elevate your privileges and continue."
        exec sudo bash "$0" "$@"
    else
        echo "ERROR: It is not possible to elevate privileges."
        exit 1
    fi
fi

echo "###############################################################"
echo "# Starting the Unbound Dashboard installation. Please wait... #"
echo "###############################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Install the prerequisite packages
apt install -y apt-transport-https gnupg musl

# steps to install Grafana from the APT repository
# Import the GPG key
mkdir -p /etc/apt/keyrings
wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
chmod 644 /etc/apt/keyrings/grafana.asc

# Add a repository for stable releases
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

# Updates the list of available packages
apt update -y

# Installs the latest Grafana Open-Source release
apt install -y grafana

# Reload System daemon
systemctl daemon-reload

# Enable automatic Grafana service startup
systemctl enable grafana-server

# Start Grafana service
systemctl start grafana-server

# Check Grafana service status
systemctl status grafana-server

echo "#--------------------------------------"
echo "# WebGUI access"
echo "# http://<FQDN-or-IP>:3000/"
echo "# Default user/pass ➟ admin/admin"
echo "#--------------------------------------"

# Prometheus install
#apt install prometheus


