WFC3/IR GAIN Monitor
====================

Authors: C.M. Gosmeyer (June 2015)

Last Update: 4 Feb. 2016

This document will outline the procedures for operating the WFC3/IR gain monitor.

The scripts are primarily IDL with a few python and ipython notebook scripts
mixed in. Many of the scripts were imported from B. Hilbert's IDL library. The
main gain script 'ir_gain.pro' is, in fact, based on one written by B. Hilbert.

Our purpose is to revamp B. Hilbert's IR gain script, obtain new values for the 
gain, and produce an ISR [accomplished as of Fall 2015]. Once these goals are 
met, we will continue the yearly gain monitor, publishing new values as necessary.

-----------------------------------------------------------------------------------------

1. ISRs, etc.
++++++++++++++

WFC3 ISR 2005-14: `Results of the WFC3 Thermal Vacuum Testing: IR Channel Gain`
B. Hilbert 11 April 2005
http://www.stsci.edu/hst/wfc3/documents/ISRs/WFC3-2005-14.pdf

WFC3 ISR 2008-50: `WFC3 TV3 Testing: IR Gain Results`
B. Hilbert 16 Dec. 2008
http://www.stsci.edu/hst/wfc3/documents/ISRs/WFC3-2008-50.pdf

WFC3 ISR 2015-xx: `WFC3 IR Gain from 2010 to 2015`
C. Gosmeyer and S. Baggett, in progress

WFC3 Instrument Handbook for Cycle 23, `7.9 Other Considerations for IR Imaging`
http://www.stsci.edu/hst/wfc3/documents/handbooks/currentIHB/c07_ir10.html

-----------------------------------------------------------------------------------------


2. Programs
+++++++++++++


11930 "IR Gain Measurement" PI Bryan Hilbert.
http://www.stsci.edu/hst/phase2-public/11930.pdf

12350 "IR Gain Monitor" PI Bryan Hilbert.
http://www.stsci.edu/hst/phase2-public/12350.pdf

12697 "IR Gain Monitor" PI Bryan Hilbert.
http://www.stsci.edu/hst/phase2-public/12697.pdf

13080 "IR Gain Monitor" PI Bryan Hilbert.
http://www.stsci.edu/hst/phase2-public/13080.pdf

13564 "IR Gain Monitor" PI Bryan Hilbert.
http://www.stsci.edu/hst/phase2-public/13464.pdf

14010 "WFC3 IR Gain Monitor" PI Catherine Gosmeyer.
http://www.stsci.edu/hst/phase2-public/14010.pdf

14376 "WFC3 IR Gain Monitor" PI Catherine Gosmeyer.
http://www.stsci.edu/hst/phase2-public/14376.pdf

-----------------------------------------------------------------------------------------


3. Data
+++++++++

16 identical Visits/year, one half observed every six months.
New addition to Cycle 23: Trailing darks at end of each Visit, whose
purpose is to help us measure 'burped' out persistence from flats,
if any.

In each Visit,

