#!/bin/bash
# -----------------------------------------------------------------------------------
# Generating self-signed SSL/TLS certificates for NTPsec
# IMPORTANT: Do not use this in a prod environment, only for testing!
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Apr 09 13:01:52 UTC 2026
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
WORK_DIR="/root/certs"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Create 'issuer' self-signed private key
openssl ecparam -name secp384r1 -genkey -noout -out trustedCA.key

# Create 'issuer' self-signed Root CA certificate (Valid for 10 years)
openssl req -x509 -new -nodes -key trustedCA.key -sha384 -days 3650 \
  -subj "/C=US/ST=CA/L=Berkeley/CN=Trusted Root CA" \
  -out trustedCA.crt

# Create 'client' self-signed private key
openssl ecparam -name secp384r1 -genkey -noout -out ntp-server.key

# Defining required variables
SERVER_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')

# Create a temporary configuration file for SAN (Subject Alternative Name) extensions
cat > ntp.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${SERVER_IP}
DNS.1 = ntp.local
EOF

# Create 'client' certificate signing request (CSR) file
openssl req -new -key ntp-server.key \
  -subj "/C=BR/ST=CE/L=Fortaleza/CN=ntp.local" \
  -out ntp-server.csr

# Create 'client' self-signed certificate (Valid for 2 and a half years)
openssl x509 -req -in ntp-server.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out ntp-server.crt -days 910 -sha384 -extfile ntp.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat ntp-server.crt trustedCA.crt > cert-chain.pem

# Copy generated files to required path
cp cert-chain.pem /etc/ntpsec/cert-chain.pem && cp ntp-server.key /etc/ntpsec/key.pem

# Verify that the files were actually created before changing necessary permissions
if [ -f ntp-server.crt ]; then
    cp cert-chain.pem /etc/ntpsec/cert-chain.pem
    cp ntp-server.key /etc/ntpsec/key.pem
    
    chmod 600 /etc/ntpsec/key.pem
    chmod 644 /etc/ntpsec/cert-chain.pem
    chown ntpsec:ntpsec /etc/ntpsec/key.pem /etc/ntpsec/cert-chain.pem
    # Secure the CA private key in the /root/certs directory
    chmod 600 "$WORK_DIR/trustedCA.key"
    
    echo -e "\e[32m>>> Certificates generated successfully! <<<\e[0m"
    echo -e "\e[33m[!] Remember to distribute the $WORK_DIR/trustedCA.crt file to your network endpoints.\e[0m"
else
    echo -e "\e[31m[X] Error: OpenSSL failed to generate certificates!\e[0m"
    exit 1
fi


#--------------------------------------------------------------------------------------------------------------
# Important Note!
#
# For your clients to accept the NTS connection, you need to copy the trustedCA.crt file (only the public part)
# to the endpoints and add it to their list of trusted certificates (on Debian/Ubuntu, it is usually placed
# in /usr/local/share/ca-certificates/ and run update-ca-certificates).
#--------------------------------------------------------------------------------------------------------------
