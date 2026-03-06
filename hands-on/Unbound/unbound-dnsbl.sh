#!/bin/bash
# -----------------------------------------------------------------------------------
# Create Unbound DNS Blacklists (DNSBL)
# Created by allexBR | https://github.com/allexBR
# Last review date: Fri Mar 06 16:57:09 UTC 2026
# -----------------------------------------------------------------------------------

# Output file path
OUTPUT="/etc/unbound/conf.d/dnsblacklist.conf"

# Open-Source Blacklists
LISTS=(
"https://adaway.org/hosts.txt"
"https://pgl.yoyo.org/adservers/serverlist.php?mimetype=plaintext&hostformat=plain"
"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
"https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
"https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
"https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
"https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Spotify-AdBlock.txt"
"https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt"
"https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
"https://small.oisd.nl/unbound"
"https://big.oisd.nl/unbound"
"https://nsfw.oisd.nl/unbound"
"https://blocklistproject.github.io/Lists/abuse.txt"
"https://blocklistproject.github.io/Lists/fraud.txt"
"https://blocklistproject.github.io/Lists/gambling.txt"
"https://blocklistproject.github.io/Lists/malware.txt"
"https://blocklistproject.github.io/Lists/phishing.txt"
"https://blocklistproject.github.io/Lists/piracy.txt"
"https://blocklistproject.github.io/Lists/ransomware.txt"
"https://blocklistproject.github.io/Lists/scam.txt"
"https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
"https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
"https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt"
"https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
"https://v.firebog.net/hosts/static/w3kbl.txt"
"https://v.firebog.net/hosts/BillStearns.txt"
"https://v.firebog.net/hosts/Prigent-Malware.txt"
"https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt"
"https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt"
"https://raw.githubusercontent.com/Dawsey21/Lists/master/main-blacklist.txt"
"https://someonewhocares.org/hosts/zero/hosts"
"http://winhelp2002.mvps.org/hosts.txt"
"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
"http://sysctl.org/cameleon/hosts"
"https://raw.githubusercontent.com/vokins/yhosts/master/hosts"
"https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
"https://phishing.army/download/phishing_army_blocklist_extended.txt"
"https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
"https://raw.githubusercontent.com/notracking/hosts-blocklists/master/unbound/unbound.blacklist.conf"
)

# Clears previous file
echo "server:" > "$OUTPUT"

# Download lists, extract domains, remove duplicates
TMPFILE=$(mktemp)
for URL in "${LISTS[@]}"; do
    echo "Downloading: $URL"
    curl -s "$URL" >> "$TMPFILE"
done

# Process:
# - Remove comments (#)
# - Remove IPs (keep only domains)
# - Extract valid domains
# - Remove duplicates
grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$TMPFILE" | \
    sort -u | \
    sed 's/^/local-zone: "/; s/$/" refuse/' >> "$OUTPUT"

# Remove temp file
rm "$TMPFILE"

echo "Blacklist generated in $OUTPUT"
