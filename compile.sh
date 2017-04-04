#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage : ./compile.sh <file> <object_file>"
	exit
fi
		
echo 
echo "Compiling $1 to executable $2"
echo "-----------------------------"
		
if cc $1 -o $2 apue.3e/lib/libapue.a; then
	echo "Compiled successfully!"
else
	echo "ERROR!"
fi
				
echo "-----------------------------"
