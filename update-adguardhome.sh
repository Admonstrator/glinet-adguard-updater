#!/bin/sh
# shellcheck shell=dash
# NOTE: 'echo $SHELL' reports '/bin/ash' on the routers, see:
# - https://en.wikipedia.org/wiki/Almquist_shell#Embedded_Linux
# - https://github.com/koalaman/shellcheck/issues/1841
#
# Description: This script updates AdGuardHome to the latest version.
# Thread: https://forum.gl-inet.com/t/how-to-update-adguard-home-testing/39398
# Author: Admon
# Date: 2024-03-13
SCRIPT_VERSION="2024.08.22.03"
SCRIPT_NAME="update-adguardhome.sh"
UPDATE_URL="https://raw.githubusercontent.com/Admonstrator/glinet-adguard-updater/main/update-adguardhome.sh"
AGH_TINY_URL="https://github.com/Admonstrator/glinet-adguard-updater/releases/latest/download/"
#
# Usage: ./update-adguardhome.sh [--ignore-free-space]
# Warning: This script might potentially harm your router. Use it at your own risk.
#
# Populate variables
TEMP_FILE="/tmp/AdGuardHomeNew"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
INFO='\033[0m' # No Color
IGNORE_FREE_SPACE=0

# Function for backup
backup() {
    log "INFO" "Creating backup of AdGuard Home config ..."
    cd /etc
    tar czf /root/AdGuardHome_backup.tar.gz AdGuardHome
    cd - >/dev/null
    log "INFO" "Backup created: /root/AdGuardHome_backup.tar.gz"
}

# Function for creating the persistance script
create_persistance_script() {
    log "INFO" "Creating persistance script in /usr/bin/enable-adguardhome-update-check ..."
    cat <<EOF >/usr/bin/enable-adguardhome-update-check
    #!/bin/sh
    # This script enables the update check for AdGuard Home
    # It should be executed after every reboot
    # Author: Admon
    # Date: 2024-03-06
    if [ -f /etc/init.d/adguardhome ] 
    then
        sed -i '/procd_set_param command \/usr\/bin\/AdGuardHome/ s/--no-check-update //' "/etc/init.d/adguardhome"
    else
        echo "Startup script not found. Exiting ..."
        echo "Please report this issue on the GL.iNET forum."
        exit 1
    fi
EOF
    chmod +x /usr/bin/enable-adguardhome-update-check

    # Creating cron job
    log "INFO" "Creating entry in rc.local ..."
    if ! grep -q "/usr/bin/enable-adguardhome-update-check" /etc/rc.local; then
        sed -i "/exit 0/i . /usr/bin/enable-adguardhome-update-check" "/etc/rc.local"
    fi
}

# Function for persistance
upgrade_persistance() {
    log "INFO" "Modifying /etc/sysupgrade.conf ..."
    # Removing old entry because it's not needed anymore
    if grep -q "/root/AdGuardHome_backup.tar.gz" /etc/sysupgrade.conf; then
        sed -i "/root\/AdGuardHome_backup.tar.gz/d" /etc/sysupgrade.conf
    fi
    # If entry "/etc/AdGuardHome" is not found in /etc/sysupgrade.conf
    if ! grep -q "/etc/AdGuardHome" /etc/sysupgrade.conf; then
        echo "/etc/AdGuardHome" >>/etc/sysupgrade.conf
    fi
    # If entry /usr/bin/AdGuardHome is not found in /etc/sysupgrade.conf
    if ! grep -q "/usr/bin/AdGuardHome" /etc/sysupgrade.conf; then
        echo "/usr/bin/AdGuardHome" >>/etc/sysupgrade.conf
    fi
    # If entry /usr/bin/enable-adguardhome-update-check is not found in /etc/sysupgrade.conf
    if ! grep -q "/usr/bin/enable-adguardhome-update-check" /etc/sysupgrade.conf; then
        echo "/usr/bin/enable-adguardhome-update-check" >>/etc/sysupgrade.conf
    fi
    # If entry /etc/rc.local is not found in /etc/sysupgrade.conf
    if ! grep -q "/etc/rc.local" /etc/sysupgrade.conf; then
        echo "/etc/rc.local" >>/etc/sysupgrade.conf
    fi
}

