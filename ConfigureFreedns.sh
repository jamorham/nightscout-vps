#!/bin/bash

echo
echo "Move to use free dns instead of noip.com"
echo


if [ "`id -u`" != "0" ]
then
echo "Script needs root - execute bootstrap.sh or use sudo bash installation.sh"
echo "Cannot continue.."
exit 5
fi

read -rep "Please enter host name (for example mynightscoute.mooo.com) "$'\n'"hostname: " hostname
read -rep "please enter direct url. Should look like https://freedns.afraid.org/dynamic/update.php?d005WVNjWkE3aDhyWkJpa1h1cFZiOUV5OjIwNzQ4NTY1 "$'\n'" direct_url: " directurl

#Start the first update immediately
wget -O - --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 $directurl

#Add the command to renew the script to the startup url
if ! grep -q "freedns.afraid.org" /etc/rc.local; then
    echo wget -O /tmp/freedns.txt --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 $directurl >>  /etc/rc.local
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