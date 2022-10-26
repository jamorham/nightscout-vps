#!/bin/bash

echo
echo "Bringing up the menu"
echo

while :
do

Choice=$(dialog --colors --nocancel --nook --menu "\
      \Zr Developed by the xDrip team \Zn\
  \n\n
Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n\n" 22 50 11\
 "1" "Initial Nightscout install"\
 "2" "noip.com association"\
 "3" "Edit Nightscout Variables"\
 "4" "Copy data from another Nightscout"\
 "5" "Update/Customize Nightscout"\
 "6" "Update scripts"\
 "7" "Backup MongoDB"\
 "8" "Restore MongoDB backup"\
 "9" "Status"\
 "10" "Reboot server (Nightscout)"\
 "11" "Exit to shell (terminal)"\
 3>&1 1>&2 2>&3)

case $Choice in

1)
sudo /xDrip/scripts/NS_Install.sh
;;

2)
sudo /xDrip/scripts/NS_Install2.sh
;;

3)
/xDrip/scripts/variables.sh
;;

4)
sudo /xDrip/scripts/clone_nightscout.sh
;;

5)
sudo /xDrip/scripts/update_nightscout.sh
;;

6)
/xDrip/scripts/update_scripts.sh
;;

7)
/xDrip/scripts/backupmongo.sh
;;

8)
/xDrip/scripts/restoremongo.sh
;;

9)
/xDrip/scripts/Status.sh
;;

10)
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

11)
cd /tmp
clear
dialog --msgbox "You will now exit to the shell (terminal).\n\
To return to the menu, enter menu in the terminal." 7 54
clear
exit
;;

esac

done
 
