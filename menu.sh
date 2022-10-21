#!/bin/bash

echo
echo "Bringing up the menu"
echo

while [ true ]
do
clear #  Clear the screen before placing the next dialog on.

Choice=$(dialog --nocancel --menu "Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n\n" 17 50 9\
 "1" "Initial Nightscout install"\
 "2" "noip.com association"\
 "3" "Edit Nightscout Variables"\
 "4" "Transfer database from another server"\
 "5" "Update/Customize Nightscout"\
 "6" "Update scripts"\
 "7" "Status"\
 "8" "Reboot server"\
 "9" "Terminal" 3>&1 1>&2 2>&3)

case $Choice in
1)
clear
sudo /xDrip/scripts/NS_Install.sh
;;

2)
clear
sudo /xDrip/scripts/NS_Install2.sh
;;

3)
clear
/xDrip/scripts/variables.sh
;;

4)
clear
sudo /xDrip/scripts/clone_nightscout.sh
;;

5)
clear
sudo /xDrip/scripts/update_nightscout.sh
;;

6)
/xDrip/scripts/update_scripts.sh
;;

7)
clear
/xDrip/scripts/Status.sh
;;

8)
dialog --yesno "Are you sure you want to reboot the server?\n
If you do, all unsaved open files will close without saving.\n"  8 50
response=$?
if [ $response = 255 ] || [ $response = 1 ]
then
clear
else
sudo reboot
fi
;;

9)
# Clear before exiting. 
clear
exit
;;

esac

done
