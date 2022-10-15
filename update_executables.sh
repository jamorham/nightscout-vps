#!/bin/bash

echo
echo "Fetch the latest executables from GitHub"
echo


if [ "`id -u`" != "0" ]
then
echo "Script needs root - execute bootstrap.sh or use sudo bash installation.sh"
echo "Cannot continue.."
exit 5
fi

cd /tmp
if [ -s ./nightscout-vps ]
then
sudo rm -r nightscout-vps # If the directory already exists in the tmp directory, delete it.
fi
sudo git clone https://github.com/jamorham/nightscout-vps.git # Clone the install repository.
cd nightscout-vps
sudo git checkout vps-1
sudo git pull
sudo chmod 755 *.sh # Change premissions to allow execution by all.
sudo mv -f *.sh /srv/nightscout-vps # Overwrite the executables in the install directory with the new ones.
cd ..
sudo rm -r nightscout-vps # DElete the temporary pull directory.

