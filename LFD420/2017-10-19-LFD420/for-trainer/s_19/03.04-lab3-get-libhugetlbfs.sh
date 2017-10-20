HERE=`pwd`

source ../env.sh
#source version.sh

export EXTRA_STUFF_DIR=libhugetlbfs

if [ ! -d ${EXTRA_STUFF}/${EXTRA_STUFF_DIR} ];
then
    echo "+ mkdir -p ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}"
    mkdir -p ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}
else
    echo "${EXTRA_STUFF}/${EXTRA_STUFF_DIR} exists - recreating it"
    echo "+ rm -rf ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}"
    rm -rf ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}
    echo "+ mkdir -p ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}"
    mkdir -p ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}
fi


echo "+ cd ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}"
cd ${EXTRA_STUFF}/${EXTRA_STUFF_DIR}

set -x
git clone git://github.com/libhugetlbfs/libhugetlbfs.git
set +x

cd ${HERE}
