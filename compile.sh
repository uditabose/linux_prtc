#!/bin/bash

if [ "$#" -lt 2 ]; then
	echo "Usage : ./compile.sh <file> <object_file>"
	exit
fi

f_name="$1"
o_name="$2"
shift 2
		
echo 
echo "Compiling $f_name to executable $o_name with $@"
echo "-----------------------------"
		
if cc "$@" $f_name -o $o_name apue.3e/lib/libapue.a; then
	echo "Compiled successfully!"
else
	echo "ERROR!"
fi
				
echo "-----------------------------"
