TMP_PATH=`pwd`
sudo apt-get remove latencytop
sudo apt-get install libncursesw5-dev
cd latencytop/src
make
cd ${TMP_PATH}
