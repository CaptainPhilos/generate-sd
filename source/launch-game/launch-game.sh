#!/bin/bash

##########################################################################
#
# This script starts a game automatically.
# The game to start is found in a USB key installed on the raspberry
# The directory structure of the key MUST be always the same :
#   /
#     bin
#       launch-game.sh
#     roms
#       MACHINE_NAME
#         GAME (extension depends on the kind of machine)
#         Controller configuration file (.cfg)
#
# Requirements :
# - Linux OS
##########################################################################

# Verify that it's a retropie
function check_computer() {
  local computer=$(uname -a)
  trace "Computer : ${computer}"

  if echo "${computer}" | grep -q "retropie"; then
    retropie_computer="OK"
  fi
}
retropie_computer=""
check_computer

# constantes #############################################################

CONTROLLER_CONFIG_EXT="cfg"

# Obsolete ?
#GAME_CUE_EXT="cue"
#MACHINE_NEED_CUE="pcengine"

#PCEngine constants
PCENGINE="pcengine"
PCENGINE_CDROM_BIOS="syscard3.pce"
PCENGINE_BIOS_EXT="pce"

#PSX constants
PSX="psx"
PSX_BIOS="scph*.bin"

# globals ################################################################

debug=
no_launch=

# computer for testing
if [[ -z ${retropie_computer} ]]; then
  ROOT_USB_KEY="/Volumes/ROMS"
  ROOT_CONFIG=${ROOT_USB_KEY}"/configs-tests"
  ROOT_HOME_PI=${ROOT_USB_KEY}"/home-tests"
  ROOT_SYSTEM=${ROOT_USB_KEY}"/emulationstation-tests"
else
  ROOT_USB_KEY="/media/usb0"
  ROOT_CONFIG="/opt/retropie/configs"
  ROOT_SYSTEM="/etc/emulationstation"
  ROOT_HOME_PI="/home/pi"
fi

ROOT_ROMS=${ROOT_USB_KEY}"/roms"
LOGS_PATH=${ROOT_USB_KEY}"/bin"
CONTROLLER_PATH=${ROOT_CONFIG}"/all/retroarch-joypads"
BIOS_PATH=${ROOT_HOME_PI}"/RetroPie/BIOS"
SYSTEM_LIST=${ROOT_SYSTEM}"/es_systems.cfg"

#config_file="/opt/retropie/configs/all/retroarch.cfg"

# Name of the core that will be launched
core_name=""

# name of the game
game_name=""
game_directory=""

# controller file
controller_config_filename=""

#filename of log
logFileName=""

# Error Management #######################################################

function init_log_file() {

    # if filename is empty, it's the first trace to add into log file
    if [[ -z ${logFileName} ]]; then
      logFileName=$(basename "${BASH_SOURCE[0]}")
      logFileName="${logFileName%.*}.log"
      logFileName="${LOGS_PATH}/${logFileName}"

      # if it's trace, then remove previous log file if any
      rm ${logFileName}
    fi
}

function trace() {
  local tracemsg="[$(date -u)][debug] $1"

  # display to console
  if ! [[ -z ${debug} ]]; then
    echo ${tracemsg}
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${tracemsg} >> ${logFileName}
}

function warning() {
  local warningmsg="[$(date -u)][WARN] $1"

  # display to console
  if ! [[ -z $debug ]]; then
    echo ${warningmsg}
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${warningmsg} >> ${logFileName}
}

function exitonerror() {
  local errormsg="[$(date -u)][ERROR] $1"

  # display to console
  if ! [[ -z $debug ]]; then
    echo ${errormsg}
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${errormsg} >> ${logFileName}

  exit 1
}

# Check functions ########################################################

