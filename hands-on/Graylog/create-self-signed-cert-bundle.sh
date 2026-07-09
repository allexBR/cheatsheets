#!/bin/bash
# -----------------------------------------------------------------------------------
# Generating self-signed SSL/TLS certificates for Graylog WebUI via Nginx
# IMPORTANT: Do not use this in a prod environment, only for testing!
# Created by allexBR | https://github.com/allexBR
# Last review date: Wed Jul 09 20:49:01 UTC 2026
# -----------------------------------------------------------------------------------

set -Eeuo pipefail
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
openssl ecparam -name secp384r1 -genkey -noout -out graylog.key

# Defining required variables
SERVER_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
#SERVER_HOSTNAME=$(hostname -s)

# Create a temporary configuration file for SAN (Subject Alternative Name) extensions
cat > https.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${SERVER_IP}
DNS.1 = graylog.local
EOF

# Create 'client' certificate signing request (CSR) file
openssl req -new -key graylog.key \
  -subj "/CN=Graylog Open Edition" \
  -out graylog.csr

# Create 'client' self-signed certificate (Valid for 10 years)
openssl x509 -req -in graylog.csr -CA trustedCA.crt -CAkey trustedCA.key \
  -CAcreateserial -out graylog.crt -days 3650 -sha384 -extfile https.ext

# Create the Chain by combining the server certificate and the Root CA certificate
cat graylog.key graylog.crt trustedCA.crt > graylog.pem

# Verify that the files were actually generated and copy them to the required path
# After that, modify necessary permissions
if [ -f graylog.crt ]; then
    cp graylog.key /etc/ssl/private/
    cp graylog.pem /etc/ssl/certs/
    chmod 600 /etc/ssl/private/graylog.key
    chmod 640 /etc/ssl/certs/graylog.pem
    chown root:root /etc/ssl/private/graylog.key /etc/ssl/certs/graylog.pem
    echo -e "\e[38;5;46mDone: Certificates  generated successfully!\e[0m"
else
    echo -e "\e[31mError: OpenSSL failed to generate certificates!\e[0m"
    exit 1
fi

# Remove temp files
rm -rf /tmp/certs

# Allow previous services or installation processes to settle
echo -e "\e[93mThe script is still running! Please wait...\e[0m"
sleep 5

# Create /certs directory
mkdir -p /etc/graylog/server/certs

# Check if Java is installed on the system; if not, install it
if ! command -v java >/dev/null 2>&1; then
    echo "Java not found. Installing OpenJDK..."

    apt clean
    apt update

    JAVA_PKG=$(apt-cache search '^openjdk-[0-9]+-jdk-headless$' \
        | awk '{print $1}' \
        | sort -V \
        | tail -n1)

    if [ -z "$JAVA_PKG" ]; then
        echo "No OpenJDK Headless package found."
        exit 1
    fi

    apt install -y "$JAVA_PKG"
fi

# Locate Java cacerts file
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"

if [ -e "$JAVA_HOME/lib/security/cacerts" ]; then
    CACERTS="$JAVA_HOME/lib/security/cacerts"
elif [ -e "$JAVA_HOME/conf/security/cacerts" ]; then
    CACERTS="$JAVA_HOME/conf/security/cacerts"
else
    echo "Java cacerts file not found."
    exit 1
fi

# Copy Java Trust Store 'cacerts' file to the /certs directory created earlier
cp -a "$CACERTS" /etc/graylog/server/certs/cacerts

# Check if .pem certificate really exists
if [ ! -f /etc/ssl/certs/graylog.pem ]; then
    echo "Certificate '/etc/ssl/certs/graylog.pem' not found."
    exit 1
fi

# Convert PEM certificate to Java compatible format
# openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/graylog.pem | openssl pkcs7 -print_certs -out /etc/graylog/server/certs/graylog-ca.pem
openssl crl2pkcs7 \
    -nocrl \
    -certfile /etc/ssl/certs/graylog.pem \
| openssl pkcs7 \
    -print_certs \
    -out /etc/graylog/server/certs/graylog-ca.pem

# Adjust required permissions
chown root:root /etc/graylog/server/certs/graylog-ca.pem
chmod 640 /etc/graylog/server/certs/graylog-ca.pem

# Import certificate into Java Trust Store
# keytool -importcert -noprompt -cacerts -storepass changeit -alias graylog_ca -file /etc/graylog/server/certs/graylog-ca.pem
if keytool -list \
    -keystore /etc/graylog/server/certs/cacerts \
    -storepass changeit \
    -alias graylog_ca >/dev/null 2>&1; then

    keytool -delete \
        -keystore /etc/graylog/server/certs/cacerts \
        -storepass changeit \
        -alias graylog_ca
fi

keytool -importcert \
    -noprompt \
    -keystore /etc/graylog/server/certs/cacerts \
    -storepass changeit \
    -alias graylog_ca \
    -file /etc/graylog/server/certs/graylog-ca.pem

# Add Java Trust Store configuration to Graylog JVM options
sed -i.bak \
's|^GRAYLOG_SERVER_JAVA_OPTS=.*log4j2\.formatMsgNoLookups=true"$|'\
'GRAYLOG_SERVER_JAVA_OPTS="$GRAYLOG_SERVER_JAVA_OPTS -Dlog4j2.formatMsgNoLookups=true '\
'-Djavax.net.ssl.trustStore=/etc/graylog/server/certs/cacerts '\
'-Djavax.net.ssl.trustStorePassword=changeit"|' \
/etc/default/graylog-server

