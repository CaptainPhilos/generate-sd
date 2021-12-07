# Generation of SD Card


# Manual

USAGE: ./generate-retropie-image.sh -i "original retropie image" -o "image to generate"

# Installation on SD Card (Linux)

## Mount a freshly formatted card (On windows or Macos)
```
umount /dev/sdb
```

## copy img to sd card
```
sudo dd bs=4M if=game.img of=/dev/sdb
```
