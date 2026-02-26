#!/bin/bash
# ------------------------------------------------------------------------------------------------
# Installing NGINX (latest stable release) on Debian Server via Nginx Official Repo
# Created by allexBR | https://github.com/allexBR
# Source: https://nginx.org/en/linux_packages.html#Debian
# Last review date: Thu Feb 26 17:01:12 UTC 2026
# ------------------------------------------------------------------------------------------------

# Validating privileges and re-executing as root
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges."
    # Check if sudo is available, otherwise try su -
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    else
        echo "Enter the root password when prompted to continue."
        exec su -c "bash $0 $@"
    fi
    exit $?
fi

echo "Checking for existing NGINX installations..."

# Check and remove existing Nginx
if dpkg -l | grep -q nginx; then
    echo "Existing Nginx installation found. Removing it to ensure a clean install..."
    apt purge --auto-remove -y nginx nginx-common nginx-full nginx-core >/dev/null 2>&1
    # Remove residual directories if necessary (Optional)
    rm -rf /etc/nginx /var/log/nginx
    echo "Previous version removed."
else
    echo "No existing Nginx installation detected. Proceeding..."
fi

echo "Starting the new NGINX installation. Please wait..."

# Initial System repositories update/upgrade
apt clean ; apt update ; apt upgrade -y

# Install required dependencies
apt -y install curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# Import an official Nginx signing key
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "Verifying Nginx signing key fingerprint..."

# Stores the expected fingerprint in a variable
EXPECTED_FINGERPRINT="573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"

# Execute the gpg command and filter only the fingerprint from the output
ACTUAL_FINGERPRINTS=$(gpg --show-keys --with-colons /usr/share/keyrings/nginx-archive-keyring.gpg | grep '^fpr' | cut -d: -f10)

echo "Fingerprints found:"

echo "$ACTUAL_FINGERPRINTS"

# Checks if the expected fingerprint exists in any row of the variable
if echo "$ACTUAL_FINGERPRINTS" | grep -q "$EXPECTED_FINGERPRINT"; then
    echo "Verification successful! The key is authentic."
else
    echo "ERROR: Fingerprint mismatch!"
    echo "Expected: $EXPECTED_FINGERPRINT"
    exit 1
fi

# Set up the apt repository
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

# Set up repository pinning
tee /etc/apt/preferences.d/99nginx <<EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF

# Final System repositories update
apt update

# Start Nginx installation
apt install -y nginx

# Reload System daemon
systemctl daemon-reload

# Enable automatic Nginx service startup
systemctl enable nginx

# Start Nginx service
systemctl start nginx

# Check Nginx service status
systemctl status nginx

echo "Installation completed successfully!"

# Check Nginx installed version
nginx -v
