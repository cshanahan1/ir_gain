pro ir_gain_permutate, file_path, $
         single_gain_files=single_gain_files, $
         single_gain_plots=single_gain_plots, $
         sumdiff_fits=sumdiff_fits

;+
; NAME:
;      IR_GAIN_PERMUTATE
;
; PURPOSE: 
;      Finds gain for every permutation of two IMA files
;      in given directory.
;
; INPUTS: 
;      file_path = path to the IMA files.
;      single_gain_files = Switch on to produce text file containing
;        gain values of each quadrant. Needs be on when using B. 
;        Hilbert's original ir_gain script. 
;      single_gain_plots = Switch on to produce plots of mean vs 
;        variance fitted with line.
;      sumdiff_fits = Switch on to produce FITS files of sum and diff
;        of the two (post-corrected) infiles.
;
; OUTPUTS:   
;      ...     
;
; EXAMPLE: 
;
; MODIFICATION HISTORY:
;     4 Dec. 2014: Written by C.M. Gosmeyer.
;-  

  ;; Set up infile lists
  infile_list = file_search(file_path+'*ima.fits')

  infile_list_truncate = infile_list[1:(size(infile_list))[3]-1] 

  ;; Set up array for gain data.
  size_array = 0
  for i=1, (size(infile_list))[3]-1 do begin
     size_array += i
  endfor 
  
  gain_array = make_array(11, size_array, /STRING)
  count = 0L
  
  ;; For every infile1 in list
  foreach infile1, infile_list do begin 
  
    ;; Retrieve MJD from infile1
    hdr1 = headfits(infile1, ext=0)
    mjd1 =  sxpar(hdr1, 'EXPSTART')
    mjd1 = string(mjd1)

    ;; Pair infile1 with every other file (infile2) except with itself. 
    foreach infile2, infile_list_truncate do begin 
        
      print, '--- --- ---'
      print, count
      print, 'MJD infile1: ' + mjd1
      print, 'infile1, infile2: ' + infile1, ', ', infile2
      ; ir_gain_bhilbert, infile1, infile2
      gain_single_array = ir_gain(infile1, infile2, $
                          dark=dark, $
                          binn=binn, $
                          do_ipc='y', $
                          do_maskbad='y', $
                          do_lincorr=do_lincorr, $
                          single_gain_files=single_gain_files, $
                          single_gain_plots=single_gain_plots, $
                          sumdiff_fits=sumdiff_fits)
                                                 
      file_basename = gain_single_array[0]
      ;gain_single_array = out[1]
                                                 
      if keyword_set(single_gain_files) then begin
        ;; Obtain gains from *20x20boxes.txt.
        gain_file = ''
        line = ''
        openr, 1, strmid(infile1, 0, 13) + '_' + strmid(infile2, 0, 13) + '_gain_20x20boxes.txt'
        while not eof(1) do begin
          readf, 1, line
          gain_file = [gain_file, line]
        endwhile
        close, 1
        file_delete, strmid(infile1, 0, 13) + '_' + strmid(infile2, 0, 13) + '_gain_20x20boxes.txt'
        
        ;; append relevant info to gain_array
        gain1 = (strsplit(gain_file[5], /EXTRACT, ' '))[2]
        uncert1 = (strsplit(gain_file[5], /EXTRACT, ' '))[3]
        gain2 = (strsplit(gain_file[6], /EXTRACT, ' '))[2]
        uncert2 = (strsplit(gain_file[6], /EXTRACT, ' '))[3] 
        gain3 = (strsplit(gain_file[7], /EXTRACT, ' '))[2]
        uncert3 = (strsplit(gain_file[7], /EXTRACT, ' '))[3]
        gain4 = (strsplit(gain_file[8], /EXTRACT, ' '))[2]
        uncert4 = (strsplit(gain_file[8], /EXTRACT, ' '))[3]
       
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
      endelse 
        
      gain_array[*,count] = [infile1, infile2, gain1, uncert1, gain4, uncert4, gain2, uncert2, gain3, uncert3, mjd1]
      count+=1
        
    endforeach
  
    ;; Truncate list so next infile1 does not repeat a pair and does 
    ;; not pair with itself.
    ;; But check first that we are not at the last two infiles.
    if (size(infile_list_truncate))[3] EQ 1 then begin
      goto, endthis
    endif else begin
      infile_list_truncate=infile_list_truncate[1:(size(infile_list_truncate))[3]-1]  
    endelse
    
  endforeach



  endthis:
      
    ;; Print all gains to master gain file.
    help, gain_array
    print, gain_array
    
    openw, 2, 'gainlist' + file_basename + '.dat'
    printf, 2, ['#infile1', 'infile2', 'gain1', 'uncert1', 'gain2', 'uncert2', 'gain3', 'uncert3', 'gain4', 'uncert4', 'mjd1'], $ 
      format='(a20,a20,a12,a12,a12,a12,a12,a12,a12,a12,a18)'
    for line=0, size_array-1 do begin
      printf, 2, gain_array[*, line], format='(a20,a20,a12,a12,a12,a12,a12,a12,a12,a12,a18)'
    endfor
    close, 2
    
    max_gain1 = max(float(gain_array[2, *]))
    min_gain1 = min(float(gain_array[2, *]))
    av_gain1 = mean(float(gain_array[2, *]))
    mode_gain1 = mode(float(gain_array[2, *]))
    print, '-------------'
    print, "Max gain 1: " + string(max_gain1)
    print, "Min gain 1: " + string(min_gain1)
    print, "Average gain 1: " + string(av_gain1)
    print, "Mode gain 1: " + string(mode_gain1)
    
    max_gain2 = max(float(gain_array[6, *]))
    min_gain2 = min(float(gain_array[6, *]))
    av_gain2 = mean(float(gain_array[6, *]))
    mode_gain2 = mode(float(gain_array[6, *]))
    print, '-------------'
    print, "Max gain 2: " + string(max_gain2)
    print, "Min gain 2: " + string(min_gain2)
    print, "Average gain 2: " + string(av_gain2)    
    print, "Mode gain 2: " + string(mode_gain2)
    
    max_gain3 = max(float(gain_array[8, *]))
    min_gain3 = min(float(gain_array[8, *]))
    av_gain3 = mean(float(gain_array[8, *]))
    mode_gain3 = mode(float(gain_array[8, *]))
    print, '-------------'
    print, "Max gain 3: " + string(max_gain3)
    print, "Min gain 3: " + string(min_gain3)
    print, "Average gain 3: " + string(av_gain3)
    print, "Mode gain 3: " + string(mode_gain3)
    
    max_gain4 = max(float(gain_array[4, *]))
    min_gain4 = min(float(gain_array[4, *]))
    av_gain4 = mean(float(gain_array[4, *]))
    mode_gain4 = mode(float(gain_array[4, *]))
    print, '-------------'
    print, "Max gain 4: " + string(max_gain4)
    print, "Min gain 4: " + string(min_gain4)
    print, "Average gain 4: " + string(av_gain4)   
    print, "Mode gain 4: " + string(mode_gain4)    
   
    stat_array =  make_array(5, 5, /STRING)
    stat_array[*,0] = ['#	', 'Max	', 'Min	', 'Average	', 'Mode	']
    stat_array[*,1] = ['Gain1', string(max_gain1), string(min_gain1), string(av_gain1), string(mode_gain1)] 
    stat_array[*,2] = ['Gain2', string(max_gain2), string(min_gain2), string(av_gain2), string(mode_gain2)] 
    stat_array[*,3] = ['Gain3', string(max_gain3), string(min_gain3), string(av_gain3), string(mode_gain3)] 
    stat_array[*,4] = ['Gain4', string(max_gain4), string(min_gain4), string(av_gain4), string(mode_gain4)] 
    
    help, stat_array
    print, stat_array
    
    ;; Print statistics to file.
    ;; Columns of max, min, average, mode.
    openw, 3, 'statistics' + file_basename + '.dat'
    for line=0, 4 do begin
      print, line
      print, stat_array[*, line]
      printf, 3, stat_array[*, line], format='(a,a,a,a,a)'
    endfor
    close, 3
     
     
    ;; Plot gain vs time for each quad.
    
	set_plot, 'ps'
	!p.font=0
	!p.thick=4
	!x.thick=3
	!y.thick=3
	device, isolatin1=1, $
	        helvetica=1, $
	        /landscape, $
	        /inch, $
	        /color
	tek_color
	!p.multi=[0, 2, 2]
    
    psname = 'gain_vs_time' + file_basename + '.ps'
      
    quadno = ['1','4','2','3']


    for box=1, 4 do begin
      plot, gain_array[10, *], gain_array[box*2, *], xtit='MJD infile1 ', ytit='Gain', $
              title='Quad '+quadno[box-1], xtickformat='(F7.1)', $
              background='FFFFFF'XL, color='000000'XL, charsize=1.2, /nodata
      oplot, gain_array[10, *], gain_array[box*2, *], psym=4, color=4
    endfor

    device, /close
    file_move, 'idl.ps', psname
    cgps2pdf, psname
    file_delete, psname
    
    ;; Plot gain vs index for each quad.
    
	!p.font=0
	!p.thick=4
	!x.thick=3
	!y.thick=3
	device, isolatin1=1, $
	        helvetica=1, $
	        /landscape, $
	        /inch, $
	        ;xoffset=0, yoffset=11, $
	        ;ysize=8.5, xsize=11, $
	        /color
	tek_color
	!p.multi=[0, 2, 2]
    
    psname = 'gain_vs_index' + file_basename + '.ps'
      
    quadno = ['1','4','2','3']

    for box=1, 4 do begin
      cgplot, indgen(size_array), gain_array[box*2, *], xtit=' ', ytit='Gain', $
              title='Quad '+quadno[box-1],  $
              background='FFFFFF'XL, color='000000'XL, charsize=1.2, /nodata
      oplot, indgen(size_array), gain_array[box*2, *], psym=4, color=4
    endfor

    device, /close
    file_move, 'idl.ps', psname
    cgps2pdf, psname
    file_delete, psname
    set_plot, 'x'
    
end