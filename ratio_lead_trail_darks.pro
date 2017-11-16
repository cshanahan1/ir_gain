PRO ratio_lead_trail_darks

;+
; NAME:
;      RATIO_LEAD_TRAIL_DARKS
;
; PURPOSE: 
;      Takes ratio of reads of each trailing dark to leading dark 
;      (post-14376 data) within a Visit, as check on persistence.
;
; INPUTS: 
;      
;
; OUTPUTS:   
;
; EXAMPLE: 
;
; MODIFICATION HISTORY:
;     20 Jan. 2016: Written by C.M. Gosmeyer.
;-  

    ;; check visit nums of each and match together


  ;; Get the base path names from set_paths.pro.
  set_paths, path_to_data, path_to_outputs, path_to_scripts

  lead_loc = path_to_data + 'dark_leading/'   ;id0g08daq_flt.fits,  id0g01enq_flt.fits,  id0g04wjq_flt.fits
  trail_loc = path_to_data + 'dark_trailing/'  ;id0g08deq_flt.fits,  id0g01erq_flt.fits,  id0g04wnq_flt.fits


  ;; Generate name of timestamp directory.
  tstamp = cgtimestamp(9)  ;; 9: _02072010_10:56:37
  ;; Format tstamp
  tstamp_short = strmid(tstamp, 1, strlen(tstamp))
  tstamp_dotted = strmid(tstamp_short, 0, 2) + '.' + $
                  strmid(tstamp_short, 2, 2) + '.' + $
                  strmid(tstamp_short, 4, 4) + $
                  strjoin(strsplit(strmid(tstamp_short, 8, 9), ':', /extract), '.')
  timestamp_dir = strcompress(tstamp_dotted + '/', /remove_all)    

  ;; Set up the location of the output files.
  if file_test(path_to_outputs + 'persistence/dark_leading_and_trailing/') eq 0 then $
               file_mkdir, path_to_outputs + 'persistence/dark_leading_and_trailing/'
  out_loc = path_to_outputs + 'persistence/dark_leading_and_trailing/' + timestamp_dir 
  ;; Create the output directory if it does not exist.  
  if file_test(out_loc) eq 0 then file_mkdir, out_loc


  ;; Set up infile lists
  print, "Reading leading dark files from glob of " + lead_loc
  lead_infile_list = file_search(lead_loc+'*ima.fits')
  print, "Reading trailing dark files from glob of " + trail_loc
  trail_infile_list = file_search(trail_loc+'*ima.fits')

  ;; Loop through each trailing dark (because these are exclusive to 
  ;; only post-14376 data)
  ;; Lead on the bottom.  Trail/Lead
  foreach trail_dark, trail_infile_list do begin
      foreach lead_dark, lead_infile_list do begin

          ;; Match the leading to the trailing darks by Visit by comparing
          ;; the first 7 letters of the rootname.
          trail_dark_7 = strmid(trail_dark, strlen(trail_dark)-18, 7) 
          lead_dark_7 = strmid(lead_dark, strlen(lead_dark)-18, 7) 

          if trail_dark_7 eq lead_dark_7 then begin 
              print, "Matched ", trail_dark, " & ", lead_dark
              ;; Now take their ratio and save to FITS and PNG files.
              trail_data = ramp_read(trail_dark)
              lead_data = ramp_read(lead_dark)

              ;; Take ratio of the 1st read and the last read.
              ;; Trailing darks have 15 reads. Leading darks have 9 reads.
              ratio_1 = trail_data[1,*,*] / lead_data[1,*,*]
              help, ratio_1
              ratio_last = trail_data[15,*,*] / lead_data[9,*,*]
              help, ratio_last

              ratio_rootname_1 = strcompress(out_loc + 'trail-lead_1_' + $
                               strmid(trail_dark, strlen(trail_dark)-18, 9) + $
                               '_' + strmid(lead_dark, strlen(lead_dark)-18, 9), $
                               /remove_all)
              print, "ratio_rootname_1: "
              print, ratio_rootname_1

              ratio_rootname_last = strcompress(out_loc + 'trail-lead_last_' + $
                               strmid(trail_dark, strlen(trail_dark)-18, 9) + $
                               '_' + strmid(lead_dark, strlen(lead_dark)-18, 9), $
                               /remove_all)
              print, "ratio_rootname_last: "
              print, ratio_rootname_last
              
              ;; Open a fits files into which to begin writing ratio'd extensions.
              fits_open, ratio_rootname_1+'.fits', f1, /write  
              fits_open, ratio_rootname_last+'.fits', f2, /write  

              ;; Write each ratio'd ramp into a FITS extension.
              fits_write, f1, reform(ratio_1[0,*,*])
              fits_write, f2, reform(ratio_last[0,*,*])

              fits_close, f1
              fits_close, f2

              ;; Write ratios into PNGs.
              make_ratio_png, reform(ratio_1[0,*,*]), ratio_rootname_1
              make_ratio_png, reform(ratio_last[0,*,*]), ratio_rootname_last                  

          endif 

    endforeach ; lead_dark
  endforeach ; trail_dark


  ;; Sort outputs.
  ;; First search for ratio FITS files and move to 'ratios_fits' sub-directory.
  fits_ratio_list = file_search(out_loc +'trail-lead*.fits') 
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
  png_ratio_list = file_search(out_loc +'trail-lead*.png') 
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



end