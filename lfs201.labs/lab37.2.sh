#!/bin/bash

# cpio, backup

# pack up include
(cd /usr; find include | cpio -c -o > $HOME/spaces/devspace/include.cpio)

# pack in gzip
(cd /usr; find include | cpio -c -o | gzip -c > $HOME/spaces/devspace/include.cpio.gz)

# is it there
ls -lh include*

# see the archive
cpio -ivt < include.cpio