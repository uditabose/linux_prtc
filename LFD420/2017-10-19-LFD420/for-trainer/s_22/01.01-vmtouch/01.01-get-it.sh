#!/bin/bash
HERE=$(pwd)

source ../../env.sh
source version.sh

export EXTRA_STUFF_DIR=vmtouch

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
git clone git://github.com/hoytech/vmtouch.git
cd vmtouch
git co master
git branch -d ${CRASH_VERSION}_LOCAL
git co ${CRASH_VERSION}
git branch ${CRASH_VERSION}_LOCAL
git co ${CRASH_VERSION}_LOCAL
git branch
pwd
set +x
#echo "+ wget http://people.redhat.com/anderson/crash-${CRASH_VERSION}.tar.gz"
#wget http://people.redhat.com/anderson/crash-${CRASH_VERSION}.tar.gz

cd ${HERE}
