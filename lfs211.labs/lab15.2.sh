#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

# allow loopback
iptables -A INPUT -i lo -j ACCEPT

# allow all returning traffic
iptables -A INPUT -m state --state=ESTABLISHED,RELATED -j ACCEPT

# allow inbound SSH traffic
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# block others
iptables -P INPUT DROP

### save, DON'T DO THIS
### -----------------------------
# service iptables save

# Ubuntu
# install_pkg iptables-persistent.
#  iptables-save >/etc/iptables/rules.v4