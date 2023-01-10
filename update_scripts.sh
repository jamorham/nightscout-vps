#!/bin/bash

# This should never be called before first being updated to the latest remote release.
# Currently, only bootstrap and menu call this.  Both update this file before calling it.
# If you decide to call this anywhere else, make sure to update the local copy before calling it.

echo
echo "Fetch the latest scripts from GitHub - Navid200"
echo

if [ ! -s /srv/repo ]  # Create the file containing the repository name if nonexistent.
then
cat > /srv/repo << EOF
nightscout-vps
EOF
fi
if [ ! -s /srv/brnch ]  # Create the file containing the branch name if nonexistent.
then
cat > /srv/brnch << EOF
vps-1
EOF
fi
if [ ! -s /srv/username ]  # Create the file containing the user name if nonexistent.
then
cat > /srv/username << EOF
jamorham
EOF
fi

cd /srv
cd "$(< repo)" 
sudo git reset --hard  # delete any local edits.
sudo git pull  # Update database from remote.

sudo chmod 755 *.sh # Change premissions to allow execution by all.
sudo rm -f /xDrip/scripts/*.sh # Remove the existing sh files
sudo cp *.sh /xDrip/scripts # Overwrite the scripts in the scripts directory with the new ones.
sudo rm -rf /xDrip/ConfigServer # Remove the existing ConfigServer directory
sudo cp -r ConfigServer /xDrip/.
cd ..

# Let's install the new packages for those who already have an installation.
qrencodev=$(qrencode --version | sed -n 1p)
if [ "$qrencodev" = "" ] # If qrencode is not installed already
then
  sudo apt-get update
  sudo apt-get -y install qrencode
fi 

# Add log
rm -rf /tmp/Logs
echo -e "The platform has been updated     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs

if [ ! -s /tmp/nodialog_update_scripts ]
then
dialog --colors --msgbox "    \Zr Developed by the xDrip team \Zn\n\n\
Updated scripts will be in effect in a new window." 8 43
clear
fi
 
