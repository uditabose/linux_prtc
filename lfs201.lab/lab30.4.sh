#!/bin/bash

# yum new repo

# start the vagrant box
vagrant up 

# make the new repo
vagrant ssh -c "sudo touch /etc/yum.repos.d/webmin.repo"
vagrant ssh -c "sudo su -c 'echo [Webmin] >> /etc/yum.repos.d/webmin.repo'"
vagrant ssh -c "sudo su -c echo 'name=Webmin Distribution Neutral >> /etc/yum.repos.d/webmin.repo'"
vagrant ssh -c "sudo su -c echo 'baseurl=http://download.webmin.com/download/yum >> /etc/yum.repos.d/webmin.repo'"
vagrant ssh -c "sudo su -c echo 'mirrorlist=http://download.webmin.com/download/yum/mirrorlist >> /etc/yum.repos.d/webmin.repo'"
vagrant ssh -c "sudo su -c echo 'enabled=1 >> /etc/yum.repos.d/webmin.repo'"
vagrant ssh -c "sudo su -c echo 'gpgcheck=0 >> /etc/yum.repos.d/webmin.repo'"

# install
vagrant ssh -c "sudo yum install webmin"
