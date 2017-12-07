#!/bin/bash
source os.sh
source colors.sh

# drop packets
tc qdisc add dev lo root netem loss random 40

# start tcpdump
tcpdump  -i lo proto ICMP > 4.1.tcpdump.icmp 2>&1

(
 ping -c100 localhost > 4.1.ping.localhost  2>&1
)

tc qdisc del dev lo root
