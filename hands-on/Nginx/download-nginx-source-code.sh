#!/bin/bash
# -----------------------------------------------------------------------------
# Downloading Nginx source code based on the version installed on the system
# Created by allexBR | https://github.com/allexBR
# Last review date: Fri Feb 27 09:27:03 UTC 2026
# -----------------------------------------------------------------------------

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

# Define working directory
WORK_DIR="/tmp"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

echo "[+] Checking the current version of NGINX..."

# Capture the output of nginx -v command
NGINX_VER=$(/usr/sbin/nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')

# Checks if the variable is not empty
if [ -z "$NGINX_VER" ]; then
    echo "[-] Error: Nginx not found or version not identified."
    exit 1
fi

echo "[+] Version detected: $NGINX_VER"

# Performs the download using the variable value
URL="https://nginx.org/download/nginx-${NGINX_VER}.tar.gz"

echo "[+] Downloading from: $URL"
wget $URL

# Verify that the download actually took place
if [ $? -ne 0 ]; then
    echo "[-] Error downloading source code. Check your connection or the version on the Nginx website."
    exit 1
fi

echo "[+] Nginx source code downloaded successfully!"

# Extract files
tar -zxf nginx-${NGINX_VER}.tar.gz

echo "[+] All files were extracted successfully!"

# Print extract folder
ls -al /tmp | grep nginx

