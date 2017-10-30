#!/bin/bash

# tour of /proc
ls -F /proc
echo "************************"

# cpuinfo
cat /proc/cpuinfo
echo "************************"

# meminfo
cat /proc/meminfo
echo "************************"

# mounts
cat /proc/mounts
echo "************************"

# swaps
cat /proc/swaps
echo "************************"

# version
cat /proc/version
echo "************************"

# partitions
cat /proc/partitions
echo "************************"

# interrupts
cat /proc/interrupts
echo "************************"

# ssh process details
for ssh_proc in $(pgrep ssh); do
	ls -F /proc/$ssh_proc
	echo "************************"
	sudo cat /proc/$ssh_proc/cmdline
	echo "************************"
	sudo cat /proc/$ssh_proc/cwd
	echo "************************"
	sudo cat /proc/$ssh_proc/environ
	echo "************************"
	sudo cat /proc/$ssh_proc/mem
	echo "************************"
	sudo cat /proc/$ssh_proc/status
	echo "************************"
	break
done