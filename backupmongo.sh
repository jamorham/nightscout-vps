#!/bin/bash

while :
do
exec 3>&1
Filename=$(dialog --ok-label "Submit" --form "Enter a name for the backup file" 8 50 0 "file name" 1 1 "$filename" 1 14 25 0 2>&1 1>&3)
 response=$?
if [ $response = 255 ] || [ $response = 1 ]
then
clear
exit
fi

if [ -s $Filename ]
then
dialog --exit-label "Try again" --msgbox "A file with the same name exists.\n\
Choose a different filename." 7 37
clear
else
mongodump --gzip --archive=$Filename
exec 3>&-
dialog --msgbox "Backup is complete.\n\
However, it is on the same virtual machine as\n\
your MongoDB.\n\
It's best to download the file to your computer\n\
for safekeeping.\n\
See the guide for how to download." 10 51
clear
exit
fi
done
 
