#!/bin/bash
source colors.sh
PDF_NAME="$1"

if [[ -z  "$PDF_NAME" ]]; then
    echo -ne "$Red invalid PDF name $Color_Off\n"
    exit -1
fi

convert ~/Desktop/*.png -units PixelsPerInch -density 200 ~/spaces/workspace/LinuxPractice/lfs211/$1.pdf

rm -fv ~/Desktop/*.png
