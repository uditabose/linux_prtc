#!/bin/bash
source os.sh
source colors.sh

# ssh connect via X11
ssh -x playground "hostname && id"
