#!/bin/bash
# -----------------------------------------------------------------------------------
# Generating self-signed SSL/TLS certificates for ntopng
# IMPORTANT: Do not use this in a prod environment, only for testing!
# Created by allexBR | https://github.com/allexBR
# Last review date: Wed Apr 15 15:27:06 UTC 2026
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
openssl ecparam -name secp384r1 -genkey -noout -out ntopng.key

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
DNS.1 = ntopng.home.arpa
EOF

# Create 'client' certificate signing request (CSR) file
openssl req -new -key ntopng.key \
  -subj "/CN=WebTrust, Inc." \
  -out ntopng.csr

# Create 'client' self-signed certificate (Valid for 10 years)
openssl x509 -req -in ntopng.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out ntopng.crt -days 3650 -sha384 -extfile https.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat ntopng.key ntopng.crt trustedCA.crt > /etc/ntopng/ntopng.pem

# Verify that the files were actually generated and copy them to the required path
# After that, modify necessary permissions
if [ -f ntopng.crt ]; then
    cp ntopng.pem /etc/ntopng/
    chmod 400 /etc/ntopng/ntopng.pem
    chown ntopng /etc/ntopng/ntopng.pem
    echo -e "\e[32m>>> Certificates generated successfully! <<<\e[0m"
else
    echo -e "\e[31m[X] Error: OpenSSL failed to generate certificates!\e[0m"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs
