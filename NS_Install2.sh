#!/bin/bash

echo
echo "Log into noip.com"
echo

if [ ! -s /srv/nightscout-vps ]
then
cat > /tmp/install2_note << EOF
Complete Initial Nightscout installation first.

EOF
cd /tmp
dialog --textbox install2_note 6 51
exit
fi

if [ ! -s /usr/local/etc/no-ip2.conf ]
then
cd /usr/src
sudo tar -xzf /srv/nightscout-vps/helper/noip-duc-linux.tar.gz
cd /usr/src/noip-2.1.9-1
sudo make install
else
echo "Noip client already installed - delete /usr/local/etc/no-ip2.conf if you want to change config"
fi
noip2 -S

hostname=`noip2 -S 2>&1 | grep host | tr -s ' ' | tr -d '\t' | cut -f2 -d' ' | head -1`

if [ "$hostname" = "" ]
then
echo "Could not determine host name - did no ip dynamic dns install fail?"
echo "Cannot continue!"
exit 5
fi

# execute installer
noip2

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
sudo certbot --nginx -d "$hostname" --redirect

sudo systemctl daemon-reload
sudo systemctl start mongodb

echo
echo "Setting up startup service"
echo

cat > /etc/nsconfig << EOF

export API_SECRET="YOUR_API_SECRET_HERE"
export ENABLE="careportal food boluscalc bwp cob bgi pump openaps rawbg iob upbat cage sage basal"
export AUTH_DEFAULT_ROLES="denied"
export PUMP_FIELDS="reservoir battery clock"
export DEVICESTATUS_ADVANCED="true"

EOF

cat > /etc/nightscout-start.sh << "EOF"

#!/bin/sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

. /etc/nsconfig

export MONGO_COLLECTION="entries"
export MONGO_CONNECTION="mongodb://username:password@localhost:27017/Nightscout"
export INSECURE_USE_HTTP=true
export HOSTNAME="127.0.0.1"
export PORT="1337"

cd /srv/nightscout-vps

while [ "`netstat -lnt | grep 27017 | grep -v grep`" = "" ]
do
echo "Waiting for mongo to start"
sleep 5
done
sleep 5

while [ 1 ]
do
node server.js
sleep 30
done

EOF

echo
echo "You can edit the full configuration with: sudo nano /etc/nsconfig"
echo

cs=`grep 'API_SECRET=' /etc/nsconfig | head -1 | cut -f2 -d'"'`

echo "Current API secret is: $cs"

echo
echo "If you would like to change it please enter the new secret now or hit enter to leave the same"

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

/usr/local/bin/noip2 &
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

echo
echo "Starting everything up - if works also check okay after a reboot"
echo

sudo systemctl start rc-local.service
sudo reboot
 
