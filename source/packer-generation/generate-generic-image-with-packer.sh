#!/bin/bash

##########################################################################
#
# This script creates GENERIC retropie images starting from a brand new retropie image.
#
# Requirements :
# - Linux OS
# - losetup
# - original retropie image file

# Constants ############################################################

WORKING_DIRECTORY="work_temp"
BOOT_DIRECTORY="${WORKING_DIRECTORY}/boot"
ROMS_DIRECTORY="${WORKING_DIRECTORY}/home/pi/RetroPie/roms"
AUTOLAUNCH_SCRIPT_FILENAME="autostart.sh"
AUTOLAUNCH_DIRECTORY="${WORKING_DIRECTORY}/opt/retropie/configs/all"
AUTOLAUNCH_SCRIPT_FILENAME_GenericLaunch="10-retropie.sh.generic"
AUTOLAUNCH_SCRIPT_FILENAME_SpecificLaunch="10-retropie.sh.specific"
JOYPAD_CONFIGURATION_DIRECTORY="${WORKING_DIRECTORY}/opt/retropie/configs/all/retroarch/autoconfig"
TEMP_IMAGE="${HOME}/out.img"

# globals ################################################################

debug="ON"
logFileName=
specific=
generic=

loop=

original_retropie_image=
game_image=
result_image="out.img"
samples_dir=
controler_file=
emulatorname=
specific_console=

# OS pre-requisite #######################################################

function install_prerequesites() {

  # check losetup installation
  if [[ -z $(which losetup) ]]; then
    exitonerror "logiciel losetup manquant. Impossible de charger l'image de Retropie"
  fi
}

function check_parameters() {

  # check if the user selects Generic or Specific Mode
  if [[ -z "${specific}" && -z "${generic}" ]]; then
    usage
    exitonerror "Pas de choix entre mode générique ou spécifique"
  fi

  # check if the user selects Generic or Specific Mode
  if ! [[ -z "${specific}" ]] && ! [[ -z "${generic}" ]]; then
    usage
    exitonerror "Il faut choisir entre mode générique ou spécifique"
  fi

  # check if the user specify a good filename for the game
  if ! [[ -z "${specific}" ]]; then

    # No filename
    if [[ -z "${gamefile}" ]]; then
      usage
      exitonerror "Il faut préciser un nom de fichier pour le jeu à installer"
    fi

    # bad file
    if ! [[ -f "${gamefile}" ]]; then
      usage
      exitonerror "Il faut préciser un nom de fichier valide pour le jeu à installer"
    fi

    # if samples is provided then check samples directory existence
    if [[ ! -z "${samples_dir}" ]] && [[ ! -d "${samples_dir}" ]]; then
      usage
      exitonerror "Il faut préciser un répertoire de Samples valide pour accompagner le jeu à installer"
    fi

    # if controler filename is provided then check file exists
    if [[ ! -z "${controler_file}" ]] && [[ ! -f "${controler_file}" ]]; then
      usage
      exitonerror "Il faut préciser un nom de fichier valide pour la configuration du joystick"
    fi
  fi
}

# Error Management #######################################################

function init_log_file() {

    # if filename is empty, get the filename for logs from the script filename
    if [[ -z "${logFileName}" ]]; then
      logFileName="${BASH_SOURCE[0]}"
      logFileName="${logFileName%.*}.log"

      # Remove previous log file if any
      rm "${logFileName}"
    fi
}

function trace() {
  local tracemsg="[$(date -u)][DEBUG] $1"

  # display to console
  if ! [[ -z ${debug} ]]; then
    echo "${tracemsg}"
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${tracemsg} >> "${logFileName}"
}

function info() {
  local tracemsg="[$(date -u)][INFO] $1"

  # display to console
  if ! [[ -z ${debug} ]]; then
    echo "${tracemsg}"
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${tracemsg} >> "${logFileName}"
}


function warning() {
  local warningmsg="[$(date -u)][WARN] $1"

  # display to console
  if ! [[ -z "$debug" ]]; then
    echo "${warningmsg}"
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo "${warningmsg}" >> "${logFileName}"
}

function exitonerror() {
  local errormsg="[$(date -u)][ERROR] $1"

  # display to console
  if ! [[ -z $debug ]]; then
    echo "${errormsg}"
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo "${errormsg}" >> "${logFileName}"

  exit 1
}


