#!/bin/bash

##########################################################################
#
# This script modifies retropie file to remove printing at start and to implement specific properties
#
# Requirements :

# definitions ############################################################

# Global variables
#
# depends on mounting solution used. TO BE CONFIRMED
root_path_mounted_volumes="/media/herve"
echo "root_path_mounted_volumes : $root_path_mounted_volumes"

# Directories structure of Retropie
root_path_boot="$root_path_mounted_volumes/boot"
echo "root_path_boot : $root_path_boot"
root_path_retropie="$root_path_mounted_volumes/retropie"
echo "root_path_retropie : $root_path_retropie"

#
# boot/cmdline.txt
#
echo "-------------------------------------------------------------------"
echo " boot/cmdline.txt"
echo "-------------------------------------------------------------------"
#DEBUG
#cp $root_path_boot/cmdline.txt $root_path_boot/cmdline.txt.bak
filename="$root_path_boot/cmdline.txt"

# replace "console=tty1" by "logo.nologo loglevel=3 vt.global_cursor_default=0"
pattern_to_remove="console=tty1"
pattern_to_add="logo.nologo loglevel=3 vt.global_cursor_default=0"

#command : sed '0,/tata/ s//zaza/' in.txt
echo "-------------------------------------------------------------------"
echo "replace $pattern_to_remove by $pattern_to_add in file $filename"
echo "*Sed Command : 0,/$pattern_to_remove/ s//$pattern_to_add/"
sed -i '0,/'"$pattern_to_remove"'/ s//'"$pattern_to_add"'/' $filename

#
# boot/config.txt
#
echo "-------------------------------------------------------------------"
echo " boot/config.txt"
echo "-------------------------------------------------------------------"
#DEBUG
#cp $root_path_boot/config.txt $root_path_boot/config.txt.bak
filename="$root_path_boot/config.txt"

# uncomment "disable_overscan=1"
echo "-------------------------------------------------------------------"
echo "uncomment disable_overscan=1"
sed -i '0,/#disable_overscan/ s//disable_overscan/' $filename

# add "disable_splash=1"
echo "-------------------------------------------------------------------"
echo "add disable_splash=1"
sed -i '$adisable_splash=1' $filename

# add "disable_splash=1"
echo "-------------------------------------------------------------------"
echo "add plymouth.enable=0"
sed -i '$aplymouth.enable=0' $filename

#
# retropie/opt/retropie/configs/all/runcommand.cfg
#
echo "-------------------------------------------------------------------"
echo " retropie/opt/retropie/configs/all/runcommand.cfg"
echo "-------------------------------------------------------------------"
#DEBUG
#cp $root_path_retropie/opt/retropie/configs/all/runcommand.cfg $root_path_retropie/opt/retropie/configs/all/runcommand.cfg.bak
filename="$root_path_retropie/opt/retropie/configs/all/runcommand.cfg"

# add "disable_joystick=1"
echo "-------------------------------------------------------------------"
echo "replace disable_joystick=0 by disable_joystick=1 in file $filename"
sed -i '/disable_joystick/ s/"0"/"1"/g' $filename

# add "disable_splash=1"
echo "-------------------------------------------------------------------"
echo "replace disable_menu=0 by disable_menu=1 in file $filename"
sed -i '/disable_menu/ s/"0"/"1"/g' $filename

#
# retropie/opt/retropie/emulators/retroarch/retroarch.cfg
#
echo "-------------------------------------------------------------------"
echo " retropie/opt/retropie/emulators/retroarch/retroarch.cfg"
echo "-------------------------------------------------------------------"
#DEBUG
#sudo cp $root_path_retropie/opt/retropie/emulators/retroarch/retroarch.cfg $root_path_retropie/opt/retropie/emulators/retroarch/retroarch.cfg.bak
filename="$root_path_retropie/opt/retropie/emulators/retroarch/retroarch.cfg"

# uncomment and set to false "video_font_enable=false"
echo "-------------------------------------------------------------------"
echo "uncomment video_font_enable and set to false in file $filename"
sudo sed -i '/video_font_enable/ s/#//g' $filename
sudo sed -i '/video_font_enable/ s/true/false/g' $filename

#
# retropie/opt/retropie/configs/all/retroarch.cfg
#
echo "-------------------------------------------------------------------"
echo " retropie/opt/retropie/configs/all/retroarch.cfg"
echo "-------------------------------------------------------------------"
#DEBUG
#cp $root_path_retropie/opt/retropie/configs/all/retroarch.cfg $root_path_retropie/opt/retropie/configs/all/retroarch.cfg.bak
filename="$root_path_retropie/opt/retropie/configs/all/retroarch.cfg"

# uncomment and set to false "video_font_enable=false"
echo "-------------------------------------------------------------------"
echo "uncomment video_font_enable and set to false in file $filename"
sed -i '/video_font_enable/ s/#//g' $filename
sed -i '/video_font_enable/ s/true/false/g' $filename
