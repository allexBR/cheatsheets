#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing AdGuard Home on Debian Server
# Created by allexBR | https://github.com/allexBR
# -----------------------------------------------------------------------------------

# --- Validating privileges and re-executing as root ---
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
  echo "This script requires root privileges."
  echo "Enter the root password when prompted to continue."
  # Resolves the absolute path of the script for correct re-execution
  SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0")"
  # Re-executes the script in a root login shell while preserving arguments
  exec su - -c "/bin/bash \"$SCRIPT_PATH\" $*"
fi

echo "Starting the AdGuard Home installation. Please wait..."

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Enter to the folder where AdGuard Home will be installed
cd /usr/local/etc/

# Download AdGuard Home (latest stable release) source code
wget https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz

# Extract AdGuard Home source code
tar xzf AdGuardHome_linux_amd64.tar.gz

# Enter the directory extracted from the compressed file
cd AdGuardHome

# Start AdGuard Home as a System service
sudo ./AdGuardHome -s install

# HTTPS webGUI config (generate a self-signed certificate)
tee /usr/local/etc/AdGuardHome/openssl-san.ext <<EOF
# -----------------------------------------------------------------
# san_adguard_home.ext (v3-ext)
# Extensões X.509 para adicionar SAN ao certificado do AdGuard Home
# -----------------------------------------------------------------

[req]
distinguished_name = req_distinguished_name
req_extensions     = v3_req
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
C  = CY
ST = Limassol District
L  = Limassol
O  = AdGuard
CN = adguard.com

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

# Configure necessary permissions
chmod 600 /etc/ssl/private/adguard.key && chmod 644 /etc/ssl/certs/adguard.crt

chown root:root /etc/ssl/private/adguard.key /etc/ssl/certs/adguard.crt

# nano /usr/local/etc/AdGuardHome/AdGuardHome.yaml

# systemctl restart AdGuardHome

#-------------------------------------------------#
#  WebGUI first access: http://<IP-or-FQDN>:3000  #
#-------------------------------------------------#

