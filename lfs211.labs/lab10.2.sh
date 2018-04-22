#!/bin/bash
source os.sh
source colors.sh

rsync -av /tmp/transfer-lab/*.bin papa@localhost:/tmp/receive
