#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Mailutils on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Mar 26 14:17:35 UTC 2026
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
echo "#  Starting the Mailutils installation. Please wait...  #"
echo "#######################################################"

apt clean ; apt update ; apt upgrade -y
apt install -y build-essential libtool libssl-dev libpam0g-dev libgnutls28-dev libgsasl7-dev libreadline-dev libncurses-dev
apt install -y libsqlite3-dev libwrap0-dev

wget https://ftp.gnu.org/gnu/mailutils/mailutils-3.21.tar.gz
tar zxf mailutils-*.tar.gz
rm mailutils-*.tar.gz
cd mailutils-3.*

./configure --prefix=/usr/local --with-ssl --with-gnutls --with-pam
make -s -j$(nproc)
make install

echo "/usr/local/lib" | tee /etc/ld.so.conf.d/mailutils.conf
ldconfig
ls /usr/local/bin | grep mail

rm -rf mailutils-3.*

mail --version
