sudo umount /mnt/loop0p1
sudo rm -rf /mnt/loop0p1
sudo umount /mnt/loop0p2
sudo rm -rf /mnt/loop0p2
sudo umount /mnt/loop1p1
sudo rm -rf /mnt/loop1p1
sudo umount /mnt/loop1p2
sudo rm -rf /mnt/loop1p2
sudo kpartx -d out.img
