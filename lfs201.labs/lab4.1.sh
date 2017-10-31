#!/bin/bash

FAKE_SERVICE=fake_service
SYSMD_FAKE_SERVICE=fake.service
INITD=/etc/init.d
DEFAULT=/etc/default # RHEL : /etc/sysconfig
SYSMD=/etc/systemd/system/
LOG=/var/log/"$FAKE_SERVICE"
SYSLOG=/var/log/syslog

sudo cp -v "$FAKE_SERVICE"_init "$INITD/$FAKE_SERVICE" && sudo chmod 0755 "$INITD/$FAKE_SERVICE"
sudo cp -v "$FAKE_SERVICE"_def "$DEFAULT/$FAKE_SERVICE" && sudo chmod 0755 "$DEFAULT/$FAKE_SERVICE"
sudo cp -v "$SYSMD_FAKE_SERVICE" "$SYSMD" && sudo chmod 0755 "$SYSMD/$SYSMD_FAKE_SERVICE"

# test newly installed service
sudo service "$FAKE_SERVICE"

# start installed service
sudo service "$FAKE_SERVICE" start

# stop installed service
sudo service "$FAKE_SERVICE" stop

# verify log file
if [[ ! -f  "LOG" ]]; then
	echo "$FAKE_SERVICE log file missing"
fi

# add service 
sudo update-rc.d "$FAKE_SERVICE" defaults # RHEL : 
sudo update-rc.d "$FAKE_SERVICE" enable

# RHEL : 
# sudo chkconfig --list fake_service
# sudo chkconfig --add fake_service
# sudo chkconfig fake_service on
# sudo chkconfig fake_service off

# systemd start
sudo systemctl start "$SYSMD_FAKE_SERVICE"
sudo systemctl status "$SYSMD_FAKE_SERVICE"
sudo systemctl stop "$SYSMD_FAKE_SERVICE"

# check the log file
sudo tail -f /var/log/messages

# on boot
sudo systemctl enable "$SYSMD_FAKE_SERVICE"
sudo systemctl disable "$SYSMD_FAKE_SERVICE"
