#!/bin/bash

# test 2 types of max pids
max_pid=$(sysctl kernel.pid_max)
pid_max=$(cat /proc/sys/kernel/pid_max)

if [[ $(echo $max_pid | grep -c $pid_max) -eq 0 ]]; then
	echo "What just happened ? $max_pid != $pid_max"
else
	echo "Horray!"
fi

# cat in background
cat &

if [[ $pid_max -lt $(pgrep cat | tail -n 1) ]]; then
	echo "Bad cat"
fi

# kill that cat
sudo kill -9 $(pgrep cat | tail -n 1)

# change the max pid
sudo sysctl kernel.pid_max=24000

# cat in background, 2nd time
cat &

if [[ $pid_max -lt $(pgrep cat | tail -n 1) ]]; then
	echo "Bad cat, 2nd time"
fi

# kill that cat
sudo kill -9 $(pgrep cat | tail -n 1)

