#!/usr/bin/env python3
# -*- coding: utf-8 -*-

##########################################################################
#
# This script starts a game automatically.
# The game to start is found in a USB key installed on the raspberry
# The directory structure of the key MUST be always the same :
#   /
#     bin
#       launch-game.py
#     roms
#       MACHINE_NAME
#         GAME (extension depends on the kind of machine)
#         Controller configuration file (.cfg)
#
# Requirements :
# - Linux OS
# - Python 3.7+
##########################################################################

# Import section
from globals import *
from console import *
from logger import *
from console_finder import *
from controllers import *
import subprocess

# Main section
def main():

    logging.info('Started')
    try:

        emulation_station_launch = True

        # find game and lanch it
        finder = ConsoleFinder(ROOT_USB_KEY, ROOT_ROMS, SYSTEM_LIST)
        console_name = finder.search_console_name()
        if len(console_name) > 0:
            logging.info("Console found is : "+console_name)

            # check controllers for configuration
            controllers= Controllers(console_name)
            # copy configuration file to SD Card
            controllers.CopyControllerConfigurationToSDCard()
            # check that plugged controllers 'll have a configuration file'
            result= controllers.GetControllersListCheckConfigurations()

            if result:
                console = finder.create_console(console_name)
                if not console:
                    raise Exception('Erreur de création de la console', console_name)
                logging.info("Find files result : "+str(console.find_files()))

                # execute command
                if retropie_Computer:
                    cmdline=console.launchCommand()
                    logging.info("Command line : "+cmdline)
                    retcode=subprocess.call(cmdline, shell=True)
                    logging.info("Call termined with return code = "+str(retcode))
                    emulation_station_launch = False

        # launch Emulation Station to configure new controllers
        if emulation_station_launch:

            # execute command
            if retropie_Computer:
                logging.info("Launching : "+CONST_EMULATIONSTATION_COMMAND)
                retcode=subprocess.call(CONST_EMULATIONSTATION_COMMAND, shell=True)
                logging.info("Call termined with return code = "+str(retcode))

    except Exception as inst:
        logging.error(type(inst))    # the exception instance
        logging.error(inst.args)     # arguments stored in .args
        logging.error(inst)          # __str__ allows args to be printed directly,
                             # but may be overridden in exception subclasses
        x, y = inst.args     # unpack args
        logging.error('x =', x)
        logging.error('y =', y)

    logging.info('Finished')

if __name__ == '__main__':
    main()
