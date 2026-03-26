#!/bin/bash
# -----------------------------------------------------------------------------------
# Create Unbound DNS Blacklists (DNSBL)
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Mar 26 14:44:38 UTC 2026
# -----------------------------------------------------------------------------------

# Output file path
OUTPUT="/etc/unbound/conf.d/dnsbl.conf"

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
