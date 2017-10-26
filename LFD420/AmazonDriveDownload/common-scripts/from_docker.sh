#!/bin/bash

function from_docker {
if [ -f /.dockerenv ]; then
    echo "I'm inside the docker container"
else
    tput setaf 1; echo "$PS4$@I need to run from the docker container"
    tput sgr0
    exit -1
fi
}
