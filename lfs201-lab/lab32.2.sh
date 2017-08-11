#!/bin/bash

# find packages in apt
sudo apt-cache search bash
sudo apt-cache search -n bash
sudo apt-cache show bash

# dependencies
sudo apt-cache depends bash
sudo apt-cache rdepends bash