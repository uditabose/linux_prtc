make clean
echo "+ make C=2 CHECK=/usr/bin/sparse"
make C=2 CHECK=/usr/bin/sparse
#make C=2
sleep 1
../sign-all.sh
