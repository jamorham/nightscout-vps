#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
# curl https://raw.githubusercontent.com/Navid200/cgm-remote-monitor/RemoveFreeDNS_Test/bootstrap.sh | bash

echo 
echo "Bootstrapping the installation files - JamOrHam - Navid200"
echo

# We run bootstrap as the first step of a fresh install.  But, we also run bootstrap on a complete system in order to switch repositories, or branches.
# Running bootstrap on a complete system is destructive.  It deletes the contents of the /srv directory, some of which are written by Install Nightscout phase 1.
# What makes this extremely dangerous is that running bootstrap on a working system does not result in a catastrophic failure!  The system remains operational
# for a while, but, eventually fails.
# This is why the status page shows "Missing node_modules" in red after bootstrap until node_modules are restored.
# Regardless, we need to remember this destructive nature of bootstrap.
# One must always run Install Nightscout phase 1 after running bootstrap.

sudo apt-get update
sudo apt-get install dialog

ExistingSystem=0
if [ ! -z "$(ls /srv)" ]
then
ExistingSystem=1
clear
dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
The script you are running, \"bootstrap\", is meant to initiate an installtion.  However, the file system does not seem to be empty.\n\n\
If you already have an installtion on this machine and proceed by pressing enter, it will be modified.  If that's not your intention, please press escape to abort." 14 50
if [ $? -eq 255 ]
then
clear
exit
fi
fi
clear

ubversion="$(cat /etc/issue | awk '{print $2}')"
if [ "$ExistingSystem" = "0" ]  # Only if this is not an existing installation
then
  if [[ ! "$ubversion" = "20.04"* ]] || [[ ! "$(which vi)" = "" ]] # If the selected version of ubuntu is not what we want or if the main version has been installed instead of minimal
  then
  clear
  dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
The Ubuntu version on the virtual machine is incorrect.  You need to delete the virtual machine and create a new one.  Please refer to the guide for the details." 10 50
  exit
  fi 

  sudo apt-get install -y  git python gcc g++ make
  sudo apt-get -y install netcat
fi

if [ ! -s /xDrip ]
then
sudo mkdir /xDrip
fi
cd /xDrip
sudo rm -rf scripts
sudo -rf ConfigServer
sudo mkdir scripts

cd /srv
sudo rm -rf *
sudo git clone https://github.com/jamorham/nightscout-vps.git  # ✅✅✅✅✅ Main - Uncomment before PR.
#sudo git clone https://github.com/Navid200/cgm-remote-monitor.git  # ⛔⛔⛔⛔⛔ For test - Comment out before PR.

ls > /tmp/repo
sudo mv -f /tmp/repo .    # The repository name is now in /srv/repo
cd "$(< repo)"
sudo git checkout vps-1  # ✅✅✅✅✅ Main - Uncomment before PR.
#sudo git checkout RemoveFreeDNS_Test  # ⛔⛔⛔⛔⛔ For test - Comment out before PR.

sudo git branch > /tmp/branch
grep "*" /tmp/branch | awk '{print $2}' > /tmp/brnch
sudo mv -f /tmp/brnch ../.  # The branch name is now in /srv/brnch

sudo git remote -v > /tmp/username
grep "fetch" /tmp/username | awk '{print $2}' >/tmp/username2
FLine=$(</tmp/username2)
IFS='/'
read -a split <<< $FLine
echo ${split[3]} > /tmp/username 
sudo mv -f /tmp/username ../. # The username is now in /srv/username

if [ ! -s update_scripts.sh ]
then
echo "UNABLE TO DOWNLOAD update_scripts SCRIPT! - cannot continue - please try again!"
exit 5
fi

sudo chmod 755 *.sh
sudo cp -f update_scripts.sh /xDrip/scripts

/xDrip/scripts/update_scripts.sh

# So that the menu comes up as soon as the user logs in (opens a terminal)
cd /tmp
cat > /tmp/start_menu.sh << EOF
#!/bin/sh
sleep 1
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

if [ "$ExistingSystem" = "0" ]  # If this is a new installation.
then
  clear
  dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
If any item above the line on the status page (shown next) is red, it represents an incorrect parameter that could result in malfunction or cost.  \
Please take a note, delete the virtual machine, and create a new one.   For more detail, please refer to the guide." 13 50
else # If this is an existing installation.
  clear
  dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\nBootstrap is complete.  Press enter to go to the status page." 8 50
fi

# Add log 
rm -rf /tmp/Logs
echo -e "Bootstrap completed     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs

# Bring up the status page
/xDrip/scripts/Status.sh
clear
/xDrip/scripts/menu.sh < /dev/tty
  
