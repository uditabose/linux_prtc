#!/bin/bash

# yum managing groups

# start the vagrant box
vagrant up 

# vagrant command
vagrant ssh -c "sudo yum grouplist"
vagrant ssh -c "sudo yum groupinfo 'Backup Client'"
vagrant ssh -c "sudo yum groupinstall 'Backup Client'"
vagrant ssh -c "sudo yum groupremove 'Backup Client'"
