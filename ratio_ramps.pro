PRO ratio_ramps, ramp_num, $
                 obs_type=obs_type, $
                 use_glob_input=use_glob_input, $
                 do_fits=do_fits, $
                 do_plots=do_plots, $
                 do_pngs=do_pngs, $
                 pver_write=over_write

;+
; NAME:
;      RATIO_RAMPS
;
; PURPOSE: 
;      Takes ratio of first read of every dark or int-flat
;      to a dark/int-flat taken early in program.
;      Creates new 'ratio' image from which we can 
;      check for persistance.
;
; INPUTS: 
;      ramp_num = Number of the ramp, 0 to N in directory, you want to ratio 
;          all others to. Ramp number in first few visits is recommended.
;      obs_type = type of observation. Technically the location of the IMAs.
;          'flat_short'
;          'flat_long'
;          'dark_leading'
;          'dark_trailing'
;      use_glob_input = Switch on to glob the directory for IMAs.
;          By default input IMAs are read from 'input_files.dat'.
;      do_fits = Set equal to 'y' to output the ratio FITS.
;      do_plots = Set to 'n' to turn off. On by default.
;      do_pngs = Set to 'y' to create PNGs of the first ramps ratios.
;      over_write = Set to 'y' to overwrite already-existing FITS or
;          PNG ratios.
;
; OUTPUTS:   
;      Outputted into a time-stamped directory located in 'persistence/<obs_type>/'.
;      If do_fits is set, 
;      FITS files. Ratio of each extension: 
;          'ratio_<rootname>_ima.fits'
;
;      If do_pngs is set,
;      PNG files. Ratio of each extension: 
;          'ratio_<rootname>_ima.png'
;
;      If do_plots is set,
;      PDF and PNG plots. Median of ratio vs time for each extension: 
;          'median_ratio_vs_time_<ramp number>.pdf'   
;          'median_ratio_vs_time_<ramp number>.png'   
;
; EXAMPLE: 
;      > cd, 10nsamp
;      idl> ratio_ramps, 1, do_fits='y'
;
; MODIFICATION HISTORY:
;     11 May 2015: Written by C.M. Gosmeyer.
;-  

  ;; Set defaults.
  SetDefaultValue, do_plots, 'y'

  ;; Get the base path names from set_paths.pro.
  set_paths, path_to_data, path_to_outputs, path_to_scripts

  ;; Set up location of the input IMA files.
  data_loc = path_to_data + obs_type + '/' 
  print, data_loc

  ;; Generate name of timestamp directory.
  tstamp = cgtimestamp(9)  ;; 9: _02072010_10:56:37
  ;; Format tstamp
  tstamp_short = strmid(tstamp, 1, strlen(tstamp))
  tstamp_dotted = strmid(tstamp_short, 0, 2) + '.' + $
                  strmid(tstamp_short, 2, 2) + '.' + $
                  strmid(tstamp_short, 4, 4) + $
                  strjoin(strsplit(strmid(tstamp_short, 8, 9), ':', /extract), '.')
  timestamp_dir = strcompress('/' + tstamp_dotted + '/', /remove_all)    

  ;; Set up the location of the output files.
  out_loc = path_to_outputs + 'persistence/' + obs_type + timestamp_dir ;;'/ramp_ratios/'
  ;; Create the output directory if it does not exist.  
  if file_test(out_loc) eq 0 then file_mkdir, out_loc

  ;; Change ramp_num to long.
  ramp_num = long(ramp_num)

  ;; Set up infile lists
  ;; If user sets the keyword, then does a glob over directory for IMAs.
  if keyword_set(use_glob_input) then begin
      print, "Reading files from glob of " + data_loc
      infile_list = file_search(data_loc+'*ima.fits')
      ;; Set the ramp that will be used to ratio the others to. 
      file0 = infile_list[ramp_num]  

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
      help, infile_list
      print, infile_list

      ;; Will still need to glob in order to find the name of <ramp_num> file, so 
      ;; to consistently use the same ratio ramp of the previous files.
      ;; (Assuming I use the same ratio ramp always. If not, it's my own fault
      ;; for not double checking the file names of the previous ratio files.)
      total_infile_list = file_search(data_loc+'*ima.fits')
      file0 = total_infile_list[ramp_num]  
      print, "The ratio'ing ramp is: ", file0
  endelse

  ;; Get the rootname of the 0th file.
  rootname = strcompress(strmid(file0, strlen(file0)-18, strlen(file0)-9), /remove_all)

  ;; Read in the ramps of the ratioing ramp.
  file0_data = ramp_read(file0)
  help, file0_data

  ;; Find the number of reads in the ratioing ramp.
  nreads = n_elements(file0_data[*,0,0])
  help, nreads
  print, nreads

  ;; Initialize array to store file name, exposure starts, and flux medians.
  median_array = make_array(nreads + 2, n_elements(infile_list), /STRING)
  ;medians = make_array(nreads-1, n_elements(infile_list))
  ;expstarts = make_array(n_elements(infile_list))

  ;; Initialize count of ramps.
  i=0

  ;; Loop over each ramp and create a ratio'd image. 
  foreach file, infile_list do begin
      ;; Read in ramps.
      file_data = ramp_read(file)
    
      ;; Create base name for output ratio FITS files.
      file_trunc = strmid(file, strlen(file)-18)
      ratio_name = out_loc + 'ratio_'+file_trunc
    
      ;; Ratio'd ramps will be written into FITS file.
      if keyword_set(do_fits) then fits_open, ratio_name, f1, /write    
    
      ;; Get the expstart, put into array.
      header = headfits(file, ext=0)
      expstart = sxpar(header,'EXPSTART') 
      ;expstarts[i] = expstart
      median_array[0,i] = file_trunc
      median_array[1,i] = expstart
    
      ;; Take ratio of each read.
      for r=1, nreads-1 do begin
          ratio = file_data[r,*,*] / file0_data[r,*,*]
          help, ratio
        
          ;; If do_pngs set on, make the final ratio a PNG.
          if (keyword_set(do_pngs)) and (r eq nreads-1) then begin
              ;; Create base name for output ratio PNG files.
              ratio_name = strcompress(out_loc + 'ratio_'+string(r)+'_'+file_trunc, /remove_all)  
              make_ratio_png, reform(ratio[0,*,*]), ratio_name
          endif
        
          ;; If do_fits set on, read into FITS extension.
          if keyword_set(do_fits) then fits_write, f1, reform(ratio[0,*,*])
        
          ;; Get the median of the ratio
          median_ratio = median(ratio)
          ;medians[r-1,i] = median_ratio
          median_array[r+1,i] = median_ratio   
        
          print, file, expstart, median_ratio
      endfor
    
      ;; If do_fits set on, close the opened output FITS file.
      if keyword_set(do_fits) then fits_close, f1
      i += 1
    
  endforeach


  ;; maybe work on later; for now just re-create all median ratios at each run

  ;; If the median master file doesn't exist, create.
  ;; Will contain the medians of the ratios and the exp start times.
  ;; Each column is a median or expstart of a Visit (1-8). 
  ;; Number of rows is number of epochs.
  size_array = n_elements(infile_list)
  master_file_name = path_to_outputs + 'persistence/' + obs_type + '/ratiomedians.dat'  

  ;; Will need different numbers of columns for different numbers of reads.
  case obs_type of
      'flat_long' : begin
          col_names = ['#file', 'expstart', $
                  'med1', 'med2', 'med3', 'med4', 'med5', 'med6', 'med7', 'med8', $
                  'med9', 'med10', 'med11', 'med12', 'med13']
          cal_format = '(a20,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12)'
          out_format = 'A,F,F,F,F,F,F,F,F,F,F,F,F,F'
          end
      'flat_short' : begin
          col_names = ['#file', 'expstart', $
                  'med1', 'med2', 'med3', 'med4', 'med5', 'med6']
          cal_format = '(a20,a12,a12,a12,a12,a12,a12,a12)'
          out_format = 'A,F,F,F,F,F,F'
          end
      'dark_leading' : begin
          col_names = ['#file', 'expstart', $
                  'med1', 'med2', 'med3', 'med4', 'med5', 'med6', 'med7', 'med8', 'med9']
          cal_format = '(a20,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12)'
          out_format = 'A,F,F,F,F,F,F,F,F,F'
          end
      'dark_trailing' : begin
          col_names = ['#file', 'expstart', $
                  'med1', 'med2', 'med3', 'med4', 'med5', 'med6', 'med7', 'med8', $
                  'med9', 'med10', 'med11', 'med12', 'med13', 'med14', 'med15']
          cal_format = '(a20,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12,a12)'
          out_format = 'A,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F'
          end
  endcase 

  if file_test(master_file_name) eq 0 then begin
      openw, 2, master_file_name, width=270
      printf, 2, col_names, $ 
      format = col_format
      for line=0, size_array-1 do begin
          printf, 2, median_array[*, line], format = col_format
      endfor
      close, 2

  ;; If the master gain file does exist, append. 
  endif else begin
      print, "Appending gainlist to " + master_file_name
      openu, 2, master_file_name, /APPEND, width=270
      for line=0, size_array-1 do begin
          printf, 2, median_array[*, line], format = col_format
      endfor
      close, 2
  endelse


  ;; If do_plots set on, plot the median vs filename (corresponding to date)
  if do_plots eq 'y' then begin

  ;; Read in all medians from 'persistence/<obs_type>/ratiomedians.dat'
  case obs_type of
      'flat_long' : begin
          readcol, master_file_name, files, exptimes, med1, med2, med3, med4, med5, med6, $
              med7, med8, med9, med10, med11, med12, med13, $
              FORMAT=out_format
          median_array = [[files], [exptimes], [med1], [med2], [med3], [med4], [med5], $
                         [med6], [med7], [med8], [med9], [med10], [med11], [med12], [med13]]
          end
      'flat_short' : begin
          readcol, master_file_name, files, exptimes, med1, med2, med3, med4, med5, med6, $
              FORMAT=out_format
          median_array = [[files], [exptimes], [med1], [med2], [med3], [med4], [med5], [med6]]
          end
      'dark_leading' : begin
          readcol, master_file_name, files, exptimes, med1, med2, med3, med4, med5, med6, $
              med7, med8, med9, $
              FORMAT=out_format
          median_array = [[files], [exptimes], [med1], [med2], [med3], [med4], [med5], $
                         [med6], [med7], [med8], [med9]]
          end
      'dark_trailing' : begin
          readcol, master_file_name, files, exptimes, med1, med2, med3, med4, med5, med6, $
              med7, med8, med9, med10, med11, med12, med13, med14, med15, $
              FORMAT=out_format
          median_array = [[files], [exptimes], [med1], [med2], [med3], [med4], [med5], $
                         [med6], [med7], [med8], [med9], [med10], [med11], [med12], $
                         [med13], [med14], [med15]]
          end
  endcase 


  help, median_array
  print, median_array

  ;; Set size of the symbols
  symsize=2.5

  for r=1, nreads-1 do begin    
      print, r, string(r)
      help, r

      psname = out_loc + 'median_ratio_vs_time_' + strcompress(string(r-1), /remove_all) + '.ps'

      if (strmatch(out_loc, '*flat*', /FOLD_CASE)) then yran = [0.95, 1.03]
      if (strmatch(out_loc, '*dark_leading*', /FOLD_CASE)) then yran = [-0.05, 0.1]
      if (strmatch(out_loc, '*dark_trailing*', /FOLD_CASE)) then yran = [-0.1, 2.0]

	    set_plot, 'ps'
	    !p.font=0
	    !p.thick=4
	    !x.thick=3
	    !y.thick=3
	    device, isolatin1=1, $
	            helvetica=1, $
	            /landscape, $
	            /inch, $
	            /color, $
              filename = psname
      !p.multi=0
      plot, float(median_array[*,1]), float(median_array[*,r+1]), $
            xtit='Exposure Start [MJD]', $
            ytit='Median of Ratio/Visit [flat /' + rootname + ']', $ 
            title = 'Read ' + strcompress(string(r), /remove_all),  $
            xtickformat='(F7.1)', $
            charsize=1.6, $
            yrange = yran, $
            xrange=[55450, 57500], $
            ystyle=1, $
            xstyle=1,$
            /nodata

      oplot, (median_array[*,1])[[0,7,15,23,31,39,47,55,63,71,79]], $
            (median_array[*,r+1])[[0,7,15,23,31,39,47,55,63,71,79]], $
            psym=4, color=cgcolor('red'), symsize=symsize
      oplot, (median_array[*,1])[[1,8,16,24,32,40,48,56,64,72,80]], $
            (median_array[*,r+1])[[1,8,16,24,32,40,48,56,64,72,80]], $
            psym=4, color=cgcolor('orange'), symsize=symsize
      oplot, (median_array[*,1])[[2,9,17,25,33,41,49,57,65,73,81]], $
            (median_array[*,r+1])[[2,9,17,25,33,41,49,57,65,73,81]], $
            psym=4, color=cgcolor('yellow'), symsize=symsize
      oplot, (median_array[*,1])[[3,10,18,26,34,42,50,58,66,74,82]], $
            (median_array[*,r+1])[[3,10,18,26,34,42,50,58,66,74,82]], $
            psym=4, color=cgcolor('green'), symsize=symsize
      oplot, (median_array[*,1])[[4,11,19,27,35,43,51,59,67,75,83]], $
            (median_array[*,r+1])[[4,11,19,27,35,43,51,59,67,74,83]], $
            psym=4, color=cgcolor('blue'), symsize=symsize
      oplot, (median_array[*,1])[[5,12,20,28,36,44,52,60,68,76,84]], $
            (median_array[*,r+1])[[5,12,20,28,36,44,52,60,68,76,84]], $
            psym=4, color=cgcolor('purple'), symsize=symsize
      oplot, (median_array[*,1])[[6,13,21,29,37,45,53,61,69,77,84]], $
            (median_array[*,r+1])[[6,13,21,29,37,45,53,61,69,77,84]], $
            psym=4, color=cgcolor('magenta'), symsize=symsize
      oplot, (median_array[*,1])[[7,14,22,30,38,46,54,62,70,78,85]], $
            (median_array[*,r+1])[[7,14,22,30,38,46,54,62,70,78,85]], $
            psym=4, color=cgcolor('black'), symsize=symsize
      
      if (strmatch(out_loc, '*flat*', /FOLD_CASE)) then begin
          xyouts, 56800, 1.025, 'visit 1', color=cgcolor('red'), charsize=1.4
          xyouts, 56800, 1.020, 'visit 2', color=cgcolor('orange'), charsize=1.4
          xyouts, 56800, 1.015, 'visit 3', color=cgcolor('yellow'), charsize=1.4
          xyouts, 56800, 1.010, 'visit 4', color=cgcolor('green'), charsize=1.4
          xyouts, 57100, 1.025, 'visit 5', color=cgcolor('blue'), charsize=1.4
          xyouts, 57100, 1.020, 'visit 6', color=cgcolor('purple'), charsize=1.4
          xyouts, 57100, 1.015, 'visit 7', color=cgcolor('magenta'), charsize=1.4
          xyouts, 57100, 1.010, 'visit 8', color=cgcolor('black'), charsize=1.4
      endif
      if (strmatch(out_loc, '*dark_leading*', /FOLD_CASE)) then begin
          xyouts, 56800, 0.088, 'visit 1', color=cgcolor('red'), charsize=1.4
          xyouts, 56800, 0.078, 'visit 2', color=cgcolor('orange'), charsize=1.4
          xyouts, 56800, 0.068, 'visit 3', color=cgcolor('yellow'), charsize=1.4
          xyouts, 56800, 0.058, 'visit 4', color=cgcolor('green'), charsize=1.4
          xyouts, 57100, 0.088, 'visit 5', color=cgcolor('blue'), charsize=1.4
          xyouts, 57100, 0.078, 'visit 6', color=cgcolor('purple'), charsize=1.4
          xyouts, 57100, 0.068, 'visit 7', color=cgcolor('magenta'), charsize=1.4
          xyouts, 57100, 0.058, 'visit 8', color=cgcolor('black'), charsize=1.4
      endif
      if (strmatch(out_loc, '*dark_trailing*', /FOLD_CASE)) then begin
          xyouts, 56800, 1.94, 'visit 1', color=cgcolor('red'), charsize=1.4
          xyouts, 56800, 1.85, 'visit 2', color=cgcolor('orange'), charsize=1.4
          xyouts, 56800, 1.76, 'visit 3', color=cgcolor('yellow'), charsize=1.4
          xyouts, 56800, 1.67, 'visit 4', color=cgcolor('green'), charsize=1.4
          xyouts, 57100, 1.94, 'visit 5', color=cgcolor('blue'), charsize=1.4
          xyouts, 57100, 1.85, 'visit 6', color=cgcolor('purple'), charsize=1.4
          xyouts, 57100, 1.76, 'visit 7', color=cgcolor('magenta'), charsize=1.4
          xyouts, 57100, 1.67, 'visit 8', color=cgcolor('black'), charsize=1.4
      endif
          
      device, /close
      cgps2pdf, psname
      file_delete, psname
    
      set_plot, 'x'

  endfor ; r

  endif


  ;; Sort outputs.
  ;; First search for ratio FITS files and move to 'ratios_fits' sub-directory.
  fits_ratio_list = file_search(out_loc +'ratio*.fits') 
  if (n_elements(fits_ratio_list) gt 0) && (isa(fits_ratio_list, /array) ne 0) then begin
      ratios_fits_dir = out_loc + 'ratios_fits/'
      if file_test(ratios_fits_dir) eq 0 then file_mkdir, ratios_fits_dir
      foreach file, fits_ratio_list do begin
          if keyword_set(over_write) then begin
              file_move, file, ratios_fits_dir, /overwrite
          endif else begin
              file_move, file, ratios_fits_dir          
          endelse
          
      endforeach
  endif

  ;; Second search for ratio PNGs and move to 'ratios_png'
  png_ratio_list = file_search(out_loc +'ratio*.png') 
  if (n_elements(png_ratio_list) gt 0) && (isa(png_ratio_list, /array) ne 0) then begin
      ratios_png_dir = out_loc + 'ratios_png/'
      if file_test(ratios_png_dir) eq 0 then file_mkdir, ratios_png_dir
      foreach file, png_ratio_list do begin
          if keyword_set(over_write) then begin
              file_move, file, ratios_png_dir, /overwrite
          endif else begin
              file_move, file, ratios_png_dir
          endelse
      endforeach
  endif

  ;; Third search for plots and move to 'median_ratio_vs_time_plots' sub-directory.
  plots_list = file_search(out_loc + 'median_ratio_vs_time_*')
  if (n_elements(plots_list) gt 0) && (isa(plots_list, /array) ne 0)  then begin
      plots_dir = out_loc + 'median_ratio_vs_time_plots/'
      if file_test(plots_dir) eq 0 then file_mkdir, plots_dir
      foreach file, plots_list do begin
          if keyword_set(over_write) then begin
              file_move, file, plots_dir, /overwrite
          endif else begin
              file_move, file, plots_dir
          endelse
      endforeach
  endif


END




