#!/bin/bash

FAKE_SERVICE=fake_service
INITD=/etc/init.d
DEFAULT=/etc/default # RHEL : /etc/sysconfig
LOG=/var/log/"$FAKE_SERVICE"

sudo cp -v "$FAKE_SERVICE"_init "$INITD/$FAKE_SERVICE" && sudo chmod 0755 "$INITD/$FAKE_SERVICE"
sudo cp -v "$FAKE_SERVICE"_def "$DEFAULT/$FAKE_SERVICE" && sudo chmod 0755 "$DEFAULT/$FAKE_SERVICE"

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
update-rc.d "$FAKE_SERVICE" defaults
update-rc.d "$FAKE_SERVICE" enable

# RHEL : 
# sudo chkconfig --list fake_service
# sudo chkconfig --add fake_service
# sudo chkconfig fake_service on
# sudo chkconfig fake_service off
