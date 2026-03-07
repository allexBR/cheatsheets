#!/bin/bash
# -----------------------------------------------------------------------------------
# Installing Unbound Dashboard on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Sat Mar 07 19:30:01 UTC 2026
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

echo "###############################################################"
echo "# Starting the Unbound Dashboard installation. Please wait... #"
echo "###############################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Install the prerequisite packages
apt install -y apt-transport-https gnupg musl

# steps to install Grafana from the APT repository
# Import the GPG key
mkdir -p /etc/apt/keyrings
wget -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
chmod 644 /etc/apt/keyrings/grafana.asc

# Add a repository for stable releases
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

# Updates the list of available packages
apt update -y

echo "Starting Grafana server installation. Please wait..."

# Installs the latest Grafana Open-Source release
apt install -y grafana

# Reload System daemon
systemctl daemon-reload

# Enable automatic Grafana service startup
systemctl enable grafana-server

# Start Grafana service
systemctl start grafana-server

# Check Grafana service status
systemctl status grafana-server

echo "#--------------------------------------"
echo "# WebGUI access"
echo "# http://<IP-or-FQDN>:3000/"
echo "# Default user/pass ➟ admin/admin"
echo "#--------------------------------------"

#-----------------------------------------------------------------------------------------------------------
# Install Prometheus Monitoring System
echo "Starting Prometheus server installation. Please wait..."

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Install required packages
apt install -y sudo

# Create Prometheus user
/usr/sbin/useradd -M prometheus
/usr/sbin/usermod -L prometheus

# Create required directories
# Ensure the required directories exist and are owned by the Prometheus user
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
mkdir -p /var/log/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
chown prometheus:prometheus /var/log/prometheus

# Download Prometheus source code
wget https://github.com/prometheus/prometheus/releases/download/v3.10.0/prometheus-3.10.0.linux-amd64.tar.gz

# Extract files
tar zxf prometheus-*

# Copy bits of Prometheus to different directories
cp prometheus-3.10.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-3.10.0.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Copy the YAML configuration file to the Prometheus directory
cp -r prometheus-3.10.0.linux-amd64/prometheus.yml /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus/prometheus.yml

# Test if Prometheus runs
sudo -u prometheus /usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/data

# Add Prometheus as a System service
tee /lib/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/data \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries

ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
StandardOutput=append:/var/log/prometheus/prometheus.log
StandardError=inherit

[Install]
WantedBy=multi-user.target
EOF

# Analyze and debug system manager (used to access special functions useful for advanced system manager debugging)
systemd-analyze verify /lib/systemd/system/prometheus.service || true

# Reload System daemon
systemctl daemon-reload

# Enable automatic Prometheus service startup
systemctl enable prometheus

# Start Prometheus service
systemctl start prometheus

# Check Prometheus service status
systemctl status prometheus

# Check Prometheus
ps auxww | grep prometheus
cat /var/log/prometheus/prometheus.log

#-----------------------------------------------------------------------------------------------------------
# Install Prometheus Unbound Exporter
echo "Starting Prometheus Unbound Exporter installation. Please wait..."

# Compiling Unbound Exporter
apt install -y git golang-go 

# Enter in the working directory where the necessary files will be downloaded
cd /tmp

# Download Unbound Exporter source code
git clone https://github.com/ar51an/unbound-exporter

# Enter in the git cloned directory
cd /unbound-exporter

# Start compiling
go mod tidy
go build
strip unbound-exporter

# Copy the created file to the /usr/local/bin/ directory
cp unbound-exporter /usr/local/bin/

# Configure required permissions for the Unbound Exporter file
chown root:root /usr/local/bin/unbound-exporter

# Turn the file into executable
chmod +x /usr/local/bin/unbound-exporter

# Run Unbound Exporter
unbound-exporter -h

# Enter in the working directory where the necessary files will be downloaded
cd /tmp

# Download Unbound dashboard files
wget https://github.com/ar51an/unbound-dashboard/releases/download/v2.3/unbound-dashboard-release-2.3.tar.gz

# Extract files
tar zxf unbound-dashboard-release-*

# Backup original Prometheus YAML file
mv /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.example

# Create a new Prometheus YAML file
tee /etc/prometheus/prometheus.yml <<EOF
# Prometheus Config

global:
  scrape_interval:     5m # Default 1min
  evaluation_interval: 5m # Default 1min
  scrape_timeout:      5s # Default 10s

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules and evaluate them according to evaluation_interval
rule_files:

