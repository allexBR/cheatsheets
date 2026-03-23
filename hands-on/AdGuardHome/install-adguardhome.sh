#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing AdGuard Home on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Sun Mar 22 21:20:01 UTC 2026
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
echo "#  Starting the AdGuard Home installation. Please wait...  #"
echo "############################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Install required dependencies
apt install -y sudo

# Define working directory where AdGuard Home will be installed
WORK_DIR="/usr/local/etc"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Download AdGuard Home (latest stable release) source code
wget https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz

# Extract AdGuard Home source code
tar -zxf AdGuardHome_linux_amd64.tar.gz

# Enter the directory extracted from the compressed file
cd AdGuardHome

# Start AdGuard Home as a System service
sudo ./AdGuardHome -s install

# HTTPS webGUI config (generate a self-signed certificate)
# IMPORTANT: Do not use this in a prod environment, only for testing!
#---------------------------------------------------------------------

# Define working directory where cert files will be generated
mkdir -p /tmp/certs
cd /tmp/certs

# Create 'issuer' self-signed private key (Root CA)
openssl ecparam -name secp384r1 -genkey -out TrustedCA.key

# Create 'issuer' self-signed certificate (Root CA)
openssl req -x509 -new -nodes -key TrustedCA.key -sha384 -days 3650 \
  -subj "/C=US/ST=CA/L=Berkeley/CN=Trusted Root CA" \
  -out TrustedCA.crt

# Create 'client' self-signed private key
openssl ecparam -name secp384r1 -genkey -out adguard.key

# Create 'client' certificate signing request (CSR) file
openssl req -new -key adguard.key \
  -subj "/C=CY/ST=LMS/L=Limassol/CN=AdGuard Home" \
  -out adguard.csr

# Create 'client' self-signed certificate
openssl x509 -req -in adguard.csr -CA TrustedCA.crt -CAkey TrustedCA.key \
  -CAcreateserial -out adguard.crt -days 3650 -sha384

# Copy generated files to required path
cp adguard.crt /etc/ssl/certs/ && cp adguard.key /etc/ssl/private/

# Verify that the files were actually created before changing necessary permissions
if [ -f /etc/ssl/private/adguard.key ]; then
    chmod 640 /etc/ssl/private/adguard.key
    chmod 644 /etc/ssl/certs/adguard.crt
    chown root:root /etc/ssl/private/adguard.key /etc/ssl/certs/adguard.crt
    { echo -e "\e[30;48;5;248mCertificates generated successfully!\e[0m"; } 2> /dev/null
else
    echo "[X] Error: OpenSSL failed to generate certificates!"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs

# Restart AdGuard Home service
systemctl restart AdGuardHome

echo "###################################################"
echo "#  WebGUI first access: http://<IP-or-FQDN>:3000  #"
echo "###################################################"

# Add the key path to the AdGuard Home config YAML file
#sed -i '/^tls:/,/enabled:/ s/enabled: .*/enabled: true/' "/usr/local/etc/AdGuardHome/AdGuardHome.yaml"
#sed -i 's|^  force_https:.*|  force_https: true|' "/usr/local/etc/AdGuardHome/AdGuardHome.yaml"
#sed -i 's|^  certificate_path:.*|  certificate_path: /etc/ssl/certs/adguard.crt|' "/usr/local/etc/AdGuardHome/AdGuardHome.yaml"
#sed -i 's|^  private_key_path:.*|  private_key_path: /etc/ssl/private/adguard.key|' "/usr/local/etc/AdGuardHome/AdGuardHome.yaml"

# Uninstall AdGuard Home
# ./AdGuardHome -s uninstall
