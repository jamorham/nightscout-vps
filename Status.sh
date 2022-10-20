#!/bin/bash

cd /tmp
echo "--------------------------------------------------" > tmp
lsb_release -a | sed -n 2p >> tmp
echo "--------------------------------------------------" >> tmp
free -h | sed -n 3p >> tmp
echo "--------------------------------------------------" >> tmp
df -m . >> tmp
echo "--------------------------------------------------" >> tmp
echo "MongoDB" >> tmp
mongod --version | sed -n 1p >> tmp
echo "--------------------------------------------------" >> tmp

dialog --textbox tmp 15 50
