#!/bin/bash

# OOM killer

# turn off all swaps
sudo /sbin/swapoff -a

# turn it back on
sudo /sbin/swapon -a

# stress the memory for 10 seconds
stress -m 8 -t 10s