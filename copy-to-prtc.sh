#!/bin/bash
source colors.sh
# copy scripts to practice vm
SHELL_FILE="$1"

if [[ ! -f "$SHELL_FILE" ]]; then
    echo -ne "$Red No shell file found $Color_Off\n"
    exit -1
fi
# change file permission
chmod +x "$SHELL_FILE"

if [[ $(df | grep -c ubprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" '/Users/papa/spaces/ubprtc'
fi

if [[ $(df | grep -c ctprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" '/Users/papa/spaces/ctprtc'
fi