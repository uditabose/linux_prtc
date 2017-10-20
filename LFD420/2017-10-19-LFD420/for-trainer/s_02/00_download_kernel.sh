HERE=$(pwd)

source ../env.sh

if [ ! -d ${DL_DIR}/s_02 ];
then
  mkdir -p ${DL_DIR}/s_02
fi

cd ${DL_DIR}/s_02
if [ ! -f linux-${KERNEL_VER}.tar.xz ];
then
  set -x
  wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-${KERNEL_VER}.tar.xz
  set +x
fi
cd ${HERE}
