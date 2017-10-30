#!/bin/bash
#/* **************** LFD420:4.13 s_16/lab1_testloop.sh **************** */
#/*
# * The code herein is: Copyright the Linux Foundation, 2017
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    http://training.linuxfoundation.org
# *     email:  trainingquestions@linuxfoundation.org
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash 

set -x

P=./lab1_task 
[[ -f $P ]] || P=./lab2_task

# Take your choice of looping methods:

# n=19
# while [ $n -ge -20 ] ; do ($P $n &) ;  n=$((n-4)) ; done

for n in 19 15 10 5 0 -5 -10 -15 -20 ; do ($P $n &) ; done