invoke_update() {
    log "INFO" "Checking for script updates"
    SCRIPT_VERSION_NEW=$(curl -s "$UPDATE_URL" | grep -o 'SCRIPT_VERSION="[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}"' | cut -d '"' -f 2 || echo "Failed to retrieve scriptversion")
    if [ -n "$SCRIPT_VERSION_NEW" ] && [ "$SCRIPT_VERSION_NEW" != "$SCRIPT_VERSION" ]; then
       log "WARNING" "A new version of the script is available: $SCRIPT_VERSION_NEW"
       log "INFO" "Updating the script ..."
       wget -qO /tmp/$SCRIPT_NAME "$UPDATE_URL"
       # Get current script path
       SCRIPT_PATH=$(readlink -f "$0")
       # Replace current script with updated script
       rm "$SCRIPT_PATH"
       mv /tmp/$SCRIPT_NAME "$SCRIPT_PATH"
       chmod +x "$SCRIPT_PATH"
       log "INFO" "The script has been updated. It will now restart ..."
       sleep 3
       exec "$SCRIPT_PATH" "$@"
    else
        log "SUCCESS" "The script is up to date"
    fi
}


preflight_check() {
    AVAILABLE_SPACE=$(df -k / | tail -n 1 | awk '{print $4/1024}')
    AVAILABLE_SPACE=$(printf "%.0f" "$AVAILABLE_SPACE")
    ARCH=$(uname -m)
    FIRMWARE_VERSION=$(cut -c1 </etc/glversion)
    PREFLIGHT=0

    log "INFO" "Checking if prerequisites are met ..."
    if [ "${FIRMWARE_VERSION}" -lt 4 ]; then
        log "ERROR" "This script only works on firmware version 4 or higher."
        PREFLIGHT=1
    else
        log "SUCCESS" "Firmware version: $FIRMWARE_VERSION"
    fi
    if [ "$MODEL" = "GL.iNet GL-MT1300" ]; then
        ARCH="mipsle"
    fi
    if [ "$ARCH" = "aarch64" ]; then
        log "SUCCESS" "Architecture: arm64"
        AGH_VERSION_DOWNLOAD="https://github.com/Admonstrator/glinet-adguard-updater/releases/latest/download/AdGuardHome-linux_arm64"
    elif [ "$ARCH" = "armv7l" ]; then
        log "SUCCESS" "Architecture: armv7"
        AGH_VERSION_DOWNLOAD="https://github.com/Admonstrator/glinet-adguard-updater/releases/latest/download/AdGuardHome-linux_armv7"
    elif [ "$ARCH" = "mips" ]; then
        # Check for GL.iNet GL-MT1300 as it uses mipsle
        MODEL=$(grep 'machine' /proc/cpuinfo | awk -F ': ' '{print $2}')
        if [ "$MODEL" = "GL.iNet GL-MT1300" ]; then
            log "SUCCESS" "Architecture: mipsle"
            AGH_VERSION_DOWNLOAD="https://github.com/Admonstrator/glinet-adguard-updater/releases/latest/download/AdGuardHome-linux_mipsle_softfloat"
        else
            log "SUCCESS" "Architecture: mips"
            AGH_VERSION_DOWNLOAD="https://github.com/Admonstrator/glinet-adguard-updater/releases/latest/download/AdGuardHome-linux_mips_softfloat"
        fi
    else
        log "ERROR" "This script only works on arm64 and armv7."
        PREFLIGHT=1
    fi
    if [ "$AVAILABLE_SPACE" -lt 15 ]; then
        log "ERROR" "Not enough space available. Please free up some space and try again."
        log "ERROR" "The script needs at least 15 MB of free space. Available space: $AVAILABLE_SPACE MB"
        log "ERROR" "If you want to continue, you can use --ignore-free-space to ignore this check."
        if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
            log "WARNING" "--ignore-free-space flag is used. Continuing without enough space ..."
            log "INFO" "Current available space: $AVAILABLE_SPACE MB"
        else
            PREFLIGHT=1
        fi
    else
        log "SUCCESS" "Available space: $AVAILABLE_SPACE MB"
    fi
    # Check if curl is present
    if ! command -v curl >/dev/null; then
        log "ERROR" "curl is not installed."
        PREFLIGHT=1
    else
        log "SUCCESS" "curl is installed."
    fi
    if [ "$PREFLIGHT" -eq "1" ]; then
        log "ERROR" "Prerequisites are not met. Exiting ..."
        exit 1
    else
        log "SUCCESS" "Prerequisites are met."
    fi
}

