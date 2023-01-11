#!/bin/bash

echo
echo "Bringing up the menu" - Navid200
echo

while :
do

clear
Choice=$(dialog --colors --nocancel --nook --menu "\
      \Zr Developed by the xDrip team \Zn\n\n
Use the arrow keys to move the cursor.\n\
Press Enter to execute the highlighted option.\n\n" 19 50 9\
 "1" "Status"\
 "2" "Logs"\
 "3" "Edit variables"\
 "4" "Backup MongoDB"\
 "5" "Restore MongoDB"\
 "6" "Update platform"\
 "7" "Utilities"\
 "8" "Reboot server (Nightscout)"\
 "9" "Exit to shell (terminal)"\
 3>&1 1>&2 2>&3)

case $Choice in

1)
/xDrip/scripts/Status.sh
;;

2)
clear
dialog --colors --title "\Zr Developed by the xDrip team \Zn"   --textbox /xDrip/Logs 26 74 
;;

3)
/xDrip/scripts/varserver.sh
;;

4)
/xDrip/scripts/backupmongo.sh
;;

5)
/xDrip/scripts/restoremongo.sh
;;

6)
cd /srv
cd "$(< repo)"  # Go to the local database
sudo git reset --hard  # delete any local edits.
sudo git pull  # Update database from remote.
sudo chmod 755 update_scripts.sh
sudo cp -f update_scripts.sh /xDrip/scripts/.
clear
sudo /xDrip/scripts/update_scripts.sh
sudo /xDrip/scripts/update_packages.sh
;;

7)
/xDrip/scripts/Utilities.sh
;;

8)
dialog --colors --yesno "     \Zr Developed by the xDrip team \Zn\n\n\
Are you sure you want to reboot the server?\n
If you do, all unsaved open files will close without saving.\n"  10 50
response=$?
if [ $response = 255 ] || [ $response = 1 ]
then
clear
else
sudo reboot
fi
;;

9)
cd /tmp
clear
dialog --colors --msgbox "        \Zr Developed by the xDrip team \Zn\n\n\
You will now exit to the shell (terminal).  To return to the menu, enter menu in the terminal." 9 50
clear
exit
;;

esac

done
 
