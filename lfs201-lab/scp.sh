#!/bin/bash

echo "Transfer file to pi......"
echo

chmod +x "$1"

scp "$1" rasp-dev:/home/pi/spaces/workspace/shell
