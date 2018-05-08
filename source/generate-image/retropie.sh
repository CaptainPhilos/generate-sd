#!/bin/bash

##########################################################################
#
# This script modifies retropie file to remove printing at start and to implement specific properties
#
# Requirements :

# definitions ############################################################

# Global variables
#

DEBUG=
root_directory=

# Directories for mounted volumes.
root_path_mounted_volumes="/mnt"
root_path_boot=
root_path_retropie=

# Source directories
source_directory=
source_splash_screen_sufixe="splash_screen"
source_splash_screen=

# Options
no_splash_screen=

# Error Management #######################################################

function exitonerror_nothingmade() {
  local errormsg=$1

  echo "ERROR : " $errormsg
  exit 1
}

function usage() {
  echo
  echo "USAGE: $(basename $0) -d -l mapper"
  echo
  echo "Use '--help' to see all the options"
  echo
}

# Directories Management

function set_directories() {

  root_path_boot="$root_path_mounted_volumes/$root_directory"
  root_path_boot+="p1"
  root_path_retropie="$root_path_mounted_volumes/$root_directory"
  root_path_retropie+="p2"
  if [[ -z $root_path_boot ]]; then
    exitonerror_nothingmade "Le mapper root_path_boot est vide"
  fi
  if [[ -z $root_path_retropie ]]; then
    exitonerror_nothingmade "Le mapper root_path_retropie est vide"
  fi
  if ! [[ -z $DEBUG ]]; then
    echo "root_path_boot : $root_path_boot"
    echo "root_path_retropie : $root_path_retropie"
  fi

}

function set_directories() {

  if ! [[ -z $DEBUG ]]; then
    echo "set_directories"
  fi

  if [[ ! -d "${source_directory}" || -L "${source_directory}" ]]; then
    exitonerror_nothingmade "Le répertoire source_directory n'existe pas ou n'est pas un répertoire ($source_directory)"
  fi
  if ! [[ -z $DEBUG ]]; then
    echo "source_directory= $source_directory"
  fi

  source_splash_screen=$source_directory
  source_splash_screen+=$source_splash_screen_sufixe
  if [[ ! -d "${source_splash_screen}" || -L "${source_splash_screen}" ]]; then
    exitonerror_nothingmade "Le répertoire des splashscreens n'existe pas ou n'est pas un répertoire ($source_splash_screen) !"
  fi
  if ! [[ -z $DEBUG ]]; then
    echo "source_splash_screen= $source_splash_screen"
  fi

}

# Parameters Management #################################################

function get_options() {

  while getopts "l:s:ndh" option ;
  do
    if ! [[ -z $DEBUG ]]; then
      echo "getopts OPTIND=$OPTIND, Option=$option, OPTARG=$OPTARG, OPTERR=$OPTERR"
    fi
    case "$option" in

      #Input Retropie Directories
      l)
        root_directory=$OPTARG
        trace "Le répertoire Retropie est ${root_directory}"
        set_directories
	      ;;

      #Source Directory
      #s)
      #  source_directory=$OPTARG
      #  echo "Le répertoire des sources est $source_directory"
      #  set_directories
	    #  ;;

      #Missing Arguments
      :)
        exitonerror_nothingmade "L'option \"$OPTARG\" requiert une argument"
        exit 1
        ;;

      n)
        echo "No splashscreen"
        no_splash_screen="ON"
        ;;

      d)
        echo "Debug mode = ON"
        DEBUG="ON"
        ;;

      #Invalid Option
      \?)
        exitonerror_nothingmade "L'option \"$OPTARG\" est invalide"
        exit 1
        ;;

      # Help
      h)
        usage
        # getting the help message from the comments in this source code
        sed '/^#H /!d; s/^#H //' "$0"
        ;;
    esac
  done

  shift $((OPTIND-1))

  # get arguments if any
}

