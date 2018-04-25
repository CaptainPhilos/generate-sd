#!/bin/bash

##########################################################################

if [ "`tty`" = "/dev/tty1" ]; then

  # globals ################################################################

  debug=

  root_usb_key="/Volumes/ROMS/"
  #root_usb_key="/media/usb0/"
  bin_path="bin/launch-game.sh"

  # If script file is found in USB Key, then launch it
  if [ -f "${root_usb_key}${bin_path}" ]; then
    bash "${root_usb_key}${bin_path}"
  # otherwise, launch emulation station (maybe it's a bad idea)
  else
    bash "/opt/retropie/configs/all/autostart.sh"
  fi

fi
