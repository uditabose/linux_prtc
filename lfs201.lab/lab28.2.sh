#!/bin/bash

# RPM database

if [[ ! -x rpm ]]; then
	sudo apt install rpm
fi

# is rpm lib there
ls -l /var/lib/rpm

# backup rpm database
sudo cp -a /var/lib/rpm /var/lib/rpm_BACKUP

# rebuild rpm database
sudo rpm --rebuilddb

# list all rpms
rpm -qa | tee /tmp/rpm-qa.out

# delete the backup
sudo rm -f /var/lib/rpm_BACKUP