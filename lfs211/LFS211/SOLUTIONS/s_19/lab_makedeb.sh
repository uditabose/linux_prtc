#!/bin/bash
#/* **************** LFS211:1.0 s_19/lab_makedeb.sh **************** */
#/*
# * The code herein is: Copyright the Linux Foundation, 2016
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    http://training.linuxfoundation.org
# *     email:  trainingquestions@linuxfoundation.org
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash -x

# clean up from any previous attempts
rm -rf  WORK && mkdir WORK && cd WORK

# need a copy of the tarball in the WORK directory
cp ../myappdebian-1.0.tar.gz .

# expand the upstream tarball source
tar xvf myappdebian-1.0.tar.gz

# build the package
cd myappdebian-1.0
dh_make -f ../*myappdebian-1.0.tar.gz
dpkg-buildpackage -uc -us
# check its contents
dpkg --contents ../*.deb

echo you should be able to install now with dpkg --install




