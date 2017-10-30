#!/bin/bash

# defragmentation

# read status of /var/log
sudo e4defrag -c /var/log

# really do defrag
sudo e4defrag /var/log
