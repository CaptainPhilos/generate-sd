# -*- coding: utf-8 -*-

# Contains every tools & declaration needed for logging

# import section
import logging
import os
import sys

 # Utilities section
""" Define standard configuration for logging info """
log_filename = os.path.splitext(os.path.basename(sys.argv[0]))[0] + ".log"
logging.basicConfig(filename=log_filename, format='%(asctime)s : %(levelname)s : %(message)s', datefmt='%H:%M:%S', level=logging.INFO)
