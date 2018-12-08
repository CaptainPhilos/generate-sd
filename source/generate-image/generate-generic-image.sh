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
AUTOLAUNCH_SCRIPT_FILENAME="10-retropie.sh"
TEMP_IMAGE="${HOME}/out.img"
# globals ################################################################

debug="ON"
logFileName=

loop=

original_retropie_image=
game_image=
result_image="out.img"

# OS pre-requisite #######################################################

function install_prerequesites() {

  # check losetup installation
  if [[ -z $(which losetup) ]]; then
    exitonerror "logiciel losetup manquant. Impossible de charger l'image de Retropie"
  fi
}
# Error Management #######################################################

function init_log_file() {

    # if filename is empty, get the filename for logs from the script filename
    if [[ -z ${logFileName} ]]; then
      logFileName="${BASH_SOURCE[0]}"
      logFileName="${logFileName%.*}.log"

      # Remove previous log file if any
      rm ${logFileName}
    fi
}

function trace() {
  local tracemsg="[$(date -u)][DEBUG] $1"

  # display to console
  if ! [[ -z ${debug} ]]; then
    echo ${tracemsg}
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${tracemsg} >> ${logFileName}
}

function info() {
  local tracemsg="[$(date -u)][INFO] $1"

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

function exitonerror_cleanneeded() {
  local errormsg="[$(date -u)][ERROR] $1"

  # display to console
  if ! [[ -z $debug ]]; then
    echo ${errormsg}
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo ${errormsg} >> ${logFileName}

  # Free the images
  umount_image

  exit 1
}

# Image file Management #######################################################

function prepare_image() {
  trace "##########################"
  trace "prepare_image ############"

  if [[ -z ${original_retropie_image} ]]; then
    exitonerror "Pas d'image Retropie en entrée"
  fi
  if ! [[ -f ${original_retropie_image} ]]; then
    exitonerror "Le fichier image Retropie d'entrée est introuvable"
  fi

  if [[ -z ${result_image} ]]; then
    exitonerror "Pas d'image de destination"
  fi

  # Delete old result is any
  if [[ -f ${result_image} ]]; then
    trace "Suppression de l'ancienne image résultat ${result_image}"
    rm ${result_image}
  fi

  # Delete old result is any
  if [[ -f ${TEMP_IMAGE} ]]; then
    trace "Suppression de l'ancienne image de travail ${TEMP_IMAGE}"
    rm ${TEMP_IMAGE}
  fi

  # temporary duplicate to local directory (usefull is executing the script inside a VM)
  trace "Copie de ${original_retropie_image} vers ${TEMP_IMAGE}"
  cp ${original_retropie_image} ${TEMP_IMAGE}

  # check if result file is present
  if ! [[ -f ${TEMP_IMAGE} ]]; then
     exitonerror "Impossible de créer le fichier ${TEMP_IMAGE}"
  fi

  # End successfully
  trace "L'image de travail ${TEMP_IMAGE} a été corectement générée"
}

function prepare_result() {
  trace "##########################"
  trace "prepare_result ###########"

  # check if result file is present
  if ! [[ -f ${TEMP_IMAGE} ]]; then
     exitonerror "L'image de travail ${TEMP_IMAGE} n'existe pas"
  fi

  # copy the result to the given destianation
  trace "Copie de ${TEMP_IMAGE} vers ${result_image}"
  cp ${TEMP_IMAGE} ${result_image}
}

function mount_image() {
  trace "##########################"
  trace "mount_image ##############"

  # Get the first device available
  loop=$(sudo losetup -f)
  if [[ -z ${loop} ]]; then
    exitonerror "Impossible de trouver un périphérique disponible pour charge l'image (losetup -f error)"
  fi

  # Associate image to peripheric
  sudo losetup --show -P ${loop} ${TEMP_IMAGE}
  trace "Association de ${loop} avec l'image ${TEMP_IMAGE}"
  if [ $? -ne 0 ]; then
    exitonerror "Impossible d'associer l'image ${TEMP_IMAGE} au pseudo périphérique ${loop}"
  fi

  # Create temporary directory
  trace "Création du répertoire de travail ${WORKING_DIRECTORY}"
  mkdir ${WORKING_DIRECTORY}
  if [ $? -ne 0 ]; then
    exitonerror_cleanneeded "Impossible de créer le répertoire de travail sur le disque"
  fi

  # Mount the image and map on the working directory
  trace "Montage de ${loop}p2 sur ${WORKING_DIRECTORY}"
  sudo mount "${loop}p2" "${WORKING_DIRECTORY}"
  if [ $? -ne 0 ]; then
    exitonerror_cleanneeded "Impossible de monter ${loop}p2 sur ${WORKING_DIRECTORY}"
  fi
  trace "Montage de ${loop}p1 sur ${WORKING_DIRECTORY}/boot"
  sudo mount "${loop}p1" "${WORKING_DIRECTORY}/boot"
  if [ $? -ne 0 ]; then
    exitonerror_cleanneeded "Impossible de monter ${loop}p1 sur ${WORKING_DIRECTORY}/boot"
  fi
}

function umount_image() {
  trace "##########################"
  trace "umount_image #############"

  trace "Démontage de ${loop}p1"
  sudo umount "${loop}p1"
  trace "Démontage de ${loop}p2"
  sudo umount "${loop}p2"
  trace "Suppression du répertoire de travail ${WORKING_DIRECTORY}"
  rm -rf ${WORKING_DIRECTORY}
  trace "Désassociation du périphérique ${loop} et de l'image ${TEMP_IMAGE}"
  $(sudo losetup -d "${loop}")
}

# SD Creation Mangement #######################################################

function create_SD () {
  trace "##########################"
  trace "create_SD ################"

  #
  # boot/cmdline.txt
  #
  local filename="${BOOT_DIRECTORY}/cmdline.txt"
  trace "** Apply modifications to ${filename}"

  # replace "console=tty1" by "logo.nologo loglevel=3 vt.global_cursor_default=0"
  local pattern_to_remove="console=tty1"
  local pattern_to_add="logo.nologo loglevel=3 vt.global_cursor_default=0"

  #command : sed '0,/tata/ s//zaza/' in.txt
  trace "replace ${pattern_to_remove} by ${pattern_to_add} in file ${filename}"
  sudo sed -i '0,/'"${pattern_to_remove}"'/ s//'"${pattern_to_add}"'/' ${filename}

  #
  # boot/config.txt
  #
  filename="${BOOT_DIRECTORY}/config.txt"
  trace "** Apply modifications to ${filename}"

  # uncomment "disable_overscan=1"
  trace "uncomment disable_overscan=1"
  sudo sed -i '0,/#disable_overscan/ s//disable_overscan/' ${filename}

  # add "disable_splash=1"
  trace "add disable_splash=1"
  sudo sed -i '$adisable_splash=1' ${filename}

  # add "disable_splash=1"
  trace "add plymouth.enable=0"
  sudo sed -i '$aplymouth.enable=0' ${filename}

  #
  # retropie/opt/retropie/configs/all/runcommand.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/configs/all/runcommand.cfg"
  trace "** Apply modifications to ${filename}"

  # add "disable_joystick=1"
  trace "replace disable_joystick=0 by disable_joystick=1 in file ${filename}"
  sudo sed -i '/disable_joystick/ s/"0"/"1"/g' ${filename}

  # add "disable_splash=1"
  trace "replace disable_menu=0 by disable_menu=1 in file ${filename}"
  sudo sed -i '/disable_menu/ s/"0"/"1"/g' ${filename}

  #
  # retropie/opt/retropie/emulators/retroarch/retroarch.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/emulators/retroarch/retroarch.cfg"
  trace "** Apply modifications to ${filename}"

  # uncomment and set to false "video_font_enable=false"
  trace "uncomment video_font_enable and set to false in file ${filename}"
  sudo sed -i '/video_font_enable/ s/#//g' ${filename}
  sudo sed -i '/video_font_enable/ s/true/false/g' ${filename}

  #
  # retropie/opt/retropie/configs/all/retroarch.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/configs/all/retroarch.cfg"
  trace "** Apply modifications to ${filename}"

  # uncomment and set to false "video_font_enable=false"
  trace "uncomment video_font_enable and set to false in file ${filename}"
  sudo sed -i '/video_font_enable/ s/#//g' ${filename}
  sudo sed -i '/video_font_enable/ s/true/false/g' ${filename}

  #
  # Splash screen management
  #
  filename="${WORKING_DIRECTORY}/etc/splashscreen.list"
  trace "** Splash Screen"
  trace "No Splash Screen. Empty ${filename}"
  sudo truncate -s 0 "${filename}"

  #
  # autolaunch.sh installation
  #
  filename="$(dirname ${BASH_SOURCE[0]})/../launch-game/${AUTOLAUNCH_SCRIPT_FILENAME}"
  trace "** Autolaunch script"
  trace "Copy autolaunch script from ${filename} to ${WORKING_DIRECTORY}/etc/profile.d/"
  sudo cp ${filename} "${WORKING_DIRECTORY}/etc/profile.d/"

  #
  # enable ssh by default
  #
  filename="${BOOT_DIRECTORY}/ssh"
  trace "** SSH enabling"
  trace "touch ${filename} to activate the SSH"
  sudo touch ${filename}

  #
  # No console output when launching games
  #
  trace "** Remove traces in console"
  trace "Empty ${WORKING_DIRECTORY}/etc/issue"
  sudo truncate -s 0 "${WORKING_DIRECTORY}/etc/issue"
  trace "Empty ${WORKING_DIRECTORY}/etc/motd"
  sudo truncate -s 0 "${WORKING_DIRECTORY}/etc/motd"
  filename="${WORKING_DIRECTORY}/home/pi/.bashrc"
  trace "Comment retropie_welcome line in ${filename}"
  sudo sed -i '/^retropie_welcome/ s/^#*/#/' ${filename}
  filename="${WORKING_DIRECTORY}/etc/rc.local"
  trace "Add  sudo sh -c 'TERM=linux setterm -foreground black -clear all >/dev/tty0' in ${filename}"
  # i : add line before the line selected by search term
  sudo sed -i '/^exit 0/i\sudo sh -c "TERM=linux setterm -foreground black -clear all >\/dev\/tty0"' ${filename}
}

# Parameters Management #################################################

function usage() {
  echo
  echo "USAGE: $(basename $0) -i image Retropie d'origine -o image à générer"
  echo
}

function get_options() {

  while getopts "i:o:dh" option ;
  do
    trace "getopts OPTIND=$OPTIND, Option=$option, OPTARG=$OPTARG, OPTERR=$OPTERR"
    case "${option}" in

      #Input Retropie Image
      i)
        original_retropie_image=${OPTARG}
        trace "Le fichier d'entrée est ${original_retropie_image}"
	      ;;

      #Ouput image result
      o)
        result_image=${OPTARG}
	      trace "Le fichier de sortir est ${result_image}"
        ;;

      #Missing Arguments
      :)
        exitonerror "L'option \"$OPTARG\" requiert une argument"
        ;;

      d)
        trace "Mode Debug ON"
        debug="ON"
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

prepare_image

mount_image

read -p "Vérifier le résultat avant modification des fichiers de l'image... " -n1 -s
create_SD

read -p "Vérifier le résultat avant démontage des répertoires... " -n1 -s
umount_image

prepare_result

exit 0
