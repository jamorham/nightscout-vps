#!/bin/bash

echo
echo "JamOrHam Nightscout Installer - Designed for Google Compute Minimal Ubuntu micro instance"
echo

if [ "`id -u`" != "0" ]
then
echo "Script needs root - use sudo bash NS_Install.sh"
echo "Cannot continue.."
exit 5
fi

clear
# Initial Msgbox
dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
The required packages as well as Nightscout will now be installed. This process will take approximately 25 minutes. Please keep this terminal open. The system will reboot automatically when finished.\n\n\
Press Enter to proceed, or ESC to cancel." 14 50

clear
if [ $? = 255 ]
then
exit
fi

# Function to wrap all installation steps
run_installation() {
    if [ ! -s /var/SWAP ]
    then
        echo "Creating swap file..."
        dd if=/dev/zero of=/var/SWAP bs=1M count=2000
        chmod 600 /var/SWAP
        mkswap /var/SWAP
    fi
    swapon 2>/dev/null /var/SWAP

    echo "Running update_packages.sh..."
    /xDrip/scripts/update_packages.sh
    if [ $? -ne 0 ]; then return 1; fi

    echo "Setting up MongoDB..."
    /xDrip/scripts/wait_4_completion.sh
    mongosh Nightscout --eval 'db.createUser({user: "username", pwd: "password", roles:["readWrite"]})'
    /xDrip/scripts/wait_4_completion.sh
    mongosh admin --eval 'db.createUser({user: "mongoadmin", pwd: "mongoadmin", roles:["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]})'

    echo "Updating Nightscout Repository..."
    cd /srv 
    cd "$(< repo)" 
    git reset --hard
    git pull
    /xDrip/scripts/wait_4_completion.sh
    apt-get update || apt-get update

    LOG_DIR="/xDrip/phase1Logs"
    mkdir -p "$LOG_DIR"
    mv "$LOG_DIR/phase1_npm_3.log" "$LOG_DIR/phase1_npm_4.log" 2>/dev/null
    mv "$LOG_DIR/phase1_npm_2.log" "$LOG_DIR/phase1_npm_3.log" 2>/dev/null
    mv "$LOG_DIR/phase1_npm_1.log" "$LOG_DIR/phase1_npm_2.log" 2>/dev/null
    mv "$LOG_DIR/phase1_npm.log"   "$LOG_DIR/phase1_npm_1.log" 2>/dev/null
    LOG_FILE="$LOG_DIR/phase1_npm.log"

    /xDrip/scripts/wait_4_completion.sh
    
    if ! npm install 2>&1 | tee "$LOG_FILE" || [ "$(ls -A node_modules | grep -v '^\.cache$' | wc -l)" -eq 0 ]
    then
        echo "ERROR: Nightscout install failed."
        return 1
    fi

    echo "Finalizing keys..."
    /xDrip/scripts/wait_4_completion.sh
    npm run-script post-generate-keys

    /xDrip/scripts/AddLog.sh "Installation phase 1 completed" /xDrip/Logs
}

# EXECUTION with progressbox frame
run_installation 2>&1 | stdbuf -oL fold -s -w 75 | dialog --colors \
    --progressbox "                         \Zr Google Cloud Nightscout \Zn\n\n\
 Do not close this window while Phase 1 of the installation is in progress.\n\
 The system will reboot automatically once the process has completed.\n\n\
 An expected error message will appear after reboot.\n\
 Wait 45 seconds before attempting to reconnect.\n\
 " 30 80

# Check if the installation function failed
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
Phase 1 incomplete\n\n\
Nightscout install failed. Please run Phase 1 again." 11 50
    exit 1
fi

# Final Reboot
clear
/xDrip/scripts/reboot.sh

  
