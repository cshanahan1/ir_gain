
PRO run_ir_gain, dataset, $
	             out_mark=out_mark, $
	             obs_types=obs_types, $
	             do_pers=do_pers, $
                 do_lt_ratio=do_lt_ratio, $
	             use_newlincorr=use_newlincorr

;+
; NAME:
;      run_ir_gain
;
; PURPOSE: 
;      Wraps ir_gain_back2back.PRO and ... , so that an entire epoch's
;      (eight-Visit) analysis can be done in one script.
;
; INPUTS: 
;      dataset : 
;          'new' -- Runs the IR suite on data that has been freshly calibrated
;                   and sorted. The script will find the new data from the file
;                   'input_files.dat' that the sorting script creates in each
;                   observation-type directory.
;                   Use this option in nominal run when new data arrive.
;          'all' -- Re-runs the IR gain suite on all data.
;      out_mark :
;          String to be appended to finalresults directory after time stamp.
;          Default of ''.
;      obs_types :
;          ['flat_long'] -- Default. Or select one or both of the options
;          ['flat_short', 'flat_long'] .
;      do_pers : 
;           1 -- Runs the persistence checks on all flats and darks.
;           0 -- Default. Turns off persistence checks.
;      do_lead_trail_ratio :
;           1 -- Runs ratio of trailing over leading darks. (Only post-14376 data)
;           0 -- Default. Turns off trail-lead ratio.
;      do_newlincorr :
;           Need make this option in calibration step as well? If set on,
;           just funnel the outputs to 'new_lincorr' subdirs.
;
; OUTPUTS:   
;      FITS files of ratio of each extension: ratio_<rootname>_ima.fits
;      PDFs of median of ratio vs time for each extension: dark_ratio_median_#.pdf     
;
; EXAMPLE: 
;      IDL> run_ir_gain, 'new', obs_types=['flat_long']
;
; MODIFICATION HISTORY:
;     4 Nov. 2015: Written by C.M. Gosmeyer.
;-  


;; Set default values.
SetDefaultValue, out_mark, ''
SetDefaultValue, obs_types, ['flat_long']
SetDefaultValue, do_lt_ratio, 0
SetDefaultValue, do_pers, 0


;; Get the base path names from set_paths.pro.
set_paths, path_to_data, path_to_outputs, path_to_scripts

;; Check whether the finalresults_infile.dat already exists. Delete if so.
;; Recreate a fresh file.
if file_test(path_to_outputs + 'finalresults/finalresults_infile.dat') then begin
    file_delete, path_to_outputs + 'finalresults/finalresults_infile.dat'
endif
spawn, "touch " + path_to_outputs + 'finalresults/finalresults_infile.dat'

;; First ask whether these data are new (and are listed in 'input_files.dat's)
;; or whether this is a rerun of ALL existing data (and can just be globbed over). 
if dataset eq 'new' then begin
    print, "Running ir_gain_back2back on IMAs listed in the input_files.dat located in "
    print, "the given directories."
    print, " "
    foreach obs_type, obs_types do begin
        if file_test(path_to_data + obs_type + '/input_files.dat') eq 1 then begin
        ;; Search for 'input_files.dat' and run in all directories containing that file.
            ir_gain_back2back, obs_type, out_mark=out_mark, $
                use_newlincorr=use_newlincorr, single_gain_files='y', $
                single_gain_plots='y', $
                file_basename=file_basename
            print, ">>>>>>><<<<<<<<"
            print, "ir_gain_back2back complete on " + path_to_data + obs_type
            print, " "
            
            ;; Remove underscore from beginning.
            if strmid(file_basename, 0, 1)  eq '_' then file_basename = strmid(file_basename, 1, strlen(file_basename))

            ;; Append to file finalresults_infile.dat so that python plots can be
            ;; crated on the proper sets of data in the next step.
            openw, 2, path_to_outputs + 'finalresults/finalresults_infile.dat', /APPEND, width=270
            printf, 2, [file_basename, obs_type], format='(a12, a12)'
            close, 2

        endif else begin
            print, ">>>>>>><<<<<<<<"
            print, "An input_files.dat does NOT exist in " + path_to_data + obs_type
            print, " "
        endelse
    endforeach ; obs_type
endif

if dataset eq  'all' then begin
    print, "Running ir_gain_back2back on ALL IMAs in given obs_type directories."
    print, " "
    ;; Just globs each directory.
    foreach obs_type, obs_types do begin
        ir_gain_back2back, obs_type, out_mark=out_mark, use_glob_input='y', $
            use_newlincorr=use_newlincorr, single_gain_files='y', $
            single_gain_plots='y', $
            file_basename=file_basename 
        print, ">>>>>>><<<<<<<<"
        print, "ir_gain_back2back complete on " + path_to_data  + obs_type
        print, " "
            
        ;; Remove underscore from beginning.
        if strmid(file_basename, 0, 1)  eq '_' then file_basename = strmid(file_basename, 1, strlen(file_basename))

        ;; Append to file finalresults_infile.dat so that python plots can be
        ;; created on the proper sets of data in the next step.
        openw, 2, path_to_outputs + 'finalresults/finalresults_infile.dat', /APPEND, width=270
        printf, 2, [file_basename, obs_type], format='(a12, a12)'
        close, 2

    endforeach

endif


print, " "
print, ">>>>>>><<<<<<<<"
print, "IR gain calculate is COMPLETE on all datasets."
print, " "

print, "    Generate plots in 'finalresults' and 'automated_outputs' with "
print, "    >python create_final_ir_gain_outputs.py --a 'true' "
print, " "


;; Second call the persistence procedures if the keyword is set.
if do_pers eq 1 then begin

    ;; This includes both flats and darks.
    obs_types = ['dark_leading', 'dark_trailing', 'flat_long', 'flat_short']  ;

    if dataset eq 'new' then begin
        print, "Running ratio_ramps on IMAs listed in the input_files.dat located in "
        print, "the given directories."
        print, " "
        foreach obs_type, obs_types do begin    
            ;; Create ratio'd PNGs for each obs_type. Ratio to extension 1.    
            ratio_ramps, 1, obs_type=obs_type, do_pngs='y'
            print, ">>>>>>><<<<<<<<"
            print, "ratio_ramps complete on " + path_to_data  + obs_type
            print, " "
        endforeach ; obs_type
    endif
    if dataset eq  'all' then begin
        print, "Running ratio_ramps on ALL IMAs in given obs_type directories."
        print, " "
        foreach obs_type, obs_types do begin    
            ;; Create ratio'd PNGs for each obs_type. Ratio to extension 1.  
            ratio_ramps, 1, obs_type=obs_type, use_glob_input='y', do_pngs='y'
            print, ">>>>>>><<<<<<<<"
            print, "ratio_ramps complete on " + path_to_data  + obs_type
            print, " "
         endforeach ; obs_type 
    endif
    ; Need some kind of plot showing decay in persistence vs ramp for both leading and trailing darks?

endif


print, " "
print, ">>>>>>><<<<<<<<"
print, "Persistence-checking ramp ratio'ing complete on all selected obs types."
print, "Outputs can be found in " + path_to_outputs + 'persistence/<obs_type>/'
print, " "


;; Only works on post-14376 images.
if do_lt_ratio eq 1 then begin

    ratio_lead_trail_darks

endif


print, " "
print, ">>>>>>><<<<<<<<"
print, "Ratios of first and last reads of trailing darks over leading darks complete."
print, "Outputs can be found in " + path_to_outputs + 'persistence/leading_and_trailing_darks/'
print, " "



end