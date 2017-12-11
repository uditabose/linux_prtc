#!/bin/bash
if [[ "$#" -ne 2 ]]; then
    echo "2-part file name needed"
    exit -1
fi
cp shell.template "lab$1.$2.sh"
