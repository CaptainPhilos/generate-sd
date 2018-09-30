# -*- coding: utf-8 -*-


# imports section
from globals import *
from console import *
from logger import *
from pathlib import Path
import os
import xml.etree.ElementTree as ET

# Class console : gérer les spécificités des consoles
class ConsoleFinder:
    """ Class that detect which console is needed. Characterized by :
    """

    def __init__(self, usbKeyPath, romsPath, systemsPath):
        """Constructor"""
        self.usb_key_path = usbKeyPath
        self.roms_path = romsPath
        if not self.check_Directories():
            logging.error("Impossibilité de lancer le parseur de répertoire car les répertoires ne sont pas accessibles : "+usbKeyPath+", "+romsPath)
            raise Exception('Impossibilité de lancer le parseur de répertoire car les répertoires ne sont pas accessibles', usbKeyPath+", "+romsPath)
        self.systems = Systems(systemsPath)
        logging.info(str(self.systems.lenght())+" systèmes trouvés dans le fichier "+systemsPath)

    # Utilities functions ####################################################

    def count_SubDirectories(self, root_directory):
        root, dirs, files = next(os.walk(root_directory))
        return len(dirs)

    # Check functions ########################################################

    def check_Directories(self):
        """ Check if USB Key is present and if it contains a ROMS directory
        that contains at least one subdirectory
        """
        result = True

        # Check if the USB Key is accessible
        logging.info("ROOT_USB_KEY= "+self.usb_key_path)
        if not Path(self.usb_key_path).is_dir():
            result = False
            logging.error("La clé USB n'a pas été trouvée en "+self.usb_key_path)

        # Check if directory of roms exists
        logging.info("ROOT_ROMS= "+self.roms_path)
        if not Path(self.roms_path).is_dir():
            result = False
            logging.error("Le répertoire des ROMS "+self.roms_path+" n'a pas été trouvé sur la clé")

        # check if roms directory contains at least on machine directory
        nbRomsSubDirectories = self.count_SubDirectories(self.roms_path)
        logging.info("Nb of sub directories of "+self.roms_path+" = "+str(nbRomsSubDirectories))
        if nbRomsSubDirectories < 1:
            result = False
            logging.error("Le répertoire des ROMS ne contient aucun répertoire de machine")

        # So is it ok ?
        return result

    # Scanning functions ########################################################

    def search_console_name(self):
        """ Scan the ROMS directory and try to find the FIRST console among the subdirectories
        The name of the console to search in is the name of the directory
        """
        result = ""

        # Get the list of subdirectories
        root, dirs, files = next(os.walk(self.roms_path))
        logging.info("Nb of sub directories of "+self.roms_path+" = "+str(len(dirs)))
        logging.info("Subdirectories of "+self.roms_path+" = "+str(dirs))

        # Get the first directory that match a console name
        for dir in dirs:
            if self.systems.is_system_valid(dir):
                result = dir
                logging.info("Console found : "+dir)
                break
            else:
                logging.info(dir+" is not a console")

        # result is console name
        return result

    def get_classname_from_console_name(self, console_name):
        """ Get the name of the Class of Console corresponding to console_name
        ex : pcengine --> PCEngine
        ex : psx --> Playstation
        """
        console_class = "Console"
        try:
            """ If this console is special, then return the special class for it """
            console_class = CONSOLES_DICT[console_name]
        except Exception as inst:
            """ No exceptionnal console given, so return default Console class """
            console_class = "Console"
        return console_class

    def create_console(self, console_name):
        """ Create a console object from its name """
        console_class = self.get_classname_from_console_name(console_name)
        if console_class:
            parameters = self.systems.extract_system(console_name)
            try:
                console_instance = eval(console_class)(core_name = parameters[0], fullname = parameters[1], extensions = parameters[2], command = parameters[3], console_path = self.roms_path+"/"+parameters[0])
                logging.info("Instance of "+console_class+" created with success")
                return console_instance
            except Exception as inst:
                """ Catch of error, back to Console by default """
                logging.error("Error of creation of instance of "+console_class+". Fallback to create Console")
                return Console(core_name = parameters[0], fullname = parameters[1], extensions = parameters[2], command = parameters[3], console_path = self.roms_path+"/"+parameters[0])
        else:
            logging.error("No console name to create. Exceptionnal error")
            return None

# Class systems
class Systems:
    """ List of systems installed on retropie
    Check if system exists
    Search for information on systems
    """

    def __init__(self, path_file):
        self.systems_list = self.load_Referential(path_file)
        if not self.systems_list:
            logging.error("Erreur de chargement du référentiel : "+path_file)
            raise Exception('Erreur de chargement du référentiel', path_file)

    def load_Referential(self, path_file):
        """ Load the refential of systems """
        if Path(path_file).is_file():
            return ET.parse(path_file).getroot()
        return None

    def lenght(self):
        """ Return the number of systems managed by Retropie """
        return len(self.systems_list)

    def is_system_valid(self, machine_name):
        """ Check if the machine is known in the retropie system """
        pattern = "./system[name='" + machine_name + "']"
        list = self.systems_list.find(pattern)
        if list is not None and len(list) > 0:
            return True
        return False

    def extract_system(self, machine_name):
        """ Extract the informations of a specific system
        - name          #psx
        - fullname      #PlayStation
        - extension     #.cue .cbn .img .iso .m3u .mdf .pbp .toc .z .znx .CUE .CBN .IMG .ISO .M3U .MDF .PBP .TOC .Z .ZNX
        - command       #/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ psx %ROM%
        """
        name = fullname = extension = command = ""
        pattern = "./system[name='" + machine_name + "']"
        system = self.systems_list.find(pattern)
        if system is not None:
            name = system.find("./name").text
            fullname = system.find("./fullname").text
            extension = system.find("./extension").text
            command = system.find("./command").text
        return name, fullname, extension, command


    def get_extensions_for_core(self, machine_name):
        """ Find the core informations and return the extensions """
        if (self.is_system_valid(machine_name)):
            pattern="./system[name='"+machine_name+"']"
            return self.systems_list.find(pattern).find("./extension").text
        return ""

    def get_command_for_core(self, machine_name):
        """ Find the command to launch the emulator for this core """
        if (self.is_system_valid(machine_name)):
            pattern="./system[name='"+machine_name+"']"
            return self.systems_list.find(pattern).find("./command").text
        return ""
