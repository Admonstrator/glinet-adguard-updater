#!/bin/sh
#
#
# Description: This script updates AdGuardHome to the latest version.
# Thread: https://forum.gl-inet.com/t/how-to-update-adguard-home-testing/39398
# Author: Admon
# Date: 2024-03-13
# Updated: 2024-03-07
SCRIPT_VERSION="2024.04.13.01"
#
# Usage: ./update-adguardhome.sh [--ignore-free-space]
# Warning: This script might potentially harm your router. Use it at your own risk.
#
# Populate variables
AVAILABLE_SPACE=$(df -k / | tail -n 1 | awk '{print $4}')
ARCH=$(uname -m)
FIRMWARE_VERSION=$(cut -c1 </etc/glversion)
TEMP_FILE="/tmp/AdGuardHome.tar.gz"

# Detect firmware version
# Only continue if firmware version is 4 or higher
if [ "${FIRMWARE_VERSION}" -lt 4 ]; then
    echo "This script only works on firmware version 4 or higher."
    exit 1
fi

# Check if --ignore-free-space is used
if [ "$1" = "--ignore-free-space" ]; then
    IGNORE_FREE_SPACE=1
else
    IGNORE_FREE_SPACE=0
fi

# Choose AGH_VERSION_NEW based on architecture
if [ "$ARCH" = "aarch64" ]; then
    AGH_VERSION_NEW="https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_arm64.tar.gz"
elif [ "$ARCH" = "armv7l" ]; then
    AGH_VERSION_NEW="https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_armv7.tar.gz"
else
    echo "This script only works on arm64 and armv7."
    exit 1
fi

if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
    echo "Skipping free space check, because --ignore-free-space is used"
else
    if [ "$AVAILABLE_SPACE" -lt 35000 ]; then
        echo "Not enough space available. Please free up some space and try again."
        echo "The script needs at least 35 MB of free space."
        echo "---"
        echo "On devices with less internal storage, you can use --ignore-free-space to continue."
        exit 1
    fi
fi

# Function for backup
backup() {
    echo "Creating backup of AdGuard Home config ..."
    tar czf /root/AdGuardHome_backup.tar.gz /etc/AdGuardHome
    echo "Backup created: /root/AdGuardHome_backup.tar.gz"
}

# Function for creating the persistance script
create_persistance_script() {
    echo "Creating persistance script in /usr/bin/enable-adguardhome-update-check ..."
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
    echo "Creating entry in rc.local ..."
    if ! grep -q "/usr/bin/enable-adguardhome-update-check" /etc/rc.local; then
        sed -i "/exit 0/i . /usr/bin/enable-adguardhome-update-check" "/etc/rc.local"
    fi
}

