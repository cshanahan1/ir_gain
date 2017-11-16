#! /usr/bin/env python

"""Sorts the newly calibrated gain files by nsamp and samp_seq.
Generates a text file for each subdirectory containing the new a list
of the new IMAs so that it may be passed to the IR gain calculation
suite.
    
Author:

    C.M. Gosmeyer, Nov 2015
    
Use: 

    In nominal use, will be called from the make file in the directory
    '/data/newdata' containing the newly calibrated IR gain files as

    >>> make sort

    But to run manually, go to the same directory and do
    
    >>> python sort_and_generate_filelist.py <path/to/data/>
    
Inputs:
    
    From command line, path to the data directory. 

Outputs: 

    text file. 'input_files.dat'

    * This will overwrite the existing 'input_files.dat'! *

"""


import glob
import os
import shutil
import sys
from astropy.io import ascii, fits
import time



def sort_files(loc):
    """Sorts files by nsamp and samp_seq keywords and matches them to
    the observation type.  (Leading dark, short flat, long flat, 
        trailing dark, or Cycle 17 weirdness sorted by nsamp.)
    Returns a dictionary of all the IMAs that were sorted into each
    obs_type directory.

    Parameters:
        loc : string

    Returns:
        ima_dict : dictionary
            Contains observation types as keys and IMA filenames as
            the values.

    Outputs:
        nothing

    """

    # Initialize the dictionary to contain the new imas for
    # each observation type.
    ima_dict = {}

    filename_list = glob.glob(loc + 'newdata/*fits')
    

    for filename in filename_list:
        filename_parsed = filename.split('/')[len(filename.split('/'))-1]
        header = fits.getheader(filename)

        # First find the nsamp value.
        nsamp_value = header['NSAMP']

        # From the nsamp value sort into leading dark, short flat, long flat, trailing dark.
        if nsamp_value == 7:
            # Short flat.
            obs_type = 'flat_short'

        elif nsamp_value == 10:
            # Leading dark.
            obs_type = 'dark_leading'

        elif nsamp_value == 16:
            # Trailing dark.
            obs_type = 'dark_trailing'

        elif nsamp_value == 14: 
            # Sort further by samp_seq.
            samp_seq_value = header['SAMP_SEQ']
            samp_seq_value = str(samp_seq_value)

            if samp_seq_value == 'SPARS50':
                # Long flat.
                obs_type = 'flat_long'

            else:
                # Sort by the nsamp in the 'cycle17' directory.
                obs_type = 'cycle17/' + str(nsamp_value) + 'nsamp/' + samp_seq_value + '/'

        else: 
            # Sort by the nsamp/samp_seq in the 'cycle17' directory.
            samp_seq_value = header['SAMP_SEQ']
            samp_seq_value = str(samp_seq_value)

            obs_type = 'cycle17/' + str(nsamp_value) + 'nsamp/' + samp_seq_value + '/'
                

        # If a directory for the observation type doesn't already exist, create it.
        if not os.path.isdir(loc+ obs_type):
            print '...'
            if len(obs_type.split('/')) >= 4:
                print 'Making new directory, ' + loc + obs_type
                if not os.path.isdir(loc+ (obs_type.split('/'))[0] + '/' + (obs_type.split('/'))[1]):
                    os.mkdir(loc + (obs_type.split('/'))[0] + '/' + (obs_type.split('/'))[1])
                os.mkdir(loc + obs_type)
            else:
                print 'Making new directory, ' + loc + obs_type
                os.mkdir(loc + obs_type)

        # Move the file to the observation type directory.
        if filename_parsed not in glob.glob(loc + obs_type + '/*'):    
            print 'Moving ' + filename_parsed + ' to directory, ' + obs_type
            shutil.move(filename, loc + obs_type + '/' + filename_parsed)
        else:
            print 'ERROR. File ' + filename_parsed + ' already in directory ' + obs_type


        # Record the final destination of the IMA files.
        if '_ima' in filename_parsed:
            # Check whether the obs_type key exists.
            # If not, initialize. Append filename to value list.
            dict_key = obs_type
            if dict_key not in ima_dict.keys():
                ima_dict[dict_key] = []

            ima_dict[dict_key].append(filename_parsed)
    

    return ima_dict


def sort_and_generate_filelist(loc):
    """

    Parameters:
        loc : string
            The location of the data base directory.

    Returns:
        nothing

    Outputs:
        text file. 'input_files.dat'
        Contains a single column of all the new IMAs for the given
        observation type directory.

    Notes:
        The old 'input_files.dat' gets overwritten! 

    """
    ima_dict = sort_files(loc)

    # First remove the old files?
    for obs_type in ima_dict.keys():
        if os.path.isfile(loc + obs_type + '/input_files.dat'):
            os.remove(loc + obs_type + '/input_files.dat')

    # Then create new files.
    for obs_type, ima_list in zip(ima_dict.keys(), ima_dict.values()):
        # sort the ima_list alphabetically
        ima_list = sorted(ima_list)

        print obs_type, ima_list
        f = open(loc + obs_type + '/input_files.dat', 'a+')
        # Put a timestamp in as a comment.
        t = time.localtime()
        time_string =  ' '.join(['#Created ', str(t[2]), str(t[1]), str(t[0]), str(t[3])+':', str(t[4])+':', str(t[5])])
        f.write(time_string + '\n')

        for ima in ima_list:
            f.write(ima + '\n')
        f.close()



if __name__=="__main__":

    # Location of IR gain data.
    loc = sys.argv[1]

    sort_and_generate_filelist(loc)


