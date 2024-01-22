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
controller_file=
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

    # if controller filename is provided then check file exists
    if [[ ! -z "${controller_file}" ]] && [[ ! -f "${controller_file}" ]]; then
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

function exitonerror_cleanneeded() {
  local errormsg="[$(date -u)][ERROR] $1"

  # display to console
  if ! [[ -z "$debug" ]]; then
    echo "${errormsg}"
  fi

  #init log file if needed
  init_log_file

  #add to log file
  echo "${errormsg}" >> "${logFileName}"

  # Free the images
  umount_image

  exit 1
}

# Image file Management #######################################################

function prepare_image() {
  trace "##########################"
  trace "prepare_image ############"

  if [[ -z "${original_retropie_image}" ]]; then
    exitonerror "Pas d'image Retropie en entrée"
  fi
  if ! [[ -f "${original_retropie_image}" ]]; then
    exitonerror "Le fichier image Retropie d'entrée est introuvable"
  fi

  if [[ -z "${result_image}" ]]; then
    exitonerror "Pas d'image de destination"
  fi

  # Delete old result is any
  if [[ -f "${result_image}" ]]; then
    trace "Suppression de l'ancienne image résultat ${result_image}"
    rm "${result_image}"
  fi

  # Delete old result is any
  if [[ -f "${TEMP_IMAGE}" ]]; then
    trace "Suppression de l'ancienne image de travail ${TEMP_IMAGE}"
    rm "${TEMP_IMAGE}"
  fi

  # temporary duplicate to local directory (usefull is executing the script inside a VM)
  trace "Copie de ${original_retropie_image} vers ${TEMP_IMAGE}"
  cp "${original_retropie_image}" "${TEMP_IMAGE}"

  # check if result file is present
  if ! [[ -f "${TEMP_IMAGE}" ]]; then
     exitonerror "Impossible de créer le fichier ${TEMP_IMAGE}"
  fi

  # End successfully
  trace "L'image de travail ${TEMP_IMAGE} a été corectement générée"
}

function prepare_result() {
  trace "##########################"
  trace "prepare_result ###########"

  # check if result file is present
  if ! [[ -f "${TEMP_IMAGE}" ]]; then
     exitonerror "L'image de travail ${TEMP_IMAGE} n'existe pas"
  fi

  # copy the result to the given destianation
  trace "Copie de ${TEMP_IMAGE} vers ${result_image}"
  cp "${TEMP_IMAGE}" "${result_image}"
}

