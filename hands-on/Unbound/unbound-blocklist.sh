#!/bin/bash
# -----------------------------------------------------------------------------------
# Create Unbound DNS Blacklists (DNSBL)
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Mar 26 16:30:58 UTC 2026
# -----------------------------------------------------------------------------------

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

for URL in "${LISTS[@]}"; do
    echo "Downloading: $URL"
    # Download and immediately remove lines that begin with # or empty spaces.
    curl -s "$URL" | grep -v '^#' | grep -v '^\s*$' >> "$TMPFILE"
done

# Fine Tuning:
# - Remove IPs (127.0.0.1, 0.0.0.0) if they exist at the beginning of the line
# - Convert to lowercase
# - Remove invalid characters
# - Remove duplicates
# - Format for Unbound using 'always_refuse' for better performance

echo "server:" > "$OUTPUT"

sed -e 's/127.0.0.1//g' -e 's/0.0.0.0//g' "$TMPFILE" | \
    tr '[:upper:]' '[:lower:]' | \
    grep -Eo '([a-z0-9.-]+\.[a-z]{2,})' | \
    grep -vE '^(localhost|github.com|raw.githubusercontent.com|google.com)$' | \
    sort -u | \
    awk '{print "local-zone: \"" $1 "\" always_refuse"}' >> "$OUTPUT"

# Cleaning up temp files
rm "$TMPFILE"

# Unbound syntax validation
echo "Validating configuration..."
unbound-checkconf "$OUTPUT" && echo "Success! Blacklist generated in $OUTPUT!" || echo "Error in the generated syntax!"


#-------------------------------------------------------------------------------------------------------
# Clears previous file
#echo "server:" > "$OUTPUT"

# Download lists, extract domains, remove duplicates
#TMPFILE=$(mktemp)
#for URL in "${LISTS[@]}"; do
#    echo "Downloading: $URL"
#    curl -s "$URL" >> "$TMPFILE"
#done

# Process:
# - Remove comments (#)
# - Remove IPs (keep only domains)
# - Extract valid domains
# - Remove duplicates
#grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$TMPFILE" | \
#    sort -u | \
#    sed 's/^/local-zone: "/; s/$/" refuse/' >> "$OUTPUT"

# Remove temp file
#rm "$TMPFILE"

#echo "Blacklist generated in $OUTPUT"
