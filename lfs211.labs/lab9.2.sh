#!/bin/bash
source os.sh
source colors.sh

source install.prep.sh

# install package 
install_pkg dovecot* mutt

# /etc/dovecot/dovecot.conf

if [[ $OS == $OS_REDHAT ]]; then
    echo "protocols = imap pop3 lmtp" >> /etc/dovecot/dovecot.conf
    echo "listen = *" >> /etc/dovecot/dovecot.conf
    echo "mail_location = mbox:~/mail:INBOX=/var/spool/mail/%u" >> /etc/dovecot/conf.d/10-mail.conf
fi

if [[ $OS == $OS_UBUNTU ]]; then
    rm -f /usr/share/dovecot/protocols.d/managesieved.protocol
    echo ’protocols = $protocols lmtp’ > \
                                  /usr/share/dovecot/protocols.d/lmtp.protocol

    echo "listen = *" >> /etc/dovecot/dovecot.conf 
fi

sudo systemctl restart dovecot