#!/bin/bash

# copy scripts to 

SHELL_FILE="$1"
# change file permission
chmod +x "$SHELL_FILE"

if [[ $(df | grep -c ubprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" '/Users/papa/spaces/ubprtc'
fi

if [[ $(df | grep -c ctprtc) == 1 ]]; then
    cp -v "$SHELL_FILE" '/Users/papa/spaces/ctprtc'
fi