#!/bin/bash

echo
echo "Nightscout variables"
echo

cd /tmp

cat> /tmp/variablesNote<<EOF
You will be editing the textfile containing the variables.
The key combinations for each text editor function will be shown
at the bottom of the screen.
^ represents the control key.  Therefore, ^X means pressing
the control and x keys simultaneously.

To save, press the control and o keys simultaneously.
Then, press enter to save.

After editing and saving the variables file, you will need to
reboot the server for the changes to take effect.

Press Enter now to proceed to the text editor.
EOF

clear
dialog --textbox variablesNote 18 67
clear

sudo nano /etc/nsconfig
