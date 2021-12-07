echo "generation of pacman specific SD card"
echo "./generate-generic-image-with-packer.sh -a -d -i ../../work/origin/origin.img -o pacman.mame2003 -s ../../work/origin/game-to-install/arcade/pacman.zip -c ../../work/origin/game-to-install/arcade/Mega World.borne.1 bouton-boutongauche-2.cfg -e lr-mame2003 -x borne_pacman_mo5"
cp "../../work/origin/game-to-install/arcade/Mega World.borne.1 bouton-boutongauche-2.cfg" "../../work/origin/game-to-install/arcade/Mega World.cfg"
./generate-generic-image-with-packer.sh -d -i ../../work/origin/origin.img -o pacman.mame2003.img -s ../../work/origin/game-to-install/arcade/pacman.zip -c "../../work/origin/game-to-install/arcade/Mega World.cfg" -e lr-mame2003 -x "borne_pacman_mo5"
