HERE=`pwd`
./01_genmake.sh
rm -f Makefile
cd EXAMPLES
./10_clean.sh
cd ${HERE}