Label	     Target	Filter	SAMP-SEQ	NSAMP (# reads)	Exp. Time (s)
------------------------------------------------------------------------------
Dark	     DARK-NM	BLANK	SPARS10		9		82.940
Warm-up      TUNGSTEN	F126N	SPARS10	        6	        52.937
(short) Flat
Gain (long)  TUNGSTEN	F126N	SPARS50	        13	        602.938
Flat
Persistence  DARK      BLANK  SPARS25	      15             352.940
Dark
-----------------------------------------------------------------------------------------


4. Initial Setup
+++++++++++++++++

Since you are reading this, I expect you've gotten as far as cloning the
'detectors' repo.  Now, while you are in the subdirectory 'scripts/ir_gain/'
run the initialization script, which will set up all necessary paths and
directories. Just follow the on-screen prompts.

>>> python init_setup_ir_gain.py

Now you should have the directories
<given path>/outputs
<given path>/outputs/finalresults
<given path>/outputs/intermediates
<given path>/data/newdata

The file
<given path>/data/newdata/makefile

And a modified
scripts/ir_gain/set_paths.pro

Now you are ready to run the IR gain suite. 


-----------------------------------------------------------------------------------------

5. Procedure
+++++++++++++

i. GET DATA.

   Retrieve RAWs from MAST into 'data/newdata'.
   Go to 'data/newdata/'.
   Do a quick look on images for obvious defects. 


ii. CALIBRATE and SORT.

    To calibrate with unitcorr set to 'omit', you'll need run 'recal_unitcorr.py'.
    The makefile in data/newdata will copy the latest version from detector_tools
    and run it over all the RAWs.
    In the same step it will run 'sort_and_generate_filelist.py' to sort
    the data and make a file list of new files that the gain calculation
    script will read in.
    In the 'data/newdata/' directory just do
    
    >>> make newdata

    Note that if you wanted to, say, re-retrieve and recalibrate everything,
    just place it all in this directory.  The make command will sort everything 
    to where it needs to be.


iii. FIND GAIN.

    If you have new data, you will want to run the full IR gain wrapper.

    idIDL> run_ir_gain, 'new', do_pers=1, do_lt_ratio=1

    See the script's documentation for additional options. If you are not
    running on data you just calibrated in the directory 'newdata', you can
    run on just a subset of the observation types.  For example,

    IDL> run_ir_gain, obs_types=['flat_short'] 

    There are three kinds of outputs that will be generated in a full
    run of the wrapper.  

    1. Intermediates. 

    The outputs generated in 'outputs/intermediates/<obstype>/' include
    
    gainlist_<file_basename>.dat -- If this already exists, it will be
        appended to. Note that a new 'gainlist' is generated for each  
        combination of processing options listed in 'file_basename'. i.e., 
        'ipc_maskbad' (by default the gain calculation is IPC corrected and
        bad pixels masked).
    mean_var_plots -- Plots of mean vs variance for each ramp pair.
    mean_var_files -- Text files listing the means and variances for each ramp
        pair.   
    
    2. Finalresults.

    In 'outputs/finalresults/' will be generated the file 

    finalresults_infile.dat -- This file lists the processing 
        options selected for the run, so that the filenames can be captured
        in the final plots discussed in Section iv. 

    3. Persistence.

    If the 'do_pers' is set on, the following outputs will be generated 
    in 'outputs/persistence/<obstype>/':

    ratiomedians.dat -- If this already exists, it will be appended to.
        It contains the median of all the ratios in each Visit of each 
        Epoch.
    <time stamped directory>/median_ratio_vs_time_plots -- Plots of
        median of ratios vs time.
    <time stamped directory>/ratios_png -- PNG images of the final read
        ratios to search for persistence.
    
    If the 'do_lt_ratios' is set on, the following outputs will be 
    generated in 'outputs/persistence/dark_leading_and_trailing/':

    <time stamped directory>/ratios_flt -- Ratio FLT images of the 
        first and last reads to search for persistence.
    <time stamped directory>/ratios_png -- Same as the FLTs, but 
        in PNG format.    

    * Note *
    If you should find data that is anamolous (persistence, etc), 
    place it in an 'outliers' subdirectory.


iv. GENERATE PLOTS.

    Once the IR gain has been calculated, just do

    >>> python create_final_ir_gain_outputs.py 

    Plots will be generated in timestamped directories in 'outputs/finalresults/
    <obstype>/'. By default, the plots will be copied to 'automated_outputs/
    ir_gain/daily_outputs/' for display on website. To turn this off, run as

    >>> python create_final_ir_gain_outputs.py --a 'false'

    NOTE that only the nominal plots of obstype='flat_long' will be copied
    to automated_outputs. 

    Additionally, the script by default reads in file 
    'finalresults/finalresults_infile.dat' that was generated by 
    'run_ir_gain.pro'.
    To run just with the nominal settings filebasenames=['ipc_maskbad'] and 
    obstypes=['flat_long'], do

    >>> python create_final_ir_gain_outputs.py --n 'true'

    The final outputs in the timestamped directory include 

    gainVStime_<file_basename>.png -- Individual pair gains vs time in 
        years.
    gainVSindex_<file_basename>.png -- Individual pair gains vs index.
    epochgainsVStime_<file_basename>.png -- Epoch-averaged gains vs time 
        in years.
    epochgainsVStime_<file_basename>.dat -- List of epoch-averaged 
        gains/quad and their standard deviations.
    stats_<file_basename>.dat -- Lists the max, min, average, and standard 
        deviations of the ENTIRE list of gains/quad.



5.a Locations
--------------

Scripts can be found in the 'detectors' WFC3 Quick Look repo 
detectors/scripts/ir_gain

Data, documents, and LOG.txt can be found at 
/grp/hst/wfc3b/cgosmeyer/Projects/IR_Gain_monitor/data/



5.b Scripts for a Nominal Run
------------------------------

Located in 'detectors/scripts/ir_gain/'.

See each script's doc-string for instructions on running and its outputs.

Note that most of procedures in 'detectors/scripts/ir_gain' repo were 
copied from B. Hilbert's IDL library, as they are used in 'ir_gain.pro'. 
If a procedure is not listed here, it is likely Hilbert's.

create_final_ir_gain_outputs.py
    Generates output text files and plots showing gains trends with 
    time.

ir_gain.pro (based on B. Hilbert's 'ir_gain_bhilbert.pro')
    Runs corrections, masking, and finally the mean-variance method on a 
    pair of flat ramps to obtain values of the 4 quadrants' gains.

ir_gain_back2back.pro
    Wrapper for 'ir_gain.pro'. Matches pairs of flats taken within 24 hours
    of each other and runs them through ir_gain.pro.

ratio_lead_trail_darks.pro
    Ratios the first and last reads of the trailing darks over the 
    same-visit leading darks. (Only works on data from or after Cycle 23
    Program 14376.)

ratio_ramps.pro
    Ratios all read of all flats in cwd to an inputted flat. Purpose is to
    search for signs of persistence.

recal_unitcorr.py
    Runs calwf3 on all RAWS in cwd, setting unitcorr to 'omit'. 

run_ir_gain.pro
    The primary wrapper for running 'ir_gain_back2back.pro' and 
    'ramp_ratios.pro' over all observation types, and 
    'ratio_lead_trail_darks.pro' over all leading and trailing dark pairs.

5.c Scripts for Testing
------------------------

Most of these create plots and run tests for ISRS, posters, presentations, etc.


gainvstime_oplot_lincorrs.pro
    Overplots gain value vs MJD for both 2008 and 2014 non-linearity corrections.

ir_gain_oplot.pro
    Basically 'ir_gain.pro', but takes in two different pairs and over plots 
    the line-fits of their mean-variance plots.

recal_lincorr.py
    Runs calwf3 on any RAWs in cwd, changing the non-linearity correction to
    the 2014 file and setting unitcorr to 'omit'.

rmreads_wrapper_gain.pro
    Removes given number of reads from all RAWs in cwd. Purpose is to see what
    effect a lower number of reads has on the gain values, in case of unknown
    persistance, etc.
    Plots should be generated with 'plot_gain_vs_numreads.ipynb'.


5.d Notebooks for Plotting
---------------------------

plot_final_gain.ipynb
    Plots final gain values for all quads vs MJD on a single panel.

plot_gain_vs_numreads.ipynb
    Plots average, median, min, and max gain vs number of reads used. To be run
    in tandem with 'rmreads_wrapper_gain.pro'.


-----------------------------------------------------------------------------------------

6. History
+++++++++++

28 Nov 2014 -- Pushed 'ir_cycle18_gain.pro' to QL Repo detectors.
            -- Renamed to 'ir_gain.pro'.

2 Dec 2014 -- Retrieved all IR gain data (FLTs, RAWs, and IMAs) from MAST.

26 Jan. 2015 -- Recalibrated IR gain nsamp=7 and 14 data with unitcorr='omit'.
