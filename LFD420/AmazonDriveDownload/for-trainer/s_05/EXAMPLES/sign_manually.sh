#!/bin/bash
if [ $# -eq 0 ]; then
    echo "usage:"
    echo "../sign_manually.sh \$(pwd)/lab1_chrdrv.ko"
    exit 1
fi

source ../../env.sh
set -x
#${STAGING_DIR}/s_02/linux-${KERNEL_VER}/scripts/sign-file sha512 ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/signing_key.priv ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/signing_key.x509 $1
${STAGING_DIR}/s_02/linux-${KERNEL_VER}/scripts/sign-file sha512 ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/certs/signing_key.pem ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/certs/signing_key.x509 $1
set +x
# see: 
# https://wiki.gentoo.org/wiki/Signed_kernel_module_support
# http://localhost/lxr/http/source/linux/Documentation/module-signing.txt
