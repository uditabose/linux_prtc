#!/bin/bash

# RPM basics

if [[ ! -x rpm ]]; then
	sudo apt install rpm
fi

# who owns /etc/logrotate.conf
rpm -qf /etc/sysctl.conf

# learn all about the package that has logrotate
rpm -qil sysctl

# learn all together
echo '---------------------------'
rpm -qil $(rpm -qf /etc/sysctl.conf)

# verify package installation
rpm -V sysctl