#!/bin/bash
#source colors.sh
# copy scripts to practice vm
SHELL_FILE="$1"

if [[ ! -f "$SHELL_FILE" ]]; then
    echo  "No shell file found"
    exit -1
fi
# change file permission
chmod +x "$SHELL_FILE"

UBPRTC='/Users/papa/spaces/ubprtc'
CTPRTC='/Users/papa/spaces/ctprtc'

if [[ $(df | grep -c ubprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" "$UBPRTC"
elif [[ -d "$UBPRTC" ]]; then
    cp -v "$SHELL_FILE" "$UBPRTC"
else
    echo "Can't copy to $UBPRTC"
fi

if [[ $(df | grep -c ctprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" "$CTPRTC"
elif [[ -d "$CTPRTC" ]]; then
    cp -v "$SHELL_FILE" "$CTPRTC" 
else
    echo "Can't copy to $CTPRTC"
fi