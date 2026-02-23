#!/bin/bash
# ------------------------------------------------------------------------------------------------
# Installing NGINX (latest stable release) on Debian Server via Sury repo (https://deb.sury.org/)
# Created by allexBR | https://github.com/allexBR
# ------------------------------------------------------------------------------------------------

# --- Validating privileges and re-executing as root ---
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges."
    echo "Enter the root password when prompted to continue."
    # 'exec' Replace the current process with the command su -c
    # '$0' refers to the current script itself
    exec su -c "sh $0"
    exit $?
fi

echo "Starting the NGINX installation. Please wait..."

# Initial System repositories update/upgrade
apt clean ; apt update ; apt upgrade -y

# Installation of dependencies
apt -y install lsb-release ca-certificates apt-transport-https curl

# Add Sury repository key
curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
dpkg -i /tmp/debsuryorg-archive-keyring.deb

# Add the official SURY repository
echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/nginx/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx.list

# Final System repositories update
apt update

# Start Nginx Installation
apt install -y nginx-full

echo "Installation completed successfully!"