function mount_image() {
  trace "##########################"
  trace "mount_image ##############"

  # Get the first device available
  loop=$(sudo losetup -f)
  if [[ -z "${loop}" ]]; then
    exitonerror "Impossible de trouver un périphérique disponible pour charge l'image (losetup -f error)"
  fi

  # Associate image to peripheric
  sudo losetup --show -P "${loop}" ${TEMP_IMAGE}
  trace "Association de ${loop} avec l'image ${TEMP_IMAGE}"
  if [ $? -ne 0 ]; then
    exitonerror "Impossible d'associer l'image ${TEMP_IMAGE} au pseudo périphérique ${loop}"
  fi

  # Create temporary directory
  trace "Création du répertoire de travail ${WORKING_DIRECTORY}"
  mkdir "${WORKING_DIRECTORY}"
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

function apply_common_modifications_on_SD () {
  trace "####################################"
  trace "apply_common_modifications_on_SD ###"

  #
  # boot/cmdline.txt
  #
  local filename="${BOOT_DIRECTORY}/cmdline.txt"
  trace "## Apply modifications to ${filename}"

  # replace "console=tty1" by "console=tty3 logo.nologo loglevel=3 vt.global_cursor_default=0"
  local pattern_to_remove="console=tty1"
  local pattern_to_add="console=tty3 logo.nologo loglevel=3 vt.global_cursor_default=0"

  #command : sed '0,/tata/ s//zaza/' in.txt
  trace "replace ${pattern_to_remove} by ${pattern_to_add} in file ${filename}"
  sudo sed -i '0,/'"${pattern_to_remove}"'/ s//'"${pattern_to_add}"'/' "${filename}"

  #
  # boot/config.txt
  #
  filename="${BOOT_DIRECTORY}/config.txt"
  trace "## Apply modifications to ${filename}"

  # uncomment "disable_overscan=1"
  trace "uncomment disable_overscan=1"
  sudo sed -i '0,/#disable_overscan/ s//disable_overscan/' "${filename}"

  #     Special config for borne arcade1Up with a slight zoom neede
  if [[ "${specific_console}" == "borne_arcade_1_up" ]]; then
    trace "replace 'disable_overscan=1' by 'disable_overscan=0' in file ${filename}"
    sudo sed -i '0,/'"disable_overscan=1"'/ s//'"disable_overscan=0"'/' "${filename}"
    trace "replace '#overscan_left=16' by 'overscan_left=20' in file ${filename}"
    sudo sed -i '0,/'"#overscan_left=16"'/ s//'"overscan_left=20"'/' "${filename}"
    trace "replace '#overscan_right=16' by 'overscan_right=20' in file ${filename}"
    sudo sed -i '0,/'"#overscan_right=16"'/ s//'"overscan_right=20"'/' "${filename}"
    trace "replace '#overscan_top=16' by 'overscan_top=0' in file ${filename}"
    sudo sed -i '0,/'"#overscan_top=16"'/ s//'"overscan_top=0"'/' "${filename}"
    trace "replace '#overscan_bottom=16' by 'overscan_bottom=0' in file ${filename}"
    sudo sed -i '0,/'"#overscan_bottom=16"'/ s//'"overscan_bottom=0"'/' "${filename}"
  fi

  # Disable overscan_scale=1
  #trace "comment overscan_scale=1"
  #sudo sed -i '0,/overscan_scale/ s//#overscan_scale/' "${filename}"

  # Disable large rainbow screen on initial boot
  trace "add disable_splash=1"
  sudo sed -i '$adisable_splash=1' "${filename}"

  # add "plymouth.enable=0"
  trace "add plymouth.enable=0"
  sudo sed -i '$aplymouth.enable=0' "${filename}"

  # disable warnings such as undervoltage/overheating
  trace "add avoid_warnings=1"
  sudo sed -i '$aavoid_warnings=1' "${filename}"

  #
  # retropie/opt/retropie/configs/all/runcommand.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/configs/all/runcommand.cfg"
  trace "## Apply modifications to ${filename}"

  # add "disable_joystick=1"
  trace "replace disable_joystick=0 by disable_joystick=1 in file ${filename}"
  sudo sed -i '/disable_joystick/ s/"0"/"1"/g' "${filename}"

  # add "disable_splash=1"
  trace "replace disable_menu=0 by disable_menu=1 in file ${filename}"
  sudo sed -i '/disable_menu/ s/"0"/"1"/g' "${filename}"

  #
  # retropie/opt/retropie/emulators/retroarch/retroarch.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/emulators/retroarch/retroarch.cfg"
  trace "## Apply modifications to ${filename}"

  # uncomment and set to false "video_font_enable=false"
  trace "uncomment video_font_enable and set to false in file ${filename}"
  sudo sed -i '/video_font_enable/ s/#//g' "${filename}"
  sudo sed -i '/video_font_enable/ s/true/false/g' "${filename}"

  #     Special config for borne pacman MO5 with a screen slightly shifted
  if [[ "${specific_console}" == "borne_pacman_mo5" ]]; then

    # Index of the aspect ratio selection in the menu.
    # 19 = Config, 20 = 1:1 PAR, 21 = Core Provided, 22 = Custom Aspect Ratio
    sudo sed -i '/aspect_ratio_index/ s/19/22/g' "${filename}"

    # uncomment and set to 366 "#custom_viewport_width = 0"
    sudo sed -i '/custom_viewport_width/ s/#//g' "${filename}"
    sudo sed -i '/custom_viewport_width/ s/0/"366"/g' "${filename}"
    # uncomment and set to 476 "#custom_viewport_height = 0"
    sudo sed -i '/custom_viewport_height/ s/#//g' "${filename}"
    sudo sed -i '/custom_viewport_height/ s/0/"476"/g' "${filename}"
    # uncomment and set to 149 "#custom_viewport_x = 0"
    sudo sed -i '/custom_viewport_x/ s/#//g' "${filename}"
    sudo sed -i '/custom_viewport_x/ s/0/"149"/g' "${filename}"
    # uncomment and set to 5 "#custom_viewport_y = 0"
    sudo sed -i '/custom_viewport_y/ s/#//g' "${filename}"
    sudo sed -i '/custom_viewport_y/ s/0/"5"/g' "${filename}"
  fi
  
  #
  # retropie/opt/retropie/configs/all/retroarch.cfg
  #
  filename="${WORKING_DIRECTORY}/opt/retropie/configs/all/retroarch.cfg"
  trace "## Apply modifications to ${filename}"

  # uncomment and set to false "video_font_enable=false"
  trace "uncomment video_font_enable and set to false in file ${filename}"
  sudo sed -i '/video_font_enable/ s/#//g' "${filename}"
  sudo sed -i '/video_font_enable/ s/true/false/g' "${filename}"

  # set to true "video_smooth = false"
  trace "set video_smooth to true in file ${filename}"
  sudo sed -i '/video_smooth/ s/false/true/g' "${filename}"

  #
  # Splash screen management
  #
  filename="${WORKING_DIRECTORY}/etc/splashscreen.list"
  trace "## Splash Screen"
  trace "No Splash Screen. Empty ${filename}"
  sudo truncate -s 0 "${filename}"

  #
  # enable ssh by default
  #
  filename="${BOOT_DIRECTORY}/ssh"
  trace "## SSH enabling"
  trace "touch ${filename} to activate the SSH"
  sudo touch "${filename}"

  #
  # Audio setup
  #
  filename="${WORKING_DIRECTORY}/etc/asound.conf"

  #     Special config for borne arcade1Up with use of jack output instead of HDMI
  if [[ "${specific_console}" == "borne_arcade_1_up" ]]; then
    trace "add 'pcm.!default {type hw card 1}' in file ${filename}"
    echo "pcm.!default {type hw card 1}" | sudo tee "${filename}"
    trace "add 'ctl.!default {type hw card 1}' in file ${filename}"
    echo "ctl.!default {type hw card 1}" | sudo tee --append "${filename}"
  fi

  #
  # No console output when launching games
  #
  trace "## Remove traces in console"
  trace "Empty ${WORKING_DIRECTORY}/etc/issue"
  sudo truncate -s 0 "${WORKING_DIRECTORY}/etc/issue"
  trace "Empty ${WORKING_DIRECTORY}/etc/motd"
  sudo truncate -s 0 "${WORKING_DIRECTORY}/etc/motd"
  filename="${WORKING_DIRECTORY}/home/pi/.bashrc"
  trace "Comment retropie_welcome line in ${filename}"
  sudo sed -i '/^retropie_welcome/ s/^#*/#/' "${filename}"
  filename="${WORKING_DIRECTORY}/etc/rc.local"
  trace "Add  sudo sh -c 'TERM=linux setterm -foreground black -clear all >/dev/tty0' in ${filename}"
  # i : add line before the line selected by search term
  sudo sed -i '/^exit 0/i\sudo sh -c "TERM=linux setterm -foreground black -clear all >\/dev\/tty0"' "${filename}"
}

function create_Generic_SD () {
  trace "##########################"
  trace "create_Generic_SD ########"

  #
  # apply basics modifications
  #
  apply_common_modifications_on_SD

  #
  # autolaunch.sh installation
  #
  filename="$(dirname ${BASH_SOURCE[0]})/../launch-game/${AUTOLAUNCH_SCRIPT_FILENAME_GenericLaunch}"
  trace "## Autolaunch script"
  trace "Copy autolaunch script from ${filename} to ${AUTOLAUNCH_DIRECTORY}/${AUTOLAUNCH_SCRIPT_FILENAME}"
  sudo cp "${filename}" "${AUTOLAUNCH_DIRECTORY}/${AUTOLAUNCH_SCRIPT_FILENAME}"
}

function create_Specific_SD () {
  trace "###########################"
  trace "create_Specific_SD ########"

  #
  # apply basics modifications
  #
  apply_common_modifications_on_SD

  # get user & group of roms directory in mounting situation
  user_group="$(stat -c "%U:%G" ${ROMS_DIRECTORY})"

  #
  # autolaunch.sh installation
  #
  filename="$(dirname ${BASH_SOURCE[0]})/../launch-game/${AUTOLAUNCH_SCRIPT_FILENAME_SpecificLaunch}"
  trace "## Autolaunch script"
  trace "Copy autolaunch script from ${filename} to ${AUTOLAUNCH_DIRECTORY}/${AUTOLAUNCH_SCRIPT_FILENAME}"
  sudo cp "${filename}" "${AUTOLAUNCH_DIRECTORY}/${AUTOLAUNCH_SCRIPT_FILENAME}"

  #
  # game installation
  #
  trace "## Install game into Core directory"
  gamename=$(basename -- "${gamefile}")
  corename=$(basename -- $(dirname -- "${gamefile}"))
  trace "Game to install is ${gamename} in core ${corename}"

  # check if roms directory exists in the SD
  trace "check if the core is known --> ${ROMS_DIRECTORY}/${corename}"
  if [[ -d "${ROMS_DIRECTORY}/${corename}" ]]; then
    trace "Copy gamefile ${gamename} to core ${corename}"
    sudo cp "${gamefile}" "${ROMS_DIRECTORY}/${corename}/"
    sudo chown "${user_group}" "${ROMS_DIRECTORY}/${corename}/${gamename}"
  else
    read -p "Le jeu est dans un répertoire core inconnu. Time to check " -n1 -s
    exitonerror_cleanneeded "Le jeu est dans un répertoire core inconnu : ${corename}"
  fi

  # Samples installation
  if ! [[ -z "${samples_dir}" ]]; then

    trace "Copy Samples directory ${samples_dir} to ${ROMS_DIRECTORY}/${corename}/samples"
    sudo cp -r "${samples_dir}" "${ROMS_DIRECTORY}/${corename}/samples"
    sudo chown -R "${user_group}" "${ROMS_DIRECTORY}/${corename}/samples"

  fi

  # Controller file
  if [[ ! -z "${controller_file}" ]]; then

    controller_filename=$(basename -- "${controller_file}")
    trace "Copy controller file ${controller_file} to ${JOYPAD_CONFIGURATION_DIRECTORY}/${controller_filename}"
    sudo cp "${controller_file}" "${JOYPAD_CONFIGURATION_DIRECTORY}/${controller_filename}"
    sudo chown "${user_group}" "${JOYPAD_CONFIGURATION_DIRECTORY}/${controller_filename}"
  fi

  #
  # core and game name replacement
  #
  trace "## Put Core and Game name into the launcher file"
  filename="${AUTOLAUNCH_DIRECTORY}/${AUTOLAUNCH_SCRIPT_FILENAME}"
  trace "replace CORE_NAME by ${corename} in file ${filename}"
  sudo sed -i '0,/'"CORE_NAME"'/ s//'"${corename}"'/' "${filename}"
  trace "replace GAME_NAME by ${gamename} in file ${filename}"
  sudo sed -i '0,/'"GAME_NAME"'/ s//'"${gamename}"'/' "${filename}"
  if ! [[ -z "${emulatorname}" ]]; then
    trace "replace EMULATOR_NAME by ${emulatorname} in file ${filename}"
    sudo sed -i '0,/'"EMULATOR_NAME"'/ s//'"${emulatorname}"'/' "${filename}"
  else
    trace "replace EMULATOR_NAME by "" in file ${filename}"
    sudo sed -i '0,/'"EMULATOR_NAME"'/ s//''/' "${filename}"
  fi
}

# Parameters Management #################################################

function usage() {
  echo
  echo "USAGE:"
  echo "image générique: $(basename $0) -g -i \"image Retropie d'origine\" -o \"image à générer\""
  echo "image spécifique: $(basename $0) -s \"fichier du jeu\" (-p \"répertoire des samples\") (-e \"nom de l'émulateur\") (-c \"fichier controller à installer\") (-x \"nom de la console dont il faut appliquer les paramètres spécifiques) -i \"image Retropie d'origine\" -o \"image à générer\""
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

      #Specific controller file name to copy onto SD Card
      c)
        trace "Controller filename"
        controller_file=${OPTARG}
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

prepare_image

mount_image

# read -p "Vérifier le résultat avant modification des fichiers de l'image... " -n1 -s

if ! [[ -z ${generic} ]]; then
  create_Generic_SD
fi

if ! [[ -z ${specific} ]]; then
  create_Specific_SD
fi

read -p "Les modifications ont été appliquées.\nVérifiez le résultat avant démontage des répertoires... " -n1 -s
umount_image

prepare_result

exit 0
