#! /usr/bin/env python

"""Runs ``calwf3`` in current working directory and after
    setting UNITCORR to 'OMIT'.
    
Author:

    C.M. Gosmeyer, Jan 2015
    
Use:

   cd into directory containing RAWS. Then,
    
    >>> python recal_unitcorr.py
    
Outputs: 

    FLT files.
    IMA files.
    
Notes:
    
    TRA files are removed.

"""

import glob
import os
import shutil
from wfc3tools import calwf3
from astropy.io import fits

#-------------------------------------------------------------------------------#

def change_unitcorr_keyword(raw_file, path_to_raw=''):
	"""Changes the 'unitcorr' keyword in the RAW file to 'OMIT'.
	
	Parameters:
	    raw_file : string
	        Name of the RAW FITS file.
	    path_to_raw : string
	        Path to the raw image.
	        
	Returns:
	    nothing
	    
	Outputs:
	    nothing        
    """
	raw = fits.open(path_to_raw + raw_file, mode='update')
	hdr = raw[0].header
	print hdr['UNITCORR']
	hdr['UNITCORR'] = 'OMIT'
	print hdr['UNITCORR']
	
	print hdr['UNITCORR']
	
	raw.close()


#-------------------------------------------------------------------------------#

def recal_unitcorr():
    """Recalibrate with UNITCORR set to 'OMIT'.
    """
    raws = glob.glob("*raw.fits")
    # Change the keywords.
    for raw in raws:
        change_unitcorr_keyword(raw)
    
    # Recalibrate.
    for raw in raws:
        calwf3(raw)
        
    # Remove TRA files and linearity corr file.    
    tras = glob.glob("*tra")
    for tra in tras:
        os.remove(tra)


#-------------------------------------------------------------------------------#

if __name__ == "__main__":
    recal_unitcorr()    

