#!/bin/bash

loop=$(sudo losetup -f)
sudo losetup --show -P "${loop}" $1

mkdir d1
mkdir d2
sudo mount "${loop}p1" d1
sudo mount "${loop}p2" d2


