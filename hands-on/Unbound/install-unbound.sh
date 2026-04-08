#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS (with cache DB module) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Wed Apr 08 17:45:01 UTC 2026
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

# Before starting the whole process...
# Check if unbound package is listed in the dpkg database
echo "Checking for existing Unbound installations..."
if dpkg -l | grep -q unbound; then
    echo "Existing Unbound installation found. Removing it to ensure a clean source build..."
    # Stop the service before removing the files to avoid crashing them
    systemctl stop unbound >/dev/null 2>&1
    # Remove the package and dependencies that will no longer be used
    apt purge --auto-remove -y unbound unbound-anchor unbound-host >/dev/null 2>&1
    # Remove residual directories
    rm -rf /etc/unbound /var/log/unbound /var/lib/unbound
    echo "Previous version and configuration files removed."
else
    echo "No existing Unbound installation detected. Proceeding with compilation..."
fi

# Check if the 'unbound' group exists; if not, creates it.
if ! getent group unbound >/dev/null; then
    echo "Creating Unbound group..."
    /usr/sbin/groupadd unbound
fi
# Check if the 'unbound' user exists; if not, creates and adds them to the group
if ! id -u unbound >/dev/null 2>&1; then
    echo "Creating Unbound user..."
    /usr/sbin/useradd -g unbound -s /usr/sbin/nologin -r unbound
else
    # Ensure that he is part of the group if it already exists
    /usr/sbin/usermod -aG unbound unbound
fi

echo "The user and group Unbound are present in the system!"

# Displays the user and group Unbound
getent passwd | cut -d: -f1 | grep -w unbound
getent group | cut -d: -f1 | grep -w unbound

# Redis (cache DB module) installation is required
apt install -y lsb-release curl gpg
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
apt update
apt install -y redis-server
cp /etc/redis/redis.conf /etc/redis/redis.conf.example
sed -i '$a \
\
# Redis Socket Connection \
unixsocket /var/run/redis/redis.sock \
unixsocketperm 707' /etc/redis/redis.conf

systemctl restart redis-server

echo "#########################################################"
echo "# Starting the Unbound DNS installation. Please wait... #"
echo "#########################################################"

# Initial System repositories update
apt clean ; apt update ; apt upgrade -y

# Install required dependencies
apt install -y apt-transport-https ca-certificates curl lsb-release

# Install DNS root hints and DNSSEC trust anchor (required)
apt install -y dns-root-data unbound-anchor

# Update the system root certification authority
/usr/sbin/update-ca-certificates

# Point the Python interpreter to Python 3 (current default)
apt install -y python-is-python3

# Create the directory /var/lib/unbound/ and grant it the necessary permissions
install -d -m 755 -o unbound -g unbound /var/lib/unbound/

# Create Unbound root.key file
/usr/sbin/unbound-anchor -a /var/lib/unbound/root.key

# Unbound system user must have write permission to the file
chown unbound:unbound /var/lib/unbound/root.key && chmod 644 /var/lib/unbound/root.key

# Install libraries and packages required to start compiling
apt install -y build-essential \
  bison \
  expat \
  flex \
  libevent-dev \
  libexpat1-dev \
  libhiredis-dev \
  libnghttp2-dev \
  libsodium-dev \
  libssl-dev \
  libsystemd-dev \
  libprotobuf-c-dev \
  protobuf-c-compiler \
  python3-dev \
  swig

# Enter in the working directory where the necessary files will be downloaded
cd /tmp

# Download Unbound (latest stable release) source code
wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz

# Extract Unbound source code
tar xzf unbound-*.tar.gz

# Enter in the directory extracted from the compressed file
cd unbound-1*

# Configure the parameters to start the compilation
./configure -q \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --includedir=\${prefix}/include \
  --infodir=\${prefix}/share/info \
  --mandir=\${prefix}/share/man \
  --runstatedir=/run \
  --with-chroot-dir= \
  --with-dnstap-socket-path=/run/dnstap.sock \
  --with-libevent \
  --with-libhiredis \
  --with-libnghttp2 \
  --with-pidfile=/run/unbound.pid \
  --with-rootkey-file=/var/lib/unbound/root.key \
  --with-run-dir=/run \
  --with-user=unbound \
  --disable-dependency-tracking \
  --disable-flto \
  --disable-maintainer-mode \
  --disable-option-checking \
  --disable-rpath \
  --enable-cachedb \
  --enable-dnscrypt \
  --enable-dnstap \
  --enable-silent-rules \
  --enable-subnet \
  --enable-systemd \
  --enable-tfo-client \
  --enable-tfo-server \
  PYTHON=python3 \
  PYTHON_CONFIG=python3-config \
  --with-pythonmodule \
  --with-pyunbound

# Compile Unbound from source code and convert it into binary files
make -s -j$(nproc)

# Install created binary files
make install

# Check and recreate the index for the dynamic libraries
ldconfig

# Create Unbound log file
mkdir -p /var/log/unbound
touch /var/log/unbound/unbound.log

