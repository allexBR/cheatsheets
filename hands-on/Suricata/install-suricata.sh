#!/bin/bash
# -----------------------------------------------------------------------------------
# Installing Suricata (via Backports) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Sat Apr 11 21:18:51 UTC 2026
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

echo "##################################################"
echo "# Starting Suricata installation. Please wait... #"
echo "##################################################"

# Add Debian backports to sources.list
cat > /etc/apt/sources.list.d/debian-backports.sources <<EOF
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Update system repositories
apt clean ; apt update ; apt upgrade -y

# Installing Suricata package from backports
apt -y install -t trixie-backports suricata

# Check that the Suricata service is actually down
systemctl stop suricata                                                                                                        

# Download Suricata ET open rules file
wget -P /tmp https://rules.emergingthreats.net/open/suricata-8.0.4/emerging.rules.tar.gz

# Extract the rules from downloaded file and copy them to the required path
tar -zxf /tmp/emerging.rules.tar.gz -C /var/lib/suricata/rules/ --strip-components=1 --wildcards '*.rules'

# Remove the compressed file
rm /tmp/emerging.rules.tar.gz

# Creates the unified file in the format that Suricata uses
cat /var/lib/suricata/rules/*.rules > /var/lib/suricata/rules/suricata.rules

# Removes all .rules files EXCEPT suricata.rules
find /var/lib/suricata/rules/ -type f -name "*.rules" ! -name "suricata.rules" -delete

# Start Suricata using the main network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    echo "Error: The main network interface could not be detected!"
    exit 1
fi
echo "Starting Suricata on the network interface: $INTERFACE"

# Performs a backup of the original 'suricata.yaml' file
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak

# Changes eth0 value in Suricata config file to detected network interface
sed -i "s/interface: .*/interface: $INTERFACE/g" /etc/suricata/suricata.yaml

# Start Suricata service
systemctl enable suricata && systemctl start suricata

#-----------------------------------------------------------------------------
# Start Suricata (manual mode)
#INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
#/usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE" -D
#-----------------------------------------------------------------------------
