#!/bin/bash
# -----------------------------------------------------------------------------
# Cyber Threat Intelligence with IntelOwl on Debian server running over Docker
# Created by allexBR | https://github.com/allexBR
# Sources: https://intelowlproject.github.io/
#          https://github.com/intelowlproject/IntelOwl
# Last review date: Fri Apr 10 11:01:50 UTC 2026
# -----------------------------------------------------------------------------

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

echo "Starting IntelOwl installation. Please wait..."

# Download and install Docker (required to start IntelOwl)
#if ! command -v docker &> /dev/null; then
#    echo "[+] Docker not found. Installing..."
#    wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Docker/install-docker.sh -O /tmp/install-docker.sh
#    chmod +x /tmp/install-docker.sh
#    bash /tmp/install-docker.sh
#    
#    # Pause to ensure the daemon has launched
#    sleep 5
#else
#    echo "[+] Docker already installed."
#fi

# Initial System repositories update/upgrade
apt clean ; apt update ; apt upgrade -y

# Install required dependencies
apt install -y sudo python3-pip python-is-python3

python -m pip install --upgrade pywin32

# Define IntelOwl working directory
WORK_DIR="/opt"
cd "$WORK_DIR" || exit 1

if [ ! -d "IntelOwl" ]; then
    echo "[+] Cloning IntelOwl..."
    git clone https://github.com/intelowlproject/IntelOwl
fi

echo "[+] Operating in the directory: $WORK_DIR"

# Enter in the project directory
cd IntelOwl/ || exit 1

# Run helper script to verify installed dependencies and configure basic stuff
sudo ./initialize.sh


#-------------------------------------------------------------------------
# HTTPS webGUI config (generate a self-signed certificate)
# IMPORTANT: Do not use this in a prod environment, only for testing!
#-------------------------------------------------------------------------

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
openssl ecparam -name secp384r1 -genkey -noout -out intelowl.key

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
openssl req -new -key intelowl.key \
  -subj "/CN=WebTrust, Inc." \
  -out intelowl.csr

# Create 'client' self-signed certificate (Valid for 10 years)
openssl x509 -req -in intelowl.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out intelowl.crt -days 3650 -sha384 -extfile https.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat intelowl.crt trustedCA.crt > intelowl.pem

# Verify that the files were actually generated and copy them to the required path
# After that, modify necessary permissions
if [ -f intelowl.crt ]; then
    cp intelowl.key /etc/ssl/private/
    cp intelowl.pem /usr/local/share/ca-certificates/
    chmod 600 /etc/ssl/private/intelowl.key
    chmod 644 /usr/local/share/ca-certificates/intelowl.pem
    chown root:root /etc/ssl/private/intelowl.key /usr/local/share/ca-certificates/intelowl.pem
    echo -e "\e[32m>>> Certificates generated successfully! <<<\e[0m"
else
    echo -e "\e[31m[X] Error: OpenSSL failed to generate certificates!\e[0m"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs


# Start IntelOwl app
# Now the application is running on http://<IP-or-FQDN>:80
cd /opt/IntelOwl
sudo ./start prod up

echo "####################################################"
echo "#  WebGUI first access: http://<IP-or-FQDN>/login  #"
echo "####################################################"

#-----------------------------------------------
# Start IntelOwl app in https mode
# sudo ./start prod up --https
#-----------------------------------------------

# Create a super user
# docker exec -ti intelowl_uwsgi python3 manage.py createsuperuser


# Now you can login with the created user from http://<IP-or-FQDN>/login

# Have fun!
