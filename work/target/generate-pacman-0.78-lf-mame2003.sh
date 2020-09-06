echo "generation of pacman specific SD card"
echo "../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o pacman.mame2003.img -s ../origin/game-to-install/arcade/pacman.zip -c \"../origin/game-to-install/arcade/Mega World.borne.1 bouton-boutongauche-2.cfg\" -e lr-mame2003 -x \"borne_pacman_mo5\""
../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o pacman.mame2003.img -s ../origin/game-to-install/arcade/pacman.zip -c "../origin/game-to-install/arcade/Mega World.borne.1 bouton-boutongauche-2.cfg" -e lr-mame2003 -x "borne_pacman_mo5"
