sudo apt-get install libelf-dev libdw-dev

TMP_PATH=$(pwd)
cd systemtap
./configure --prefix=/home/rber/systemtap-1.5
make
make install
cd ${TMP_PATH}
