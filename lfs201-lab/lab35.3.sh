#!/bin/bash

# all about ACL

AFL=cfile

if [[ ! -f "$AFL" ]]; then
	touch "$AFL"
fi

# write something to the file
echo "This is a placeholder" >> "$AFL"

# what is the ACL
getfacl "$AFL"

# set new ACl
setfacl -m u:offline:rx "$AFL"
getfacl "$AFL"

# write stuff, it should fail
sudo su offline -c "echo 'This is another placeholder' >> $AFL"

