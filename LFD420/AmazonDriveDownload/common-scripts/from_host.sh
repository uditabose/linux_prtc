#!/bin/bash

function from_host {
if [ ! -f /.dockerenv ]; then
    echo "I'm on the host"
else
    tput setaf 1; echo "$PS4$@I need to run from the host and not the docker container"
    tput sgr0
    exit -1
fi
}
