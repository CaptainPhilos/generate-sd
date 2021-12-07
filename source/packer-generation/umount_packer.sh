#!/bin/bash

cd ~/Documents/mo5.com/generate-sd/source/packer-generation
loop=$(sudo losetup -f)

sudo umount "$1p1"
sudo umount "$1p2"
$(sudo losetup -d "$1")
rm -rf d1
rm -rf d2
