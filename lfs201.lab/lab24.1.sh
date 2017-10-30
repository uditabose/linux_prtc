#!/bin/bash

# bonnie++ for benchmark

# see if bonnie is there
is_bon=$(bonnie++)

if [[ -x bonnie++ ]]; then
	echo 'bonnie++ is there'
else
	sudo apt install bonnie++
fi

# see bonnie++ stuff
time sudo bonnie++ -n 0 -u 0 -r 100 -f -b -d /usr | tee 'bonnie++.out'

# turn it into HTML
bon_csv2html < bonnie++.out > bonnie++.html

# turn it into TXT
bon_csv2txt < bonnie++.out > bonnie++.txt
