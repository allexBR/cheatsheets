#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing AdGuard Home on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Fri Feb 27 19:21:02 UTC 2026
# -----------------------------------------------------------------------------------

# --- Validating privileges and re-executing as root ---
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

echo "Starting the AdGuard Home installation. Please wait..."

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

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
tee /usr/local/etc/AdGuardHome/openssl-san.ext <<EOF
# -----------------------------------------------------------#
# openssl-san.ext (v3-ext)                                   #
# X.509 extensions for adding SAN to self-signed certificate #
# -----------------------------------------------------------#

[req]
distinguished_name = req_distinguished_name
req_extensions     = v3_req
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
C  = US
ST = CA
L  = Berkeley
CN  = Trusted-CA

[v3_req]
basicConstraints = CA:FALSE
keyUsage         = critical, digitalSignature, keyEncipherment, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names

[alt_names]
DNS.1 = localhost
IP.1  = 127.0.0.1
IP.2  = ::1
EOF

# Create a ECDSA self-signed AdGuard private key and certificate using SAN
openssl req -x509 -newkey ec \
  -pkeyopt ec_paramgen_curve:secp384r1 \
  -keyout /etc/ssl/private/adguard.key \
  -out /etc/ssl/certs/adguard.crt \
  -sha256 \
  -days 36500 \
  -nodes \
  -config /usr/local/etc/AdGuardHome/openssl-san.ext \
  -extensions v3_req

# Verify that the files were actually created before changing necessary permissions
if [ -f /etc/ssl/private/adguard.key ]; then
    chmod 600 /etc/ssl/private/adguard.key
    chmod 644 /etc/ssl/certs/adguard.crt
    chown root:root /etc/ssl/private/adguard.key /etc/ssl/certs/adguard.crt
    echo "[V] Certificates generated successfully."
else
    echo "[X] Error: OpenSSL failed to generate certificates!"
    exit 1
fi

# Add the key path to the AdGuard Home config YAML file
#echo -e "enabled: true\ncertificate_chain: /etc/ssl/certs/adguard.crt\nprivate_key: /etc/ssl/private/adguard.key" \
#    | tee -a /usr/local/etc/AdGuardHome/AdGuardHome.yaml > /dev/null

# Restart AdGuard Home service
# systemctl restart AdGuardHome

#-------------------------------------------------#
#  WebGUI first access: http://<IP-or-FQDN>:3000  #
#-------------------------------------------------#

# Uninstall AdGuard Home
# ./AdGuardHome -s uninstall
