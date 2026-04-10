#!/bin/bash
# -----------------------------------------------------------------------------------
# Generating self-signed SSL/TLS certificates for Nginx
# IMPORTANT: Do not use this in a prod environment, only for testing!
# Created by allexBR | https://github.com/allexBR
# Last review date: Fri Apr 10 10:42:01 UTC 2026
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

echo "##############################################################"
echo "#  Starting SSL/TLS certificates generation. Please wait...  #"
echo "##############################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Define working directory where cert files will be generated
WORK_DIR="/tmp/certs"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Create 'issuer' self-signed private key
openssl ecparam -name secp384r1 -genkey -noout -out trustedCA.key

# Create 'issuer' self-signed Root CA certificate (Valid for 10 years)
openssl req -x509 -new -nodes -key trustedCA.key -sha384 -days 3650 \
  -subj "/C=US/ST=Texas/L=Houston/O=WebSSL Corp/CN=Trusted SSL CA" \
  -out trustedCA.crt

# Create 'client' self-signed private key
openssl ecparam -name secp384r1 -genkey -noout -out server.key

# Defining required variables
SERVER_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
SERVER_HOSTNAME=$(hostname -s)

# Create a temporary configuration file for SAN (Subject Alternative Name) extensions
cat > https.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${SERVER_IP}
DNS.1 = ${SERVER_HOSTNAME}.home.arpa
EOF

# Create 'client' certificate signing request (CSR) file
openssl req -new -key server.key \
  -subj "/CN=${SERVER_HOSTNAME}.home.arpa" \
  -out server.csr

# Create 'client' self-signed certificate (Valid for 10 years)
openssl x509 -req -in server.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out server.crt -days 3650 -sha384 -extfile https.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat server.crt trustedCA.crt > server.pem

# Verify that the files were actually generated and copy them to the required path
# After that, modify necessary permissions
if [ -f server.crt ]; then
    cp server.pem /etc/ssl/certs/
    cp server.key /etc/ssl/private/
    chmod 640 /etc/ssl/private/server.key
    chmod 644 /etc/ssl/certs/server.pem
    chown root:root /etc/ssl/private/server.key /etc/ssl/certs/server.pem
    echo -e "\e[32m>>> Certificates generated successfully! <<<\e[0m"
else
    echo -e "\e[31m[X] Error: OpenSSL failed to generate certificates!\e[0m"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs
