HERE=$(pwd)

source ../env.sh

if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    echo "e.g. sudo bash on Ubuntu"
    exit 1
fi

cd ${STAGING_DIR}/s_02

echo "+ tar xf linux-${KERNEL_VER}.tar.xz"
tar xf linux-${KERNEL_VER}.tar.xz

echo "+ cp config-${KERNEL_CONFIG}_x86_64 linux-${KERNEL_VER}/.config"
cp config-${KERNEL_CONFIG}_x86_64 linux-${KERNEL_VER}/.config

echo "+ cd linux-${KERNEL_VER}"
cd linux-${KERNEL_VER}

echo "+ ../DO_KERNEL.sh"
../DO_KERNEL.sh

cd $HERE