function create_specific_sd_with_packer () {
  trace "#######################################"
  trace "create_Specific_SD_with_Packer ########"

  # autolaunch.sh installation
  autolaunch_script_filename="$(dirname ${BASH_SOURCE[0]})/../launch-game/${AUTOLAUNCH_SCRIPT_FILENAME_SpecificLaunch}"
  trace "Autolaunch script filename is ${autolaunch_script_filename}"

  # game installation
  gamename=$(basename -- "${gamefile}")
  corename=$(basename -- $(dirname -- "${gamefile}"))
  trace "Game is ${gamename}, core is ${corename}"

  # controler file
  controler_file_target=
  if [[ ! -z "${controler_file}" ]]; then
    controler_filename=$(basename -- "${controler_file}")
    controler_file_target="/opt/retropie/configs/all/retroarch/autoconfig/${controler_filename}"
    trace "Copy controler file ${controler_file} to ${controler_file_target}"
  fi

  # Determine which Packer builder'll be used
  packer_builder="image"
  if [ "${specific_console}" == "borne_pacman_mo5" ]; then
    trace "Specific image ==> 'borne_pacman_mo5' iso"
    packer_builder="${packer_builder}_pacman"
  fi
  if [[ ! -z "${samples_dir}" ]]; then
    trace "Copy Samples directory ${samples_dir} to ${ROMS_DIRECTORY}/${corename}/samples"
    packer_builder="${packer_builder}_samples"
  fi
  if [[ ! -z "${controler_file}" ]]; then
    packer_builder="${packer_builder}_controler"
  fi

  # Builders used
  trace "###########################################"
  trace "Builders used in Packer : ${packer_builder}"
  trace "Launching Packer...."

  #
  # Build image with Packer
  #
  # sudo packer build -debug -var CABINET=borne_pacman_mo5 -var FILENAME=retropie-mo5-4.7 mo5-retropie.json
  sudo packer build \
    -debug \
    -only="${packer_builder}" \
    -var AUTOLAUNCH_FILENAME="${autolaunch_script_filename}" \
    -var OUTPUT_FILENAME="${result_image}" \
    -var CORE_NAME="${corename}" \
    -var GAME_FULLPATH="${gamefile}" \
    -var GAME_FILENAME="${gamename}" \
    -var EMULATOR_NAME="${emulatorname}" \
    -var SAMPLES_DIR="${samples_dir}" \
    -var CONTROLER_FILE="${controler_file}" \
    -var CONTROLER_FILE_TARGET="${controler_file_target}" \
    "$(dirname ${BASH_SOURCE[0]})/../packer-generation/mo5-retropie.json"

}

# Parameters Management #################################################

function usage() {
  echo
  echo "USAGE:"
  echo "image générique: $(basename $0) -g -i \"image Retropie d'origine\" -o \"image à générer\""
  echo "image spécifique: $(basename $0) -s \"fichier du jeu\" (-p \"répertoire des samples\") (-e \"nom de l'émulateur\") (-c \"fichier controler à installer\") (-x \"nom de la console dont il faut appliquer les paramètres spécifiques) -i \"image Retropie d'origine\" -o \"image à générer\""
  echo
}

function get_options() {

  while getopts "gc:e:p:s:i:o:x:dh" option ;
  do
    trace "getopts OPTIND=$OPTIND, Option=$option, OPTARG=$OPTARG, OPTERR=$OPTERR"
    case "${option}" in

      #Input Retropie Image
      i)
        original_retropie_image="${OPTARG}"
        trace "Le fichier d'entrée est ${original_retropie_image}"
	      ;;

      #Ouput image result
      o)
        result_image="${OPTARG}"
	      trace "Le fichier de sortir est ${result_image}"
        ;;

      #Specific with filepath to game to install
      s)
        trace "Specific Mode ON"
        gamefile=${OPTARG}
        specific="ON"
        ;;

      #Specific samples directory to copy beside the game
      p)
        trace "Samples directory"
        samples_dir=${OPTARG}
        ;;

      #Specific controler file name to copy onto SD Card
      c)
        trace "controler filename"
        controler_file=${OPTARG}
        ;;

      # Emulator name
      e)
        trace "Emulator name"
        emulatorname=${OPTARG}
        ;;

      g)
        trace "Generic Mode ON"
        generic="ON"
        ;;

      d)
        trace "Mode Debug ON"
        debug="ON"
        ;;

      x)
        trace "specific instructions for specifics consoles"
        specific_console=${OPTARG}
        ;;
      
      #Missing Arguments
      :)
        exitonerror "L'option \"$OPTARG\" requiert un argument"
        ;;

      #Invalid Option
      \?)
        exitonerror "L'option \"$OPTARG\" est invalide"
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

check_parameters

# With Packer
create_specific_sd_with_packer

exit 0
