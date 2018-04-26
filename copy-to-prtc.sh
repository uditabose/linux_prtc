#!/bin/bash
#source colors.sh
# copy scripts to practice vm
ARGS="$@"

if [[ -z "${ARGS// }" ]]; then
    echo  "No file found"
    exit -1
fi
# change file permission

for ff in "$@"; do
	chmod +x "$ff"
done

UBPRTC='/Users/papa/spaces/ubprtc'
CTPRTC='/Users/papa/spaces/ctprtc'

if [[ $(df | grep -c ubprtc) == 1 ]]; then
	for ff in "$@"; do
    	cp -v "$ff" "$UBPRTC"
    done
elif [[ -d "$UBPRTC" ]]; then
    for ff in "$@"; do
        cp -v "$ff" "$UBPRTC"
    done
else
    echo "Can't copy to $UBPRTC"
fi

if [[ $(df | grep -c ctprtc) == 1 ]]; then
	for ff in "$@"; do
    	cp -v "$ff" "$CTPRTC"
    done
elif [[ -d "$CTPRTC" ]]; then
	for ff in "$@"; do
    	cp -v "$ff" "$CTPRTC" 
    done
else
    echo "Can't copy to $CTPRTC"
fi
