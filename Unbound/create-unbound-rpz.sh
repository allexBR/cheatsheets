#!/bin/bash
# -----------------------------------------------------------------------------------
# Deploy Unbound Response Policy Zone (RPZ)
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

mkdir -p /etc/unbound/zonefiles

chown unbound:unbound /etc/unbound/zonefiles && chmod 750 /etc/unbound/zonefiles

tee /etc/unbound/conf.d/rpz.conf <<EOF
server:
    module-config: "respip validator iterator"

rpz:
#   name: "certpl"
    zonefile: "/etc/unbound/zonefiles/certpl.rpz.local"
#   url: https://hole.cert.pl/domains/v2/domains_rpz.db
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_certpl"

rpz:
    name: "hagezipro.rpz.local."
    zonefile: "/etc/unbound/zonefiles/hagezipro.rpz.local"
    url: https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/pro.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_hagezipro"

rpz:
#   name: "malwarefilter"
    zonefile: "/etc/unbound/zonefiles/malwarefilter.rpz.local"
#   url: https://malware-filter.gitlab.io/malware-filter/phishing-filter-rpz.conf
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_malwarefilter"

rpz:
#   name: "stevenblackhosts"
    zonefile: "/etc/unbound/zonefiles/stevenblackhosts.rpz.local"
#   url: https://scripttiger.github.io/alts/rpz/blacklist.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: rpz_stevenblackhosts

rpz:
    name: "threatfox.rpz.local."
    zonefile: "/etc/unbound/zonefiles/threatfox.rpz.local"
    url: https://threatfox.abuse.ch/downloads/threatfox.rpz
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_urlhaus"

rpz:
    name: "urlhaus.rpz.local."
    zonefile: "/etc/unbound/zonefiles/urlhaus.rpz.local"
    url: https://urlhaus.abuse.ch/downloads/rpz/
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_urlhaus"
EOF

touch /etc/unbound/zonefiles/hagezipro.rpz.local

touch /etc/unbound/zonefiles/threatfox.rpz.local

touch /etc/unbound/zonefiles/urlhaus.rpz.local

curl -o /etc/unbound/zonefiles/certpl.rpz.local https://hole.cert.pl/domains/v2/domains_rpz.db

curl -o /etc/unbound/zonefiles/malwarefilter.rpz.local https://malware-filter.gitlab.io/malware-filter/phishing-filter-rpz.conf

curl -o /etc/unbound/zonefiles/stevenblack_hosts.rpz.local https://scripttiger.github.io/alts/rpz/blacklist.txt

chown unbound:unbound /etc/unbound/zonefiles/*.rpz.local && chmod 640 /etc/unbound/zonefiles/*.rpz.local

unbound-control status

unbound-checkconf -c /etc/unbound/unbound.conf

systemctl restart unbound

# cat /etc/unbound/zonefiles/threatfox.rpz.local
