#! /usr/bin/env python

"""Creates final output for the IR gain wrapper:

Plot of average gain vs time.

Text file of average gains for each epoch.

Text file of the max,min,etc. 

All these go to outputs/date-stamped dirs.



Use:
    
    >>> python create_final_ir_gain_outputs.py

"""


import numpy as np 
import os
import pylab
import sys
import time

from astropy.io import ascii


# Only this script needs worry about finalresults/<time_stamp>

def make_timestamp_dir(dest):
	"""Creates time-stamped directory. YYYY.MM.DD

    Parameters:
        dest : string
            Path to where the time-stamp directory should be created.

    Returns:
        path_to_time_dir : string
            Path to and including the time-stamped directory.

    Outputs:
        Directory at 'dest' with a time-stamped name.
	"""
    time_tuple = time.localtime()
    year = str(time_tuple[0])
    month = str(time_tuple[1])
    day = str(time_tuple[2])

    if len(month) == 1:
        month = '0' + month
    if len(day) == 1:
        day = '0' + day        
        
    time_dir = year + '.' + month + '.' + day + '/'
    path_to_time_dir = dest + time_dir
    
    os.mkdir(path_to_time_dir)
    #print dest

	return path_to_time_dir



#------------------------------------------------------------------------------

# Read in the gainlist from data/.
def read_gainlist(loc, gainlist):
	"""

    Parameters:
        loc : string
            Location of the gainlist file.

        gainlist : string
            Name of the file containing list of gains and mjds.

    Returns:
        gain1 : array

        gain2 : array

        gain3 : array

        gain4 : array

        mjd1 : array

        mjd2 : array


    Outputs:
        nothing
	"""
    
    if os.path.isfile(loc + gainlist)
        data = ascii.read(loc + gainlist)
        gain1 = data['gain1']
        gain2 = data['gain2']
        gain3 = data['gain3']
        gain4 = data['gain4']

        mjd1 = data['mjd1']
        mjd2 = data['mjd2']

    else: 
    	print "Does NOT exist: ", loc + gainlist


	return gain1, gain2, gain3, gain4, mjd1, mjd2


#------------------------------------------------------------------------------

def get_final_gains(gain1, gain2, gain3, gain4, mjd1, mjd2):
	""" Calculates the average 'final' gain for each quad in 
	each epoch and their standard devs. Also calculate average MJD
	of each epoch.

    Parameters:

    Returns:

    Outputs:
	"""
    mjds = []
    final_gains = [[], [], [], [], [], [], [], []]

    # Initialize gain lists to be reset after each epoch.
    # These lists will be averaged and have standard deviations calculated.
    epoch_gain1 = gain1[0]
    epoch_gain2 = gain2[0]
    epoch_gain3 = gain3[0]
    epoch_gain4 = gain4[0]
    epoch_mjd = mjd1[0]
    #denom_sum = 1.
    #averages_index = 0


    for g in range(1, len(gain1)):
    	# Check MJDs. Group epochs based on whether taken more than 30 days from previous.
    	# Also check whether at the final iteration.
    	if ((float(mjd1[g]) - float(MJD1[g-1])) > 29.) or (g == len(gain1)):
    		# If ending an epoch, calcaulate the epoch's average gains and 
    		# standard deviations, as well as the average mjd.
            gain1_av = np.mean(epoch_gain1)
            gain1_stddev = np.std(epoch_gain1)
            gain2_av = np.mean(epoch_gain2)
            gain2_stddev = np.std(epoch_gain2)
            gain3_av = np.mean(epoch_gain3)
            gain3_stddev = np.std(epoch_gain3)
            gain4_av = np.mean(epoch_gain4)
            gain4_stddev = np.std(epoch_gain4)
            mjd_av = np.mean(epoch_mjd)

            print "av gain1: ", gain1_av
            print "stddev 1: ", gain1_stddev
            print "av gain2: ", gain2_av
            print "stddev 2: ", gain2_stddev
            print "av gain3: ", gain3_av
            print "stddev 3: ", gain3_stddev
            print "av gain4: ", gain4_av
            print "stddev 4: ", gain4_stddev
            print "av mjd: ", mjd_av
            
            # Append to the final gain lists.
            final_gains[0].append(gain1_av)
            final_gains[1].append(gain2_av)
            final_gains[2].append(gain3_av)
            final_gains[3].append(gain4_av)
            final_gains[4].append(gain1_stddev)
            final_gains[5].append(gain2_stddev)
            final_gains[6].append(gain4_stddev)
            final_gains[7].append(gain4_stddev)     
            mjds.append(mjd_av)       

            # Reset the lists.
            epoch_gain1 = gain1[g]
            epoch_gain2 = gain2[g]
            epoch_gain3 = gain3[g]
            epoch_gain4 = gain4[g]
            epoch_mjd = mjd1[g]

    	elif (float(mjd2[g]) - float(MJD1[g])) <= 29.:
            # If the MJD - previous MJD is less than 30 then the gains can be grouped.
            epoch_gain1.append(gain1[g])
            epoch_gain2.append(gain2[g])
            epoch_gain3.append(gain3[g])
            epoch_gain4.append(gain4[g])
            epoch_mjd.append(mjd1[g])
            #denom_sum += 1.

	return final_gains, mjds


