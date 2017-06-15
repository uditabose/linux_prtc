#!/bin/bash

echo "Transfer file to pi......"
echo

chmod +x "$1"

scp "$1" pi@192.168.0.7:/home/pi/spaces/workspace/shell
