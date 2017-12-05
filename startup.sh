#!/bin/bash
 
nmtui
 
subscription-manager register --force --username ub298@nyu.edu --password Bon_1_Vacance --auto-attach
subscription-manager refresh
yum makecache fast

yum -y update

ssh-copy-id -i ~/.ssh/id_rsa papa@192.168.0.6