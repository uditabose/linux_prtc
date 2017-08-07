#!/bin/bash

# logical volumes
PART=/dev/sdb
PART_2=/dev/sdb2
PART_3=/dev/sdb3
VG=papa_vg
LVM=papa_lvm
MNTPNT=/mnt/tempdir

# wipe all partition
sudo wipefs -af "$PART"

# change partition type
echo -e "t\n8e\nw" | sudo fdisk "$PART"

# make 2 partition, 256 MB
echo -e "n\np\n2\n\n+256M\nw" | sudo fdisk "$PART"
echo -e "n\np\n3\n\n+256M\nw" | sudo fdisk "$PART"

# view the partition details
sudo partprobe -s

# convert partition to physical volumes
sudo pvcreate "$PART_2"
sudo pvcreate "$PART_3"

# view the physical volumes
sudo pvdisplay 

# create a volume group
sudo vgcreate "$VG" "$PART_2" "$PART_3"

# view the volume group
sudo vgdisplay

# create the logical volume
sudo lvcreate -L 300M -n "$LVM" "$VG"

# view logical volume
sudo lvdisplay

# put a filesystem, and mount 
sudo mkfs.ext4 "/dev/$VG/$LVM"
sudo mkdir "/$LVM"
sudo mount "/dev/$VG/$LVM" "/$LVM"

# view logical volume
sudo lvdisplay

# see the details
df -h

# extend the logical volume
sudo lvextend -L 300M "/dev/$VG/$LVM"
sudo resize2fs "/dev/$VG/$LVM"

# see the details
df -h

# or do the next
# sudo lvextend -r -L +50M /dev/myvg/mylvm







