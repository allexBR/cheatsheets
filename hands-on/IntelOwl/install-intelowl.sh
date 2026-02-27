#!/bin/bash
# -----------------------------------------------------------------------------
# Cyber Threat Intelligence with IntelOwl on Debian server running over Docker
# Created by allexBR | https://github.com/allexBR
# Sources: https://intelowlproject.github.io/
#          https://github.com/intelowlproject/IntelOwl
# Last review date: Fri Feb 27 11:01:47 UTC 2026
# -----------------------------------------------------------------------------

# Validating privileges and re-executing as root
# Check if the script is already running as root (UID 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges."
    # Check if sudo is available, otherwise try su -
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    else
        echo "Enter the root password to continue."
        exec su -c "bash $0 $@"
    fi
    exit $?
fi

# Define working directory
WORK_DIR="/opt"
cd "$WORK_DIR" || exit 1

echo "[+] Operating in the directory: $WORK_DIR"

#https://github.com/intelowlproject/IntelOwl/releases/
