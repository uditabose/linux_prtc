#!/bin/bash
#/* **************** LFD420:4.13 s_05/print_license.sh **************** */
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
for names in $(cat /proc/modules | awk ' {print $1;} ')
        do echo -ne "$names\t     \t"
        modinfo $names | grep  license
done
