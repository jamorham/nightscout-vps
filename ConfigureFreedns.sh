#!/bin/bash

if [ "`id -u`" != "0" ]
then
echo "Script needs root - use sudo bash ConfigureFreedns.sh"
echo "Cannot continue."
exit 5
fi

sudo apt-get install bind9-dnsutils -y

echo
echo "Move to use free dns instead of noip.com" - tzachi-dar
echo

got_them=0
while [ $got_them -lt 1 ]
do
go_back=0
clear
exec 3>&1
Values=$(dialog --colors --ok-label "Submit" --form "     \Zr Developed by the xDrip team \Zn\n\n\n\
Enter your FreeDNS userID and password." 12 50 0 "User ID:" 1 1 "$user" 1 14 25 0 "Password:" 2 1 "$pass" 2 14 25 0 2>&1 1>&3)
response=$?
if [ $response = 255 ] || [ $response = 1 ] # cancled or escaped
then
clear
exit 5
fi

exec 3>&-
user=$(echo "$Values" | sed -n 1p)
pass=$(echo "$Values" | sed -n 2p)

if [ "$user" = "" ] || [ "$pass" = "" ] #  At least one parameter is blank. 
then
  go_back=1
  clear
  dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
  You need to enter both userID and password.  Try again."  8 50
fi
clear

if [ $go_back -lt 1 ] # if 7
then
  arg1="https://freedns.afraid.org/api/?action=getdyndns&v=2&sha="
  arg2=$(echo -n "$user|$pass" | sha1sum | awk '{print $1;}')
  arg="$arg1$arg2"

  wget -O /tmp/hosts "$arg"
if [ ! "`grep 'Could not authenticate' /tmp/hosts`" = "" ] # Failed to log in
then
  dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\n\
  Failed to authenticate.  Try again."  8 50
  go_back=1
fi

if [ $go_back -lt 1 ] # if 6
then
  Lines=$(awk 'END{print NR}' /tmp/hosts)
  if [ $Lines -eq 0 ] # No hostnames # if 5
  then
    dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\
    No subdomains found.  Ensure you have one in your Free DNS account, and try again."  9 50
    go_back=1

  elif [ $Lines -gt 1 ] # More than one hostname
  then
    clear
    exec 3>&1
    subvalue=$(dialog --colors --ok-label "Submit" --form "     \Zr Developed by the xDrip team \Zn\n\n\n\
    You have more than one subdomain.  Enter the subdomain you want to use. \n\
    It should look like mine.strangled.net"  12 50 0 "Subdomain:" 1 1 "$subd" 1 14 25 0 2>&1 1>&3)
    response2=$?
    if [ $response2 = 255 ] || [ $response2 = 1 ] # canceled or escaped
    then
      go_back=1
    fi

    exec 3>&-
    subd=$(echo "$subvalue" | sed -n 1p)
    if [ $go_back -lt 1 ] # if 4
    then
      if [ "$subd" = "" ] # Nothing entered
      then
        go_back=1
        clear
        dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\n\
        You need to enter a subdomain.  Try again."  8 50
      fi

      if [ $go_back -lt 1 ] # if 3
      then
        grep $subd /tmp/hosts > /tmp/FullLine # Find the lines that match and put them in FullLine.
        if [ ! -s /tmp/FullLine ] # Not found
        then
          go_back=1
          dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\n\
          The subdomain you entered is not one of the ones we found.  Try again." 9 50
        fi
        if [ $go_back -lt 1 ]  # if 2
        then
        Lines2=$(wc -l < /tmp/FullLine)
        if [ $Lines2 -gt 1 ] # More than one found  if 1
        then
          go_back=1
          dialog --colors --msgbox "     \Zr Developed by the xDrip team \Zn\n\n\n\
          The value you entered matches more than one of your subdomains.  Try again and enter a unique value." 11 50
        else
          FLine=$(</tmp/FullLine)
          got_them=1 # We have the hostname and direct URL
        fi # fi 1

      fi # fi 2
      fi # fi 3
    fi # fi 4
  else
    cp /tmp/hosts /tmp/FullLine
    FLine=$(</tmp/FullLine)
    got_them=1 # We have the hostname and direct URL
  fi # fi 5

fi # fi 6
fi # fi 7

done
clear

IFS='|'
read -a split <<< $FLine
hostname=${split[0]}
directurl=${split[2]}

#create a file to store the data for the startup script.
cat> /etc/free-dns.sh<<EOF
#!/bin/sh
export HOSTNAME=$hostname
export DIRECTURL=$directurl
EOF

# Start the first update immediately
wget -O - --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 $directurl

#Add the command to renew the script to the startup url
if ! grep -q "DIRECTURL" /etc/rc.local; then
    echo . /etc/free-dns.sh >>  /etc/rc.local
    echo wget -O /tmp/freedns.txt --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 \$DIRECTURL >>  /etc/rc.local
fi

# wait for the ip to be updated. This might take up to 10 minutes.

while : ; do
    sleep 30
    registered=$(nslookup $hostname|tail -n2|grep A|sed s/[^0-9.]//g)
    current=$(wget -q -O - http://checkip.dyndns.org|sed s/[^0-9.]//g)
    echo $current $registered
    [[ "$registered" != "$current" ]] || break
done

#Fix the certificate using the new host name.
sudo certbot --nginx -d "$hostname" --redirect 
 
