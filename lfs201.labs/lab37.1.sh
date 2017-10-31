#!/bin/bash

# tar, backup

# this dir
this_dir=`pwd`

# go back
cd ..

# tar it up
tar zcvf haha.tar.gz .

# tar it in 3 steps
cd "$this_dir"
tar -C ../ -zcf haha.tar.gz ../
tar -C ../ -jcf haha.tar.bz2 ../
tar -C ../ -Jcf haha.tar.xz ../

# how efficient is this ?
cd ..
du -sh .

ls -lh haha.*

# see what's inside
tar tvf haha.tar.xz
