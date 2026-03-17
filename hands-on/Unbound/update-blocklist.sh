#!/bin/bash
# -----------------------------------------------------------------------------------
# Compiling and Installing Unbound DNS (with cache DB module) on Debian Server
# Created by allexBR | https://github.com/allexBR
# Last review date: Thu Mar 17 16:45:01 UTC 2026
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

# Permissions and required folders
# List of folders that need to exist; if not, create them
FOLDER=(
    "/etc/unbound/blocklists"
)

echo "Checking configuration directories..."

for folder in "${FOLDER[@]}"; do
    if [ ! -d "$folder" ]; then
        echo "Creating directory: $folder"
        install -d -m 755 -o root -g unbound "$folder"
    else
        echo "Directory already exists: $folder"
    fi
done

# Config path
UNBOUND_DIR=/etc/unbound
BLOCKLIST_DIR=$UNBOUND_DIR/blocklists
UNBOUND_CONF_DIR=$UNBOUND_DIR/conf.d/dnsbl.conf

# Blocklists path
ABUSE_BLOCKLIST=$BLOCKLIST_DIR/abuse.hosts
ADAWAY_BLOCKLIST=$BLOCKLIST_DIR/adaway.hosts
ADGUARD_BLOCKLIST=$BLOCKLIST_DIR/adguard.hosts
ANUDEEP_BLOCKLIST=$BLOCKLIST_DIR/anudeep.hosts
BADWARE_BLOCKLIST=$BLOCKLIST_DIR/badware.hosts
CERTPL_BLOCKLIST=$BLOCKLIST_DIR/certpl.hosts
DAN_POLLOCK_BLOCKLIST=$BLOCKLIST_DIR/someonewhocares.hosts
DANDELION_BLOCKLIST=$BLOCKLIST_DIR/dandelion.hosts
DISCONNECTME_BLOCKLIST=$BLOCKLIST_DIR/disconnectme.hosts
ETHEREUM_BLOCKLIST=$BLOCKLIST_DIR/ethereum.hosts
FROGEYE_BLOCKLIST=$BLOCKLIST_DIR/frogeye.hosts
MALTRAIL_BLOCKLIST=$BLOCKLIST_DIR/maltrail.hosts
MALWAREFILTER_BLOCKLIST=$BLOCKLIST_DIR/malwarefilter.hosts
PHISHINGFILTER_BLOCKLIST=$BLOCKLIST_DIR/phishingfilter.hosts
NOTRACK_BLOCKLIST=$BLOCKLIST_DIR/notrack.hosts
OISDBIG_BLOCKLIST=$BLOCKLIST_DIR/oisdbig.hosts
OISDNSFW_BLOCKLIST=$BLOCKLIST_DIR/oisdnsfw.hosts
PHISHINGARMY_BLOCKLIST=$BLOCKLIST_DIR/phishingarmy.hosts
PHISHINGDB_BLOCKLIST=$BLOCKLIST_DIR/phishingdb.hosts
PRIGENTMALWARE_BLOCKLIST=$BLOCKLIST_DIR/prigentmalware.hosts
SCAM_BLOCKLIST=$BLOCKLIST_DIR/scam.hosts
SHADOWWHISPERER_BLOCKLIST=$BLOCKLIST_DIR/shadowwhisperer.hosts
SNAFU_BLOCKLIST=$BLOCKLIST_DIR/snafu.hosts
SPOTIFY_BLOCKLIST=$BLOCKLIST_DIR/spotify.hosts
STEVEN_BLOCKLIST=$BLOCKLIST_DIR/steven.hosts
STOPFORUMSPAM_BLOCKLIST=$BLOCKLIST_DIR/stopforumspam.hosts
TRCERT_BLOCKLIST=$BLOCKLIST_DIR/trcert.hosts
YOUTUBE_BLOCKLIST=$BLOCKLIST_DIR/youtube.hosts
YOYO_BLOCKLIST=$BLOCKLIST_DIR/yoyo.hosts

# Blocklists
# Other host lists can be added here, parse with sed to remove comments and blank lines

