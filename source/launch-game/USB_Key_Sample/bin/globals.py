# -*- coding: utf-8 -*-

# import section
import platform
from logger import *

# Command to launch games
CONST_LAUNCH_COMMAND = "/opt/retropie/supplementary/runcommand/runcommand.sh"

# Files constants
CONTROLLER_CONFIG_EXT="*.cfg"

# Directories depending on the computer used for executing
platform_uname_version = platform.uname().node
retropie_Computer = platform_uname_version.find("retropie") >= 0
if retropie_Computer:
  ROOT_USB_KEY="/media/usb0"
  ROOT_CONFIG="/opt/retropie/configs"
  ROOT_HOME_PI="/home/pi"
  ROOT_SYSTEM="/etc/emulationstation"
else:
  ROOT_USB_KEY="/Volumes/ROMS"
  ROOT_CONFIG=ROOT_USB_KEY+"/configs-tests"
  ROOT_HOME_PI=ROOT_USB_KEY+"/home-tests"
  ROOT_SYSTEM=ROOT_USB_KEY+"/emulationstation-tests"

ROOT_ROMS=ROOT_USB_KEY+"/roms"
LOGS_PATH=ROOT_USB_KEY+"/bin"
CONTROLLER_PATH=ROOT_CONFIG+"/all/retroarch-joypads"
BIOS_PATH=ROOT_HOME_PI+"/RetroPie/BIOS"
SYSTEM_LIST=ROOT_SYSTEM+"/es_systems.cfg"

logging.info("Retropie computer is : "+str(retropie_Computer))
logging.info("ROOT_USB_KEY : "+ROOT_USB_KEY)
logging.info("ROOT_CONFIG : "+ROOT_CONFIG)
logging.info("ROOT_HOME_PI : "+ROOT_HOME_PI)
logging.info("ROOT_SYSTEM : "+ROOT_SYSTEM)
logging.info("ROOT_ROMS : "+ROOT_ROMS)
logging.info("LOGS_PATH : "+LOGS_PATH)
logging.info("BIOS_PATH : "+BIOS_PATH)
logging.info("SYSTEM_LIST : "+SYSTEM_LIST)
