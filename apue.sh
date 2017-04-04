#!/bin/bash

#1. Compile `apue.3e` package
#  - `sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip`
#  - `sudo apt-get install libbsd*`
#  - `cd {root-dir}/apue.3e`
#  - `make`
#  - `sudo cp ./apue.3e/include/apue.h /usr/include/`

#### Imp :  Run with a user in sudoers list with all rights

sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip
sudo apt-get install libbsd*

if [ -d 'apue.3e/' ]
then
	cd apue.3e/
	make
	sudo cp -v include/apue.h /usr/include/
else 
	echo "Fix the directory path!"
	exit 1
fi
