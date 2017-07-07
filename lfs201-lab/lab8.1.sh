#!/bin/bash

# this is not gonna work, my pi is not detecting

MY_USB=myusb
RULES_F=/etc/udev/rules.d/75-"$MY_USB".rules

touch "$RULES_F"

echo 'SUBSYSTEM=="usb", SYMLINK+="myusb"' >> "$RULES_F"





