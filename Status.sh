#!/bin/bash

# Show a summary of parameters.  -  Navid200
clear
echo "Please be patient (30 seconds)"
echo "  "
echo "  "

# Virtual machine zone
ZoneRaw=$(basename `curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"`)
Zone="$ZoneRaw"
basename `curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google"` > /tmp/Zone
grep 'us-west1' /tmp/Zone > /tmp/us-west1
grep 'us-central1' /tmp/Zone > /tmp/us-central1
grep 'us-east1' /tmp/Zone > /tmp/us-east1
if [ ! -s /tmp/us-west1 ] && [ ! -s /tmp/us-central1 ] && [ ! -s /tmp/us-east1 ] 
then
Zone="\Zb\Z1"$ZoneRaw"\Zn"
fi

# Ram size - This is used to determine if the machine type is micro or not
Ram=$(free -m | sed -n 2p | awk '{print $2}')
unit="M"
Ramsize="$Ram"$unit
if [ $Ram -gt 1000 ]
then
Ramsize="\Zb\Z1 $Ram$unit \Zn"
fi

# Disk type
disk="\Z1\ZbBalanced\Zn"
if [ $(cat /sys/block/sda/queue/rotational) -eq 1 ]
then 
disk="Standard"
fi

#Disk size
disksz="$(df -h | sed -n 2p | awk '{print $2}')"
DiskUsedPercent="$(df -h | sed -n 2p | awk '{print $5}')"
if [ ! "$disksz" = "29G" ]
then
disksz="\Zb\Z1$(df -h | sed -n 2p | awk '{print $2}')\Zn"
fi

#Swap file
swap="$(free -h | sed -n 3p | awk '{print $2}')"

#Ubuntu version
ubuntu="$(lsb_release -a | sed -n 2p | awk '{print $3, $4}')"
if [ ! "$ubuntu" = "20.04.5 LTS" ]
then
ubuntu="\Zb\Z1$(lsb_release -a | sed -n 2p | awk '{print $3, $4}')\Zn"
fi

#Firewall
current=$(wget -q -O - http://checkip.dyndns.org|sed s/[^0-9.]//g)
nc -zvw10 $current 80 2> /tmp/http
grep 'timed out' /tmp/http > /tmp/http2
nc -zvw10 $current 443 2> /tmp/https
grep 'timed out' /tmp/https > /tmp/https2
http="Open"
if [ -s /tmp/http2 ] || [ -s /tmp/https2 ]
then
http="\Zb\Z1Closed\Zn"
fi

mongo="$(mongod --version | sed -n 1p)"
ns="$(ps -ef | grep SCREEN | grep root | fold --width=40 | sed -n 1p)"

uname="$(< /srv/username)"
if [ ! "$(< /srv/username)" = "jamorham" ]
then
uname="\Zb\Z1$(< /srv/username)\Zn"
fi

repo="$(< /srv/repo)"
if [ ! "$(< /srv/repo)" = "nightscout-vps" ]
then
repo="\Zb\Z1$(< /srv/repo)\Zn"
fi

branch="$(< /srv/brnch)"
if [ ! "$(< /srv/brnch)" = "vps-1" ]
then
branch="\Zb\Z1$(< /srv/brnch)\Zn"
fi

HOSTNAME=""
. /etc/free-dns.sh
if [ "$HOSTNAME" = "" ]
then
FD="No hostname"
else
registered=$(nslookup $HOSTNAME|tail -n2|grep A|sed s/[^0-9.]//g)
current=$(wget -q -O - http://checkip.dyndns.org|sed s/[^0-9.]//g)
if [ ! "$registered" = "$current" ]
then
FD="\Zb\Z1Mismatch\Zn"
else
FD="Match"
fi
fi

. /etc/nsconfig
apisec=$API_SECRET

curl https://$HOSTNAME > /tmp/$HOSTNAME.txt
curl_ret=$?
if (( curl_ret != 0 )); then
cert="\Zb\Z1Invalid\Zn"
else
cert="Valid"
fi

# Verify that the latest added package has been installed
Missing=""
if [ "$(which qrencode)" = "" ]
then
  Missing="\Zb\Z1Missing packages\Zn"
fi

clear
Choice=$(dialog --colors --nocancel --nook --menu "\
        \Zr Developed by the xDrip team \Zn\n\n\
                \Zb Status \Zn\n\n\
Zone: $Zone \n\
RAM: $Ramsize \n\
Disk type: $disk \n\
Disk size: $disksz        $DiskUsedPercent used \n\
Ubuntu: $ubuntu \n\
HTTP & HTTPS:  $http \n\
------------------------------------------ \n\
Nightscout on Google Cloud: 2023.01.15\n\
$Missing \n\n\
/$uname/$repo/$branch\n\
Swap: $swap \n\
Mongo: $mongo \n\
NS proc: $ns \n\
FreeDNS name and IP: $FD \n\
Certificate: $cert \
 " 29 50 2\
 "1" "Return"\
 "2" "Hostname and password"\
 3>&1 1>&2 2>&3)
 
 case $Choice in
 
 1)
exit
;;

2)
dialog --colors --msgbox "       \Zr Developed by the xDrip team \Zn\n\n\
               \Zb\Z1Keep private.\Zn\n\
FreeDNS hostname:  $HOSTNAME\n\
API_SECRET: $apisec" 9 50
;;

esac
 
