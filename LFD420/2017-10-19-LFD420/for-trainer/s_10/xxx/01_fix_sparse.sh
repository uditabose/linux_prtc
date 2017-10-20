TMP_PATH=`pwd`
echo "The version of sparse which comes with Ubuntu did not work for me"
echo "I'll uninstall it!"
sudo apt-get remove sparse
echo "we'll get a fresh version from git"
sudo rm -rf sparse
git clone git://git.kernel.org/pub/scm/devel/sparse/sparse.git
cd sparse
make
make install
cd ${TMP_PATH}

