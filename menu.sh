#!/bin/bash

echo
echo "Bringing up the menu"
echo

while [ true ]
do
clear #  Clear the screen before placing the next dialog on.

Choice=$(dialog --nocancel --menu "Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n\n" 16 50 9\
 "1" "Initial Nightscout install"\
 "2" "noip.com association"\
 "3" "Transfer database from another server"\
 "4" "Update/Customize Nightscout"\
 "5" "Update scripts"\
 "6" "Status"\
 "7" "Reboot server"\
 "8" "Terminal" 3>&1 1>&2 2>&3)

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
sudo /xDrip/scripts/clone_nightscout.sh
;;

4)
clear
sudo /xDrip/scripts/update_nightscout.sh
;;

5)
/xDrip/scripts/update_scripts.sh
;;

6)
clear
/xDrip/scripts/Status.sh
;;

7)
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

8)
# Clear before exiting. 
clear
exit
;;

esac

done
