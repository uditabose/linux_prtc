#!/bin/bash

# yum search

# start the vagrant box
vagrant up 

# vagrant command
vagrant ssh -c "sudo yum search bash"
vagrant ssh -c "sudo yum list bash"
vagrant ssh -c "sudo yum info bash"
vagrant ssh -c "sudo yum deplist bash"