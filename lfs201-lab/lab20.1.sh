#!/bin/bash

# limits for processes

# start a new shell, so close this sub-shell, that clears everything
bash

# see the limit
ulimit -n

# soft 
ulimit -S -n

# hard
ulimit -H -n

# set the limit
ulimit -n hard
ulimit -n

# hard limit to 20148
ulimit -n 2048
ulimit -n

# try reset
ulimit -n 4096
ulimit -n

# exit from the sub-shell
exit