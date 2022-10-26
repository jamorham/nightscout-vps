#!/bin/bash

cd /tmp
echo "       Developed by the xDrip team " > tmp
echo "                                                  " >> tmp
echo "--------------------------------------------------" >> tmp
lsb_release -a | sed -n 2p >> tmp
echo "                                                  " >> tmp
echo "--------------------------------------------------" >> tmp
free -h | sed -n 3p >> tmp
echo "                                                  " >> tmp
echo "--------------------------------------------------" >> tmp
df -m . >> tmp
echo "                                                  " >> tmp
echo "--------------------------------------------------" >> tmp
echo "MongoDB" >> tmp
mongod --version | sed -n 1p >> tmp
echo "                                                  " >> tmp
echo "--------------------------------------------------" >> tmp
echo "Nightscout process" >> tmp
ps -ef | grep SCREEN | grep root | fold --width=40 | sed -n 1p >> tmp

dialog --colors --textbox tmp 25 50
 