# Configure permissions for the Unbound log file
chown -R unbound:unbound /var/log/unbound/ && chmod 664 /var/log/unbound/unbound.log

# Create the directory /etc/unbound/conf.d/ and grant it the necessary permissions
install -d -m 755 -o root -g unbound /etc/unbound/conf.d/

# Create a symbolic link to the root.hints file in Unbound default path
ln -s /usr/share/dns/root.hints /etc/unbound

# Unbound system user must have write permission to the file
chmod 644 /etc/unbound/root.hints

# Rename default Unbound server configuration file
mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.example

# Creates a new custom Unbound server configuration file
tee /etc/unbound/unbound.conf <<EOF
###################################################################################
#
# Unbound configuration file for Debian.
#
# https://nlnetlabs.nl/documentation/unbound/unbound.conf/
#
# See the unbound.conf(5) man page.
#
# See /usr/share/doc/unbound/examples/unbound.conf for a commented
# reference config file.
#
# An example config file is shown below. Copy this to /etc/unbound/unbound.conf
# and start the server with:
#
#  $  /usr/sbin/unbound -c /etc/unbound/unbound.conf
#
# Most settings are the defaults. Stop the server with:
#
#  $ kill `cat /var/run/unbound.pid`
#
###################################################################################

server:
        # Common Server Options
        directory: "/etc/unbound"
        username: unbound
        chroot: ""
        pidfile: "/var/run/unbound.pid"
        port: 53
        do-udp: yes
        do-tcp: yes
        do-ip4: yes
        do-ip6: yes
        prefer-ip6: no

        # Default Interface to Bind to (listen on all interfaces = 0.0.0.0 - ::0)
        interface-automatic: no
        interface: 127.0.0.1
        interface: ::1

        # Control which clients are allowed to make (recursive) queries to this server
        # By default everything is refused, except for localhost
        access-control: 127.0.0.0/8 allow
        access-control: ::1 allow
        access-control: ::ffff:127.0.0.1 allow
        access-control: 192.168.0.0/16 allow

        # Logging Options
        use-syslog: no
        logfile: /var/log/unbound/unbound.log
        verbosity: 1
        log-queries: yes
        log-replies: yes
        log-tag-queryreply: yes
        log-local-actions: yes
        log-servfail: yes
        log-time-ascii: yes

        # Statistics Options
        statistics-interval: 0
        statistics-cumulative: no
        extended-statistics: yes

        # Prefetching settings
        prefetch: yes
        prefetch-key: yes
        minimal-responses: yes

        # Privacy Options
        hide-identity: yes
        hide-version: yes
        aggressive-nsec: yes
        qname-minimisation: yes

        # System Performance Options
        # Set num-threads equal to the number of CPU cores on the system.
        # For 4 CPUs with 2 cores each, use 8.
        # Set *-slabs to a power of 2 close to the num-threads value.
        # Do this for msg-cache-slabs, rrset-cache-slabs, infra-cache-slabs and key-cache-slabs.
        # This reduces lock contention.
        num-threads: 2
        msg-cache-slabs: 2
        rrset-cache-slabs: 2
        infra-cache-slabs: 2
        key-cache-slabs: 2
        cache-min-ttl: 0
        cache-max-ttl: 86400
        msg-cache-size: 64m
        rrset-cache-size: 128m
        outgoing-range: 8192
        num-queries-per-thread: 4096
        rrset-roundrobin: yes
        serve-expired: yes
        serve-expired-reply-ttl: 0
        so-sndbuf: 4m
        so-rcvbuf: 4m
        so-reuseport: yes
        do-daemonize: no

        # Hardening Options
        harden-glue: yes
        harden-dnssec-stripped: yes
        harden-below-nxdomain: yes
        harden-large-queries: yes
        harden-algo-downgrade: yes
        harden-short-bufsize: yes
        harden-referral-path: yes
        serve-expired: no
        serve-expired-ttl-reset: no

        # Harden Against DNS Cache Poisoning
        unwanted-reply-threshold: 1000000

        # Timeout Behaviour Options
        infra-keep-probing: no

        # Private networks for DNS Rebinding prevention (when enabled)
        # Enforce privacy of these addresses. Strips them away from answers.
        private-address: 0.0.0.0/8
        private-address: 10.0.0.0/8
        private-address: 100.64.0.0/10
        private-address: 169.254.0.0/16
        private-address: 172.16.0.0/12
        private-address: 192.0.2.0/24
        private-address: 192.168.0.0/16
        private-address: 198.18.0.0/15
        private-address: 198.51.100.0/24
        private-address: 203.0.113.0/24
        private-address: 233.252.0.0/24
        private-address: ::1/128
        private-address: 2001:db8::/32
        private-address: fc00::/8
        private-address: fd00::/8
        private-address: fe80::/10

        # Module configuration - validator must be present for DNSSEC
        # Default is "validator iterator"
        module-config: "validator cachedb iterator"

        # DNSSEC Validation Options
        auto-trust-anchor-file: "/var/lib/unbound/root.key"
        val-log-level: 1

        # Bootstrap DNS Root Servers Options
        root-hints: "/etc/unbound/root.hints"
 
        # TLS Options
        tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"


