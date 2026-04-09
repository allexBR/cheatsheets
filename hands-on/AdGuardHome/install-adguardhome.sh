#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing AdGuard Home on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Apr 09 16:57:09 UTC 2026
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
WORK_DIR="/tmp/certs"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Create 'issuer' self-signed private key (Root CA)
openssl ecparam -name secp384r1 -genkey -noout -out trustedCA.key

# Create 'issuer' self-signed certificate (Root CA)
openssl req -x509 -new -nodes -key trustedCA.key -sha384 -days 3650 \
  -subj "/C=US/ST=CA/L=Berkeley/O=WebSSL Corp/CN=Trusted SSL Intermediate CA" \
  -out trustedCA.crt

# Create 'client' self-signed private key
openssl ecparam -name secp384r1 -genkey -noout -out adguard.key

# Defining required variable
SERVER_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')

# Create a temporary configuration file for SAN (Subject Alternative Name) extensions
cat > adguard.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${SERVER_IP}
DNS.1 = adguard.home.arpa
EOF

# Create 'client' certificate signing request (CSR) file
openssl req -new -key adguard.key \
  -subj "/CN=adguard.home.arpa" \
  -out adguard.csr

# Create 'client' self-signed certificate
openssl x509 -req -in adguard.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out adguard.crt -days 3650 -sha384 -extfile adguard.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat adguard.crt trustedCA.crt > adguard.pem

# Verify that the files were actually generated and copy them to the required path
# After that, modify necessary permissions
if [ -f adguard.crt ]; then
    cp adguard.pem /etc/ssl/certs/
    cp adguard.key /etc/ssl/private/
    chmod 640 /etc/ssl/private/adguard.key
    chmod 644 /etc/ssl/certs/adguard.pem
    chown root:root /etc/ssl/private/adguard.key /etc/ssl/certs/adguard.pem
    echo -e "\e[32m>>> Certificates generated successfully! <<<\e[0m"
else
    echo -e "\e[31m[X] Error: OpenSSL failed to generate certificates!\e[0m"
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