#------------------------------------------------------------------------------

def write_stats_file(gain1, gain2, gain3, gain4, mjd1, mjd2, timestamp_dir, file_basename):
	""" Writes a file with the max, min, average, and standard dev of
	ENTIRE set of gains.

    Parameters:

    Returns:

    Outputs:
	"""
    max_gain1 = np.max(gain1)
    min_gain1 = np.min(gain)
    av_gain1 = np.mean(gain1)
    stddev_gain1 = np.std(gain1)
    
    max_gain2 = np.max(gain2)
    min_gain2 = np.min(gain2)
    av_gain2 = np.mean(gain2)
    stddev_gain2 = np.std(gain2)

    max_gain3 = np.max(gain3)
    min_gain3 = np.min(gain3)
    av_gain3 = np.mean(gain3)
    stddev_gain3 = np.std(gain3)

    max_gain4 = np.max(gain4)
    min_gain4 = np.min(gain4)
    av_gain4 = np.mean(gain4)
    stddev_gain4 = np.std(gain4)
    
    quads = ['Gain1', 'Gain2', 'Gain3', 'Gain4']
    maxes = [max_gain1, max_gain2, max_gain3, max_gain4]
    mins = [min_gain1, min_gain2, min_gain3, min_gain4]
    averages = [av_gain1, av_gain2, av_gain3, av_gain4]
    stddevs = [stddev_gain1, stddev_gain2, stddev_gain3, stddev_gain4]


    tt = {'#quad':quads, 'max':maxes, 'min':mins, 'average':averages, 'stddev':stddevs}

    ascii.write(tt, timestamp_dir + 'stats_' + file_basename + '.dat', 
                 names=['#quad', 'max', 'min', 'average', 'stddev'])


#------------------------------------------------------------------------------

def create_gain_vs_plots(gain1, gain2, gain3, gain4, mjd1, mjd2, timestamp_dir, file_basename):
    """ Plots ALL gains in each quad vs time and vs index. 

    Parameters:

    Returns:

    Outputs:

    """
    fig, axarr = pylab.subplots(2, 2)
    axarr[0, 0].scatter(gain1, np.arange(mjd1))
    axarr[0, 0].set_title('Gain 1')
    axarr[1, 0].scatter(gain2, np.arange(mjd1))
    axarr[1, 0].set_title('Gain 2')
    axarr[1, 1].scatter(gain3, np.arange(mjd1))
    axarr[1, 1].set_title('Gain 3')
    axarr[0, 1].scatter(gain4, np.arange(mjd1))
    axarr[0, 1].set_title('Gain 4')
    # Fine-tune figure; hide x ticks for top plots and y ticks for right plots.
    pylab.setp([a.get_xticklabels() for a in axarr[0, :]], visible=False)
    pylab.setp([a.get_yticklabels() for a in axarr[:, 1]], visible=False)

    #pylab.xlim(0, 2002)
    #pylab.ylim(0.8,1.2)
    pylab.xlabel('MJD', fontsize=18)

    pylab.savefig(timesamp_dir + 'gainVSindex_' + file_basename + 'png')


    fig, axarr = pylab.subplots(2, 2)
    axarr[0, 0].scatter(gain1, mjd1)
    axarr[0, 0].set_title('Gain 1')
    axarr[1, 0].scatter(gain2, mjd1)
    axarr[1, 0].set_title('Gain 2')
    axarr[1, 1].scatter(gain3, mjd1)
    axarr[1, 1].set_title('Gain 3')
    axarr[0, 1].scatter(gain4, mjd1)
    axarr[0, 1].set_title('Gain 4')
    # Fine-tune figure; hide x ticks for top plots and y ticks for right plots.
    pylab.setp([a.get_xticklabels() for a in axarr[0, :]], visible=False)
    pylab.setp([a.get_yticklabels() for a in axarr[:, 1]], visible=False)

    #pylab.xlim(0, 2002)
    #pylab.ylim(0.8,1.2)
    pylab.xlabel('MJD', fontsize=18)


    pylab.savefig(timesamp_dir + 'gainVStime_' + file_basename + 'png')    


#------------------------------------------------------------------------------

