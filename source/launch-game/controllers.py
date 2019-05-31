# -*- coding: utf-8 -*-

import subprocess
from globals import *
from logger import *
from pathlib import Path
from console_finder import *

######################################################################
class Controllers:
    """
    Manage controllers and controllers's configurations on the device
    """

    def __init__(self, consoleName):
        """Init the class"""
        self.consoleName = consoleName
        pass

    def GetListPluggedControllers(self):
        """
        Build a list of name of controllers that are currently plugged into
        the device
        """
        result=[]

        try:
            list=subprocess.check_output('dmesg | grep -Po "(?<=input: )(.*)(?= as)"', shell=True).decode("utf-8").split(os.linesep)
            for joystick in list:
                if len(joystick) > 0:
                    logging.info(joystick+" is added to the list of plugged controllers")
                    result.append(joystick)

        except Exception as inst:
            logging.warn(type(inst))    # the exception instance
            logging.warn(inst.args)     # arguments stored in .args
            logging.warn(inst)          # __str__ allows args to be printed directly,

        return result

    def CheckControllersConfiguration(self, joystick_list):
        """
        Check if a configuration file exists for every plugged joystick into the device
        """

        logging.info("List of controllers for a configuration file check : "+str(joystick_list))
        if len(joystick_list) > 0:
            for joystick in joystick_list:
                logging.info("Controller name : "+joystick)
                configurationFile=CONTROLLER_PATH+"/"+joystick+".cfg"
                logging.info("Configuration file : "+configurationFile)
                if not Path(configurationFile).is_file():
                    # one file is missing
                    return False
            # All the files have been found
            return True
        else:
            # list is empty
            return False

    def GetControllersListCheckConfigurations(self):
        """
        Get the list of plugged controllers and check if configuration files exist
        """

        joystick_list=self.GetListPluggedControllers()
        logging.info("List of controllers connected to device : "+str(joystick_list))
        if len(joystick_list) > 0:
            result=self.CheckControllersConfiguration(joystick_list)
        else:
            # no plugged controllers, no problems for now
            result=True

        logging.info("CheckControllersConfiguration : "+str(result))

        return result

    def CopyControllerConfigurationToSDCard(self):
        """
        If a controller configuration file is found into the console directory,
        then copy it to the standard SD Card directory
        """

        if len(self.consoleName) > 0:
            consolePath= ROOT_ROMS+"/"+self.consoleName
            list_config_files=glob.glob(consolePath+"/"+CONTROLLER_CONFIG_EXT)
            for file in list_config_files:
                # get the filename only
                filename=os.path.basename(file)
                copyfile(file, CONTROLLER_PATH+"/"+filename)
                logging.info("Copying "+filename+" from "+consolePath+" to "+CONTROLLER_PATH)

if __name__ == '__main__':
    controls=Controllers("nes")
    controls.CopyControllerConfigurationToSDCard()
    result=controls.GetControllersListCheckConfigurations()
    logging.info("Check Conntrolers : "+str(result))
