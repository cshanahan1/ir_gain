#! /usr/bin/env python

"""Sets the paths (by editing 'set_paths.pro'), creates directories, 
and generates makefile necessary to run the IR gain monitor scripts.

*Run this script before all others!*

This only needs be run once when you first clone the repo.


Author:

    C.M. Gosmeyer, Nov. 2015
    
Use: 

    >>> init_setup_ir_gain.py
    
Outputs: 
    <path>/outputs/
    <path>/data/newdata/makefile

Notes:

    You might not want to commit to the Grit server 'set_paths.pro' 
    after your paths are written to it. Your choice.

"""

import os
import time
import astropy
import numpy

def init_setup_ir_gain():
    """

    Parameters:
        nothing

    Returns:
        nothing

    Outputs:
        <path>/outputs/
        <path>/data/newdata/makefile

    """
    print " "
    print " Welcome to the initial setup for the WFC3/IR Gain Monitor."
    print " You will be prompted to enter one path. Afterward, this script will automatically"
    print " set up needed directories and paths. If you need to later edit the paths"
    print " you enter here, edit the program 'set_paths.pro' and move directories"
    print " where necessary."


    # This is where your IR gain suite is located.
    cwd = os.getcwd()
    print " The 'ir_gain' scripts are located at"
    print cwd
    print " "
    path_to_scripts = cwd

    base_path_raw = raw_input(" Type the primary path that will contain the 'data' and 'outputs' directories:\n")
    while base_path_raw != 'y':
        base_path = base_path_raw
        print " For the primary path you entered. "
        print base_path_raw
        base_path_raw = raw_input(" If this is right, type 'y'.  Otherwise, re-enter path:\n")

    # Check that the paths are properly formatted. 
    if base_path[len(base_path)-1] != '/':
        base_path += '/'
    if base_path[0] != '/':
        base_path = '/' + base_path

    print " "
    print " Your primary path is set to"
    print base_path
    print " "

    print " Now writing paths to 'set_paths.pro'..."
    # Read in the set_paths script.
    set_paths_pro = open(path_to_scripts + '/set_paths.pro', 'r')
    lines = set_paths_pro.readlines()
    set_paths_pro.close()     

    # Write the IDL script back to file with the user's paths entered.
    set_paths_pro = open(path_to_scripts + '/set_paths.pro', 'w')
    for line in lines:
        if 'path_to_outputs =' in line:
            set_paths_pro.write("path_to_outputs = '" + base_path + "outputs/'\n")
        elif 'path_to_data =' in line:
            set_paths_pro.write("path_to_data = '" + base_path + "data/'\n")
        elif 'path_to_scripts =' in line:
            set_paths_pro.write("path_to_scripts = '" + path_to_scripts + "/'\n")
        else:
            set_paths_pro.write(line)
    set_paths_pro.close()


    # Do the same for a Python version.
    print " Now writing paths to 'set_paths.py'..."
    # Read in the set_paths script.
    set_paths_py = open(path_to_scripts + '/set_paths.py', 'r')
    lines = set_paths_py.readlines()
    set_paths_py.close()    

    set_paths_py = open(path_to_scripts + '/set_paths.py', 'w')
    for line in lines:
        if 'path_to_outputs =' in line:
            set_paths_py.write("path_to_outputs = '" + base_path + "outputs/'\n")
        elif 'path_to_data =' in line:
            set_paths_py.write("path_to_data = '" + base_path + "data/'\n")
        elif 'path_to_scripts =' in line:
            set_paths_py.write("path_to_scripts = '" + path_to_scripts + "/'\n")
        else:
            set_paths_py.write(line)
    set_paths_py.close()


    print " "
    print " Now setting up the 'outputs' and 'data' directories..."
    # Set up outputs.
    if not os.path.isdir(base_path + 'outputs/'):
        os.mkdir(base_path + 'outputs/')
        print " Created " + base_path + 'outputs/'
    if not os.path.isdir(base_path + 'outputs/finalresults/'):
        os.mkdir(base_path + 'outputs/finalresults/')
        print " Created " + base_path + 'outputs/finalresults/'
    if not os.path.isdir(base_path + 'outputs/intermediates/'):
        os.mkdir(base_path + 'outputs/intermediates/')
        print " Created " + base_path + 'outputs/intermediates/'
    if not os.path.isdir(base_path + 'outputs/persistence/'):
        os.mkdir(base_path + 'outputs/persistence/')
        print " Created " + base_path + 'outputs/persistence/'

    if not os.path.isdir(base_path + 'data/'):
        os.mkdir(base_path + 'data/')
        print " Created " + base_path + 'data/'
    if not os.path.isdir(base_path + 'data/newdata/'):
        os.mkdir(base_path + 'data/newdata/')
        print " Created " + base_path + 'data/newdata/'

    obstypes = ['dark_leading/', 'flat_short/', 'flat_long/', 'dark_trailing/', 'cycle17/']

    for maindir in ['data/', 'outputs/finalresults/', 'outputs/intermediates/', 'outputs/persistence/']:
        for obstype in obstypes:
            if not os.path.isdir(base_path + maindir + obstype):
                os.mkdir(base_path + maindir + obstype)
                print "Created " + base_path + maindir + obstype


    print " "
    print " Finally generating the makefile for the newdata directory..."

    with open(base_path+"data/newdata/makefile", "w") as makefile:
        makefile.write("PYTHON=$(shell which python)\n")
        makefile.write("\n")
        makefile.write(".PHONY: newdata\n")
        makefile.write("newdata:\n")
        makefile.write("\tcp " + path_to_scripts + "/recal_unitcorr.py .\n")
        makefile.write("\t$(PYTHON) recal_unitcorr.py\n")
        makefile.write("\t$(PYTHON) " + path_to_scripts + "/sort_and_generate_filelist.py " + base_path + "data/\n")
    print " "
    print " The ir_gain setup is COMPLETE."



if __name__=='__main__':

    init_setup_ir_gain()