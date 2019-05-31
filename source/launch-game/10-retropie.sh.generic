#!/bin/bash

##########################################################################

if [ "`tty`" = "/dev/tty1" ] && [ "$USER" = "pi" ]; then

  # globals ################################################################

  root_usb_key="/media/usb0/bin/"
  bash_bin_file="launch-game.sh"
  python_bin_file="launch-game.py"

  # If script file is found in USB Key, then launch it
  if [[ -f "${root_usb_key}${python_bin_file}" ]]; then
    # bash version - incomplete
    #(bash "${root_usb_key}${bash_bin_path}" > /dev/null 2>&1)
    # python version
    cd "${root_usb_key}"
    (python3 "${python_bin_file}" > /dev/null 2>&1)
  # otherwise, launch emulation station (maybe it's a bad idea)
  else
    bash "/opt/retropie/configs/all/autostart.sh"
  fi

fi
