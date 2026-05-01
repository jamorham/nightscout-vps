#!/bin/bash

# Show a summary of parameters.  -  Navid200
clear
echo "Please be patient.  It may take up to 2 minutes."
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
Zone="\Zb\Z1"$ZoneRaw"\Zn" # Set color to red if the zone is not one of the three free ones.
fi

# Ram size - This is used to determine if the machine type is micro or not
Ram=$(free -m | sed -n 2p | awk '{print $2}')
unit="M"
Ramsize="$Ram"$unit
if [ $Ram -gt 1000 ]
then
Ramsize="\Zb\Z1 $Ram$unit \Zn" # Set color to red if Ram size is greater than 1G
fi

# Disk type
disk="\Z1\ZbBalanced\Zn" # Set the color to red.
if [ $(cat /sys/block/sda/queue/rotational) -eq 1 ]
then 
disk="Standard" # Clear the color if the disk type is standard.
fi

#Disk size
disksz="$(df -h | sed -n 2p | awk '{print $2}')"
DiskUsedPercent="$(df -h | sed -n 2p | awk '{print $5}')"
if [ ! "$disksz" = "29G" ]
then
disksz="\Zb\Z1$(df -h | sed -n 2p | awk '{print $2}')\Zn" # Set color to red if disk size is not 29G.
fi

#Swap file
swap="$(free -h | sed -n 3p | awk '{print $2}')"

#Ubuntu version
ubuntu="$(lsb_release -a | sed -n 2p | awk '{print $3, $4}')"
if [ ! "$ubuntu" = "24.04.4 LTS" ]
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
http="\Zb\Z1Closed\Zn" # Set color to red if the Firewall is not set.
fi

mongo="$(mongod --version | awk '/db version/ {print $NF}')"

ns="$(ps -ef | grep SCREEN | grep root | awk '{print $2, "  ", $5}')"

uname="$(< /srv/username)"
if [ ! "$(< /srv/username)" = "jamorham" ]
then
uname="\Zb\Z1$(< /srv/username)\Zn" # Set the color to red if the user name is not jamorham.
fi

repo="$(< /srv/repo)"
if [ ! "$(< /srv/repo)" = "nightscout-vps" ]
then
repo="\Zb\Z1$(< /srv/repo)\Zn" # Set the color to red if the repository name is not nightscout-vps.
fi

branch="$(< /srv/brnch)"
if [ ! "$(< /srv/brnch)" = "vps-2" ] && [ ! "$(< /srv/brnch)" = "vps-dev" ]
then
branch="\Zb\Z1$(< /srv/brnch)\Zn" # Set the color to red if the branch name is neither vps-2 nor vps-dev.
fi

