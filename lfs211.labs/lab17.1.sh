#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg mariadb-server

sudo systemctl start mariadb
sudo systemctl status mariadb

# DON'T do 
# sudo systemctl enable mariadb

mysql_secure_installation