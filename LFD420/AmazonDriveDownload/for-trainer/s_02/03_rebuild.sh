source ../env.sh

if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    echo "e.g. sudo bash on Ubuntu"
    exit 1
fi

HERE=$(pwd)

cd ${STAGING_DIR}/s_02/linux-${KERNEL_VER}

#../DO_KERNEL.sh
make
make modules
make install

cd ${HERE}
