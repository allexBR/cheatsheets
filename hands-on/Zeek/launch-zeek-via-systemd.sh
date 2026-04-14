#!/bin/bash
# -----------------------------------------------------------------------------------
# Launch Zeek Network Security Monitor via Systemd on Debian Server
# Created by allexBR | https://github.com/allexBR
# Source: https://github.com/awelzel/zeekctl-systemd
# Last review date: Mon Apr 13 21:38:42 UTC 2026
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

echo "########################################"
echo "# Starting the process. Please wait... #"
echo "########################################"

# Install required package in a non-interactive mode
/opt/zeek/bin/zkg install --force https://github.com/awelzel/zeekctl-systemd || \
    { echo "[ERROR] Failed to install the zeekctl-systemd package."; exit 1; }

# Enables systemd support in the Zeek configuration file
echo "[INFO] Configuring systemd.enabled in zeekctl.cfg..."
if ! grep -q "^systemd.enabled = 1" /opt/zeek/etc/zeekctl.cfg; then
{
        echo ""
        echo "# Enable Systemd integration"
        echo "systemd.enabled = 1"
    } >> /opt/zeek/etc/zeekctl.cfg
    echo "[OK] Entry added to zeekctl.cfg"
else
    echo "[OK] systemd enabled is already set!"
fi

# Ensure a zeek user and group exists
# Check if the 'zeek' group exists; if not, creates it
if ! getent group zeek > /dev/null 2>&1; then
    echo "[INFO] The 'zeek' group not found! Creating..."
    /usr/sbin/groupadd -r zeek || { echo "[ERROR] Failed to create zeek group."; exit 1; }
else
    echo "[OK] The 'zeek' group already exists."
fi

# Check if the 'zeek' user exists; if not, creates it
if ! getent passwd zeek > /dev/null 2>&1; then
    echo "[INFO] The 'zeek' user not found! Creating...."
    /usr/sbin/useradd -g zeek -s /usr/sbin/nologin -d /opt/zeek -M -r zeek || \
        { echo "[ERROR] Failed to create zeek user."; exit 1; }
else
    echo "[OK] The 'zeek' user already exists."
fi

# Ensure if Zeek's logs/ and spool/ directory is owned by zeek user
# Applies permissions only if required directories exist
if [ -d "/opt/zeek/logs" ] && [ -d "/opt/zeek/spool" ]; then
    echo "[INFO] Adjusting permissions in /logs and /spool..."
    chown -R root:zeek /opt/zeek/logs /opt/zeek/spool || { echo "[ERROR] Change owner failed."; exit 1; }
    chmod -R 2770 /opt/zeek/logs /opt/zeek/spool || { echo "[ERROR] Change mode failed"; exit 1; }
    echo "[OK] Permissions successfully configured!"
else
    echo "[ERROR] Destination directories not found. Was Zeek installed correctly?"
    exit 1
fi

# Install the Zeek cluster's unit files onto the *local* system
/opt/zeek/bin/zeekctl install

# Check the created systemd unit files:
ls -ahl /usr/lib/systemd/system/zeek-*
ls -ahl /etc/systemd/system/zeek.target.wants/
ls -ahl /etc/systemd/system/zeek-*@*.d/*

# Reloads the systemd daemon to recognize new files.
systemctl daemon-reload

# Start the Zeek cluster (zeekctl start) would work too.
systemctl start zeek.target

# Status the Zeek cluster
systemctl status zeek.target


#-------------------------------------------------------------------
# Stop the Zeek cluster
# systemctl stop zeek.target
#
# Restart individual Zeek processes
# systemctl restart zeek-logger@1 zeek-proxy@1 zeek-worker@4
#
#-------------------------------------------------------------------
