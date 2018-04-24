#!/bin/bash

##########################################################################
#
# This script starts a game automatically.
# The game to start is found in a USB key installed on the raspberry
# The directory structure of the key MUST be always the same :
#   /
#     roms
#       MACHINE_NAME
#         GAME (extension depends on the kind of machine)
#         Controller configuration file (.cfg)
#
# Requirements :
# - Linux OS
##########################################################################

# constantes #############################################################

CONTROLLER_CONFIG_EXT="cfg"
GAME_CUE_EXT="cue"

MACHINE_NEED_CUE="pcengine"

# globals ################################################################

debug=

root_usb_key="/Volumes/ROMS"
#root_usb_key = "/media/usb0/"
root_roms="roms"
#system_list="/etc/remulation/es_systems.cfg"
system_list="/Volumes/ROMS/roms/es_systems.cfg"

# Name of the core that will be launched
core_name=""

# name of the game
game_name=""

# controller file
controller_config_filename=""

# Error Management #######################################################

function trace() {
  local tracemsg=$1

  if ! [[ -z $debug ]]; then
    echo "[debug] " $tracemsg
  fi
}

function warning() {
  local warningmsg=$1

  echo "[WARN] " $warningmsg
}

function exitonerror() {
  local errormsg=$1

  echo "[ERROR] " $errormsg
  exit 1
}

# Check functions ########################################################

function check_directories() {
  trace "##########################"
  trace "Function check_directories"

  # Check if the USB Key is accessible
  trace "root_usb_key=${root_usb_key}"
  if [[ ! -d "${root_usb_key}" || -L "${root_usb_key}" ]]; then
    exitonerror "La clé USB n'a pas été trouvée"
  fi

  # Check if directory of roms exists
  local roms_directory="${root_usb_key}/${root_roms}"
  trace "roms_directory=${roms_directory}"
  if [[ ! -d "${roms_directory}" || -L "${roms_directory}" ]]; then
    exitonerror "Le répertoire 'roms' n'a pas été trouvé sur la clé"
  fi

  # check if roms directory contains at least on machine directory
  local nbOfDirectories=$(ls -d1 "${roms_directory}"/*/ | wc -l)
  trace "nbOfDirectories in roms=${nbOfDirectories}"
  if [ $nbOfDirectories -eq 0 ]; then
    exitonerror "Le répertoire 'roms' ne contient aucun répertoire de machine"
  fi
}

# Game Management #######################################################

# get the name of the core
function extract_machine_name() {
  trace "##########################"
  trace "Function extract_machine_name"

  local roms_directory="${root_usb_key}/${root_roms}"

  # get the first directory in roms directory
  local machine_name=$(file ${roms_directory}/* | grep directory | cut -d':' -f1 | head -1)
  trace "Machine Name (first)= ${machine_name}"
  machine_name=$(basename ${machine_name})
  trace "Machine Name (first)= ${machine_name}"

  # no core name, exit
  if [[ -z ${machine_name} ]]; then
    exitonerror "Le premier répertoire trouvé n'a pas de nom"
  fi

  # core name founded
  core_name=${machine_name}
  trace "Machine name is ${core_name}"

  #check core_name in /etc/remulation/es_systems.cfg
  if [[ $(grep "<name>${core_name}</name>" "${system_list}" | wc -l) -eq 0 ]]; then
    exitonerror "Le nom de la machine (${core_name}) n'est pas supporté par cette version de Retropie"
  fi
}

# Get the name of the game
function extract_game_name() {
  trace "##########################"
  trace "Function extract_game_name"

  local game_directory="${root_usb_key}/${root_roms}/${core_name}"

  # get list of files in core directory
  local files_in_directory=$(find ${game_directory}/* -type f)
  trace "List of files in ${game_directory}= ${files_in_directory}"
  # check number of file in core directory
  local nb_files_in_directory=$(find ${game_directory}/* -type f | wc -l)
  trace "Nb of files in ${game_directory}= ${nb_files_in_directory}"

  #control the content of the directory
  if [[ -z ${files_in_directory} ]]; then
    exitonerror "Le répertoire de la machine ${game_directory} est vide"
  fi
  if [ $nb_files_in_directory -lt 2 ]; then
    exitonerror "Le répertoire de la machine ${game_directory} ne contient pas les bons fichiers : fichier du jeu (parfois 2) + la configuration des Controllers"
  fi

  # if some file to examine, scan file list and examines each
#  for file in $(find "${game_directory}"/* -type f);
#  do
  while read file; do

    # extract filename and extension name
    local onlyFileName=$(basename ${file})
    local extension=${onlyFileName: -3}
    extension=$(echo $extension | tr [:upper:] [:lower:])
    trace "file : ${file}"
    trace "file only : ${onlyFileName}"
    trace "extension gotten : ${extension}"

    case ${extension} in

      # the extension founded shows it's a configuration file
      ${CONTROLLER_CONFIG_EXT})
        controller_config_filename=${file}
        trace "Controller configuration file found = ${controller_config_filename}"
        ;;

      # cue file for an ISO game
      # deponds on the machine
      ${GAME_CUE_EXT})

        # if it's a CUE file, check that it's compatible with the current machine
        trace "Actual core name = ${core_name}"

        # if the core takes part of the core needing a cue file as game
        if echo "${MACHINE_NEED_CUE}" | grep -q "${core_name}"; then
          game_name=${file}
          trace "Game file found = ${game_name}"
        fi
        ;;

        *)
        # Check it's not a core needing cue file
        if ! echo "${MACHINE_NEED_CUE}" | grep -q "${core_name}"; then
          game_name=${file}
          trace "Game file found = ${game_name}"
        fi
        ;;

    esac

  done <<< "$(find "${game_directory}"/* -type f)"

  if [[ -z "${controller_config_filename}" ]]; then
    warning "Pas de fichier de configuration des controllers. Utilisation des configurations installées en /opt/retropie/configs/all/retroarch-joypads"
  fi

  if [[ -z "${game_name}" ]]; then
    exitonerror "Pas de jeux trouvé en ${game_directory}."
  fi
}

function summary() {

  echo "La machine à émuler = ${core_name}"
  echo "Le fichier de configuration des controlleurs = ${controller_config_filename}"
  echo "Le fichier de jeu = ${game_name}"
}

# Launching games #######################################################

function launch_game() {
  trace "##########################"
  trace "Function launch_game"

  trace "Launching /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ ${core_name} ${game_name}"
  /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ "${core_name}" "${game_name}"
}

# Parameters Management #################################################

function get_options() {

  while getopts "dh" option ;
  do
    case "$option" in

      #Input Retropie Image
#      l)
#        ROOT_LOOP=$OPTARG
#        echo "Le mapper est $ROOT_LOOP"
#        set_mappers
#	      ;;

      #Source Directory
#      s)
#        source_directory=$OPTARG
#        echo "Le répertoire des sources est $source_directory"
#        set_directories
#	      ;;

      #Missing Arguments
      :)
        exitonerror "L'option \"$OPTARG\" requiert une argument"
        ;;

#      n)
#        echo "No splashscreen"
#        no_splash_screen="ON"
#        ;;

      d)
        debug="ON"
        trace "debug mode = ON"
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

function usage() {
  echo
  echo "USAGE: $(basename $0) -d"
  echo
  echo "Use '-h' to see all the options"
  echo
}

# Main starts here ######################################################

get_options "$@"

check_directories

extract_machine_name

extract_game_name

summary

launch_game

exit 0
