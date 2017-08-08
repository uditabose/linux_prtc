#!/bin/bash

# setuid

CODE=writeit

# build the `c` file
gcc -o "$CODE" "$CODE.c"

# or try this
# make "$CODE"

# create a file
sudo touch afile

# run as normal user
./"$CODE"

# run as root
sudo ./"$CODE"

# change the file owner
sudo chown root:root "$CODE"

# run as normal user
./"$CODE"

# add setuid bit
sudo chmod +s "$CODE"

# now run as normal user
./"$CODE"