echo "generation of space invaders II (Midway Cocktail 1980) specific SD card"
echo "../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o space.ivaders.II.cocktail.mame2003.img -s ../origin/game-to-install/arcade/invad2ct.zip -c \"../origin/game-to-install/arcade/DragonRise Inc.   Generic   USB  Joystick  .cfg\" -e lr-mame2003 -x borne_rene_pierre"
../../source/generate-image/generate-generic-image.sh -d -i ../origin/origin.img -o space.ivaders.II.cocktail.mame2003.img -s ../origin/game-to-install/arcade/invad2ct.zip -c "../origin/game-to-install/arcade/DragonRise Inc.   Generic   USB  Joystick  .cfg" -e lr-mame2003 -x borne_rene_pierre
# ajout d'une ligne display_rotate=3
# affectation de la fct tir sur chaque bouton


