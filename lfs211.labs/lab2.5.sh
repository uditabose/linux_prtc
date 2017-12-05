#!/bin/bash
source os.sh
source colors.sh

# enable service
systemctl enable vsftpd.service

# see status
systemctl status vsftpd.service
