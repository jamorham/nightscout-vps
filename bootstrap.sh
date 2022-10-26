#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

# curl https://raw.githubusercontent.com/Navid200/cgm-remote-monitor/Navid_2022_10_25Test/bootstrap.sh | bash

echo 
echo "Bootstrapping the menu - JamOrHam"
echo

sudo apt-get update
sudo apt-get -y install wget bash
sudo apt-get -y install dialog
sudo apt-get install -y  git python gcc g++ make

cd /tmp
clear
dialog --msgbox "Shortly after you proceed, the server  will\n\
automatically reboot and an expected error\n\
message will appear.\n\
Please wait 30 seconds before clicking on\n\
"Retry" to reconnect.\n\n\
After this, every time you open a terminal,\n\
a menu will offer all the available options.\n\n\
To proceed, press Enter." 15 48
clear

cd /
if [ ! -s xDrip ]
then
sudo mkdir xDrip
fi
cd xDrip
if [ ! -s scripts ]
then
sudo mkdir scripts
fi

cd /tmp
sudo rm update_scripts.sh
wget https://raw.githubusercontent.com/Navid200/cgm-remote-monitor/Navid_2022_10_25Test/update_scripts.sh # Navid's
#wget https://raw.githubusercontent.com/jamorham/nightscout-vps/vps-1/update_scripts.sh # Main
if [ ! -s update_scripts.sh ]
then
echo "UNABLE TO DOWNLOAD update_scripts SCRIPT! - cannot continue - please try again!"
exit 5
fi

sudo chmod 755 update_scripts.sh
sudo mv -f update_scripts.sh /xDrip/scripts

# Updating the scripts
sudo /xDrip/scripts/update_scripts.sh

# So that the menu comes up as soon as the user logs in (opens a terminal)
cd /tmp
cat > /tmp/start_menu.sh << EOF
#!/bin/sh
/xDrip/scripts/menu.sh

EOF
sudo chown root:root start_menu.sh
sudo chmod 755 start_menu.sh
sudo mv -f start_menu.sh /etc/profile.d

if [ "$(grep /xDrip/scripts/menu.sh ~/.bash_aliases)" = "" ] # If there is no alias to menu.sh not even commented out
then
cat >> ~/.bash_aliases << EOF
alias menu="/xDrip/scripts/menu.sh"
EOF
fi

# Reboot
sudo reboot
