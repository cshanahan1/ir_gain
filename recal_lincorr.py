#! /usr/bin/env python

"""Runs ``calwf3`` in current working directory and performs
    new linearity correction.
    
Author:

    C.M. Gosmeyer, Dec. 2014
    
Use:

   cd into directory containing RAWS. Then,
    
    >>> python recal_lincorr.py
    
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

def change_nlinfile_keyword(lin_file, raw_file, path_to_raw=''):
	"""Changes the 'nlinfile' keyword in the RAW file to
	the name of 'lin_file'. Checks that the linearity correction 
	is set to 'perform'.
	
	Also checks that UNITCORR set to 'OMIT'.
	
	Parameters:
	    lin_file : string
	        Name of linearity correction file.
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
	print hdr['NLINFILE']
	hdr['NLINFILE'] = lin_file
	print hdr['NLINFILE']
	
	print hdr['NLINCORR']
	hdr['NLINCORR'] = 'PERFORM'
	print hdr['NLINCORR']
	
	print hdr['UNITCORR']
	hdr['UNITCORR'] = 'OMIT'
	print hdr['UNITCORR']
	
	raw.close()

#-------------------------------------------------------------------------------#

def recal_lincorr():
    """Recalibrate with new lincorr file.
    """
    path_to_lincorr = '/grp/hst/wfc3b/cgosmeyer/Projects/IR_Gain_monitor/lincorr_files/'
    # Copy the linearity corr file.
    lin_file_orig = 'CDBS_nlincofs_spars2550_4sig3linskip0_schi.04lchi.04_lin.fits'
    shutil.copy(path_to_lincorr + lin_file_orig, lin_file_orig)    

    # Rename linearity corr file.
    lin_file = 'lincorr2014.fits'
    shutil.move(lin_file_orig, lin_file)
    
    raws = glob.glob("*raw.fits")
    # Change the keywords.
    for raw in raws:
        change_nlinfile_keyword(lin_file, raw)
    
    # Recalibrate.
    for raw in raws:
        calwf3.calwf3(raw)
        
    # Remove TRA files and linearity corr file.    
    tras = glob.glob("*tra")
    for tra in tras:
        os.remove(tra)
    os.remove(lin_file)

#-------------------------------------------------------------------------------#

if __name__ == "__main__":
    recal_lincorr()    

