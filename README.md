## This repository contains worked out examples from **Advanced Programming in Unix Environment 3rd Edition** 

### Steps to compile code : 

Valid for Ubuntu 14.0

1. Compile `apue.3e` package 
  - `sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip`
  - `sudo apt-get install libbsd*`
  - `cd {root-dir}/apue.3e`
  - `make`
  - `sudo cp ./apue.3e/include/apue.h /usr/include/`
2. Compile code
  - `cd {root-dir}`
  - `./compile.sh {c-file} {object-file}`
  
