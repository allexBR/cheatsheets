#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS on Debian Server
# Created by allexBR | https://github.com/allexBR
# -----------------------------------------------------------------------------------

# --- Validating privileges and re-executing as root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script requires root privileges."
  echo "Enter the root password when prompted to continue."
  # Resolves the absolute path of the script for correct re-execution
  SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0")"
  # Re-executes the script in a root login shell while preserving arguments
  exec su - -c "/bin/bash \"$SCRIPT_PATH\" $*"
fi

apt clean ; apt update ; apt upgrade -y

apt install -y unbound-anchor lsb-release ca-certificates apt-transport-https curl

update-ca-certificates

cd /tmp

apt install -y build-essential bison flex libssl-dev libexpat1-dev libevent-dev libnghttp2-dev libsystemd-dev libsodium-dev libhiredis-dev python3-dev swig protobuf-c-compiler libprotobuf-c-dev

apt install -y python-is-python3

wget https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz

tar xzf unbound-*.tar.gz

cd unbound-1*

./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --runstatedir=/run \
  --with-run-dir=/run/unbound \
  --with-pidfile=/run/unbound.pid \
  --with-libevent \
  --with-libnghttp2 \
  --with-rootkey-file=/var/lib/unbound/root.key \
  --disable-dependency-tracking \
  --disable-flto \
  --disable-maintainer-mode \
  --disable-option-checking \
  --disable-rpath \
  --disable-silent-rules \
  --enable-systemd \
  --enable-dnscrypt \
  --enable-tfo-client \
  --enable-tfo-server \
  PYTHON=python3 \
  PYTHON_CONFIG=python3-config \
  --with-pyunbound \
  --with-pythonmodule

make

make install

ldconfig

adduser --system --group --no-create-home --quiet unbound

touch /var/log/unbound

chown root:unbound /var/log/unbound

chmod 640 /var/log/unbound

install -d -m 755 -o root -g unbound /etc/unbound/conf.d/

install -d -m 755 -o unbound -g unbound /var/lib/unbound/

unbound-anchor -a /var/lib/unbound/root.key

chmod 644 /var/lib/unbound/root.key

curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

chmod 644 /etc/unbound/root.hints

rm -f /etc/resolv.conf

tee /etc/resolv.conf <<EOF
nameserver 127.0.0.1
nameserver ::1
EOF

#lsattr /etc/resolv.conf
#chattr -e /etc/resolv.conf
#chattr +i /etc/resolv.conf

tee /lib/systemd/system/unbound.service <<EOF
[Unit]
Description=Unbound DNS Resolver
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/unbound -d -c /etc/unbound/unbound.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemd-analyze verify /lib/systemd/system/unbound.service || true

unbound-control-setup -d /etc/unbound

chmod 640 /etc/unbound/unbound_*.key

chmod 644 /etc/unbound/unbound_*.pem

mv /etc/unbound/unbound.conf /etc/unbound/unbound.conf.example

chown -R root:unbound /etc/unbound

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
        # Common settings
        directory: "/etc/unbound"
        username: unbound
        chroot: ""
        pidfile: "/var/run/unbound.pid"
        port: 53
        do-udp: yes
        do-tcp: yes
        do-ip4: yes
        do-ip6: no

        # Interface IP(s) to bind to (listen on all interfaces 0.0.0.0 - ::0)
        interface-automatic: no
        interface: 127.0.0.1
        interface: ::1

        # Logging settings
        use-syslog: no
        logfile: /var/log/unbound
        log-time-ascii: yes
        verbosity: 1

        # Statistics settings
        statistics-interval: 86400
        statistics-cumulative: no
        extended-statistics: yes

        # Prefetching settings
        prefetch: yes
        prefetch-key: yes

        # Privacy settings
        hide-identity: yes
        hide-version: yes
        aggressive-nsec: yes
        qname-minimisation: yes

        # System performance settings
        rrset-cache-slabs: 2
        msg-cache-slabs: 2
        key-cache-slabs: 2
        infra-cache-slabs: 2
        num-threads: 2
        outgoing-range: 8192
        num-queries-per-thread: 4096
        so-sndbuf: 425984
        so-rcvbuf: 425984
        do-daemonize: yes
        so-reuseport: yes

        # Hardening settings
        harden-glue: yes
        harden-dnssec-stripped: yes
        harden-below-nxdomain: yes
        harden-large-queries: yes
        harden-referral-path: yes
        serve-expired: no
        serve-expired-ttl-reset: no

        # Harden against DNS cache poisoning
        unwanted-reply-threshold: 1000000

        # DNS queries logging
        log-queries: yes
        log-replies: yes
        log-tag-queryreply: no
        log-servfail: yes
        log-local-actions: yes

        # Timeout behaviour
        infra-keep-probing: no

        # Bootstrap root servers
        root-hints: "/etc/unbound/root.hints"

        # Private networks for DNS Rebinding prevention (when enabled)
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
        module-config: "validator iterator"

        # DNSSEC validation settings
        auto-trust-anchor-file: "/var/lib/unbound/root.key"
        val-log-level: 1

        # DNSCrypt-proxy to work
        #do-not-query-localhost: no

        # TLS settings
        tls-cert-bundle: "/etc/ssl/certs/ca-certificates.crt"


# Forward zones over TLS settings (Public DNS-over-TLS Upstreams)
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


# Remote control settings
remote-control:
    control-enable: yes
    control-interface: 127.0.0.1
    control-port: 8953
    server-key-file: "/etc/unbound/unbound_server.key"
    server-cert-file: "/etc/unbound/unbound_server.pem"
    control-key-file: "/etc/unbound/unbound_control.key"
    control-cert-file: "/etc/unbound/unbound_control.pem"


# Import custom configs: the following line includes additional
# configuration files from the /etc/unbound/unbound.conf.d directory.
include-toplevel: "/etc/unbound/conf.d/*.conf"
EOF


unbound-checkconf /etc/unbound/unbound.conf

systemctl daemon-reload

systemctl status unbound

systemctl enable unbound

systemctl start unbound


# Display version and basic post-start test
echo
echo "Unbound version:"
/usr/sbin/unbound -V || true

echo
echo "Recursive query test (A de 'nlnetlabs.nl'):"
drill -p 53 @127.0.0.1 nlnetlabs.nl A 2>/dev/null || dig @127.0.0.1 nlnetlabs.nl A || true

echo
echo "=== End: $(date -Is) ==="
