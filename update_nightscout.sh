#!/bin/bash

echo
echo "Install Nightscout from a fork - Navid200"
echo

# Only if phase 1 has been completed.
a=$(node -v)
if [ "$a" = ""  ]
then
clear
dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
You need to complete installation phase 1 first." 9 50
exit
fi

got_them=0
while [ $got_them -lt 1 ]
do
go_back=0
# open fd
exec 3>&1

# Ask for the fork details. 
clear
VALUES=$(dialog --colors --ok-label "Submit" --form "     \Zr Developed by the xDrip team \Zn\n\n Enter the GitHub details for the Nightscout version you want to install.\n" 14 50 0 "User ID:" 1 1 "$user" 1 14 25 0 "Repository:" 2 1 "$repo" 2 14 25 0 "Branch:" 3 1 "$brnch" 3 14 25 0 2>&1 1>&3)
response=$?
if [ $response = 255 ] || [ $response = 1 ] # Exit if escaped or cancelled
then
  clear
  exit
fi

# close fd
exec 3>&-

# Assign the entered values to corresponding parameters 
user=$(echo "$VALUES" | sed -n 1p)
repo=$(echo "$VALUES" | sed -n 2p)
brnch=$(echo "$VALUES" | sed -n 3p)
if [ "$user" = "" ] || [ "$repo" = "" ] || [ "$brnch" = "" ] # Abort if either paramter was left blank. 
then
  go_back=1
  clear
  dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\nYou need to enter all three parameters.  Try again."  8 50
fi
if [ $go_back -lt 1 ]
then
  got_them=1
fi

done

clear  # Clear the last dialog

# Last chance to stop before any destructive actions.
dialog --colors --msgbox "    \Zr Developed by the xDrip team \Zn\n\n
The installation will take about 15 minutes.  Nightscout will be down during that period.  You can cancel by pressing escape now.\n\n\
If you proceed, you can minimize this terminal.  But, please don't close it.  After completion, the server will reboot." 13 50
response=$?
if [ $response = 255 ]
then
  clear # Clear dialog.
  echo "Cancel"
  echo "Cannot continue."
  exit 5
fi
clear

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

clear

sudo npm install
sudo npm run postinstall # Complete the install.

for loop in 1 2 3 4 5 6 7 8 9
do
read -t 0.1 dummy
done


# Create the first section of the Nightscout start script replacing the $repo variable
# with its value, the entered repository title. 
cat> /etc/nightscout-start.sh<<EOF

#!/bin/sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
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

. /etc/nsconfig
export MONGO_COLLECTION='entries'
export MONGO_CONNECTION='mongodb://username:password@localhost:27017/Nightscout'
export INSECURE_USE_HTTP='true'
export HOSTNAME='127.0.0.1'
export PORT='1337'

node server.js
sleep 10
done
EOF

# Add log
rm -rf /tmp/Logs
echo -e "Nightscout customization completed     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs

sudo reboot # Reboot so that Nightscout starts.
 
