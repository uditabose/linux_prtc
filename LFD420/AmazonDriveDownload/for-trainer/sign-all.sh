#!/bin/bash
FILES=*.ko
for f in $FILES
do
  echo "Processing $f file..."
  ../sign_manually.sh $(pwd)/$f
done
