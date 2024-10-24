echo "generation of pacman specific SD card"
echo "../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o pacman.mame2003.img -s ../origin/game-to-install/arcade/pacman.zip -c \"../origin/game-to-install/arcade/Mega World.cfg\" -e lr-mame2003 -x pacman_GameStoryVersailles"
../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o pacman.mame2003.img -s ../origin/game-to-install/arcade/pacman.zip -c "../origin/game-to-install/arcade/Mega World.cfg" -e lr-mame2003 -x pacman_GameStoryVersailles


# boot/config.txt
# disable_overscan=1

# enable_tvout=1
# sdtv_mode=2 # PAL
# sdtv_aspect=1 # 4:3
