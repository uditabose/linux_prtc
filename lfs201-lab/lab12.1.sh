#!/bin/bash

# file attributes

FILE=/tmp/appendit
RNMFL=/tmp/renamed
HOSTS=/etc/hosts
PASS=/etc/passwd

# create a file to play with attributes
touch "$FILE"
cat "$HOSTS" > "$FILE"

# see the difference
diff "$HOSTS" "$FILE"
echo $?

# append only attribute, as normal user
chattr +a "$FILE"

# append only attribute, as root
sudo chattr +a "$FILE"

# overwrite stuff to the file, as normal user, will fail
cat "$PASS" > "$FILE"

# overwrite stuff to the file, as root, will fail
sudo cat "$PASS" > "$FILE"

# append stuff to the file, as normal user
cat "$PASS" >> "$FILE"

# make file immutable
sudo chattr +i "$FILE"

# try rename
mv "$FILE" "$RNMFL"

# try appending stuff to the file, as normal user
cat "$PASS" >> "$FILE"

