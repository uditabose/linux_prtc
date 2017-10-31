#!/bin/bash

# process details

# see process details, Unix way
ps -ef

# see process details, BSD way
ps aux

# see a subset of parameters
ps -o pid,pri,ni,cmd

# start a new child-shell
bash

# nice it up
nice -n 10 bash
# see some process details
ps_det=ps -o pid,pri,ni,cmd
echo "$ps_det"

# see the process details
pid=$(echo $ps_det | head | tail -n 1 | cut -d ' ' -f 1)
echo "PID : $pid"

# renice it
renice 15 -p $pid

# see a process details
ps -o pid,pri,ni,cmd