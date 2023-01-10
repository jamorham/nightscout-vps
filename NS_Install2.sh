#!/bin/bash

echo
echo "Finalizing Nightscout installation"
echo

if [ "$(node -v)" = "" ] # If Node.js is not installed
then
clear
dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
You need to complete installation phase 1 first." 9 50
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

if [ ! -s /etc/nsconfig ] # Only if nsconfig does not exist already
then

cat > /etc/nsconfig << EOF

export API_SECRET="YOUR_API_SECRET_HERE"
export ENABLE="careportal food boluscalc bwp cob bgi pump openaps rawbg iob upbat cage sage basal"
export AUTH_DEFAULT_ROLES="denied"
export PUMP_FIELDS="reservoir battery clock"
export DEVICESTATUS_ADVANCED="true"
export THEME="colors"
export DBSIZE_MAX="20000"

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

cs=`grep 'API_SECRET=' /etc/nsconfig | head -1 | cut -f2 -d'"'`

echo "Current API secret is: $cs"
echo
echo "If you would like to change it please enter the new secret now or hit enter to leave the same"

for j in {1..1000}
do
read -t 0.001 dummy
done
read -p "New secret 12 character minimum length (blank to skip change) : " ns

if [ "$ns" != "" ]
then
while [ ${#ns} -lt 12 ] && [ "$ns" != "" ]
do
read -p "Needs to be at least 12 chars - try again: " ns
done
if [ "$ns" != "" ]
then
sed -i -e "s/API_SECRET=\".*/API_SECRET=\"${ns}\"/g" /etc/nsconfig
echo
echo "Secret changed to: ${ns}"
sleep 3
fi
fi

cat > /etc/rc.local << "EOF"
#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd /tmp
swapon /var/SWAP
service snapd stop
service mongodb start
screen -dmS nightscout sudo -u nobody bash /etc/nightscout-start.sh
service nginx start
EOF

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

dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
Press enter to restart the server.  This will result in an expected error message.  Wait 30 seconds before clicking on retry to reconnect or using a browser to access your Nightscout." 10 50
sudo reboot
fi
 
