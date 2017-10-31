#!/bin/bash

# umask

AFL=bfile

if [[ ! -f "$AFL" ]]; then
	touch "$AFL"
fi

# what is the file situation
ls -l "$AFL"

# what is mask
umask

# change the mask
umask 0022
touch "$AFL"2
umask 0666
touch "$AFL"3

ls -lrt "$AFL"*
