#!/bin/bash
install_pkg() {
    if [[ $OS == $OS_UBUNTU ]]; then
        install_ub_pkg "$@"
    fi

    if [[ $OS == $OS_REDHAT ]]; then
        install_rhel_pkg -y "$@"
    fi
}

install_ub_pkg() {
    sudo apt install -y "$@"
}

install_rhel_pkg() {
    sudo yum install -y "$@"
}
