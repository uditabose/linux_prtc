#!/bin/bash
#/* **************** LFD420:4.13 s_09/nomake.sh **************** */
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

cat <<EOF

   When you have patched the kernel you can
   run genmake again in this directory to prepare a Makefile
   making sure to point to the right headers:

   CPPFLAGS=-I/lib/modules/$(uname -r)/build/arch/x86/include/generated/uapi ../genmake *

EOF





