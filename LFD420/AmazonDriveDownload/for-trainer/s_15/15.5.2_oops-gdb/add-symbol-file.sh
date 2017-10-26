#!/bin/bash
#
# Constructs the GDB "add-symbol-file" command string
# from the sys entry of a loaded module

sect_addr() {
	cat ${DIR}/sections/$1
}

add_sect() {
	F=${DIR}/sections/$1
	[ -r $F ] && echo "-s $1 `cat $F`"
}

DIR=/sys/module/$1

[ $# == 1 ] && [ -d $DIR ] || { echo "Usage: $0 <module>" >&2 ; exit 1 ; }

ARGS="`sect_addr .text`\
 `add_sect .rodata`\
 `add_sect .data`\
 `add_sect .sdata`\
 `add_sect .bss`\
 `add_sect .sbss`\
"

echo "add-symbol-file ${1}.o $ARGS" > add-symbol-file.gdb
