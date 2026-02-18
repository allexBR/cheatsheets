#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing AdGuard Home on Debian Server
# Created by allexBR | https://github.com/allexBR
# -----------------------------------------------------------------------------------

# --- Validating privileges and re-executing as root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script requires root privileges."
  echo "Enter the root password when prompted to continue."
  # Resolves the absolute path of the script for correct re-execution
  SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0")"
  # Re-executes the script in a root login shell while preserving arguments
  exec su - -c "/bin/bash \"$SCRIPT_PATH\" $*"
fi

apt clean ; apt update ; apt upgrade -y

cd /usr/local/etc/

wget https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz

tar xzf AdGuardHome_linux_amd64.tar.gz

cd AdGuardHome

sudo ./AdGuardHome -s install

#------------------------------------------
# WebGUI access: http://<IP-or-FQDN>:3000
#------------------------------------------

#------------------------------------------
# HTTPS WebGUI Config:
#------------------------------------------
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
OU = AdGuard-Home
CN = localhost

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

openssl req -x509 -newkey ec \
  -pkeyopt ec_paramgen_curve:secp384r1 \
  -keyout /etc/ssl/private/adguard.key \
  -out /etc/ssl/certs/adguard.crt \
  -sha256 \
  -days 36500 \
  -nodes \
  -config /usr/local/etc/AdGuardHome/openssl-san.ext \
  -extensions v3_req

chmod 600 /etc/ssl/private/adguard.key

chmod 644 /etc/ssl/certs/adguard.crt

chown root:root /etc/ssl/private/adguard.key /etc/ssl/certs/adguard.crt

# nano /usr/local/etc/AdGuardHome/AdGuardHome.yaml

# systemctl restart AdGuardHome
