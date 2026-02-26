#!/bin/bash
# -----------------------------------------------------------------------------
# Downloading Nginx source code based on the version installed on the system
# Created by allexBR | https://github.com/allexBR
# -----------------------------------------------------------------------------

# Validating privileges and re-executing as root
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges."
    echo "Enter the root password when prompted to continue."
    exec su -c "sh $0"
    exit $?
fi

# Define working directory
WORK_DIR="/tmp"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

echo "[+] Checking the current version of NGINX..."

# Capture the output of nginx -v command
NGINX_VER=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')

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

