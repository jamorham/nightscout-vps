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
Press Enter to execute the highlighted option.\n\n" 18 50 8\
 "1" "Status"\
 "2" "Logs"\
 "3" "Google Cloud setup"\
 "4" "Nightscout setup"\
 "5" "xDrip setup"\
 "6" "Data"\
 "7" "Reboot server (Nightscout)"\
 "8" "Exit to shell (terminal)"\
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
/xDrip/scripts/menu_GC_Setup.sh
;;

4)
/xDrip/scripts/menu_NS_setup.sh
;;

5)
/xDrip/scripts/menu_xDripSetup.sh
;;

6)
/xDrip/scripts/menu_Data.sh
;;

7)
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

8)
cd /tmp
clear
dialog --colors --msgbox "        \Zr Developed by the xDrip team \Zn\n\n\
You will now exit to the shell (terminal).  To return to the menu, enter "menu" in the terminal without the quotes." 9 50
clear
exit
;;

esac

done
 
