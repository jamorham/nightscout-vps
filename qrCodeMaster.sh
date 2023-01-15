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
dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
You need to complete Nightscout installation and have a hostname and API_SECRET to be able to show a QR code for setting up xDrip as an uploader." 10 50
exit
fi

baseurl="https://$apisec@$HOSTNAME/api/v1/" 

clear
echo "      Developed by the xDrip team"
echo ""
echo ""
echo "You have 2 options for setting up xDrip as your uploader."
echo ""
echo "1- In xDrip, Enable Settings -> Cloud Upload -> Nightscout Sync (REST-API) -> Enabled."
echo "Enter the following line (keep private) on the same page under Base URL."
echo "$baseurl"
echo ""
echo "2- Use auto configure in xDrip to scan the following QR code (keep private)."
qrencode -s 6 -t UTF8 {"rest":{"endpoint":[\"$baseurl\"]}}
read -p "Press enter to return to the menu."
  
