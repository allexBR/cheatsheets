#!/bin/bash
# -----------------------------------------------------------------------------
# Cyber Threat Intelligence with IntelOwl on Debian server running over Docker
# Created by allexBR | https://github.com/allexBR
# Sources: https://intelowlproject.github.io/
#          https://github.com/intelowlproject/IntelOwl
# Last review date: Thu Mar 26 13:49:12 UTC 2026
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

# Verify that the files were actually created before changing necessary permissions
if [ -f /etc/ssl/private/intelowl.key ]; then
    chmod 600 /etc/ssl/private/intelowl.key
    chmod 644 /usr/local/share/ca-certificates/intelowl.crt
    chown root:root /etc/ssl/private/intelowl.key /usr/local/share/ca-certificates/intelowl.crt
    { echo -e "\e[30;48;5;248m >>> Certificates generated successfully! <<<\e[0m"; } 2> /dev/null
else
    echo "[X] Error: OpenSSL failed to generate certificates!"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs


# Start IntelOwl app
# Now the application is running on http://<IP-or-FQDN>:80
cd /opt/IntelOwl
sudo ./start prod up

#-----------------------------------------------
# Start IntelOwl app in https mode
# sudo ./start prod up --https
#-----------------------------------------------

# Create a super user
# docker exec -ti intelowl_uwsgi python3 manage.py createsuperuser


# Now you can login with the created user from http://<IP-or-FQDN>/login

# Have fun!
