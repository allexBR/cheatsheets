#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS (with cache DB module) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Sun Mar 22 18:52:01 UTC 2026
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

echo "############################################################"
echo "#  Starting SSL/TLS certificates creation. Please wait...  #"
echo "############################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Define working directory where cert files will be generated
mkdir -p /tmp/certs

WORK_DIR="/tmp/certs"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Create 'issuer' self-signed private key (Root CA)
openssl ecparam -name secp384r1 -genkey -out TrustedCA.key

# Create 'issuer' self-signed certificate (Root CA)
openssl req -x509 -new -nodes -key TrustedCA.key -sha384 -days 3650 \
  -subj "/C=US/ST=CA/L=Berkeley/CN=Trusted Root CA" \
  -out TrustedCA.crt

# Create 'client' self-signed private key
openssl ecparam -name secp384r1 -genkey -out server.key

# Create 'client' certificate signing request (CSR) file
openssl req -new -key server.key \
  -subj "/C=US/ST=MA/L=Cambridge/CN=WebTrust, Inc." \
  -out server.csr

# Create 'client' self-signed certificate
openssl x509 -req -in server.csr -CA TrustedCA.crt -CAkey TrustedCA.key \
  -CAcreateserial -out server.crt -days 3650 -sha384

# Copy generated files to required path
cp server.crt /etc/ssl/certs/ && cp server.key /etc/ssl/private/

# Change files permissions
chmod 640 /etc/ssl/private/server.key && chmod 644 /etc/ssl/certs/server.crt
chown root:root /etc/ssl/private/server.key /etc/ssl/certs/server.crt

# The following steps will only be applied if Nginx is installed on Debian.
# Checks if the Nginx executable exists on the system
if command -v nginx > /dev/null 2>&1; then
    echo "Nginx detected! Configuring required packages..."
    # Install required package
    apt update && apt install -y ssl-cert
    # Verify if Nginx user exists before modifying the group
    if id "nginx" &>/dev/null; then
        usermod -aG ssl-cert nginx
        echo "Success: User 'nginx' added to the ssl-cert group!"
    fi
else
    echo "Warning: Nginx not found! Skipping permissions and groups configuration."
fi

echo "The 'client' certificate and private key (self-signed) were successfully generated!"
