#!/bin/bash

# IPC old-style, SystemV

# get overall
ipcs

# more details
ipcs -p

# get the pids
pid_line=$(ipcs -p | tail | head -1)
echo "$pid_line"
pid1=$(echo "$pid_line" | cut -d ' ' -f 7)
pid1=$(echo "$pid_line" | cut -d ' ' -f 14)

echo "PID : $pid1"
echo "PID : $pid2"

# see the process details
ps aux | grep -e $pid1 -e $pid2