HOSTNAME=""
. /etc/free-dns.sh
if [ "$HOSTNAME" = "" ]
then
FD="No hostname"
else
registered=$(nslookup $HOSTNAME|tail -n2|grep A|sed s/[^0-9.]//g)
if [ ! "$registered" = "$current" ]
then
FD="\Zb\Z1Mismatch\Zn"
else
FD="Match"
fi
fi

. /etc/nsconfig
apisec=$API_SECRET # What Nightscout sees as API_SECRET

curl https://$HOSTNAME > /tmp/$HOSTNAME.txt
curl_ret=$?
if (( curl_ret != 0 )); then
cert="\Zb\Z1Invalid\Zn"
else
cert="Valid"
fi

# Node
node="$(node -v)"
if [ ! "${node%%.*}" = "v22" ] # If node version is any other than v16
then
node="\Zb\Z1$(node -v)\Zn" 
fi

# Verify that the latest added package has been installed
# The utility must be the last added utility to the update_packages.sh file.
Missing=""
if [ "$(which file)" = "" ]
then
  Missing="\Zb\Z1Missing packages  \Zn"
fi

# Verify that Installation phase 1 has been executed after bootstrap
# Bootstrap clears the /srv directory.  It then creates a local clone of the repository, which recreates the node_modules directory.
# But, this directory will only contain a .cache directory until phase 1 is run.  That's how we verify if phase 1 has been executed after or not.
Phase1=""
cd /srv
cd "$(< repo)"
if [ "$(ls -A node_modules | grep -v '^\.cache$' | wc -l)" -eq 0 ]
then
  Phase1="\Zb\Z1Missing node_modules\Zn"
fi 

# Verify that exit 0 is in rc.local so that Nightscout can start after a reboot even if FreeDNS is down.
rclocal_1="\Zb\Z1Startup dependence on FreeDNS\Zn"
grep 'exit 0' /etc/rc.local > /tmp/rclocal_1
if [ -s /tmp/rclocal_1 ]
then
  rclocal_1=""
fi

# Mark FreeDNS login issues.
freedns_id=""
freedns_pass=""
if [ -s /xDrip/FreeDNS_ID_Pass ]
then
  . /xDrip/FreeDNS_ID_Pass
  freedns_id=$User_ID
  freedns_pass=$Password
fi
freedns_id_pass=""
if [ -s /xDrip/FreeDNS_Fail ] || [ ! -s /xDrip/FreeDNS_ID_Pass ]
then
  freedns_id_pass="\Zb\Z5FreeDNS ID and pass\Zn"
fi

# Verify API_SECRET since it can be edited after installation
apisec_problem="" # No flag
apisec_literal=$(grep 'API_SECRET=' /etc/nsconfig) # Extract the line containing API_SECRET= from the nsconfig file (including the quotation marks).
apisec_literal=$(echo "$apisec_literal" | sed 's/^.*=//') # Drop everything up to and including the equal sign.
if [[ "$apisec_literal" == *" #"* ]] # Is there a comment?
then
  apisec_literal=${apisec_literal%%#*} # Remove the comment and everything after.
fi
apisec_literal=$(echo "$apisec_literal" | awk '{$1=$1};1') # Remove trailing spaces
apisec_literal="$apisec_literal"
first="${apisec_literal:0:1}" # The first character, which should be either ' or "
last="${apisec_literal: -1}" # The last character, which should be either ' or "
if [[ "$first" == "$last" ]] # Are the first and last characters identical?
then
  if [[ "$first" == "'" ]] || [[ "$first" == "\"" ]] # Is the first character either ' or "
  then
    apisec_literal="${apisec_literal:1: -1}" # Remove the first and last characters (quotation mark pair)
    if [[ "$apisec_literal" == *"@"* ]] || [[ "$apisec_literal" == *" "* ]] || [[ "$apisec_literal" == *"/"* ]] || [[ "$apisec_literal" == *"\\"* ]] || [[ "$apisec_literal" == *"'"* ]] || [[ "$apisec_literal" == *"\""* ]] || [[ "$apisec_literal" == *"$"* ]] || [[ ${#apisec_literal} -lt 12 ]] # Is an illegal character present?
    then
      apisec_problem="*" # Mark the presence of one of the seven illegal characters.  
      if [[ "$apisec" != "$apisec_literal"  ]] # Is what Nightscout sees different than what we have extracted?
      then
        apisec_problem="*" # Mark an unacceptable combination.
      fi
    fi
  else
    apisec_problem="*" # Mark that the first character is neither ' nor "
  fi
else
  apisec_problem="*" # Mark that the first and last characters (should be a pair of quoation marks) are not identical.
fi

# Show the first line of last reboot
LastReboot=$(last reboot | head -1 | awk '{print $4, "", $5, $6, $7}')

# Check window size
while true; do
  rows=$(tput lines)
  cols=$(tput cols)
  if (( rows > 37 && cols > 72 )); then
    break
  fi
  clear
  dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
Terminal window is too small to display the status page.\n\n\
Current size : ${cols} x ${rows} \n\
Minimum size : 73 x 38 \n\n\
Please enlarge your terminal window, then press ENTER to retry." 15 50
done

clear
Choice=$(dialog --colors --nocancel --nook --menu "          \Zr Google Cloud Nightscout \Zn\n\n\
                \Zb Status \Zn\n\n\
Zone: $Zone \n\
RAM: $Ramsize \n\
Disk type: $disk \n\
Disk size: $disksz        $DiskUsedPercent used \n\
Ubuntu: $ubuntu \n\
HTTP & HTTPS:  $http \n\
------------------------------------------ \n\
Google Cloud Nightscout  2026.04.30\n\
$apisec_problem $Missing $Phase1 $rclocal_1 $freedns_id_pass \n\n\
/$uname/$repo/$branch\n\
Swap: $swap \n\
Ubuntu update: $LastReboot \n\
Node: $node \n\
Mongo: $mongo \n\
NS proc: $ns \n\
FreeDNS name and IP: $FD \n\
Certificate: $cert \
 " 32 50 3\
 "1" "Return"\
 "2" "Login credentials"\
 3>&1 1>&2 2>&3)
 
case $Choice in
 
1)
exit
;;

2)
dialog --colors --msgbox "         \Zr Google Cloud Nightscout \Zn\n\n\
              \Zb\Z1Keep private!\Zn\n\n\
Hostname:  $HOSTNAME\n\
API_SECRET: $apisec\n\n\
FreeDNS User ID: $freedns_id\n\
FreeDNS password: $freedns_pass" 13 50
tput civis
read -p "" -n1 -s
tput cnorm
;;
esac

 
