#/* **************** LF320:1.4 s_08/lab3_loadit.sh **************** */
#/*
# * The code herein is: Copyright Jerry Cooperstein and the Linux Foundation, 2011
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    http://training.linuxfoundation.org
# *     email:  trainingquestions@linuxfoundation.org
# *
# * The primary maintainer for this code is Jerry Cooperstein
# * The CONTRIBUTORS file (distributed with this
# * file) lists those known to have contributed to the source.
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash 

# Script to find the address of a kernel symbol and
# optionally load a module with it:

# Jerry Cooperstein, coop@linuxfoundation.org, 12/2005 (GPL v2)

#  Look for $SYMBOL address (until found) in:
#
#    /lib/modules/$(uname -r)/build/System.map 
#    /proc/kallsyms 
#
#   This will fail if $SYMBOL is a variable, not a function
#   and support for this is not built in
#
#   COMMAND LINE ARGUMENTS: 
#
#       SYMBOL: the name to find
#       MODULE: name of module to load (OPTIONAL)
#       PARAM:  name of parameter to pass to module (OPTIONAL)
#
#  Examples:
#
#  loadit.sh sys_call_table
#  loadit.sh sys_call_table mymodule.ko address
#
#  executes: insmod mymodule.ko address=(address of sys_call_table);

###########################################################################
function find_symbol(){
    SYM=$1 ; SF=$2 ; ADDRESS=
    [ ! -f "$SF" ] && echo could not find symbol file: $SF && return
# The v=1 complication is because in 2.6 the same symbol can appear
# multiple times in /proc/kallsyms; we only want it once.
    ADDRESS=`awk -v pat=$SYM ' $3 == pat { if (v == 0) {print $1; v = 1} } ' $SF`
    [ "$ADDRESS" == "" ] && echo "$0" Failed to find address of "$SYM" in: "$SF" && return
    ADDRESS=0x"$ADDRESS"
    echo "$0" Found address of "$SYM" in: "$SF" to be "$ADDRESS"
}
###########################################################################
USAGE="USAGE:
\tTo just find address of sys_call_table:\n
\t\t             $0 sys_call_table\n
\tTo load my_module.ko with a parameter address set:\n
\t\t      SYMBOL=sys_call_table MODULE=mymodule.ko PARAM=address $0\n
"
###########################################################################
# Beginning of Script:

SYMBOL=$1 ; MODULE=$2 ; PARAM=$3 

[ "$SYMBOL" == "" ] && echo -e $USAGE && exit -1

for SF_FILES in \
    /lib/modules/$(uname -r)/build/System.map  /proc/kallsyms ; \
    do [ "$ADDRESS" == "" ] && find_symbol $SYMBOL $SF_FILES
done
[ "$ADDRESS" == "" ] &&  exit

[ "$#" -lt 3 ] && exit
# if $MODULE and $PARAM are defined, load the module

echo executing: insmod $MODULE $PARAM=$ADDRESS
                insmod $MODULE $PARAM=$ADDRESS
