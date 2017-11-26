#!/bin/bash

##########################################################################
#
# This script creates retropie images for a specific game.
#
# Requirements :
# - Linux OS
# - kpartx
# - original retropie image file
# - game binary file

# definitions ############################################################


# globals ################################################################

ORIGINAL_RETROPIE_IMAGE=
GAME_IMAGE=
RESULT_IMAGE="out.img"
MOUNT_PATH="/mnt/loop0p2"

DEBUG=

# OS pre-requisite #######################################################

function install_prerequesites() {

  # if not Debian then exit

  # Kpartx installation
  [[ -z $(which kpartx) ]] && sudo apt install kpartx -y
}

# Image file Management #######################################################

function prepare_image() {
  if [[ -z $ORIGINAL_RETROPIE_IMAGE ]]; then
    exitonerror_nothingmade "Pas d'image Retropie en entrée"
  fi
  if ! [[ -f $ORIGINAL_RETROPIE_IMAGE ]]; then
    exitonerror_nothingmade "Le fichier image Retropie d'entrée est introuvable"
  fi

  if [[ -z $RESULT_IMAGE ]]; then
    exitonerror_nothingmade "Pas d'image de destination"
  fi

  # Duplicate the original image file into destination image file

  if ! [[ -z $DEBUG ]] && [[ -f $ORIGINAL_RETROPIE_IMAGE ]]; then
    echo "Debug = ON. Le fichier de résultat existe déjà donc pas de copie"
  else
    rm $RESULT_IMAGE
    cp $ORIGINAL_RETROPIE_IMAGE $RESULT_IMAGE
  fi

  # check if result file is present

  if ! [[ -f $RESULT_IMAGE ]]; then
    local errormsg="Impossible de créer le fichier $RESULT_IMAGE"
    exitonerror_nothingmade $errormsg
  fi

  # End successfully
  echo "L'image de destination $RESULT_IMAGE a été corectement générée"
}

function mount_image() {

  KPARTX_COMMAND=$(sudo kpartx -av ${RESULT_IMAGE})
  echo $KPARTX_COMMAND
  sudo mkdir -v ${MOUNT_PATH} 2> /dev/null
  sudo mount /dev/mapper/loop0p2 ${MOUNT_PATH}

}

function umount_image() {

  sudo umount ${MOUNT_PATH}
  sudo rm -rf ${MOUNT_PATH}
  sudo kpartx -d ${RESULT_IMAGE}
}

# Error Management #######################################################

function exitonerror_nothingmade() {
  local errormsg=$1

  echo "ERROR : " $errormsg
  exit 1
}

function usage() {
  echo
  echo "USAGE: $(basename $0) -i image Retropie d'origine -o image à générer"
  echo
  echo "Use '--help' to see all the options"
  echo
}

# Parameters Management #################################################

function get_options() {

  while getopts "i:o:dh" option ;
  do
    if [[ -z $DEBUG ]]; then
      echo "getopts OPTIND=$OPTIND, Option=$option, OPTARG=$OPTARG, OPTERR=$OPTERR"
    fi
    case "$option" in

      #Input Retropie Image
      i)
        ORIGINAL_RETROPIE_IMAGE=$OPTARG
        echo "Le fichier d'entrée est $ORIGINAL_RETROPIE_IMAGE"
	      ;;

      #Ouput image result
      o)
        RESULT_IMAGE=$OPTARG
	      echo "Le fichier de sortir est $RESULT_IMAGE"
        ;;

      #Missing Arguments
      :)
        exitonerror_nothingmade "L'option \"$OPTARG\" requiert une argument"
        exit 1
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

# Main start here #######################################################

get_options "$@"

install_prerequesites

prepare_image

mount_image

# if not debug then unmount the image file
if [[ -z $DEBUG ]]; then
  umount_image
fi

exit 0
