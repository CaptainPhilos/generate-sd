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

WORKING_DIR="./work"
ORIGINAL_RETROPIE_IMAGE=
GAME_IMAGE=
RESULT_IMAGE=$WORKING_DIR+"/result.img"

function prepare_image() {
  if [[ -z $ORIGINAL_RETROPIE_IMAGE ]]; then
    exitonerror_nothingmade "Aucune image de Retropie fournie"
  fi
  if ! [[ -f $ORIGINAL_RETROPIE_IMAGE ]]; then
    exitonerror_nothingmade "Le fichier image Retropie fourni n'exite pas"
  fi

  if [[ -z $RESULT_IMAGE ]]; then
    exitonerror_nothingmade "Aucun nom de fichier résultat fourni"
  fi

  # Prepare target image 
  rm $RESULT_IMAGE
  cp $ORIGINAL_RETROPIE_IMAGE $RESULT_IMAGE
  if ! [[ -f $RESULT_IMAGE ]]; then
    local errormsg="Impossible de créer le fichier $RESULT_IMAGE"
    exiterror_nothingmade $errormsg
  fi
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

  while getopts ":hi:o:" option ;
  do
    echo "getopts OPTIND=$OPTIND, Option=$option, OPTARG=$OPTARG, OPTERR=$OPTERR"
    case "$option" in
      
      #Input Retropie Image
      i)
        ORIGINAL_RETROPIE_IMAGE=$OPTARG
        echo "Le fichier d'éntrée est $ORIGINAL_RETROPIE_IMAGE"
	shift
	#exit 0
	;;

      #Ouput image result
      o)
	RESULT_IMAGE=$OPTARG
	echo "Le fichier de résultat est $RESULT_IMAGE"
	#exit 0
	;;

      #Missing Arguments
      :)
	exitonerror_nothingmade "L'option \"$OPTARG\" requiert une argument"
	;;

      #Invalid Option
      \?)
	exitonerror_nothingmade "L'option \"$OPTARG\" est invalide"
	;;

      # Help
      h)
        usage
        # getting the help message from the comments in this source code
        sed '/^#H /!d; s/^#H //' "$0"
        exit 0
        ;;
    esac
  done

  #shift $((OPTIND-1))

}

# Main start here #######################################################

get_options "$@"

prepare_image

exit 0
 
