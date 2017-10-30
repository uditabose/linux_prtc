#!/bin/bash

# change mod

AFL=afile

if [[ ! -f "$AFL" ]]; then
	touch "$AFL"
fi

# use chmod to update user permission
sudo chmod u=r,g=w,o=x "$AFL"
ls -l "$AFL"
sudo chmod u=+w,g=-w,o=+rw "$AFL"
ls -l "$AFL"
sudo chmod ug=rwx,o=-x "$AFL"
ls -l "$AFL"