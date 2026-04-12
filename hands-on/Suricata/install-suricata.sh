#!/bin/bash
# -----------------------------------------------------------------------------------
# Installing Suricata (via Backports) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Sat Apr 11 22:37:08 UTC 2026
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

# Check for rule updates
suricata-update

# Reload System daemon
systemctl daemon-reload

# Enable automatic Suricata service startup
systemctl enable suricata

# Start Suricata service
systemctl start suricata

# Check Suricata service status
systemctl status suricata



#------------------------------------------------------------------------------------
#---------------------------------IMPORTANT-NOTES------------------------------------
#
# Start Suricata (manual mode)
# INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
# /usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE" -D
#
#
#
# Start Suricata in IPS Mode
#
# 1. nftables Firewall Rules
#
# Create a specific table for Suricata
#--------------------------------------
# nft add table inet suricata_ips
#
#
# Add the INPUT and OUTPUT chains
#---------------------------------
# nft add chain inet suricata_ips input { type filter hook input priority 0 \; }
# nft add chain inet suricata_ips forward { type filter hook forward priority 0 \; }
# nft add chain inet suricata_ips output { type filter hook output priority 0 \; }
#
#
# Sends traffic to NFQUEUE 0
# With the bypass, if Suricata is not running, the packet goes
# straight through instead of getting stuck in the queue
#--------------------------------------------------------------
# nft add rule inet suricata_ips input queue num 0 bypass
# nft add rule inet suricata_ips forward queue num 0 bypass
# nft add rule inet suricata_ips output queue num 0 bypass
#
#
#
# Applies nftables firewall rules
#---------------------------------
# nft -f /etc/nftables.conf
#
#
# cat /etc/nftables.conf
#
# table inet suricata_ips {
#    chain input {
#        type filter hook input priority 0; policy accept;
#        queue num 0 bypass
#    }
#    chain forward {
#        type filter hook forward priority 0; policy accept;
#        queue num 0 bypass
#    }
#    chain output {
#        type filter hook output priority 0; policy accept;
#        queue num 0 bypass
#    }
# }
#
#
#
# 2. Transforms all alerts into 'drops' in the main rules file
# sed -i 's/^alert/drop/g' /var/lib/suricata/rules/suricata.rules
#
#
#
# 3. Start Suricata in q (queue) mode via Systemd
# systemctl stop suricata
#
# mkdir -p /etc/systemd/system/suricata.service.d/
#
# cat > /etc/systemd/system/suricata.service.d/ips.conf <<EOF 
# [Service]
# Type=simple
# ExecStart=
# ExecStart=/usr/bin/suricata -q 0 -c /etc/suricata/suricata.yaml --pidfile /var/run/suricata/suricata.pid
# EOF
#
#
#
# 4. Reload Systemd and restart Suricata in IPS mode (-q 0)
# systemctl daemon-reload
# systemctl restart suricata
#
#------------------------------------------------------------------------------------