# Function for persistance
upgrade_persistance() {
    echo "Modifying /etc/sysupgrade.conf ..."
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
     SCRIPT_VERSION_NEW=$(curl -s "https://raw.githubusercontent.com/Admonstrator/glinet.forum/main/scripts/update-adguardhome/update-adguardhome.sh" | grep -o 'SCRIPT_VERSION="[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{2\}"' | cut -d '"' -f 2 || echo "Failed to retrieve script version")
    if [ "$SCRIPT_VERSION_NEW" != "$SCRIPT_VERSION" ]; then
        echo -e "\033[33mA new version of this script is available: $SCRIPT_VERSION_NEW\033[0m"
        echo -e "\033[33mThe script will now be updated ...\033[0m"
        wget -qO /tmp/update-adguardhome.sh "https://raw.githubusercontent.com/Admonstrator/glinet.forum/main/scripts/update-adguardhome/update-adguardhome.sh"
        # Get current script path
        SCRIPT_PATH=$(readlink -f "$0")
        # Replace current script with updated script
        rm "$SCRIPT_PATH"
        mv /tmp/update-adguardhome.sh "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "\033[32mThe script has been updated successfully. It will restart in 3 seconds ...\033[0m"
        sleep 3
        exec "$SCRIPT_PATH" "$@"
    else
        echo -e "\033[32mYou are using the latest version of this script!\033[0m"
    fi
}

# Check if the script is up to date
invoke_update "$@"

echo "Another GL.iNET router script by Admon for the GL.iNET community"
echo "---"
echo -e "\033[31mWARNING: THIS SCRIPT MIGHT POTENTIALLY HARM YOUR ROUTER!\033[0m"
echo -e "\033[31mIt's only recommended to use this script if you know what you're doing.\033[0m"
echo "---"
echo "This script will update AdGuard Home on your router."
echo "Do you want to continue? (y/N)"
read answer

if [ "$answer" != "${answer#[Yy]}" ]; then
    # Ask for confirmation when --ignore-free-space is used
    if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
        echo -e "\033[31m---\033[0m"
        echo -e "\033[31mWARNING: --ignore-free-space is used. There will be no backup of your current config of AdGuard Home!\033[0m"
        echo -e "\033[31mYou might need to reset your router to factory settings if something goes wrong.\033[0m"
        echo -e "\033[31m---\033[0m"
        echo "Are you sure you want to continue? (y/N)"
        read answer
        if [ "$answer" != "${answer#[Yy]}" ]; then
            echo "Ok, continuing ..."
        else
            echo "Ok, see you next time!"
            exit 0
        fi
    fi
    # Create backup of AdGuardHome
    if [ "$IGNORE_FREE_SPACE" -eq 1 ]; then
        echo "Skipping backup, because --ignore-free-space is used"
    else
        backup
    fi
    # Download latest version of AdGuardHome
    echo "Downloading latest Adguard Home version ..."
    wget -qO $TEMP_FILE $AGH_VERSION_NEW
    # Extracting
    echo "Extracting Adguard Home ..."
    # If directory already exists, remove it
    if [ -d /tmp/AdGuardHome ]; then
        rm -rf /tmp/AdGuardHome
    fi
    mkdir /tmp/AdGuardHome
    tar xzf $TEMP_FILE -C /tmp/AdGuardHome
    # Removing archive
    rm $TEMP_FILE
    # Search for AdGuardHome binary
    AGH_BINARY=$(find /tmp/AdGuardHome -name AdGuardHome -type f)
    if [ -f $AGH_BINARY ]; then
        echo "AdGuardHome binary found, download was successful!"
    else
        echo "AdGuardHome binary not found. Exiting ..."
        echo "Please report this issue on the GL.iNET forum."
        exit 1
    fi
    # Stop AdGuardHome
    echo "Stopping Adguard Home ..."
    /etc/init.d/adguardhome stop 2 &>/dev/null
    sleep 2
    # Stop it by killing the process if it's still running
    if pgrep AdGuardHome; then
        killall AdGuardHome
    fi
    # Remove old AdGuardHome
    echo "Moving AdGuardHome to /usr/bin ..."
    rm /usr/bin/AdGuardHome
    mv $AGH_BINARY /usr/bin/AdGuardHome
    # Remove temporary files
    echo "Removing temporary files ..."
    rm -rf /tmp/AdGuardHome
    # Restart AdGuardHome
    echo "Restarting AdGuard Home ..."
    /etc/init.d/adguardhome restart 2 &>/dev/null
    # Make persistance
    echo "The update was successful. Do you want to make the installation permanent?"
    echo "This will make your AdGuard Home config persistant - even after a firmware up-/ or downgrade."
    echo "It could lead to issues, even if not likely. Just keep that in mind."
    echo "In worst case, you might need to remove the config from /etc/sysupgrade.conf and /etc/rc.local."
    echo "Do you want to make the installation permanent? (y/N)"
    read answer_create_persistance
    if [ "$answer_create_persistance" != "${answer_create_persistance#[Yy]}" ]; then
        echo "Making installation permanent ..."
        create_persistance_script
        upgrade_persistance
        /usr/bin/enable-adguardhome-update-check
    fi
else
    echo "Ok, see you next time!"
fi
echo "Script finished."
exit 0