# Scrape configuration
scrape_configs:
  - job_name: unbound
    scrape_interval: 5m
    scrape_timeout: 5s
    static_configs:
      - targets: ['localhost:9167']
EOF


# Add Prometheus Unbound Exporter as a System service
tee  /lib/systemd/system/unbound-exporter.service <<EOF
[Unit]
Description=Prometheus Unbound Exporter

[Service]
Type=simple
Restart=on-failure
User=root
ExecStart=/usr/local/bin/unbound-exporter \
        --block-file "/etc/unbound/conf.d/dnsbl.conf" \
        --unbound.uri "unix://var/run/unbound.sock"

[Install]
WantedBy=multi-user.target
EOF

# Configure required root permissions
chown root:root /lib/systemd/system/unbound-exporter.service

# Analyze and debug system manager (used to access special functions useful for advanced system manager debugging)
systemd-analyze verify /lib/systemd/system/unbound-exporter.service || true

# Reload System daemon
systemctl daemon-reload

# Enable automatic Prometheus Unbound Exporter service startup
systemctl enable unbound-exporter

# Start Prometheus Unbound Exporter service
systemctl start unbound-exporter

# Check Prometheus Unbound Exporter service status
systemctl status unbound-exporter

# Download Loki and Promtail
wget https://github.com/grafana/loki/releases/download/v3.6.7/loki_3.6.7_amd64.deb
wget https://github.com/grafana/loki/releases/download/v3.6.7/promtail_3.6.7_amd64.deb

# Install Loki and Promtail
dpkg -i loki_3.6.7_amd64.deb
dpkg -i promtail_3.6.7_amd64.deb

# Backup original Loki and Promtail YAML file
mv /etc/loki/config.yml /etc/loki/config.yml.example
mv /etc/promtail/config.yml /etc/promtail/config.yml.example

# Copy the unbound dashboard release config YAML file template to the required paths
cp /tmp/unbound-dashboard-release-2.3/loki/config.yml /etc/loki/
cp /tmp/unbound-dashboard-release-2.3/promtail/config.yml /etc/promtail/

# Services must be restarted
systemctl restart loki
systemctl restart promtail


#-----------------------------------------------------------------------------------------------------------
#  > Import Dashboard (these steps must be done manually)
#
#    Open Grafana UI ➟ http://<IP-or FQDN>:3000/
#
#      • Click Data Sources under Configuration. Click Add data source select Prometheus. Add below options:
#
#           Name ➟ Prometheus
#           Default ➟ On
#           Add URL ➟ http://localhost:9090
#           Add Scrape interval ➟ 5m
#           Hit ➟ Save & test
#
#      • Click Data Sources under Configuration. Click Add data source select Loki. Add below options:
#
#           Name ➟ Loki
#           Add URL ➟ http://localhost:3100
#           Add Maximum lines ➟ 100000
#           Hit ➟ Save & test
#
#
#        Dashboard, unbound-dashboard.json is available in the release. Click Import under Dashboards.
#       
#      • Click Upload JSON file. Select unbound-dashboard.json. Add below options:
#
#           Folder ➟ Dashboards
#           Select Prometheus ➟ Data Source
#           Select Loki ➟ Data Source
#           Hit ➟ Import
#
#
#  ❯ Tips & Notes
#
#    • Grafana:
#      How to ➟ Change grafana landing page to unbound dashboard & Switch between Dark (default) and Light theme.
#
#          Open Grafana UI ➟ http://<IP-or-FQDN>:3000/
#          Click Profile under top right icon
#          Under Preferences select General/Unbound in Home Dashboard drop down
#          Change theme in Interface theme drop down
#          Hit Save
#
#      There is an additional panel in the dashboard at the top right, not visible in the preview.
#      It shows unbound-exporter status and may be beneficial. If you are not interested in that simply remove it.
#      Screenshot below:
#
#        Metrics
#
#    • Prometheus:
#      How to ➟ Remove time series (metrics) collected by prometheus instantly for fresh start & Reduce prometheus journal logging.
#
#        Enable admin API:
#        sudo nano /etc/default/prometheus
#        Add at the top: ARGS="--web.enable-admin-api --log.level=warn"
#        Save & Exit
#
#        To delete all metrics of specific exporter add job_name as last argument in delete cmd:
#        Delete:
#        curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/delete_series?match[]={job="node"}'
# 
#        Purge:
#        curl -X POST -g 'http://localhost:9090/api/v1/admin/tsdb/clean_tombstones'
# 
#        Restart:
#        sudo systemctl restart prometheus
#
#-----------------------------------------------------------------------------------------------------------
