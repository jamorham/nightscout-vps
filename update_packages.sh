#!/bin/bash

echo
echo "Install packages only if they are not installed already. - Navid200"
echo

# Let's install the missing needed packages.

sudo apt-get update

whichpack=$(which vis)
if [ "$whichpack" = "" ]
then
  sudo apt-get -y install vis
fi

whichpack=$(which nano)
if [ "$whichpack" = "" ]
then
  sudo apt-get -y install nano
fi

whichpack=$(which screen)
if [ "$whichpack" = "" ]
then
  sudo apt-get -y install screen
fi

whichpack=$(which jq)
if [ "$whichpack" = "" ]
then
  sudo apt-get -y install jq
fi

whichpack=$(which qrencode)
if [ "$whichpack" = "" ]
then
  sudo apt-get -y install qrencode
fi
 

# Add log
rm -rf /tmp/Logs
echo -e "The packages have been installed     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs
 
