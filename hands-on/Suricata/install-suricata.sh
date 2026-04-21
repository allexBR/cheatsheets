#!/bin/bash
# -----------------------------------------------------------------------------------
# Installing Suricata (via Backports) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Tue Apr 21 20:12:28 UTC 2026
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

# Capture the output of Suricata version
SURICATA_VER=$(/usr/bin/suricata -V 2>&1 | grep -oP '\d+\.\d+\.\d+')

# Checks if the variable is not empty
if [ -z "$SURICATA_VER" ]; then
    echo "[-] Error: Suricata not found or version not identified."
    exit 1
fi
echo "[+] Version detected: $SURICATA_VER"

# Performs download using the currently installed version of Suricata
wget -P /tmp https://rules.emergingthreats.net/open/suricata-${SURICATA_VER}/emerging.rules.tar.gz

# Performs download using other open-source rules
wget -P /tmp https://ti.stamus-networks.io/open/stamus-lateral-rules.tar.gz
wget -P /var/lib/suricata/rules https://sslbl.abuse.ch/blacklist/ja3_fingerprints.rules
wget -P /var/lib/suricata/rules https://sslbl.abuse.ch/blacklist/sslblacklist_tls_cert.rules
wget -O /var/lib/suricata/rules/urlhaus.rules https://urlhaus.abuse.ch/downloads/ids

# Extract the rules from downloaded file and copy them to the required path
tar -zxf /tmp/emerging.rules.tar.gz -C /var/lib/suricata/rules/ --strip-components=1 --wildcards '*.rules'
tar -zxf /tmp/stamus-lateral-rules.tar.gz -C /var/lib/suricata/rules/ --strip-components=1 --wildcards '*.rules'

# Remove the compressed file
rm /tmp/*.tar.gz

# # Unify all rules into a single suricata.rules file safely
cd /var/lib/suricata/rules/ && cat *.rules > rules.tmp && rm *.rules && mv rules.tmp suricata.rules

# Adjusts read permissions for Suricata downloaded rules
find /var/lib/suricata/rules -name "*.rules" -exec chmod 644 {} + -exec chown root:root {} +

# Check Suricata merged rules file
suricata -T -c /etc/suricata/suricata.yaml -v

# Start Suricata using the main network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    echo "Error: The main network interface could not be detected!"
    exit 1
fi
echo "Starting Suricata on the network interface: $INTERFACE"

# Performs a copy of the suricata.yaml original file and apply the changes
# Changes eth0 default value to detected network interface and
# Changes the Suricata rules template (suricata.rules) to a generic format.
sed -i.bak -e "s/interface: .*/interface: $INTERFACE/g" \
           #-e 's/^[[:space:]]*- suricata.rules/#  - suricata.rules\n  - "*.rules"/' \
           /etc/suricata/suricata.yaml

# Reload System daemon
systemctl daemon-reload

# Enable automatic Suricata service startup
systemctl enable suricata

# Start Suricata service
systemctl start suricata

# Check Suricata service status
systemctl status suricata



# Refresh the rules without taking down the service (Hot Reload)
# suricatasc -c reload-rules

# Check for rule updates
# suricata-update



#------------------------------------------------------------------------------------
#---------------------------------IMPORTANT-NOTES------------------------------------
#
# Start Suricata (manual mode)
# INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
# /usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE" -D
#
#
#
# >> Start Suricata in HIPS Mode <<
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
