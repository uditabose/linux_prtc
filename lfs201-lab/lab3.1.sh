#!/bin/bash

# boot in non-graphical mode
# then do one of the following to bring up the GUI

 sudo systemctl start gdm
 sudo systemctl start lightdm
 sudo telinit 5
 sudo service gdm restart
 sudo service lightdm restart