#!/bin/bash

# yum basics

# start the vagrant box
#vagrant init
vagrant up 

# run commands
vagrant ssh -c "sudo yum list"
vagrant ssh -c "sudo yum -y update"
vagrant ssh -c "sudo yum check-update"
vagrant ssh -c "sudo yum -y check-update"
vagrant ssh -c "sudo yum list updates"
vagrant ssh -c "sudo yum -y update bash"
vagrant ssh -c "sudo yum list installed 'kernel*'"
vagrant ssh -c "sudo yum list 'kernel*'"
vagrant ssh -c "sudo yum install httpd-devel"