invoke_intro() {
    echo "┌────────────────────────────────────────────────────────────────────────┐"
    echo "│ GL.iNet router script by Admon 🦭 for the GL.iNet community            |"
    echo "| Version: $SCRIPT_VERSION                                                 |"
    echo "├────────────────────────────────────────────────────────────────────────┤"
    echo "│ WARNING: THIS SCRIPT MIGHT POTENTIALLY HARM YOUR ROUTER!               │"
    echo "│ It's only recommended to use this script if you know what you're doing.│"
    echo "├────────────────────────────────────────────────────────────────────────┤"
    echo "│ This script will update AdGuard Home on your router.                   │"
    echo "└────────────────────────────────────────────────────────────────────────┘"
}

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local color=$INFO # Default to no color

    # Assign color based on level
    case "$level" in
        ERROR)
            level="x"
            color=$RED
            ;;
        WARNING)
            level="!"
            color=$YELLOW
            ;;
        SUCCESS)
            level="✓"
            color=$GREEN
            ;;
        INFO)
            level="→"
            ;;
    esac

    echo -e "${color}[$timestamp] [$level] $message${INFO}"
}

enable_querylog() {
    log "INFO" "Due to the GL firmware, the query log is in RAM only."
    log "INFO" "It will be lost after a reboot or restart of AdGuard Home."
    log "INFO" "This is to prevent the router from running out of memory"
    log "INFO" "and wearing out the flash memory too quickly."
    log "INFO" "We can enable storing the query log on flash for you."
    log "WARNING" "Please keep in mind that this will wear out the flash memory faster."
    log "WARNING" "This is not recommended for routers with only 16 MB of flash memory."
    echo -e "\033[93m┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[93m| Do you want to enable the query log on flash? (y/N) |\033[0m"
    echo -e "\033[93m└─────────────────────────────────────────────────────┘\033[0m"
    read answer_querylog
    if [ "$answer_querylog" != "${answer_querylog#[Yy]}" ]; then
        log "INFO" "Enabling query log ..."
        sed -i '/^querylog:/,/^[^ ]/ s/^  file_enabled: .*/  file_enabled: true/' /etc/AdGuardHome/config.yaml
        log "INFO" "Restarting AdGuard Home ..."
        /etc/init.d/adguardhome restart 2 &>/dev/null
        log "SUCCESS" "Query log is now enabled."
    else
        log "INFO" "Ok, skipping query log ..."
    fi
}

# Check if the script is up to date
preflight_check
invoke_update "$@"
invoke_intro
echo -e "\033[93m┌──────────────────────────────────────────────────┐\033[0m"
echo -e "\033[93m| Are you sure you want to continue? (y/N)         |\033[0m"
echo -e "\033[93m└──────────────────────────────────────────────────┘\033[0m"
read answer