function check_directories() {
  trace "##########################"
  trace "Function check_directories"

  # Check if the USB Key is accessible
  trace "ROOT_USB_KEY=${ROOT_USB_KEY}"
  if [[ ! -d "${ROOT_USB_KEY}" || -L "${ROOT_USB_KEY}" ]]; then
    exitonerror "La clé USB n'a pas été trouvée"
  fi

  # Check if directory of roms exists
  local roms_directory="${ROOT_ROMS}"
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

function check_machine() {
  trace "##########################"
  trace "Function check_machine"

  if [[ "${core_name}" == "${PCENGINE}" ]]; then
    check_machine_pcengine
  fi
  if [[ "${core_name}" == "${PSX}" ]]; then
    check_machine_psx
  fi

}

function check_machine_pcengine() {
  trace "##########################"
  trace "Function check_machine_pcengine"

  trace "Console : ${core_name}"
  trace "Bios file : ${PCENGINE_CDROM_BIOS}"

  # if BIOS is not already installed in BIOS Directory
  if [[ ! -f "${BIOS_PATH}/${PCENGINE_CDROM_BIOS}" ]]; then

    # if BIOS is not in the games directory
    trace "check BIOS file in directory : ${game_directory}/${PCENGINE_CDROM_BIOS}"
    if [[ ! -f "${game_directory}/${PCENGINE_CDROM_BIOS}" ]]; then
      exitonerror "Aucun BIOS pour la pcengine n'a été trouvé dans le répertoire '/home/pi/RetroPie/BIOS' ou dans le répertoire de la machine ${game_directory}"
    fi

    # So BIOS file is in game_directory, copy it to BIOS directory
    trace "copy bios file ${PCENGINE_CDROM_BIOS} in ${BIOS_PATH}"
    cp "${game_directory}/${PCENGINE_CDROM_BIOS}" "${BIOS_PATH}/${PCENGINE_CDROM_BIOS}"
  else
    trace "Bios file ${PCENGINE_CDROM_BIOS} found in ${BIOS_PATH}"
  fi
}

function check_machine_psx() {
  trace "##########################"
  trace "Function check_machine_psx"

  trace "Console : ${core_name}"
  trace "Bios file : ${PSX_BIOS}"

  # Get the BIOS files in game directory
  local nbOfBIOSFiles=$(ls ${game_directory}/${PSX_BIOS} | wc -l)
  trace "Nb of BIOS files found in ${game_directory} (${PSX_BIOS}): ${nbOfBIOSFiles}"

  if [[ ${nbOfBIOSFiles} -gt 0 ]]; then
    # Copy files to BIOS Directory
    trace "Copy BIOS file from game directory to BIOS directory"
    cp ${game_directory}/${PSX_BIOS} "${BIOS_PATH}/"
  else
    # Na BIOS files found in game directory, check the BIOS directory
    nbOfBIOSFiles=$(ls ${BIOS_PATH}/${PSX_BIOS} | wc -l)
    trace "Nb of BIOS files found in ${BIOS_PATH} (${PSX_BIOS}): ${nbOfBIOSFiles}"
    if [[ ${nbOfBIOSFiles} -eq 0 ]]; then
      # No BIOS files. Core can't execute.
      exitonerror "Aucun BIOS pour la psx n'a été trouvé dans le répertoire ${BIOS_PATH} ou dans le répertoire de la machine ${game_directory}"
    fi
  fi
}

function check_controllers() {
  trace "##########################"
  trace "Function check_controllers"

  # if no controller configuration is found, then check the controller configuration is SD Card
  if [[ -z ${controller_config_filename} ]]; then

    # nb of controller file in SD card
    if [[ $(find ${CONTROLLER_PATH}/* -type f | wc -l) -lt 1 ]]; then
      exitonerror "Aucune configuration de manette n'a été trouvée, ni sur la carte (${CONTROLLER_PATH}) ni dans le répertoire de la machine ${game_directory}"
    fi

    trace "No configuration found in game directory but use SD card configuration instead"

  # copy the configuration in SD card
  else
    local config_filename=$(basename "${controller_config_filename}")
    trace "config_filename : ${config_filename}"
    trace "Copy configuration file in SD card : cp ${controller_config_filename} ${CONTROLLER_PATH}/${config_filename}"
    cp "${controller_config_filename}" "${CONTROLLER_PATH}/${config_filename}"
  fi
}

# Game Management #######################################################

# get the name of the core
function extract_machine_name() {
  trace "##########################"
  trace "Function extract_machine_name"

  local roms_directory="${ROOT_ROMS}"

  # get the first directory in roms directory
  local machine_name=$(file ${roms_directory}/* | grep directory | cut -d':' -f1 | head -1)
  trace "Machine Name (first)= ${machine_name}"
  machine_name=$(basename ${machine_name})
  trace "Machine Name (first)= ${machine_name}"

  # no core name, exit
  if [[ -z ${machine_name} ]]; then
    exitonerror "Le premier répertoire trouvé n'a pas de nom"
  fi

  # core name found
  core_name=${machine_name}
  trace "Machine name is ${core_name}"

  #check core_name in /etc/remulation/es_systems.cfg
  if [[ $(grep "<name>${core_name}</name>" "${SYSTEM_LIST}" | wc -l) -eq 0 ]]; then
    exitonerror "Le nom de la machine (${core_name}) n'est pas supporté par cette version de Retropie"
  fi
}

# Get the name of the game
function extract_game_name() {
  trace "##########################"
  trace "Function extract_game_name"

  game_directory="${ROOT_ROMS}/${core_name}"
  trace "game_directory = ${game_directory}"

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
  if [ $nb_files_in_directory -lt 1 ]; then
    exitonerror "Le répertoire de la machine ${game_directory} ne contient pas les bons fichiers : fichier du jeu (parfois 2) + la configuration des Controllers"
  fi

  # if some file to examine, scan file list and examines each
#  for file in $(find "${game_directory}"/* -type f);
#  do
  while read file; do

    # extract filename and extension name
    local extension=${file: -3}
    extension=$(echo $extension | tr [:upper:] [:lower:])
    trace "file : ${file}"
    trace "extension gotten : ${extension}"

    case ${extension} in

      # the extension found shows it's a configuration file
      ${CONTROLLER_CONFIG_EXT})
        controller_config_filename=${file}
        trace "Controller configuration file found = ${controller_config_filename}"
        ;;

      # Obsolete ?
      # cue file for an ISO game
      # depends on the machine

      #${GAME_CUE_EXT})

        # if it's a CUE file, check that it's compatible with the current machine
      #  trace "Actual core name = ${core_name}"

        # if the core takes part of the core needing a cue file as game
      #  if echo "${MACHINE_NEED_CUE}" | grep -q "${core_name}"; then
      #    game_name=${file}
      #    trace "Game file found = ${game_name}"
      #  fi
      #  ;;

      # bios file for pcengine
      ${PCENGINE_BIOS_EXT})
        trace "BIOS file found for PCEngine ${file}"
        ;;

      *)
        # find supported extension for current core
        if [[ -z ${retropie_computer} ]]; then
          local supported_extension=$(xmllint --xpath string\(//system[name[text\(\)=\'${core_name}\']]/extension/text\(\)\) ${SYSTEM_LIST})
        else
          local supported_extension=$(xmlstarlet sel --text -t -c "//system[name='${core_name}']/extension" ${SYSTEM_LIST})
        fi
        trace "supported_extension : ${supported_extension}"

        # check if extension found is in the supported extension list of the current core
        if echo "${supported_extension}" | grep -q "${extension}"; then
          # We have found a compatible game
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

function install_controllers() {
  trace "##########################"
  trace "Function install_controllers"

  trace "Launching /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ ${core_name} ${game_name}"
  /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ "${core_name}" "${game_name}"
}

function launch_game() {
  trace "##########################"
  trace "Function launch_game"

  trace "Launching /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ ${core_name} ${game_name}"
  /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ "${core_name}" "${game_name}"

#  local verbose=
#  if ! [[ -z $debug ]]; then
#    verbose="-v"
#  fi
#  trace "Launching /opt/retropie/emulators/retroarch/bin/retroarch ${verbose} --subsystem=${core_name} --config ${config_file} ${game_name}"
#  /opt/retropie/emulators/retroarch/bin/retroarch "${verbose}" --subsystem="${core_name}" --config "${config_file}" "${game_name}"
}

# Parameters Management #################################################

function get_options() {

  while getopts "dhn" option ;
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

      d)
        debug="ON"
        trace "debug mode = ON"
        ;;

      n)
        no_launch="ON"
        trace "No Launch option"
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
  echo "USAGE: $(basename $0) -d -n -h"
  echo
  echo "Use '-h' to see all the options"
  echo
}

# Main starts here ######################################################

get_options "$@"

check_directories

extract_machine_name

extract_game_name

check_machine
check_controllers

summary

if [[ -z ${no_launch} ]]; then
  launch_game
fi

exit 0
