#!/bin/bash
# -----------------------------------------------------------------------------------
# Create Unbound DNS Blacklists (DNSBL)
# Created by allexBR | https://github.com/allexBR
# Last review date: Mon Apr 13 19:10:01 UTC 2026
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

echo "###########################################################"
echo "#  Starting Unbound blocklist generation. Please wait...  #"
echo "###########################################################"

# Output file path
OUTPUT="/etc/unbound/conf.d/dnsbl.conf"

# Temp file path
TMPFILE=$(mktemp)

# Open-Source Blacklists
LISTS=(
## Abuse (The Blocklist Project):
"https://blocklistproject.github.io/Lists/abuse.txt"
## AdAway:
"https://adaway.org/hosts.txt"
## AdGuardDNS:
"https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt"
## Anudeep:
"https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
## CERT.PL:
"https://hole.cert.pl/domains/v2/domains.txt"
## Dan Pollock:
"https://someonewhocares.org/hosts/zero/hosts"
## Dandelion Sprout:
"https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
## Disconnect.me:
"https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
## Ethereum Phishing Detect:
"https://raw.githubusercontent.com/MetaMask/eth-phishing-detect/master/src/hosts.txt"
## Geoffrey Frogeye:
"https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
## Maltrail:
"https://raw.githubusercontent.com/stamparm/aux/master/maltrail-malware-domains.txt"
## Malware-Filter (Online Malicious URL):
"https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts-online.txt"
## Malware-Filter (Phishing):
"https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt"
## NoTrack:
"https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
## oisd.nl Big List:
"https://big.oisd.nl/domainswild2"
## oisd.nl NSFW List:
"https://nsfw.oisd.nl/domainswild2"
## Peter Lowe:
"https://pgl.yoyo.org/adservers/serverlist.php?mimetype=plaintext&hostformat=plain"
## Phishing Army:
"https://phishing.army/download/phishing_army_blocklist_extended.txt"
## Phishing Database:
"https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt"
## Prigent-Malware from UT1 Blacklists:
"https://v.firebog.net/hosts/Prigent-Malware.txt"
## Scam Blocklist by DurableNapkin:
"https://raw.githubusercontent.com/durablenapkin/scamblocklist/master/hosts.txt"
## Shadow Whisperer:
"https://raw.githubusercontent.com/ShadowWhisperer/BlockLists/master/Lists/Malware"
## SNAFU:
"https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
## Spotify Ads & Trackers:
"https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Spotify-AdBlock.txt"
## StevenBlack:
"https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
## StopForumSpam:
"https://www.stopforumspam.com/downloads/toxic_domains_whole.txt"
## TR-CERT (USOM):
"https://raw.githubusercontent.com/cenk/trcert-malware/main/trcert-domains.txt"
## uBlock Origin Badware:
"https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt"
## YouTube Ads & Trackers:
"https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
)

echo "Starting download and processing..."

TMPFILE=$(mktemp)
TMP_OUT=$(mktemp)

for URL in "${LISTS[@]}"; do
    echo "Downloading: $URL"
    curl -fsSL "$URL" | grep -v '^#' | grep -v '^[[:space:]]*$' >> "$TMPFILE"
done

echo "server:" > "$TMP_OUT"

sed -e 's/127.0.0.1//g' -e 's/0.0.0.0//g' "$TMPFILE" | \
tr '[:upper:]' '[:lower:]' | \
grep -oE '([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}' | \
grep -vE '^(localhost|github.com|raw.githubusercontent.com|google.com)$' | \
grep -vE '^\.' | \
grep -vE '\.(js|css|png|jpg|jpeg|gif|svg|json|map|txt)$' | \
grep -vE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
grep -vE '^[[:space:]]*$' | \
sort -u | \
awk '{print "local-zone: \"" $1 "\" always_refuse"}' >> "$TMP_OUT"

mv "$TMP_OUT" "$OUTPUT"
rm "$TMPFILE"

echo "Validating configuration..."
/usr/sbin/unbound-checkconf "$OUTPUT" && echo "Check Configuration: OK!" || echo "Error!"

if [ -f "$OUTPUT" ]; then
    echo "Fixing permissions..."
    chown root:unbound "$OUTPUT"
    chmod 644 "$OUTPUT"
fi
echo -e "\e[32m>>> Process completed successfully! <<<\e[0m"
