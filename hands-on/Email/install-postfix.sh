#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS (with cache DB module) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Mar 26 14:08:15 UTC 2026
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

echo "#######################################################"
echo "#  Starting the Postfix installation. Please wait...  #"
echo "#######################################################"

apt clean ; apt update ; apt upgrade -y
apt install -y build-essential
apt install -y libdb-dev m4 libmysqlclient-dev libicu-dev libsasl2-dev libssl-dev libnsl-dev
apt install -y libpcre3-dev libpcre2-dev pkg-config libcdb-dev libsqlite3-dev libpq-dev

groupadd -g 32 postfix && groupadd -g 126 postdrop
useradd -c "Postfix Daemon User" -d /var/spool/postfix -g postfix -s /bin/false -u 32 postfix
chown -v postfix:postfix /var/mail

wget https://linorg.usp.br/postfix/release/official/postfix-3.11.1.tar.gz
tar zxf postfix-*.tar.gz
rm postfix-*.tar.gz
cd postfix-3.*

make makefiles CCARGS="-DHAS_CDB -DUSE_TLS -I/usr/include/openssl/ \
-DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl \
-DHAS_MYSQL -I/usr/include/mysql \
-DHAS_PCRE=2 `pcre2-config --cflags`" \
AUXLIBS="-lssl -lcrypto -lsasl2 -lmysqlclient -lz -lm /usr/lib/x86_64-linux-gnu/libcdb.a" \
AUXLIBS_PCRE="`pcre2-config --libs8`"

make -s -j$(nproc)

sh postfix-install -non-interactive  \
   daemon_directory=/usr/lib/postfix \
   manpage_directory=/usr/share/man  \
   html_directory=/usr/share/doc/postfix-3.10.4/html \
   readme_directory=/usr/share/doc/postfix-3.10.4/readme

rm -rf postfix-3.*

/usr/sbin/postfix check

/usr/sbin/postfix status

/usr/sbin/postfix start

/usr/sbin/postfix -c /etc/postfix set-permissions

postconf mail_version
