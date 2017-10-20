make clean
./01_genmake.sh
rm -f Makefile

pushd extra-stuff
./10_clean.sh
popd