# Cache DB Module Options
cachedb:
        backend: redis
        #redis-server-host: 127.0.0.1
        #redis-server-port: 6379
        #redis-server-password: "<your-redis-password>"
        redis-server-path: "/var/run/redis/redis.sock"
        redis-timeout: 100
        redis-expire-records: no


# Forward zones over TLS (to Public DNS-over-TLS Upstreams)
#forward-zone:
#        name: "."
#        forward-tls-upstream: yes
#        forward-addr: 9.9.9.9@853#dns.quad9.net
#        forward-addr: 1.0.0.2@853#security.cloudflare-dns.com
#        forward-addr: 94.140.14.14@853#dns.adguard-dns.com
#        forward-addr: 76.76.2.2@853#p2.freedns.controld.com
#        forward-addr: 185.228.168.9@853#security-filter-dns.cleanbrowsing.org
#        forward-addr: 86.54.11.213@853#noads.joindns4.eu
#        forward-addr: 194.242.2.4@853#base.dns.mullvad.net
#        forward-addr: 78.47.212.211@853#dns.decloudus.com
#        forward-addr: 62.192.153.243@853#dns.dnsguard.pub
#        forward-addr: 149.112.122.20@853#protected.canadianshield.cira.ca


# Remote Control Options
remote-control:
        control-enable: yes
        control-interface: /run/unbound.sock
        control-use-cert: no
        #server-key-file: "/etc/unbound/unbound_server.key"
        #server-cert-file: "/etc/unbound/unbound_server.pem"
        #control-key-file: "/etc/unbound/unbound_control.key"
        #control-cert-file: "/etc/unbound/unbound_control.pem"


# Import custom configs: the following line includes additional
# configuration files from the /etc/unbound/unbound.conf.d directory.
include: "/etc/unbound/conf.d/*.conf"
EOF

# Creates a custom Unbound configuration file for DNS-over-HTTPS queries forwarding
tee /etc/unbound/conf.d/doh.conf <<EOF
server:
        interface: 127.0.0.1@8443
        https-port: 8443
        http-endpoint: "/dns-query"
        http-notls-downstream: yes
        http-max-streams: 200
        http-query-buffer-size: 1m
        http-response-buffer-size: 1m
EOF

# Check that all Unbound default settings are correct
/usr/sbin/unbound-checkconf /etc/unbound/unbound.conf

# Creates Unbound server keys into Unbound folder
/usr/sbin/unbound-control-setup -d /etc/unbound

# Configure permissions for the Unbound server keys
chmod 640 /etc/unbound/unbound_*.key && chmod 644 /etc/unbound/unbound_*.pem

# Set recursive permissions for the Unbound system user in Unbound folder
chown -R root:unbound /etc/unbound

# Enable log rotation
tee /etc/logrotate.d/unbound <<EOF
/var/log/unbound/unbound.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/sbin/unbound-control -c /etc/unbound/unbound.conf log_reopen > /dev/null 2>&1 || true
    endscript
}
EOF

# Remove default resolv.conf file from the System
rm -f /etc/resolv.conf

# Create a new resolv.conf file
tee /etc/resolv.conf <<EOF
nameserver 127.0.0.1
nameserver ::1
EOF

# Read the current permissions of the resolv.conf file and change the attributes
lsattr /etc/resolv.conf
chattr -e /etc/resolv.conf
chattr +i /etc/resolv.conf

# Download sysctl.conf template to increase system performance
if [ -f /etc/sysctl.conf ]; then
    cp /etc/sysctl.conf /etc/sysctl.conf.backup
fi
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/allexBR/cheatsheets/main/hands-on/Debian/sysctl.conf

# Applies changes immediately without needing to restart
sysctl -p

# Add Unbound as a System service
tee /lib/systemd/system/unbound.service <<EOF
[Unit]
Description=Unbound DNS Resolver
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/unbound -d -c /etc/unbound/unbound.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
LimitNOFILE=16384

[Install]
WantedBy=multi-user.target
EOF

# Analyze and debug system manager (used to access special functions useful for advanced system manager debugging)
systemd-analyze verify /lib/systemd/system/unbound.service || true

# Reload System daemon
systemctl daemon-reload

# Enable automatic Unbound service startup
systemctl enable unbound

# Start Unbound service
systemctl start unbound

# Check Unbound service status
systemctl status unbound

# Displays version and basic post-start test
echo
echo "Unbound version:"
/usr/sbin/unbound -V || true

echo
echo "Recursive query test (A de 'nlnetlabs.nl'):"
drill -p 53 @127.0.0.1 nlnetlabs.nl A 2>/dev/null || dig @127.0.0.1 nlnetlabs.nl A || true

echo
echo "=== End: $(date -Is) ==="
