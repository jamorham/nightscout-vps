#!/bin/bash
if [ "`id -u`" != "0" ]
then
echo "Script needs root - execute bootstrap.sh or use sudo bash installation.sh"
echo "Cannot continue.."
exit 5
fi

sudo apt-get install bind9-dnsutils -y

echo
echo "Move to use free dns instead of noip.com"
echo

read -rep "Please enter host name (for example mynightscoute.mooo.com) "$'\n'"hostname: " hostname
read -rep "please enter direct url. Should look like https://freedns.afraid.org/dynamic/update.php?d005WVNjWkE3aDhyWkJpa1h1cFZiOUV5OjIwNzQ4NTY1 "$'\n'" direct_url: " directurl


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