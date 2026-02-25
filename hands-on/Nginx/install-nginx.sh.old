#!/bin/bash
# ------------------------------------------------------------------------------------------------
# Installing NGINX (latest stable release) on Debian Server via Nginx Official Repo
# Created by allexBR | https://github.com/allexBR
# from: https://nginx.org/en/linux_packages.html#Debian
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
apt -y install curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# Import an official Nginx signing key so apt could verify the packages authenticity
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# Verify that the downloaded file contains the proper key
gpg --homedir /tmp --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "The output should contain the full fingerprint 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"

# Set up the apt repository for stable Nginx packages
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

# Set up repository pinning to prefer our packages over distribution-provided ones
tee /etc/apt/preferences.d/99nginx cat <<EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF

# Final System repositories update
apt update

# Start Nginx installation in full mode
apt install nginx

echo "Installation completed successfully!"

nginx -v
