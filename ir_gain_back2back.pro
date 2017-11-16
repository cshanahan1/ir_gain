pro ir_gain_back2back, obs_type, $
                       out_mark=out_mark, $
                       matchdayrange=matchdayrange, $
                       use_glob_input=use_glob_input, $
                       use_newlincorr=use_newlincorr, $
                       single_gain_files=single_gain_files, $
                       single_gain_plots=single_gain_plots, $
                       sumdiff_fits=sumdiff_fits, $
                       clip_cnts=clip_cnts, $
                       boxsize=boxsize, $
                       b_hilbert=b_hilbert, $
                       file_basename=file_basename

;+
; NAME:
;      IR_GAIN_BACK2BACK
;
; PURPOSE: 
;      Finds gain for every pair of files (paired back to back in time)
;      located in directory.
;
; INPUTS: 
;      obs_type = type of observation. Technically the location of the IMAs.
;          'flat_short'
;          'flat_long'
;          'dark_leading'
;          'dark_trailing'
;      out_mark = string to be appended to finalresults directory after
;        time stamp.
;      matchdayrange = Float of how many days over which to search for 
;        an image pair. Default of 1.
;      use_glob_input = Switch on to glob the directory for IMAs.
;          By default input IMAs are read from 'input_files.dat'.
;      use_newlincorr = Switch on to use the new linearity correction.
;      single_gain_files = Switch on to produce text file containing
;        gain values of each quadrant. (Needs be on when using B. 
;        Hilbert's original ir_gain script.  * Deprecated for now. *
;        If want to use B. Hilbert's script, will need also set the 
;        keyword 'b_hilbert'.
;      single_gain_plots = Switch on to produce plots of mean vs 
;        variance fitted with line.
;      sumdiff_fits = Switch on to produce FITS files of sum and diff
;        of the two (post-corrected) infiles.
;      boxsize = Number of pixels wide to make grid divisions. 
;         Default of 20, which makes 25x25 grid in each quadrant.
;         Setting to 100 makes a 5x5 grid.
;      b_hilbert = Set on to use B. Hilbert's gain script. Must be used in
;         conjunction with 'single_gain_files' set on. 
;      file_basename = To be output. Contains the string uniquely identifying
;         the settings of the gain run.
;
; OUTPUTS:   
;      text file. gainlist_<ipc>_<maskbad>.dat
;      text file. statistics_<ipc>_<maskbad>.dat  
;      text file. FINALgain.dat
;      PDF plot. gain_vs_time_<ipc>_<maskbad>.pdf
;      PDF plot. gain_vs_index_<ipc>_<maskbad>.pdf 
;      PDF plot. FINALgain.pdf
;
; EXAMPLE: 
;      IDL> ir_gain_back2back, '14nsamp', out_mark='old_lincorr', single_gain_plots='y'
;
; MODIFICATION HISTORY:
;     18 Dec. 2014: Written by C.M. Gosmeyer.
;
;-  

  ;; Set default values.
  SetDefaultValue, matchdayrange, 1.
  SetDefaultValue, out_mark, ''

  ;; Get the base path names from set_paths.pro.
  set_paths, path_to_data, path_to_outputs, path_to_scripts

  ;; Check whether using new linearity correction. Append to 'obs_type' if so.
  if keyword_set(use_newlincorr) then begin
      obs_type = obs_type + '/new_lincorr'
  endif

  ;; Directory name for outputs.
  out_loc = path_to_outputs + 'intermediates/' + obs_type + '/'
  print, out_loc
  
  ;; Create the output directory if it does not exist.  
  if file_test(out_loc) eq 0 then file_mkdir, out_loc

  ;; Set up location of the input IMA files.
  data_loc = path_to_data + obs_type + '/' 
  print, data_loc

  ;; Set up infile lists
  ;; If user sets the keyword, then does a glob over directory for IMAs.
  if keyword_set(use_glob_input) then begin
      print, "Reading files from glob of " + data_loc
      infile_list = file_search(data_loc+'*ima.fits')
  ;; Otherwise read in 'input_files.dat' for the list of IMAs to use.
  endif else begin 
      print, "Reading files from input_files.dat in ", data_loc
      readcol, data_loc+ 'input_files.dat', infile_list_raw, format='a', comment='#'
      infile_list = strarr((size(infile_list_raw))[3])
      count = 0
      foreach infile, infile_list_raw do begin
          infile_list[count] = data_loc + infile
          count += 1
      endforeach
      help, infile_list_raw
      print, infile_list_raw
      help, infile_list
      print, infile_list
  endelse

  size_array = (size(infile_list))[3]-1
  
  gain_array = make_array(20, size_array, /STRING)

  count = 0L

  for i=1, size_array, 2 do begin
      infile1 = infile_list[i-1]
      infile2 = infile_list[i]
      
      print, " "
      print, "Infile pair: "
      print, infile1, " ", infile2

      ;; Retrieve MJDs from infile1 and infile2
      hdr1 = headfits(infile1, ext=0)
      mjd1 =  sxpar(hdr1, 'EXPSTART')
      mjd1 = string(mjd1)

      hdr2 = headfits(infile2, ext=0)
      mjd2 =  sxpar(hdr2, 'EXPSTART')
      mjd2 = string(mjd2)
      
      ;; Only compare observations taken within 'matchdayrange' days of each other.
      if (abs(float(mjd1) - float(mjd2)) le matchdayrange) then begin
        gain_single_array = ir_gain(infile1, infile2, $
                            out_loc=out_loc, $  
                            dark=dark, $
                            binn=binn, $
                            do_ipc='y', $
                            do_maskbad='y', $
                            single_gain_files=single_gain_files, $
                            single_gain_plots=single_gain_plots, $
                            sumdiff_fits=sumdiff_fits, $
                            clip_cnts=clip_cnts, $
                            boxsize=boxsize)      
      
        file_basename = gain_single_array[0]
                                                 
        if keyword_set(single_gain_files) and keyword_set(b_hilbert) then begin
          ;; Obtain gains from *20x20boxes.txt.
          gain_file = ''
          line = ''
          mean_var_lists_dir = out_loc + 'mean_var_lists/' + strmid(file_basename, 1, strlen(file_basename)) + '/'
          mean_var_file = mean_var_lists_dir + strmid(infile1, strlen(infile1)-18, 13) + '_' + strmid(infile2, strlen(infile2)-18, 13) + file_basename + '_means_variances.txt'
          openr, 1, mean_var_file
          while not eof(1) do begin
            readf, 1, line
            gain_file = [gain_file, line]
          endwhile
          close, 1
          ;file_delete, mean_var_file
        
          ;; append relevant info to gain_array
          gain1 = (strsplit(gain_file[5], /EXTRACT, ' '))[2]
          uncert1 = (strsplit(gain_file[5], /EXTRACT, ' '))[3]
          gain2 = (strsplit(gain_file[6], /EXTRACT, ' '))[2]
          uncert2 = (strsplit(gain_file[6], /EXTRACT, ' '))[3] 
          gain3 = (strsplit(gain_file[7], /EXTRACT, ' '))[2]
          uncert3 = (strsplit(gain_file[7], /EXTRACT, ' '))[3]
          gain4 = (strsplit(gain_file[8], /EXTRACT, ' '))[2]
          uncert4 = (strsplit(gain_file[8], /EXTRACT, ' '))[3]
          ;; need to put the mean and var in starting in 'ir_gain.pro'
       
        endif else begin 
          ;; Just obtain gains from array.
          gain1 = string(gain_single_array[1])
          uncert1 = string(gain_single_array[5])
          gain2 = string(gain_single_array[3])
          uncert2 = string(gain_single_array[7])
          gain3 = string(gain_single_array[4])
          uncert3 = string(gain_single_array[8])
          gain4 = string(gain_single_array[2])
          uncert4 = string(gain_single_array[6])
          stddev_mean1 = string(gain_single_array[9])
          stddev_mean2 = string(gain_single_array[11])
          stddev_mean3 = string(gain_single_array[12])
          stddev_mean4 = string(gain_single_array[10])
          stddev_var1 = string(gain_single_array[13])
          stddev_var2 = string(gain_single_array[15])
          stddev_var3 = string(gain_single_array[16])
          stddev_var4 = string(gain_single_array[14])
        endelse 
        
        ;; Ensure that infile names do not contain path name when writing into file.
        infile1_split = strsplit(infile1, '/', /extract)
        if (n_elements(infile1_split) gt 1) then begin 
            infile1_cut = infile1_split[n_elements(infile1_split)-1]
        endif else begin
            infile1_cut = infile1
        endelse
             
        infile2_split = strsplit(infile2, '/', /extract)
        if (n_elements(infile2_split) gt 1) then begin
            infile2_cut = infile2_split[n_elements(infile2_split)-1]
        endif else begin
            infile2_cut = infile2
        endelse
        
        gain_array[*,count] = [infile1_cut, infile2_cut, gain1, uncert1, gain2, $
                               uncert2, gain3, uncert3, gain4, uncert4, mjd1, mjd2, $
                               stddev_mean1, stddev_mean2, stddev_mean3, stddev_mean4, $
                               stddev_var1, stddev_var2, stddev_var3, stddev_var4]
        count += 1      
      endif
      
      ; Deal with case where there is an odd number of files?
  endfor

      
  ;; Print all gains to master gain file.
  help, gain_array
  print, gain_array
    
   master_file_name = out_loc + 'gainlist' + file_basename + '.dat'  

  ;; If the master gain file doesn't exist, create. 
  if file_test(master_file_name) eq 0 then begin
      openw, 2, master_file_name, width=270
      printf, 2, ['#infile1', 'infile2', 'gain1', 'uncert1', 'gain2', 'uncert2', 'gain3', $
                  'uncert3', 'gain4', 'uncert4', 'mjd1', 'mjd2', 'stdv_mn1', $
                  'stdv_mn2', 'stdv_mn3', 'stdv_mn4', 'stdv_vr1', 'stdv_vr2', 'stdv_vr3', 'stdv_vr4'], $ 
      format='(a20,a20,a12,a12,a12,a12,a12,a12,a12,a12,a18,a18,a12,a12,a12,a12,a12,a12,a12,a12)'
      for line=0, size_array-1 do begin
          printf, 2, gain_array[*, line], format='(a20,a20,a12,a12,a12,a12,a12,a12,a12,a12,a18,a18,a12,a12,a12,a12,a12,a12,a12,a12)'
      endfor
      close, 2

  ;; If the master gain file does exist, append. 
  endif else begin
      print, "Appending gainlist to " + master_file_name
      openu, 2, master_file_name, /APPEND, width=270
      for line=0, size_array-1 do begin
          printf, 2, gain_array[*, line], format='(a20,a20,a12,a12,a12,a12,a12,a12,a12,a12,a18,a18,a12,a12,a12,a12,a12,a12,a12,a12)'
      endfor
      close, 2
  endelse

  
  
end