#!/bin/bash

echo
echo "Finalizing Nightscout installation"
echo

if [ "$(node -v)" = "" ] # If Node.js is not installed
then
clear
dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
You need to complete install Nightscout phase 1 first." 9 50
exit
fi

if [ "`id -u`" != "0" ]
then
echo "Script needs root - use sudo bash NS_Install2.sh"
echo "Cannot continue.."
exit 5
fi

sudo apt-get install -y nginx python3-certbot-nginx inetutils-ping

if [ "`grep '.well-known' /etc/nginx/sites-enabled/default`" = "" ]
then
sudo rm -f /tmp/nginx.conf
sudo grep -v '^#' /etc/nginx/sites-enabled/default >/tmp/nginx.conf

cat /tmp/nginx.conf | sed -z -e 'sZlocation / {[^}]*}Zlocation /.well-known {\n        try_files $uri $uri/ =404;\n}\n\nlocation / {\nproxy_pass  http://127.0.0.1:1337/;\nproxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\nproxy_set_header X-Forwarded-Proto https;\nproxy_http_version 1.1;\nproxy_set_header Upgrade $http_upgrade;\nproxy_set_header Connection "upgrade";\n}Zg' >/etc/nginx/sites-enabled/default

sudo service nginx stop

else
echo "Nginx config already patched"
fi

sudo service nginx start

sudo systemctl daemon-reload
sudo systemctl start mongodb

echo
echo "Setting up startup service"
echo

if [ ! -s /etc/nsconfig ] # Create a new nsconfig file only if one does not exit already.
then

cat > /etc/nsconfig << EOF

export API_SECRET='YOUR_API_SECRET_HERE'
export ENABLE='careportal food boluscalc bwp cob bgi pump openaps rawbg iob upbat cage sage basal'
export AUTH_DEFAULT_ROLES='denied'
export PUMP_FIELDS='reservoir battery clock'
export DEVICESTATUS_ADVANCED='true'
export THEME='colors'
export DBSIZE_MAX='20000'

EOF

fi

cat > /etc/nightscout-start.sh << "EOF"
#!/bin/sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
cd /srv
cd "$(< repo)" 
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

cs2=`grep 'API_SECRET=' /etc/nsconfig | cut -s -f2 -d'"'` # This is API_SECRET if double quotes are used in nsconfig.
cs1=`grep 'API_SECRET=' /etc/nsconfig | cut -s -f2 -d\'` # This is API_SECRET if single quotes are used in nsconfig.
cs="$cs2"
if [ "$cs2" = "" ]
then
  cs="$cs1" # This is the current secret (API_SECRET) from nsconfig.
fi

got_it=0
while [ $got_it -lt 1 ]
do
go_back=0
clear
exec 3>&1
Value=$(dialog --colors --ok-label "Submit" --form "       \Zr Developed by the xDrip team \Zn\n\n\n\
API_SECRET:   $cs\n\n\
Press escape to keep it, or enter a new API_SECRET with at least 12 characters excluding the following.\n\
  $   \"   '   \\   SPACE   @   / " 16 50 0 "API_SECRET:" 1 1 "$secr" 1 14 25 0 2>&1 1>&3)
response=$?
if [ $response = 255 ] || [ $response = 1 ] # cancled or escaped
then
  ns="$cs"
else 
  ns=$(echo "$Value" | sed -n 1p)
fi
exec 3>&-

if [ ${#ns} -lt 12 ] # Reject if the submission has less than 12 characters.
then
  go_back=1
  clear
  dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
API_SECRET should have at least 12 characters.  Please try again."  8 50
fi
clear

if [ $go_back -lt 1 ]
then
  if [[ $ns == *[\$]* ]] || [[ $ns == *[\"]* ]] || [[ $ns == *[\']* ]] || [[ $ns == *[\\]* ]] || [[ $ns == *[\ ]* ]] || [[ $ns == *[@]* ]] || [[ $ns == *[\/]* ]] # Reject if submission contains unacceptable characters.
  then
    go_back=1
    clear
    dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
API_SECRET should not include the following characters. Please try again.\n $  \"  \\  '  SPACE  @  /"  9 50
  else
    got_it=1
  fi
fi

done

if [ "$ns" != "$cs" ] # Only if the new secret is different than the current secret (API_SECRET)
then
  sed -i -e "s/API_SECRET=.*/API_SECRET=\'${ns}\'/g" /etc/nsconfig # Replace API_SECRET in nsconfig with the new one using single quotes.
fi

/xDrip/scripts/StartUpSetup.sh

 chmod a+x /etc/rc.local

cat > /etc/systemd/system/rc-local.service << "EOF"
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local
[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
[Install]
 WantedBy=multi-user.target
EOF

sudo sed -i -e 'sX//Unattended-Upgrade::Automatic-Reboot "false";XUnattended-Upgrade::Automatic-Reboot "true";Xg' /etc/apt/apt.conf.d/50unattended-upgrades 
sudo systemctl daemon-reload
sudo systemctl enable rc-local

sudo systemctl start rc-local.service
 
sudo /xDrip/scripts/ConfigureFreedns.sh
if [ ! -s /tmp/FreeDNS_Failed ]
then
clear

# Add log
rm -rf /tmp/Logs
echo -e "Installation phase 2 completed     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
sudo /bin/cp -f /tmp/Logs /xDrip/Logs

dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
Press enter to restart the server.  This will result in an expected error message.  Wait 30 seconds before clicking on retry to reconnect or using a browser to access your Nightscout." 10 50
sudo reboot
fi
 
