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

MOUNT_BOOT_PATH=
MAPPER_BOOT_PATH=
MOUNT_RETROPIE_PATH=
MAPPER_RETROPIE_PATH=

DEBUG=

# OS pre-requisite #######################################################

function install_prerequesites() {

  # if not Debian then exit

  # Kpartx installation
  [[ -z $(which kpartx) ]] && sudo apt install kpartx -y
}

# Image file Management #######################################################

function prepare_image() {

  if ! [[ -z $DEBUG ]]; then
    echo "Prepare Image"
  fi

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

  if [[ -f $RESULT_IMAGE ]]; then
    echo "Suppression de l'ancienne image résultat $RESULT_IMAGE"
    rm $RESULT_IMAGE
  fi
  echo "Copie de $ORIGINAL_RETROPIE_IMAGE vers $RESULT_IMAGE"
  cp $ORIGINAL_RETROPIE_IMAGE $RESULT_IMAGE

  # check if result file is present

  if ! [[ -f $RESULT_IMAGE ]]; then
    local errormsg="Impossible de créer le fichier $RESULT_IMAGE"
    exitonerror_nothingmade $errormsg
  fi

  # End successfully
  echo "L'image de destination $RESULT_IMAGE a été corectement générée"
}

function mount_image() {

  if ! [[ -z $DEBUG ]]; then
    echo "Mount Image"
  fi

  ROOT_LOOP=$(sudo kpartx -av ${RESULT_IMAGE} | grep -o 'loop[0-9]' | head -n 1)

  if ! [[ -z $DEBUG ]]; then
    echo "Mapper = $ROOT_LOOP"
  fi

  if [[ -z $ROOT_LOOP ]]; then
    exitonerror_cleanneeded "Kpartx n'a pas retourné de mapper correct : $ROOT_LOOP reçu, 'loop%p%' attendu"
  fi

  MOUNT_BOOT_PATH="/mnt/$ROOT_LOOP"
  MOUNT_BOOT_PATH+="p1"
  MAPPER_BOOT_PATH="/dev/mapper/$ROOT_LOOP"
  MAPPER_BOOT_PATH+="p1"
  MOUNT_RETROPIE_PATH="/mnt/$ROOT_LOOP"
  MOUNT_RETROPIE_PATH+="p2"
  MAPPER_RETROPIE_PATH="/dev/mapper/$ROOT_LOOP"
  MAPPER_RETROPIE_PATH+="p2"
  if ! [[ -z $DEBUG ]]; then
    echo "MOUNT_BOOT_PATH = $MOUNT_BOOT_PATH"
    echo "MAPPER_BOOT_PATH = $MAPPER_BOOT_PATH"
    echo "MOUNT_RETROPIE_PATH = $MOUNT_RETROPIE_PATH"
    echo "MAPPER_RETROPIE_PATH = $MAPPER_RETROPIE_PATH"
  fi
  sudo mkdir -v ${MOUNT_BOOT_PATH}
#  sudo mkdir -v ${MOUNT_BOOT_PATH} 2> /dev/null
#  while ! [[ -f ${MAPPER_BOOT_PATH} ]]; do
  if ! [[ -L ${MAPPER_BOOT_PATH} ]]; then
    echo "${MAPPER_BOOT_PATH} n'existe pas"
  fi
  sudo mount ${MAPPER_BOOT_PATH} ${MOUNT_BOOT_PATH}
#  MOUNT_OK=$(ls -A ${MOUNT_BOOT_PATH} | wc -c)
  MOUNT_OK=$?
  echo "MOUNT_OK=$MOUNT_OK"
  if [[ $MOUNT_OK -eq 0 ]]; then
    echo "${MOUNT_BOOT_PATH} est vide"
  fi

  sudo mkdir -v ${MOUNT_RETROPIE_PATH}
#  sudo mkdir -v ${MOUNT_RETROPIE_PATH} 2> /dev/null
  if ! [[ -L ${MAPPER_RETROPIE_PATH} ]]; then
    echo "${MAPPER_RETROPIE_PATH} n'existe pas"
  fi
  sudo mount ${MAPPER_RETROPIE_PATH} ${MOUNT_RETROPIE_PATH}
  MOUNT_OK=$?
#  MOUNT_OK=$(ls -A ${MOUNT_RETROPIE_PATH} | wc -c)
  echo "MOUNT_OK=$MOUNT_OK"
  if [[ $MOUNT_OK -eq 0 ]]; then
    echo "${MOUNT_RETROPIE_PATH} est vide"
  fi

}

function umount_image() {

  if ! [[ -z $DEBUG ]]; then
    echo "Unmount Image"
  fi

  if ! [[ -z $MOUNT_BOOT_PATH ]]; then
    sudo umount ${MOUNT_BOOT_PATH}
    sudo rm -rf ${MOUNT_BOOT_PATH}
  fi
  if ! [[ -z $MOUNT_RETROPIE_PATH ]]; then
    sudo umount ${MOUNT_RETROPIE_PATH}
    sudo rm -rf ${MOUNT_RETROPIE_PATH}
  fi
  if ! [[ -z $RESULT_IMAGE ]]; then
    sudo kpartx -d ${RESULT_IMAGE}
  fi
}

# Error Management #######################################################

function exitonerror_nothingmade() {
  local errormsg=$1

  echo "ERROR : " $errormsg
  exit 1
}

function exitonerror_cleanneeded() {
  local errormsg=$1

  echo "ERROR : " $errormsg
  umount_image
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
    if [[ ! -z $DEBUG ]]; then
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