if [ "$answer" != "${answer#[Yy]}" ]; then
    # Ask for confirmation when --ignore-free-space is used
    if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
        log "WARNING" "--ignore-free-space is used. There will be no backup of your current config of AdGuard Home!"
        log "WARNING" "You might need to reset your router to factory settings if something goes wrong."
        echo -e "\033[93m┌──────────────────────────────────────────────────┐\033[0m"
        echo -e "\033[93m| Are you sure you want to continue? (y/N)         |\033[0m"
        echo -e "\033[93m└──────────────────────────────────────────────────┘\033[0m"
        read answer
        if [ "$answer" != "${answer#[Yy]}" ]; then
            log "INFO" "Ok, continuing ..."
        else
            log "ERROR" "Ok, see you next time!"
            exit 0
        fi
    fi
    
    log "INFO" "Detecting latest AdGuard Home version"
    AGH_VERSION_NEW=$(curl -L -s $AGH_TINY_URL/version.txt | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    if [ -z "$AGH_VERSION_NEW" ]; then
        log "ERROR" "Could not get latest AdGuard Home version. Please check your internet connection."
        exit 1
    fi
    log "INFO" "Latest AdGuard Home version: $AGH_VERSION_NEW"
    AGH_VERSION_OLD=$(/usr/bin/AdGuardHome --version | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    log "INFO" "Current AdGuard Home version: $AGH_VERSION_OLD"
        if [ "$AGH_VERSION_NEW" == "$AGH_VERSION_OLD" ]; then
        log "SUCCESS" "You already have the latest version."
        exit 0
    fi
    log "WARNING" "Updating from version $AGH_VERSION_OLD to $AGH_VERSION_NEW"
    # Create backup of AdGuardHome
    if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
        log "WARNING" "Skipping backup, because --ignore-free-space is used"
    else
        backup
    fi
    # Download latest version of AdGuardHome
    log "INFO" "Downloading latest Adguard Home version ..."
    curl -L -s --output $TEMP_FILE $AGH_VERSION_DOWNLOAD
    AGH_BINARY=$(find /tmp -name AdGuardHomeNew -type f)
    if [ -f $AGH_BINARY ]; then
        log "SUCCESS" "AdGuardHome binary found, download was successful!"
    else
        log "ERROR" "AdGuardHome binary not found. Exiting ..."
        log "ERROR" "Please report this issue on the GL.iNET forum."
        exit 1
    fi
    # Stop AdGuardHome
    log "INFO" "Stopping Adguard Home ..."
    /etc/init.d/adguardhome stop 2 &>/dev/null
    sleep 4
    # Stop it by killing the process if it's still running
    AGH_PID=$(pgrep AdGuardHome)
    if [ -n "$AGH_PID" ]; then
        killall AdGuardHome 2>/dev/null
    fi
    # Remove old AdGuardHome
    log "INFO" "Moving AdGuardHome to /usr/bin ..."
    rm /usr/bin/AdGuardHome
    mv $AGH_BINARY /usr/bin/AdGuardHome
    chmod +x /usr/bin/AdGuardHome
    # Restart AdGuardHome
    log "INFO" "Restarting AdGuard Home ..."
    /etc/init.d/adguardhome restart 2 &>/dev/null
    AGH_VERSION_CHECK=$(/usr/bin/AdGuardHome --version | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    log "SUCCESS" "AdGuard Home has been updated to version $AGH_VERSION_CHECK"
    # Enable query log
    enable_querylog
    # Make persistance
    echo -e "\033[93m┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐\033[0m"
    echo -e "\033[93m| The update was successful. Do you want to make the installation permanent?                               |\033[0m"
    echo -e "\033[93m| This will make your AdGuard Home config persistant - even after a firmware up-/ or downgrade.            |\033[0m"
    echo -e "\033[93m| It could lead to issues, even if not likely. Just keep that in mind.                                     |\033[0m"
    echo -e "\033[93m| In worst case, you might need to remove the config from /etc/sysupgrade.conf and /etc/rc.local.          |\033[0m"
    echo -e "\033[93m| Do you want to make the installation permanent? (y/N)                                                    |\033[0m"
    echo -e "\033[93m└──────────────────────────────────────────────────────────────────────────────────────────────────────────┘\033[0m"
    read answer_create_persistance
    if [ "$answer_create_persistance" != "${answer_create_persistance#[Yy]}" ]; then
        log "INFO" "Making installation permanent ..."
        create_persistance_script
        upgrade_persistance
        /usr/bin/enable-adguardhome-update-check
    fi
else
    log "SUCCESS" "Ok, see you next time!"
fi
log "SUCCESS" "Script finished."
exit 0
