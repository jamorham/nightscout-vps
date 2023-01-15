#!/bin/bash

echo
echo "Bringing up the Data menu" - Navid200
echo

clear
Choice=$(dialog --colors --nocancel --nook --menu "\
        \Zr Developed by the xDrip team \Zn\n\n\
Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n" 14 50 4\
 "1" "Copy data from another Nightscout"\
 "2" "Backup MongoDB"\
 "3" "Restore MongoDB"\
 "4" "Return"\
 3>&1 1>&2 2>&3)

case $Choice in


1)
clear
sudo /xDrip/scripts/clone_nightscout.sh
;;

2)
/xDrip/scripts/backupmongo.sh
;;

3)
/xDrip/scripts/restoremongo.sh
;;

4)
;;

esac
