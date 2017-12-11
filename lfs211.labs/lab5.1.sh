#!/bin/bash
source os.sh
source colors.sh

# now, I have all the keys I need, this is just for fun
FUN_SSH_ID="$HOME/.ssh/fun-id-rsa"
ssh-keygen -t rsa -f "$FUN_SSH_ID"
eval $(ssh-agent)
ssh-add "$FUN_SSH_ID"

# copying it to itself
ssh-copy-id papa@localhost
id

(
 ssh papa@localhost 
 id
)
