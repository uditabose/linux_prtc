#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_REDHAT ]]; then
    mkdir -m 730 '/var/ftp/uploads'
    chown root.ftp '/var/ftp/uploads'
    if [[ -f '/etc/vsftpd/vsftpd.conf' ]]; then
        echo "anon_upload_enable=yes" >> '/etc/vsftpd/vsftpd.conf'
        echo "anonymous_enable=yes" >> '/etc/vsftpd/vsftpd.conf'
    fi
fi

if [[ $OS == $OS_UBUNTU ]]; then
    mkdir -m 730 '/srv/ftp/uploads'
    chown root.ftp '/srv/ftp/uploads'

    if [[ -f '/etc/vsftpd.conf' ]]; then
        echo "anon_upload_enable=yes" >> '/etc/vsftpd.conf'
        echo "anonymous_enable=yes" >> '/etc/vsftpd.conf'
        echo "write_enable=YES" >> '/etc/vsftpd.conf'
    fi
fi


