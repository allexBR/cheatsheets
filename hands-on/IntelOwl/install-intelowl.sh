#!/bin/bash
# -----------------------------------------------------------------------------
# Cyber Threat Intelligence with IntelOwl on Debian server running over Docker
# Created by allexBR | https://github.com/allexBR
# Sources: https://intelowlproject.github.io/
#          https://github.com/intelowlproject/IntelOwl
# Last review date: Fri Feb 27 11:32:57 UTC 2026
# -----------------------------------------------------------------------------

# Validating privileges and re-executing as root
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

echo "Starting IntelOwl installation. Please wait..."

# Download and install packages required to start IntelOwl
wget https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Docker/install-docker.sh

chmod +x install-docker.sh

bash install-docker.sh

# Define IntelOwl working directory
WORK_DIR="/opt"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

# Clone the IntelOwl project repository
git clone https://github.com/intelowlproject/IntelOwl

# Enter in the project directory
cd IntelOwl/

# Run helper script to verify installed dependencies and configure basic stuff
./initialize.sh

# HTTPS webGUI config (generate a self-signed certificate / important: test only!)
tee /opt/IntelOwl/configuration/nginx/openssl-san.conf <<EOF
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
O  = Trusted-CA
CN = Root

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

# Create a ECDSA self-signed IntelOwl private key and certificate using SAN
openssl req -x509 -newkey ec \
  -pkeyopt ec_paramgen_curve:secp384r1 \
  -keyout /etc/ssl/private/intelowl.key \
  -out /etc/ssl/certs/intelowl.crt \
  -sha256 \
  -days 36500 \
  -nodes \
  -config /opt/IntelOwl/configuration/nginx/openssl-san.ext \
  -extensions v3_req

# Configure necessary permissions
chmod 600 /etc/ssl/private/intelowl.key && chmod 644 /etc/ssl/certs/intelowl.crt

chown root:root /etc/ssl/private/intelowl.key /etc/ssl/certs/intelowl.crt

# IntelOwl web server config
tee /opt/IntelOwl/configuration/nginx/https.conf <<EOF
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/ssl/certs/intelowl.crt;
    ssl_certificate_key /etc/ssl/private/intelowl.key;
EOF

cat /opt/IntelOwl/configuration/nginx/https.conf

# Check IntelOwl web server config changes
nginx -t

# Restart IntelOwl web server
systemctl reload nginx

# Start the app
./start prod up

#---------------------------------
# Start the app in https mode
#./start prod up --https
#---------------------------------

# Now the application is running on http://localhost:80

# Create a super user
# docker exec -ti intelowl_uwsgi python3 manage.py createsuperuser


# Now you can login with the created user from http://localhost:80/login

# Have fun!

#-----------------------------------------------
# apt install -y python3-pip python-is-python3
#
# python -m pip install --upgrade pywin32
