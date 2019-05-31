# -*- coding: utf-8 -*-

import subprocess
from globals import *
from logger import *
from pathlib import Path


######################################################################
class Controllers:
    """
    Manage controllers and controllers's configurations on the device
    """

    def __init__(self):
        """Init the class"""
        pass

    def GetListPluggedControllers(self):
        """
        Build a list of name of controllers that are currently plugged into
        the device
        """
        result=[]
        list=subprocess.check_output('dmesg | grep -Po "(?<=input: )(.*)(?= as)"', shell=True).decode("utf-8").split(os.linesep)
        for joystick in list:
            if len(joystick) > 0:
                logging.info(f"Add ${joystick} to the list of plugged controllers")
                result.append(joystick)

        return result

    def CheckControllersConfiguration(self, joystick_list):
        """
        Check if a configuration file exists for every plugged joystick into the device
        """

        logging.info(f"List of controllers for a configuration file check : {joystick_list}")
        if len(joystick_list) > 0:
            for joystick in joystick_list:
                logging.info(f"Controller name : {joystick}")
                configurationFile=CONTROLLER_PATH+joystick+".cfg"
                logging.info(f"Configuration file : {configurationFile}")
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
        logging.info(f"List of controllers connected to device : {joystick_list}")
        if len(joystick_list) > 0:
            result=self.CheckControllersConfiguration(joystick_list)
        else:
            # no plugged controllers, no problems for now
            result=True

        logging.info(f"CheckControllersConfiguration : {result}")

        return result


########################################################
# for testing purpose

if __name__ == '__main__':
    controllers= Controllers()

    result= controllers.GetControllersListCheckConfigurations()
    sys.exit(result)
