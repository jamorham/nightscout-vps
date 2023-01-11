#!/bin/bash

echo
echo "Show the base URL required to become master" - Navid200
echo

HOSTNAME=""
. /etc/free-dns.sh

. /etc/nsconfig
apisec=$API_SECRET

if [ "$(node -v)" = "" ] || [ "$HOSTNAME" = "" ] || [ "$apisec" = "" ] # If Node.js is not installed or there is no hostname or password
then
clear
dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
You need to complete Nightscout installation and have a hostname and API_SECRET to show a QR code for setting up xDrip as an uploader." 9 50
exit
fi

baseurl="https://$apisec@$HOSTNAME/api/v1/" 

clear
echo "Developed by the xDrip team"
echo ""
echo "Use auto configure in xDrip to scan this QR code to set up xDrip as your uploader."
echo "This QR code image contains your hostname and password.  Keep it private."
qrencode -s 6 -t UTF8 {"rest":{"endpoint":[\"$baseurl\"]}}
read -p "Press enter to return to the menu."
  
