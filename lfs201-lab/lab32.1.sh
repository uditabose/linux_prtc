#!/bin/bash

# basic apt

# update
sudo apt update
sudo apt upgrade

# update a package
sudo apt upgrade bash

# search a package
sudo apt-cache search 'kernel'
sudo apt-cache search -n 'kernel'
sudo apt-cache pkgnames 'kernel'

# dpkg
sudo dpkg --get-selections '*kernel*'

# install
sudo apt install apache2-dev
