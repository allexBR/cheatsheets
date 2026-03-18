#!/bin/bash
# -----------------------------------------------------------------------------------
# Deploy Unbound Response Policy Zone (RPZ)
# Created by allexBR | https://github.com/allexBR
# Last review date: Wed Mar 18 09:45:01 UTC 2026
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

install -d -m 750 -o unbound -g unbound /etc/unbound/zonefiles

tee /etc/unbound/conf.d/rpz.conf <<EOF
server:
    module-config: "respip validator iterator"

rpz:
    name: "adguard-ads.rpz.local."
    zonefile: "/etc/unbound/zonefiles/adguard-ads.rpz.local"
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_ads_rpz.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_adguard-ads"

rpz:
    name: "adguard-clickthroughs.rpz.local."
    zonefile: "/etc/unbound/zonefiles/adguard-clickthroughs.rpz.local"
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_clickthroughs_rpz.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_adguard-clickthroughs"

rpz:
    name: "adguard-mailtrackers.rpz.local."
    zonefile: "/etc/unbound/zonefiles/adguard-mailtrackers.rpz.local"
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_mail_trackers_rpz.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_adguard-mailtrackers"

rpz:
    name: "adguard-microsites.rpz.local."
    zonefile: "/etc/unbound/zonefiles/adguard-microsites.rpz.local"
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_microsites_rpz.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_adguard-microsites"

rpz:
    name: "adguard-trackers.rpz.local."
    zonefile: "/etc/unbound/zonefiles/adguard-trackers.rpz.local"
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_trackers_rpz.txt
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_adguard-trackers"

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
    name: "oisd-big.rpz.local."
    zonefile: "/etc/unbound/zonefiles/oisd-big.rpz.local"
    url: https://big.oisd.nl/rpz
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_oisd-big"

rpz:
    name: "oisd-nsfw.rpz.local."
    zonefile: "/etc/unbound/zonefiles/oisd-nsfw.rpz.local"
    url: https://nsfw.oisd.nl/rpz
    rpz-action-override: nxdomain
    rpz-log: yes
    rpz-log-name: "rpz_oisd-nsfw"

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

touch /etc/unbound/zonefiles/adguard-ads.rpz.local

touch /etc/unbound/zonefiles/adguard-clickthroughs.rpz.local

touch /etc/unbound/zonefiles/adguard-mailtrackers.rpz.local

touch /etc/unbound/zonefiles/adguard-microsites.rpz.local

touch /etc/unbound/zonefiles/adguard-trackers.rpz.local

touch /etc/unbound/zonefiles/hagezipro.rpz.local

touch /etc/unbound/zonefiles/oisd-big.rpz.local

touch /etc/unbound/zonefiles/oisd-nsfw.rpz.local

touch /etc/unbound/zonefiles/threatfox.rpz.local

touch /etc/unbound/zonefiles/urlhaus.rpz.local

curl -o /etc/unbound/zonefiles/certpl.rpz.local https://hole.cert.pl/domains/v2/domains_rpz.db

curl -o /etc/unbound/zonefiles/malwarefilter.rpz.local https://malware-filter.gitlab.io/malware-filter/phishing-filter-rpz.conf

curl -o /etc/unbound/zonefiles/stevenblack_hosts.rpz.local https://scripttiger.github.io/alts/rpz/blacklist.txt

chown unbound:unbound /etc/unbound/zonefiles/*.rpz.local && chmod 640 /etc/unbound/zonefiles/*.rpz.local

/usr/sbin/unbound-control status

/usr/sbin/unbound -c /etc/unbound/unbound.conf

systemctl restart unbound

# cat /etc/unbound/zonefiles/threatfox.rpz.local
