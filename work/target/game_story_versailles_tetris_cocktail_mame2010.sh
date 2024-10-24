echo "generation of Tetris Cocktail specific SD card"
echo "../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o tetris.cocktail.mame2010.img -s ../origin/game-to-install/arcade/atetrisc.zip -c \"../origin/game-to-install/arcade/DragonRise Inc.   Generic   USB  Joystick  .cfg\" -e lr-mame2010 -x borne_rene_pierre"
../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o tetris.cocktail.mame2010.img -s ../origin/game-to-install/arcade/atetrisc.zip -c "../origin/game-to-install/arcade/DragonRise Inc.   Generic   USB  Joystick  .cfg" -e lr-mame2010 -x borne_rene_pierre
# ajout du son par la sortie jack

# /boot/config.txt
# uncomment to force a specific HDMI mode (this will force VGA)
#hdmi_group=2
#hdmi_mode=9
# ajout d'une ligne
#display_rotate=3 ou 1
# installer le core mame 0.139 pour Tetris
# sudo ./retropie_packages.sh lr-mame2010 install