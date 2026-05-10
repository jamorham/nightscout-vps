#!/bin/bash

echo
echo "Install packages after the installation of Nightscout. - Navid200"
echo

# Let's upgrade packages if available and install the missing needed packages.

# packages
/xDrip/scripts/wait_4_completion.sh
sudo apt-get update
/xDrip/scripts/wait_4_completion.sh
sudo apt-get -y install screen nano qrencode file vis lsb-release apt-transport-https ca-certificates python3-pip bind9-dnsutils nginx python3-certbot-nginx inetutils-ping 
/xDrip/scripts/wait_4_completion.sh
sudo apt -y install python3-django python3-django-extensions python3-werkzeug python3-qrcode

# The last item on the above list of packages must be verified in Status.sh to have been installed.  

# Add log
/xDrip/scripts/AddLog.sh "The secondary packages have been installed" /xDrip/Logs
  
  
