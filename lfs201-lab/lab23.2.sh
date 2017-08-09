#!/bin/bash

# monitoring process states

# write a random file to /dev/null, bg
dd if=/dev/urandom of=/dev/null &

# see the process state, flag `-C` would be `-c` without any argument
ps -C dd -o pid,cmd,stat

# see all jobs
jobs

# bring it in foreground
fg

# kill the darling, but manually