def write_finalgain_file(final_gains, mjds, timestamp_dir):
	""" Writes a file with the final averaged gain and standard deviation
	for each epoch. Basically a file of what gets plotted in 
	func:`create_finalgain_vs_time_plots`. 

    Parameters:
        final_gains : list of lists

        mjds : list

        timestamp_dir : string
    

    Returns:

    Outputs:

	"""
    av_gain1 = final_gains[0]
    av_gain2 = final_gains[1]
    av_gain3 = final_gains[2]
    av_gain4 = final_gains[3]

    stddev1 = final_gains[4]
    stddev2 = final_gains[5]
    stddev3 = final_gains[6]
    stddev4 = final_gains[7]

    tt = {'#av_gain1':av_gain1, 'stddev1':stddev1, 'av_gain2':av_gain2, 'stddev2':stddev2, \
          'av_gain3':av_gain3, 'stddev3':stddev3, 'av_gain4':av_gain4, 'stddev4':stddev4}

    ascii.write(tt, timestamp_dir + 'finalgains_' + file_basename + '.dat', 
                 names=['#av_gain1', 'stddev1', 'av_gain2', 'stddev2', \
                 'av_gain3', 'stddev3', 'av_gain4', 'stddev4'])


#------------------------------------------------------------------------------

def create_finalgain_vs_time_plots(final_gains, mjds, timestamp_dir, file_basename):
    """


    Parameters:

    Returns:

    Outputs:

    Notes:
        When plotting proceeed 1-4-2-3. Because IR quad labels are silly.    
    """

#fig = pylab.figure()

    fig, axarr = pylab.subplots(2, 2)
    axarr[0, 0].scatter(final_gains[0], mjds)
    axarr[0, 0].set_title('Gain 1')
    axarr[1, 0].scatter(final_gains[2], mjds)
    axarr[1, 0].set_title('Gain 2')
    axarr[1, 1].scatter(final_gains[3], mjds)
    axarr[1, 1].set_title('Gain 3')
    axarr[0, 1].scatter(final_gains[4], mjds)
    axarr[0, 1].set_title('Gain 4')
    # Fine-tune figure; hide x ticks for top plots and y ticks for right plots.
    pylab.setp([a.get_xticklabels() for a in axarr[0, :]], visible=False)
    pylab.setp([a.get_yticklabels() for a in axarr[:, 1]], visible=False)

    #pylab.xlim(0, 2002)
    #pylab.ylim(0.8,1.2)
    pylab.xlabel('MJD', fontsize=18)


    pylab.savefig(timesamp_dir + 'finalgains_' + file_basename + 'png')
    #pylab.savefig(path_to_automated_outputs + 'FINALgain.png')


#------------------------------------------------------------------------------
# The main controller.
#------------------------------------------------------------------------------

def create_final_ir_gain_outputs(path_to_outputs, file_basename, obs_type):
	""" Main wrapper function.

    Parameters:

    Returns:

    Outputs:

	"""
	###Make a switch for whether want to put things into automated_outputs
    path_to_automated_outputs = '/grp/hst/wfc3a/automated_outputs/cal_ir_gain/daily_outputs/'

    # String together the path to int
    path_to_inter = path_to_outputs + 'intermediates/' + obs_type + '/'
    gainlist = 'gainlist_' + file_basename  + '.dat'

    # Read in the gain values.
    gain1, gain2, gain3, gain4, mjd1, mjd2 = read_gainlist(path_to_inter, gainlist)

    # Write the overall max, min, etc. gains into a file.
    write_stats_file(gain1, gain2, gain3, gain4, mjd1, mjd2, timestamp_dir, file_basename)

    # Create plots of all gains vs time and index. 
    create_gain_vs_plots(gain1, gain2, gain3, gain4, mjd1, mjd2, timestamp_dir, file_basename)


    # Average the gains for each epoch (the 'final' gains)
    final_gains, mjds = get_final_gains(gain1, gain2, gain3, gain4, mjd1, mjd2)
    
    # Generate the timestamp directory in finalresults/<obs_type>
    timestamp_dir = make_timestamp_dir(path_to_outputs + 'finalresults/' + obs_type + '/')

    # Write the 'final' epoch gains and their standard devs into a file.
    write_finalgain_file(final_gains, mjds, timestamp_dir)

    # Create the plots of 'final' epoch gain vs time.
    create_finalgain_vs_time_plots(final_gains, mjds, timestamp_dir)





if __name__=='__main__':
	# Need take in argument for gainlist filename.

    path_to_outputs= str(sys.argv[1])
    file_basename = str(sys.argv[2])
    obs_type = str(sys.argv[3])

	create_final_ir_gain_outputs(path_to_outputs, file_basename, obs_type)


