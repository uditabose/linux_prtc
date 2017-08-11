#!/bin/bash

# restricted bash

# start a restricted bash
rbash -r

# try something
cd $HOME

exit

# link files
cd /home/offline
sudo ln '/bin/bash' '/bin/rbash'

# create a restricted user
sudo useradd -s '/bin/rbash' fool
sudo passwd fool

# change the user
sudo su - fool

# try something
cd $HOME
cd /tmp
PATH=$PATH:/tmp
exit
sudo userdel -r fool
sudo rm /bin/rbash