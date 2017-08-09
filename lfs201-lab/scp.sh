#!/bin/bash

echo "Transfer file to pi......"
echo

chmod +x "$@"

#scp "$1" rasp-dev:/home/pi/spaces/workspace/shell
scp "$@" dev2:/home/papa/spaces/devspace/shell
