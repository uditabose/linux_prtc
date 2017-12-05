#!/bin/bash

convert ~/Desktop/*.png -units PixelsPerInch -density 200 ~/spaces/workspace/LinuxPractice/lfs211/$1.pdf

rm -fv ~/Desktop/*.png
