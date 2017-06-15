#!/bin/bash

FAKE_SERVICE=fake_service
INITD=/etc/init.d
DEFAULT=/etc/default # RHEL : /etc/sysconfig
LOG=/var/log/"$FAKE_SERVICE"

# copy fake service config
./scp.sh fake_service_def
./scp.sh fake_service_init 
./scp.sh lab4.1.sh
