#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
# curl https://raw.githubusercontent.com/Navid200/cgm-remote-monitor/MongoDriverVersionCheck_Test/bootstrap.sh | bash -s -- Navid200/cgm-remote-monitor MongoDriverVersionCheck_Test

if [[ "$CLOUD_SHELL" = true ]]; then
  echo "You cannot run this script in Cloud Shell."
  echo "Terminating"
  exit 0
fi

echo 
echo "Bootstrapping the installation files - JamOrHam - Navid200"
echo

# --- GIT CONFIGURATION LOGIC ---
# Hardcoded defaults (Standard Production)
REPO_PATH="jamorham/nightscout-vps"
GIT_BRANCH="vps-2"

# 1. Handle "dev" shortcut
if [ "$1" = "dev" ]; then
  GIT_BRANCH="vps-dev"

# 2. Handle Custom Repository
elif [ ! -z "$1" ]; then
  # If they provided a repo but NO branch ($2 is empty)
  if [ -z "$2" ]; then
    echo
    echo "ERROR: Missing branch name."
    echo "When using a custom repository, you must specify which branch to install."
    echo
    echo "Usage: ... | bash -s -- [username/repo] [branch-name]"
    echo "Example: ... | bash -s -- some-developer/nightscout-vps my-test-branch"
    echo
    exit 1
  fi
  
  # Both repo and branch were provided
  REPO_PATH="$1"
  GIT_BRANCH="$2"
fi

GIT_URL="https://github.com/${REPO_PATH}.git"

echo "Installing from: $GIT_URL"
echo "Using branch:    $GIT_BRANCH"

# We run bootstrap as the first step of a fresh install.  But, we also run bootstrap on a complete system in order to switch repositories, or branches.
# Running bootstrap on a complete system is destructive.  It deletes the contents of the /srv directory, some of which are written by Install Nightscout phase 1.
# What makes this extremely dangerous is that running bootstrap on a working system does not result in a catastrophic failure!  The system remains operational
# for a while, but, eventually fails.
# This is why the status page shows "Missing node_modules" in red after bootstrap until node_modules are restored.
# Regardless, we need to remember this destructive nature of bootstrap.
# One must always run Install Nightscout phase 1 after running bootstrap.

####### Keep this marked content synchronized with the contents of the wait_4_completion.sh file ###
####################### Wait for updates to complete
count=0
apt_present=1
while [ $apt_present -gt 0 ]
do
running_apt=$(ps aux | grep '[a]pt') 
if [ "$running_apt" = "" ]
then
  apt_present=0
else
  echo " $count  Waiting for background processes to complete"
  sleep 10
  count=$((count+10))
fi
done
#######################################################################
sudo apt-get update
sudo apt-get install -y dialog git

ubversion="$(cat /etc/issue | awk '{print $2}')"

if  [[ ! "$ubversion" == "24."* ]]
then
  clear
  dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
This bootstrap is intended for Ubuntu 24.  You are running it on a different version of Ubuntu.  If you intend to update your setup, there is a different recommended approach.  Please contact us for more information at https://github.com/NightscoutFoundation/xDrip/discussions." 15 50
  exit
fi

ExistingSystem=0
if [ ! -z "$(ls /srv)" ]
then
ExistingSystem=1

clear
dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
The script you are running, \"bootstrap\", is designed to initiate an installation. However, the file system does not appear to be empty.\n\n  
If an installation already exists on this machine, pressing Enter will modify it.  If this is not your intention, please press ESC to abort." 14 50
if [ $? -eq 255 ]
then
clear
exit
fi
fi

if [[ ! "$ubversion" == "24.04"* ]] || [[ ! "$(which tbl)" == "" ]] # If the selected version of ubuntu is not what we want or if the main version has been installed instead of minimal
then
  clear
  dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
The Ubuntu installation option is incorrect. Please refer to the guide for detailed instructions." 9 50  
  exit
fi 

clear
dialog --colors --defaultno --yesno "              \Zr Google Cloud Nightscout \Zn\n\n\
This software and its associated online instructions are provided “as is,” without any warranties, express or implied. By using this software, you accept full responsibility and assume all risks associated with its use.\n\n\
The developers and contributors shall not be held liable for any damages, losses, or other consequences arising from the use of this software or its documentation.\n\n\
Before using this software, consult a qualified healthcare professional to determine its suitability for your specific needs.\n\n\
I understand and agree." 21 62
response=$?
if [ $response = 255 ] || [ $response = 1 ]
then
  clear
  exit
fi
clear

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
echo
echo "     Please be patient."
echo

# Clone the repository
sudo git clone "$GIT_URL"

ls > /tmp/repo
sudo mv -f /tmp/repo .    # The repository name is now in /srv/repo
cd "$(< repo)"

sudo git checkout "$GIT_BRANCH"

echo "$GIT_BRANCH" > /tmp/brnch
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
  dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
If any item above the line on the status page (shown next) is red, it indicates an incorrect parameter that could lead to malfunction or additional costs.  Please take note of the issue, delete the virtual machine, and create a new one. For more details, refer to the guide." 13 50
else # If this is an existing installation.
  clear
  dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\nBootstrap is complete.  Press Enter to proceed to the status page." 8 50
fi

# Add log 
/xDrip/scripts/AddLog.sh "Bootstrap completed" /xDrip/Logs

# Bring up the status page
/xDrip/scripts/Status.sh
clear
/xDrip/scripts/menu.sh
  
  
