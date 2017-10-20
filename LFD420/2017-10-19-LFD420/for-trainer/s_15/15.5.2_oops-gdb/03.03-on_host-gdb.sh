source ../../env.sh
echo "+ ${CROSS_COMPILE}gdb oops.ko"
echo "+ in ${CROSS_COMPILE}gdb execute:"
echo "source ${NFS_EXPORTED_ROOTFS_ROOT}$(pwd)/add-symbol-file.gdb"
echo "+ press ENTER to go on"
read r
${CROSS_COMPILE}gdb oops.ko
