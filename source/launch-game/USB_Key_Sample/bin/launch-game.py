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

# Main section
def main():

    logging.info('Started')
    try:
        finder = ConsoleFinder(ROOT_USB_KEY, ROOT_ROMS, SYSTEM_LIST)
        console_name = finder.search_console_name()
        if len(console_name) > 0:
            print("Console found is : "+console_name)
            console = finder.create_console(console_name)
            if not console:
                raise Exception('Erreur de création de la console', console_name)
            print("Find files result : "+str(console.find_files()))
            print("Command line : "+console.launchCommand())

            # execute command
            if retropie_Computer:
                os.system('"'+console.launchCommand()+'"')

    except Exception as inst:
        print(type(inst))    # the exception instance
        print(inst.args)     # arguments stored in .args
        print(inst)          # __str__ allows args to be printed directly,
                             # but may be overridden in exception subclasses
        x, y = inst.args     # unpack args
        print('x =', x)
        print('y =', y)

    logging.info('Finished')

if __name__ == '__main__':
    main()
