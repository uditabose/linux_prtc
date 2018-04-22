#!/bin/bash
source os.sh
source colors.sh

mkdir /tmp/transfer-lab/
mkdir /tmp/receive/

for i in '/tmp/transfer-lab/{a,b,c}-{1,2,3}.{txt,log,bin}'; do
    echo $i > $i
done

sudo scp /tmp/transfer-lab/*.log papa@localhost:/receive