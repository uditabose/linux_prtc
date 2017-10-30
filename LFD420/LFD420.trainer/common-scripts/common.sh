#!/bin/bash 
#SCRIPT_PATH=${HOME}/common-scripts
SCRIPT_PATH="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${SCRIPT_PATH}/plus_echo.sh
source ${SCRIPT_PATH}/plus_echo_color.sh
source ${SCRIPT_PATH}/plusplus_echo.sh
source ${SCRIPT_PATH}/plus_on.sh
source ${SCRIPT_PATH}/plus_off.sh

source ${SCRIPT_PATH}/press_enter.sh
source ${SCRIPT_PATH}/from_docker.sh
source ${SCRIPT_PATH}/from_host.sh

source ${SCRIPT_PATH}/color_grep.sh
source ${SCRIPT_PATH}/plus_vim_read.sh
