# -*- coding: utf-8 -*-

# imports section
from globals import *
from logger import *
from shutil import copyfile
import os
import glob

# Globals section
CONSOLES_DICT={"pcengine":"PCEngine", "psx":"Playstation"}

# Class console : gérer les spécificités des consoles
class Console:
    """Classe définissant la commande à lancer selon le type de console. Caractérisée par :
    - son nom : console_name
    - le nom de l'émulateur : core_name
    - le nom du jeu : game_name
    """

    def __init__(self, core_name, fullname, extensions, command, console_path):
        """Init the console"""
        self.core_name = core_name
        self.console_name = fullname
        self.game_extensions = extensions
        self.launch_command = command
        self.console_path = console_path
        self.game_name=""
        logging.info("Init Console with : core= "+self.core_name+", fullname= "+self.console_name+", extensions= "+self.game_extensions+", command= "+self.launch_command+", path= "+self.console_path)

    def find_files(self):
        """ Search for all the necessary files for launching the emulator
        """
        try:
            self.find_controller()
            self.find_game()
            self.find_bios()
            return True
        except Exception as inst:
            logging.error("Exception "+inst)
            print("EXCEPTION in 'find_files' : "+inst)
            print("See log file for details ")
            return False

    def find_controller(self):
        """ Check if the controler file description is included
        if no controller is found, then raise an error
        COULD BE CHANGED
        """
        # find every files with controller config extension
        list_config_files=glob.glob(self.console_path+"/"+CONTROLLER_CONFIG_EXT)

        # no files ? we can stop immediately
        if len(list_config_files) == 0:
            logging.error("No Controller file found in directory "+self.console_path+" for Console : "+self.console_name)
            raise Exception("No Controller file found in directory "+self.console_path,"Console : "+self.console_name)

        # get the first controller config
        logging.info("Controller files "+str(list_config_files)+" found in directory "+self.console_path+" for Console : "+self.console_name)

        # copy controller config files into SD Card dans CONTROLLER_PATH
        for file in list_config_files:
            # get the filename only
            filename=os.path.basename(file)
            copyfile(file, CONTROLLER_PATH+"/"+filename)
            logging.info("Copying "+filename+" from "+self.console_path+" to "+CONTROLLER_PATH)

    def find_game(self):
        """ Check if there's a file game inside the Directory
        Take the first one
        if no game is found, raise an error
        """
        self.game_name=""

        # get list of files in console directory
        root, dirs, files = next(os.walk(self.console_path))

        # no files ? we can stop immediately
        if len(files) == 0:
            logging.error("No files in directory "+self.console_path+" for Console : "+self.console_name)
            raise Exception("No files in directory "+self.console_path,"Console : "+self.console_name)

        # for each file, check if the extension corresponds to a game
        for file in files:
            filename, extension = os.path.splitext(file)
            if self.game_extensions.find(extension.lower()) > -1:
                logging.info("Game file "+file+" found in directory "+self.console_path+" for Console : "+self.console_name)
                self.game_name = file
                break

        # No result ? then error
        if not self.game_name:
            logging.error("No game file in directory "+self.console_path+" for Console : "+self.console_name)
            raise Exception("No game file in directory "+self.console_path,"Console : "+self.console_name)

    def find_bios(self):
        """ Find the bios file if needed
        For generic console, no BIOS
        if Error, raise an exception
        """
        pass

    def launchCommand(self):
        """Return the Retropie command line to launch the game
        ex : /opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ core_name game_name
        """
        command_line = ""
        if len(self.game_name) > 0:
            command_line = self.launch_command.replace('%ROM%', self.game_name)
            logging.info("Command line for game "+self.game_name+" is : "+command_line)
        return command_line


class PCEngine(Console):
    """ Special implementation of the console for PCEngine especially on the bios file particularity """

    def __init__(self, core_name, fullname, extensions, command, console_path):
        """Init the console"""
        Console.__init__(self, core_name, fullname, extensions, command, console_path)

    def find_bios(self):
        """ Find the bios file if needed
        For generic console, no BIOS
        if Error, raise an exception
        """
        raise Exception("No Bios files found for Palystation in console directory", self.console_path)

    def find_bios(self):
        """
        For PCEngine console, BIOS is named syscard3.pce
        if Error, raise an exception
        """
        PCENGINE_BIOS="syscard3.pce"
        found = False

        # get list of files in console directory
        root, dirs, files = next(os.walk(self.console_path))
        # look for bios file
        for file in files:
            if file.lower() == PCENGINE_BIOS:
                logging.info("Bios files found for PCEngine in console directory : "+file)
                found = True

                """ Todo : remove the warning """
                logging.warn("copy bios file into retropie system /Retropie/BIOS ??")
                break

        # if not found in console directory then check in BIOS directory
        if not found:
            logging.warn("No Bios files found in console directory : "+self.console_path)

            root, dirs, files = next(os.walk(BIOS_PATH))
            for file in files:
                if file.lower() == PCENGINE_BIOS:
                    logging.info("Bios files found in Retropie BIOS directory : "+file)
                    found = True
                    break

        # No bios files found at all
        if not found:
            raise Exception("No Bios files found in Retropie BIOS directory", BIOS_PATH)

class Playstation(Console):
    """ Special implementation of the console for Playstation especially on the bios file particularity """

    def __init__(self, core_name, fullname, extensions, command, console_path):
        """Init the console"""
        Console.__init__(self, core_name, fullname, extensions, command, console_path)

    def find_bios(self):
        """ Find the bios file if needed
        For Playstation console, BIOS are named like scph*.bin
        if Error, raise an exception
        """
        PSX_BIOS="scph*.bin"

        """ First, check into game directory """
        list_bin_files=glob.glob(self.console_path+"/"+PSX_BIOS)
        logging.info("Bios files found for Playstation in console directory : "+str(list_bin_files))

        """ Todo : remove the warning """
        if len(list_bin_files) > 0:
            logging.warn("copy bios file into retropie system /Retropie/BIOS ??")

        if not len(list_bin_files) > 0:
            logging.warn("No Bios files found for Playstation in console directory : "+self.console_path)
            """ Then check in Retropie BIOS directory """
            list_bin_files=glob.glob(BIOS_PATH+"/"+PSX_BIOS)
            logging.info("Bios files found for Playstation in Retropie BIOS directory : "+str(list_bin_files))

            """ No bios files found at all """
            if not len(list_bin_files) > 0:
                raise Exception("No Bios files found for Palystation in Retropie BIOS directory", BIOS_PATH)
