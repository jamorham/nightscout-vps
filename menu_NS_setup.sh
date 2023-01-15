#!/bin/bash

echo
echo "Bringing up the Nightscout setup menu" - Navid200
echo

clear
Choice=$(dialog --colors --nocancel --nook --menu "\
        \Zr Developed by the xDrip team \Zn\
  \n\n
Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n" 14 50 4\
 "1" "Edit variables using a text editor"\
 "2" "Edit variables using a web browser"\
 "3" "Customize Nightscout"\
 "4" "Return"\
 3>&1 1>&2 2>&3)

case $Choice in


1)
/xDrip/scripts/variables.sh
;;

2)
/xDrip/scripts/varserver.sh
;;

3)
sudo /xDrip/scripts/update_nightscout.sh
;;

4)
;;

esac
  