## Abuse (The Blocklist Project)
{ echo -e "\e[30;48;5;248mDownloading Abuse Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$ABUSE_BLOCKLIST" -L "https://blocklistproject.github.io/Lists/abuse.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $ABUSE_BLOCKLIST
echo -e "Host list cleaned ..."

## AdAway (Ads)
{ echo -e "\e[30;48;5;248mDownloading AdAway Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$ADAWAY_BLOCKLIST" -L "https://adaway.org/hosts.txt"
echo -e "Host list downloaded ..."
sed -i -E '/localhost/d; /^::1/d; s/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $ADAWAY_BLOCKLIST
echo -e "Host list cleaned ..."

## AdGuardDNS
{ echo -e "\e[30;48;5;248mDownloading AdGuardDNS Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$ADGUARD_BLOCKLIST" -L "https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $ADGUARD_BLOCKLIST
echo -e "Host list cleaned ..."

## Anudeep (Ads & Tracking)
{ echo -e "\e[30;48;5;248mDownloading Anudeep's Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$ANUDEEP_BLOCKLIST" -L "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $ANUDEEP_BLOCKLIST
echo -e "Host list cleaned ..."

## CERT.PL (Domains)
{ echo -e "\e[30;48;5;248mDownloading CERT.PL Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$CERTPL_BLOCKLIST" -L "https://hole.cert.pl/domains/v2/domains.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $CERTPL_BLOCKLIST
echo -e "Host list cleaned ..."

## Dan Pollock (someonewhocares.org)
{ echo -e "\e[30;48;5;248mDownloading Dan Pollock's Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$DAN_POLLOCK_BLOCKLIST" -L "https://someonewhocares.org/hosts/zero/hosts"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $DAN_POLLOCK_BLOCKLIST
echo -e "Host list cleaned ..."

## Dandelion Sprout
{ echo -e "\e[30;48;5;248mDownloading Dandelion Sprout's Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$DANDELION_BLOCKLIST" -L "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
echo -e "Host list downloaded ..."
sed -i -E '/localhost/d; /^::1/d; s/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $DANDELION_BLOCKLIST
echo -e "Host list cleaned ..."

## Disconnect.me (Malvertising)
{ echo -e "\e[30;48;5;248mDownloading Disconnect.me Malvertising Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$DISCONNECTME_BLOCKLIST" -L "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; /disconnect\.me/d; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; /[[:space:]]/d; /^[a-zA-Z0-9]/ s/^/0.0.0.0 /' $DISCONNECTME_BLOCKLIST
echo -e "Host list cleaned ..."

## Ethereum Phishing Detect (Phishing)
{ echo -e "\e[30;48;5;248mDownloading Ethereum Phishing Detect Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$ETHEREUM_BLOCKLIST" -L "https://raw.githubusercontent.com/MetaMask/eth-phishing-detect/master/src/hosts.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $ETHEREUM_BLOCKLIST
echo -e "Host list cleaned ..."

## Frogeye (Trackers)
{ echo -e "\e[30;48;5;248mDownloading Geoffrey Frogeye's Trackers Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$FROGEYE_BLOCKLIST" -L "https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $FROGEYE_BLOCKLIST
echo -e "Host list cleaned ..."

## Maltrail (Domains)
{ echo -e "\e[30;48;5;248mDownloading Maltrail Malware Domains Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$MALTRAIL_BLOCKLIST" -L "https://raw.githubusercontent.com/stamparm/aux/master/maltrail-malware-domains.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $MALTRAIL_BLOCKLIST
echo -e "Host list cleaned ..."

## Malware-Filter (Online Malicious URL)
{ echo -e "\e[30;48;5;248mDownloading Online Malicious URL Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$MALWAREFILTER_BLOCKLIST" -L "https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts-online.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $MALWAREFILTER_BLOCKLIST
echo -e "Host list cleaned ..."

## Malware-Filter (Phishing)
{ echo -e "\e[30;48;5;248mDownloading Malware-Filter Phishing Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$PHISHINGFILTER_BLOCKLIST" -L "https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $PHISHINGFILTER_BLOCKLIST
echo -e "Host list cleaned ..."

## NoTrack (Malware)
{ echo -e "\e[30;48;5;248mDownloading NoTrack Malware Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$NOTRACK_BLOCKLIST" -L "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $NOTRACK_BLOCKLIST
echo -e "Host list cleaned ..."

## oisd.nl Big List (Ads/Phishing/Malvertising/Malware/Spyware/Ransomware/CryptoJacking)
{ echo -e "\e[30;48;5;248mDownloading OISD Big Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$OISDBIG_BLOCKLIST" -L "https://big.oisd.nl/domainswild2"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $OISDBIG_BLOCKLIST
echo -e "Host list cleaned ..."

## oisd.nl NSFW List (Porn/Adult/Shock/Gore)
{ echo -e "\e[30;48;5;248mDownloading OISD NSFW Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$OISDNSFW_BLOCKLIST" -L "https://nsfw.oisd.nl/domainswild2"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $OISDNSFW_BLOCKLIST
echo -e "Host list cleaned ..."

## Phishing Army (Domains)
{ echo -e "\e[30;48;5;248mDownloading Phishing Army Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$PHISHINGARMY_BLOCKLIST" -L "https://phishing.army/download/phishing_army_blocklist_extended.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $PHISHINGARMY_BLOCKLIST
echo -e "Host list cleaned ..."

## Phishing Database (Domains)
{ echo -e "\e[30;48;5;248mDownloading Phishing Database Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$PHISHINGDB_BLOCKLIST" -L "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $PHISHINGDB_BLOCKLIST
echo -e "Host list cleaned ..."

## Prigent-Malware from Université Toulouse Capitole's malware blacklist
{ echo -e "\e[30;48;5;248mDownloading Prigent-Malware Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$PRIGENTMALWARE_BLOCKLIST" -L "https://v.firebog.net/hosts/Prigent-Malware.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $PRIGENTMALWARE_BLOCKLIST
echo -e "Host list cleaned ..."

## Scam Blocklist by DurableNapkin
{ echo -e "\e[30;48;5;248mDownloading DurableNapkin Scam Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$SCAM_BLOCKLIST" -L "https://raw.githubusercontent.com/durablenapkin/scamblocklist/master/hosts.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $SCAM_BLOCKLIST
echo -e "Host list cleaned ..."

## Shadow Whisperer (Malware)
{ echo -e "\e[30;48;5;248mDownloading Shadow Whisperer Malware Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$SHADOWWHISPERER_BLOCKLIST" -L "https://raw.githubusercontent.com/ShadowWhisperer/BlockLists/master/Lists/Malware"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $SHADOWWHISPERER_BLOCKLIST
echo -e "Host list cleaned ..."

## SNAFU (Ads & Tracking)
{ echo -e "\e[30;48;5;248mDownloading The SNAFU Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$SNAFU_BLOCKLIST" -L "https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $SNAFU_BLOCKLIST
echo -e "Host list cleaned ..."

## Spotify (Spotify Ads & Trackers)
{ echo -e "\e[30;48;5;248mDownloading GoodbyeAds-Spotify Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$SPOTIFY_BLOCKLIST" -L "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-Spotify-AdBlock.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $SPOTIFY_BLOCKLIST
echo -e "Host list cleaned ..."

## StevenBlack (Ads, Trackers & Porn)
{ echo -e "\e[30;48;5;248mDownloading StevenBlack Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$STEVEN_BLOCKLIST" -L "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $STEVEN_BLOCKLIST
echo -e "Host list cleaned ..."

## StopForumSpam (Domains)
{ echo -e "\e[30;48;5;248mDownloading StopForumSpam Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$STOPFORUMSPAM_BLOCKLIST" -L "https://www.stopforumspam.com/downloads/toxic_domains_whole.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $STOPFORUMSPAM_BLOCKLIST
echo -e "Host list cleaned ..."

## TR-CERT (USOM)
{ echo -e "\e[30;48;5;248mDownloading TR-CERT Domain Blocklist\e[0m"; } 2> /dev/null
curl --silent -o "$TRCERT_BLOCKLIST" -L "https://raw.githubusercontent.com/cenk/trcert-malware/main/trcert-domains.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $TRCERT_BLOCKLIST
echo -e "Host list cleaned ..."

## uBlock Origin Badware
{ echo -e "\e[30;48;5;248mDownloading uBlock Origin Badware List\e[0m"; } 2> /dev/null
curl --silent -o "$BADWARE_BLOCKLIST" -L "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt"
echo -e "Host list downloaded ..."
#sed -i -E '/^!/d; /##/d; s/\|\|//g; s/\^.*//; s/[[:space:]]*$//; /^[[:space:]]*$/d; /.*\/.*/d; /^[a-zA-Z0-9]/ s/^/0.0.0.0 /' $BADWARE_BLOCKLIST
sed -i -E '/^!/d; /##/d; s/\|\|//g; s/\^.*//; /[?&%=*]/d; /^[[:space:]]*$/d; /.*\/.*/d; s/[[:space:]]*$//; /^[a-zA-Z0-9.-]+$/ s/^/0.0.0.0 /; /^(0.0.0.0 )/!d' $BADWARE_BLOCKLIST
echo -e "Host list cleaned ..."

## YouTube (YouTube Ads & Trackers)
{ echo -e "\e[30;48;5;248mDownloading GoodbyeAds-YouTube BlockList\e[0m"; } 2> /dev/null
curl --silent -o "$YOUTUBE_BLOCKLIST" -L "https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Extension/GoodbyeAds-YouTube-AdBlock.txt"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $YOUTUBE_BLOCKLIST
echo -e "Host list cleaned ..."

## Yoyo (Ads)
{ echo -e "\e[30;48;5;248mDownloading Yoyo Adservers BlockList\e[0m"; } 2> /dev/null
curl --silent -o "$YOYO_BLOCKLIST" -L "https://pgl.yoyo.org/adservers/serverlist.php?mimetype=plaintext&hostformat=plain"
echo -e "Host list downloaded ..."
sed -i -E 's/#.*//; s/^(127\.0\.0\.1|0\.0\.0\.0)[[:space:]]*//; /^#/d; /^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^/0.0.0.0 /' $YOYO_BLOCKLIST
echo -e "Host list cleaned ..."


## Create unbound configuration block file
{ echo -e "\e[30;48;5;248mCreating Unbound Blocklist\e[0m"; } 2> /dev/null

# Merge other host lists here to unbound blocklist
# The `grep` command below joins the lists. If you have more lists in the future, simply add them
grep -h "^0.0.0.0" \
    "$ABUSE_BLOCKLIST" \
    "$ADAWAY_BLOCKLIST" \
    "$ADGUARD_BLOCKLIST" \
    "$ANUDEEP_BLOCKLIST" \
    "$BADWARE_BLOCKLIST" \
    "$CERTPL_BLOCKLIST" \
    "$DAN_POLLOCK_BLOCKLIST" \
    "$DANDELION_BLOCKLIST" \
    "$DISCONNECTME_BLOCKLIST" \
    "$ETHEREUM_BLOCKLIST" \
    "$FROGEYE_BLOCKLIST" \
    "$MALTRAIL_BLOCKLIST" \
    "$MALWAREFILTER_BLOCKLIST" \
    "$PHISHINGFILTER_BLOCKLIST" \
    "$NOTRACK_BLOCKLIST" \
    "$OISDBIG" \
    "$OISDNSFW" \
    "$PHISHINGARMY" \
    "$PHISHINGDB" \
    "$PRIGENTMALWARE" \
    "$SCAM_BLOCKLIST" \
    "$SHADOWWHISPERER" \
    "$SNAFU_BLOCKLIST" \
    "$SPOTIFY_BLOCKLIST" \
    "$STEVEN_BLOCKLIST" \
    "$STOPFORUMSPAM" \
    "$TRCERT" \
    "$YOUTUBE_BLOCKLIST" \
    "$YOYO_BLOCKLIST" > "$UNBOUND_CONF_DIR"

# Sort and remove duplicates
LC_COLLATE=C sort -uf -o $UNBOUND_CONF_DIR{,}

# Formats to the Unbound defaults
# Two unbound blocklist formats are provided below, always_null (0.0.0.0) & redirect to IP. Use the one you prefer:

# Always null:
sed -i -E -n 's/0.0.0.0 /local-zone: "/;/local-zone:/s/$/." always_null/p' $UNBOUND_CONF_DIR

# Redirect to IP:
# sed -i -E -n 's/0.0.0.0 /local-zone: "/;/local-zone:/s/$/." redirect/p;s/local-zone: /local-data: /;/local-data:/s/" redirect/ A 127.0.0.1"/p' $UNBOUND_CONF_DIR

# Adds the "server:" header required for Unbound
sed -i '1s/^/server:\n/' $UNBOUND_CONF_DIR
echo -e "All lists sorted & uniquely merged to Unbound blocklist format ..."

# Check and reload Unbound blocklist config
{ echo -e "\e[30;48;5;248mReloading Unbound Config\e[0m"; } 2> /dev/null
set -x
# Check Unbound
/usr/sbin/unbound-checkconf /etc/unbound/unbound.conf
# Reload Unbound
/usr/sbin/unbound-control reload_keep_cache
