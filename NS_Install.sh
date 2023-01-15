#!/bin/bash

echo
echo "JamOrHam Nightscout Installer - Designed for Google Compute Minimal Ubuntu 20 micro instance"
echo

if [ "`id -u`" != "0" ]
then
echo "Script needs root - use sudo bash NS_Install.sh"
echo "Cannot continue.."
exit 5
fi

clear
dialog --colors --msgbox "      \Zr Developed by the xDrip team \Zn\n\n\
Some required packages will be installed now.  It will take about 15 minutes to complete.  This terminal needs to be kept open.  Press enter to proceed.\n\n\
If this is not a good time, you can press escape now to cancel." 13 50
if [ $? = 255 ]
then
clear
exit
fi
clear

if [ ! -s /var/SWAP ]
then
echo "Creating swap file"
dd if=/dev/zero of=/var/SWAP bs=1M count=2000
chmod 600 /var/SWAP
mkswap /var/SWAP
fi
swapon 2>/dev/null /var/SWAP

echo "Installing system basics"
sudo apt-get update
sudo apt-get -y install wget gnupg libcurl4 openssl liblzma5
sudo apt-get -y install dirmngr apt-transport-https lsb-release ca-certificates
sudo apt-get -y install net-tools
sudo apt-get -y install build-essential
# Please don't add any more utilities here.  Please instead, add them to update_packages.sh.

/xDrip/scripts/update_packages.sh

# Create mongo user and admin.
echo -e "use Nightscout\ndb.createUser({user: \"username\", pwd: \"password\", roles:[\"readWrite\"]})\nquit()" | mongo
echo -e "use admin\ndb.createUser({ user: \"mongoadmin\" , pwd: \"mongoadmin\", roles: [\"userAdminAnyDatabase\", \"dbAdminAnyDatabase\", \"readWriteAnyDatabase\"]})\nquit()" | mongo

cd /srv

echo "Installing Nightscout"
cd "$(< repo)" 
sudo git reset --hard  # delete any local edits.
sudo git pull  # Update database from remote.

sudo npm install
sudo npm run generate-keys

for loop in 1 2 3 4 5 6 7 8 9
do
read -t 0.1 dummy
done

# Add log
rm -rf /tmp/Logs
echo -e "Installation phase 1 completed     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs
 
