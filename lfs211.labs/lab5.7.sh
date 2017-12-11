#!/bin/bash
source os.sh
source colors.sh

vncviewer -via papa@playground localhost:1

vncserver -kill :1
