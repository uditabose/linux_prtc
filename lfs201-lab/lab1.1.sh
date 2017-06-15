#!/bin/bash

# user name
USER=new_lfs_student
NAME='LFS Student'
PASSWD=$(echo -n "$USER" | md5sum)
HOME="/home/$USER"
BASHRC="$HOME/.bashrc"
SUDOERS="/etc/sudoers.d/$USER"

# create user
# @see https://www.tecmint.com/add-users-in-linux/
sudo useradd -c "$NAME" "$USER"

# create a password
# @see http://www.linuxquestions.org/questions/linux-newbie-8/non-interactive-way-to-set-a-password-825627/
echo "$USER:$PASSWD" | sudo chpasswd

# add to sudoers file
# @see https://stackoverflow.com/questions/323957/how-do-i-edit-etc-sudoers-from-a-script
echo "$USER ALL=(ALL) ALL" | sudo EDITOR='tee -a' visudo

# update file permission
if [[ -f "$SUDOERS" ]]; then
	chmod 440 /etc/sudoers.d/"$USER"
fi

# update .bashrc
if [[ ! -d "$HOME" ]]; then
	sudo mkdir -p "$HOME"
fi

if [[ ! -f "$BASHRC" ]]; then
	su - "$USER" touch "$BASHRC"
fi

su - "$USER" echo "PATH=$PATH:/usr/sbin:/sbin" >> "$BASHRC"
su - "$USER" echo "export $PATH" >> "$BASHRC"