function create_SD () {

  #
  # boot/cmdline.txt
  #
  echo "-------------------------------------------------------------------"
  echo " boot/cmdline.txt"
  echo "-------------------------------------------------------------------"
  #DEBUG
  #cp $root_path_boot/cmdline.txt $root_path_boot/cmdline.txt.bak

  if [[ ! -d "${root_path_boot}" || -L "${root_path_boot}" ]]; then
    exitonerror_nothingmade "Le mapper de boot n'existe pas ou n'est pas un répertoire ($root_path_boot) !"
  fi
  filename="$root_path_boot/cmdline.txt"
  if ! [[ -z $DEBUG ]]; then
    echo "boot/cmdline.txt file is located at ($filename)"
  fi

  # replace "console=tty1" by "logo.nologo loglevel=3 vt.global_cursor_default=0"
  pattern_to_remove="console=tty1"
  pattern_to_add="logo.nologo loglevel=3 vt.global_cursor_default=0"

  #command : sed '0,/tata/ s//zaza/' in.txt
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
  if [[ ! -d "${root_path_boot}" || -L "${root_path_boot}" ]]; then
    exitonerror_nothingmade "Le mapper de boot n'existe pas ou n'est pas un répertoire ($root_path_boot) !"
  fi
  filename="$root_path_boot/config.txt"
  if ! [[ -z $DEBUG ]]; then
    echo "boot/config.txt file is located at ($filename)"
  fi

  # uncomment "disable_overscan=1"
  echo "uncomment disable_overscan=1"
  sed -i '0,/#disable_overscan/ s//disable_overscan/' $filename

  # add "disable_splash=1"
  echo "add disable_splash=1"
  sed -i '$adisable_splash=1' $filename

  # add "disable_splash=1"
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
  if [[ ! -d "${root_path_retropie}" || -L "${root_path_retropie}" ]]; then
    exitonerror_nothingmade "Le mapper de retropie n'existe pas ou n'est pas un répertoire ($root_path_retropie) !"
  fi
  filename="$root_path_retropie/opt/retropie/configs/all/runcommand.cfg"
  if ! [[ -z $DEBUG ]]; then
    echo "retropie/opt/retropie/configs/all/runcommand.cfg file is located at ($filename)"
  fi

  # add "disable_joystick=1"
  echo "replace disable_joystick=0 by disable_joystick=1 in file $filename"
  sed -i '/disable_joystick/ s/"0"/"1"/g' $filename

  # add "disable_splash=1"
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
  if [[ ! -d "${root_path_retropie}" || -L "${root_path_retropie}" ]]; then
    exitonerror_nothingmade "Le mapper de retropie n'existe pas ou n'est pas un répertoire ($root_path_retropie) !"
  fi
  filename="$root_path_retropie/opt/retropie/emulators/retroarch/retroarch.cfg"
  if ! [[ -z $DEBUG ]]; then
    echo "retropie/opt/retropie/emulators/retroarch/retroarch.cfg file is located at ($filename)"
  fi

  # uncomment and set to false "video_font_enable=false"
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
  if [[ ! -d "${root_path_retropie}" || -L "${root_path_retropie}" ]]; then
    exitonerror_nothingmade "Le mapper de retropie n'existe pas ou n'est pas un répertoire ($root_path_retropie) !"
  fi
  filename="$root_path_retropie/opt/retropie/configs/all/retroarch.cfg"
  if ! [[ -z $DEBUG ]]; then
    echo "retropie/opt/retropie/configs/all/retroarch.cfg file is located at ($filename)"
  fi

  # uncomment and set to false "video_font_enable=false"
  echo "uncomment video_font_enable and set to false in file $filename"
  sed -i '/video_font_enable/ s/#//g' $filename
  sed -i '/video_font_enable/ s/true/false/g' $filename

  #
  # Splash screen installation
  #
  if ! [[ -z $no_splash_screen ]]; then
    echo "-------------------------------------------------------------------"
    echo " No Splash Screen"
    echo " destination : /etc/splashscreen.list"
    echo "-------------------------------------------------------------------"

    sudo rm /etc/splashscreen.list
  elif
    echo "-------------------------------------------------------------------"
    echo " Splash Screen Installation"
    echo " destination : retropie/home/pi/Retropie/splashscreens"
    echo "-------------------------------------------------------------------"
    if [[ ! -d "${root_path_retropie}" || -L "${root_path_retropie}" ]]; then
      exitonerror_nothingmade "Le mapper de retropie n'existe pas ou n'est pas un répertoire ($root_path_retropie) !"
    fi
    if [[ ! -d "${source_splash_screen}" || -L "${source_splash_screen}" ]]; then
      exitonerror_nothingmade "Le repertoire source n'existe pas ou n'est pas un répertoire ($source_splash_screen) !"
    fi
    directoryname="$root_path_retropie/home/pi/RetroPie/splashscreens/"
    if ! [[ -z $DEBUG ]]; then
      echo "retropie/home/pi/Retropie/splashscreens directory is located at ($directoryname)"
    fi
    echo "cp -R $source_splash_screen/* $directoryname"
    cp -R $source_splash_screen/* $directoryname

    # récupérer le répertoire+nom du fichier et les intégrer dans splashscreen.list
    #voir /etc/splashscreen.list
  fi
}

# Main start here #######################################################

if [[ ! -z $DEBUG ]]; then
  echo "retropie.sh Main"
fi

get_options "$@"

create_SD

exit 0
