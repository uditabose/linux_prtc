HERE=`pwd`

source ../env.sh
#source version.sh

export EXTRA_STUFF_DIR=libhugetlbfs

echo "+ cd ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}/${EXTRA_STUFF_DIR}"
cd ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}/${EXTRA_STUFF_DIR}

set -x
make
sudo make install
set +x

cd ${HERE}
