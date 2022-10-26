#!/bin/bash

echo
echo "Install Nightscout again, from the official repository or from a fork"
echo

# Setting the defaults to correspond to the official Nightscout repository. 
user="nightscout"
repo="cgm-remote-monitor"
brnch="master"

clear #  Clear the screen before placing the next dialog on.
dialog --colors --yesno "     \Zr Developed by the xDrip team \Zn\n\n\
Reinstall official Nightscout?\n\n
Choose Yes to install the latest version of official Nightscout.\n\n
Choose No to install from a fork (advanced).\n\n
Or, press escape to cancel." 16 50
ans=$?
if [ $ans = 255 ] # Exit if escape is pressed.
then
clear # Clear the screen before exiting.
echo "Escape"
echo "Cannot continue."
exit 5
elif [ $ans = 1 ] # We need Github details
then
# Clear fork parameters so that we can detect user not entering them all.
user=""
repo=""
brnch=""

# open fd
exec 3>&1

# Ask for the fork details. 
clear # Clear the screen before placing the next dialog on.
VALUES=$(dialog --colors --ok-label "Submit" --form "     \Zr Developed by the xDrip team \Zn\n\n\
Enter the GitHub details for the Nightscout version you want to install.\n" 14 50 0 "User ID:" 1 1 "$user" 1 14
25 0 "Repository:" 2 1 "$repo" 2 14 25 0 "Branch:" 3 1 "$brnch" 3 14 25 0 2>&1 1>&3)
ans2=$?
if [ $ans2 = 255 ] || [ $ans2 = 1 ] # Exit if escaped or cancelled
then
clear # Clear dialog.
echo "Escape or Cancel"
echo "Cannot continue."
exit 5
fi

# close fd
exec 3>&-

# Assign the entered values to corresponding parameters 
user=$(echo "$VALUES" | sed -n 1p)
repo=$(echo "$VALUES" | sed -n 2p)
brnch=$(echo "$VALUES" | sed -n 3p)
if [ "$user" = "" ] || [ "$repo" = "" ] || [ "$brnch" = "" ] # Abort if either paramter was left blank. 
then
clear # clear before exiting
echo "Missing fork parameters"
echo "Cannot continue."
exit 5
fi
fi
clear  # Clear the last dialog

cd /
if [ -s ./nightscout_start ] # Delete the previous install directory if it exists.
then
sudo rm -r nightscout_start
fi
sudo mkdir nightscout_start # Create a directory where the GitHub fork will be extracted to.
cd /nightscout_start

combined="https://github.com/$user/$repo.git" # This is the path to the repository we are installing from.
sudo git clone $combined

# Kill Nightscout to speed up the install.
sudo pkill -f SCREEN
cd $repo
sudo git checkout $brnch
sudo git pull

sudo npm install
sudo npm run postinstall # Complete the install.


# Create the first section of the Nightscout start script replacing the $repo variable
# with its value, the entered repository title. 
cat> /etc/nightscout-start.sh<<EOF

#!/bin/sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
. /etc/nsconfig
export MONGO_COLLECTION="entries"
export MONGO_CONNECTION="mongodb://username:password@localhost:27017/Nightscout"
export INSECURE_USE_HTTP=true
export HOSTNAME="127.0.0.1"
export PORT="1337"
cd /nightscout_start/$repo
EOF

# Create the last section of the Nightscout start script
# not replacing the argument of while with its value.
cat>> /etc/nightscout-start.sh<< "EOF"

while [ "`netstat -lnt | grep 27017 | grep -v grep`" = "" ]
do
echo "Waiting for mongo to start"
sleep 5
done
sleep 5
while [ 1 ]
do
node server.js
sleep 30
done
EOF

sudo reboot # Reboot so that Nightscout starts.
 
