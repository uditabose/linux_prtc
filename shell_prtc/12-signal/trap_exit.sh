#!/bin/bash

# trap [COMMANDS] [SIGNALS]

# This instructs the trap command to catch the listed SIGNALS, 
# which may be signal names with or without the SIG prefix, 
# or signal numbers. If a signal is 0 or EXIT, 
# the COMMANDS are executed when the shell exits. 
# If one of the signals is DEBUG, the list of COMMANDS 
# is executed after every simple command.

LOCKFILE='/var/lock/makewhatis.lock'

# previous make what is should exit successfully

[ -f $LOCKFILE ] && exit 0

# Upon exit, remove lockfile.

trap "{ rm -f $LOCKFILE; exit 255; }" EXIT

touch $LOCKFILE
makewhatis -u -w # this is a dummy command
exit 0