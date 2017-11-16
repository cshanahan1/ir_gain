FUNCTION ir_gain, infile1, infile2, $
                  out_loc=out_loc, $
                  dark=dark, $
                  binn=binn, $
                  do_ipc=do_ipc, $
                  do_maskbad=do_maskbad, $
                  single_gain_files=single_gain_files, $
                  single_gain_plots=single_gain_plots, $
                  sumdiff_fits=sumdiff_fits, $
                  clip_cnts=clip_cnts, $
                  boxsize=boxsize

;+
; NAME:
;      IR_GAIN
;
; PURPOSE: 
;      Using mean-variance method, calculates IR gain from two IMA 
;      files of same number of reads.
;
; INPUTS: 
;      infile1 = IMA file 1.
;      infile2 = IMA file 2. (Order should not matter).
;      out_loc = Location for outputs to be generated.
;      dark = Name of the dark current file. Fill in if wish to
;        subtract it.
;      binn = Number of bins. Set to 1 by default.
;      do_ipc = Switch on to do IPC deconvolution. (recommended)
;      do_maskbad = Switch on to mask bad pixels. (also recommended)
;      single_gain_files = Switch on to produce text file containing
;        gain values of each quadrant.
;        * Deprecated for now. *
;      single_gain_plots = Switch on to produce plots of mean vs 
;        variance fitted with line.
;      sumdiff_fits = Switch on to produce FITS files of sum and diff
;        of the two (post-corrected) infiles.
;      boxsize = Number of pixels wide to make grid divisions. 
;         Default of 20, which makes 25x25 grid in each quadrant.
;         Setting to 100 makes a 5x5 grid.
;
; OUTPUTS:   
;      if single_gain_plots='y', PDF plot for each pair. 
;          <rootname1>_<rootname2>_meanVSvar 
;
; EXAMPLE: 
;      idl> ir_gain, 'x_ima.fits', 'y_ima.fits', do_ipc='y', sumdiff_fits='y'
;
;       Finds the gain from the two IMA infiles that have had the IPC
;       corrections performed on them and generates FITS files of
;       the summed and diffed infiles.
;
; NOTES:
;     Based on B. Hilbert's ir_cycle18_gain.pro in idl_procs.
;
; MODIFICATION HISTORY:
;     8 Dec. 2014: Written by C.M. Gosmeyer.
;
; REFERENCES:
;     http://www.stsci.edu/hst/wfc3/documents/ISRs/WFC3-2008-50.pdf
;-  

  ;; Set default values.
  SetDefaultValue, boxsize, 20

  ;; Will append names of corrections done onto this string so it will
  ;; become part of the output filenames.
  file_basename = ''

  ;; Read in data.
  original1 = ramp_read(infile1)
  original2 = ramp_read(infile2)

  xdim = n_elements(original1[0,*,0])
  ydim = n_elements(original1[0,0,*])
  zdim = n_elements(original1[*,0,0])

  print, "x dimensions: ", xdim
  print, "y dimensions: ", ydim
  print, "z dimensions: ", zdim


;----------------------------------------------------------------------
  
  if keyword_set(do_ipc) then begin
    print, 'do_ipc set on'
    for i=0, n_elements(original1[*,0,0])-1 do begin
      tmp = reform(original1[i,*,*])
      ipcdecon_4vals, tmp, alphaleft=0.01700, alpharight=0.01724, $
        betaabove=0.01249, betabelow=0.01264
      original1[i,*,*] = tmp
      
      tmp = reform(original2[i,*,*])
      ipcdecon_4vals, tmp, alphaleft=0.01700, alpharight=0.01724, $
        betaabove=0.01249, betabelow=0.01264
      original2[i,*,*] = tmp
    endfor
    
    print, ''
    print, 'IPC DECON PERFORMED ON INPUT RAMPS, ONE READ AT A TIME.'
    print, ''
    
    file_basename += '_ipc'
  endif

;----------------------------------------------------------------------

  ;; Remove the image border.
  
  original1 = original1[*,5:xdim-6,5:ydim-6]
  original2 = original2[*,5:xdim-6,5:ydim-6]

;----------------------------------------------------------------------

  ;; Normalize mean signal levels to one another, using the mean
  ;; of the last read to normalize. Go quad by quad, read by read.
  x1list = ([391,391,507,507])
  x2list = ([506,506,728,622])
  y1list = ([507,251,0,507])
  y2list = ([762,506,265,762])
  xdnr = xdim - 10
  
;----------------------------------------------------------------------  

  ;; Add an optional keyword?
  ;; Here clip the counts, so none are too far
  ;; above mean value.
  ;; For now, just do it quick and dirty: anything above mean + 200 counts
  ;; will be clipped.
  if keyword_set(clip_cnts) then begin
    print, "Old max1: ", max(original1)
    print, "Old max2: ", max(original2)  
  
      mean1 = mean(original1[where(original1 ne !VALUES.F_NAN)])
      mean2 = mean(original2[where(original2 ne !VALUES.F_NAN)])

      print, "Mean counts of image1: ", mean1
      print, "Mean counts of image2: ", mean2
 
        for i=0,n_elements(original1[*,0,0])-1 do begin
            tmp = reform(original1[i,*,*])
            ;mean1 = mean(tmp[where(tmp ne !values.f_nan)])
            ;print, "Mean counts of image1: ", mean1
            tmp[where(tmp gt (mean1+5000))] = !values.f_nan
            tmp[where(tmp lt (mean1-5000))] = !values.f_nan
            original1[i,*,*] = tmp
        
            tmp = reform(original2[i,*,*])
            ;mean2 = mean(tmp[where(tmp ne !values.f_nan)])
            ;print, "Mean counts of image2: ", mean2
            tmp[where(tmp gt (mean2+5000))] = !values.f_nan
            tmp[where(tmp lt (mean2-5000))] = !values.f_nan
            original2[i,*,*] = tmp
        endfor
    endif
    
    print, "New max1: ", max(original1)
    print, "New max2: ", max(original2)
    
;----------------------------------------------------------------------
  
  ;; Mask out pixels marked as reed-soloman error, fill error, dead,
  ;; perm bad 0th read, hot, unstable, warm, bad, refpix, saturated,
  ;; and bad in flat.
 
  if keyword_set(do_maskbad) then begin
    print, 'do_maskbad set on'
    fits_read, infile1 ,exten=3, masktmp1
    fits_read, infile2, exten=3, masktmp2

    binmasktmp1 = reform(binary(fix(masktmp1)), 16, xdim, xdim)
    binmasktmp2 = reform(binary(fix(masktmp2)), 16, xdim, xdim)
    print,''
    print,'# PIXELS WITH DQ VALUES:'
    print,'0 - ' + strcompress(string(n_elements(where(masktmp1 eq 0))),/remove_all)
    print,'1 - ' + strcompress(string(n_elements(where(binmasktmp1[15,*,*] eq 1))),/remove_all)
    print,'2 - ' + strcompress(string(n_elements(where(binmasktmp1[14,*,*] eq 1))),/remove_all)
    print,'4 - ' + strcompress(string(n_elements(where(binmasktmp1[13,*,*] eq 1))),/remove_all)
    print,'8 - ' + strcompress(string(n_elements(where(binmasktmp1[12,*,*] eq 1))),/remove_all)
    print,'16 - ' + strcompress(string(n_elements(where(binmasktmp1[11,*,*] eq 1))),/remove_all)
    print,'32 - ' + strcompress(string(n_elements(where(binmasktmp1[10,*,*] eq 1))),/remove_all)
    print,'64 - ' + strcompress(string(n_elements(where(binmasktmp1[9,*,*] eq 1))),/remove_all)
    print,'128 - ' + strcompress(string(n_elements(where(binmasktmp1[8,*,*] eq 1))),/remove_all)
    print,'256 - ' + strcompress(string(n_elements(where(binmasktmp1[7,*,*] eq 1))),/remove_all)
    print,'512 - ' + strcompress(string(n_elements(where(binmasktmp1[6,*,*] eq 1))),/remove_all)
    print,'1024 - ' + strcompress(string(n_elements(where(binmasktmp1[5,*,*] eq 1))),/remove_all)
    print,'2048 - ' + strcompress(string(n_elements(where(binmasktmp1[4,*,*] eq 1))),/remove_all)
    print,'4096 - ' + strcompress(string(n_elements(where(binmasktmp1[3,*,*] eq 1))),/remove_all)
    print,'8192 - ' + strcompress(string(n_elements(where(binmasktmp1[2,*,*] eq 1))),/remove_all)
    print,'16384 - ' + strcompress(string(n_elements(where(binmasktmp1[1,*,*] eq 1))),/remove_all)
    print,'32768 - ' + strcompress(string(n_elements(where(binmasktmp1[0,*,*] eq 1))),/remove_all)
    print,''
  
    mask1 = masktmp1[5:xdim-6, 5:xdim-6]
    mask2 = masktmp2[5:xdim-6, 5:ydim-6]

    for i=0,n_elements(original1[*,0,0])-1 do begin
        tmp = reform(original1[i,*,*])
        tmp[where((mask1 ne 0) and (mask1 ne 2048) and (mask2 ne 0) and (mask2 ne 2048))] = !values.f_nan
        original1[i,*,*] = tmp
        
        tmp = reform(original2[i,*,*])
        tmp[where((mask1 ne 0) and (mask1 ne 2048) and (mask2 ne 0) and (mask2 ne 2048))] = !values.f_nan
        original2[i,*,*] = tmp
    endfor
    
    file_basename += '_maskbad'
  endif

;----------------------------------------------------------------------  

  ;; Mask out bad portions of detector (eg, death star). Set pixels
  ;; to zero.
  
  ;; Wagon Wheel:
  original1[*,818:*,0:595] = !values.f_nan
  original2[*,818:*,0:595] = !values.f_nan
  
  ;; Death Star:
  original1[*,290:425,0:130] = !values.f_nan
  original2[*,290:425,0:130] = !values.f_nan
  
  ;; Weird area to the right of the Death Star:
  original1[*,290:545,0:130] = !values.f_nan
  original2[*,290:545,0:130] = !values.f_nan  
  
  ;; Glow on upper edge of quad 1:
  original1[*,370:563,974:*] = !values.f_nan
  original2[*,370:563,974:*] = !values.f_nan  

;----------------------------------------------------------------------  

  ;; Do any other corrections/masking.

  
;---------------------------------------------------------------------- 

  ;; Normalize the mean dark signal to the mean data signal.
  
  ;; First, get exposure times.
  
  seq = strupcase(strcompress(sxpar(headfits(infile1),'SAMP_SEQ',count=seqcount),/remove_all))
  xdim = xdim - 10
  ydim = ydim - 10
  
  if xdim eq 1014 then xdt = xdim + 10 else xdt = xdim
  exptime = ramp_times(infile1) 

  orignorm1 = original1
  orignorm2 = original2

;---------------------------------------------------------------------- 

  ;; Subtract the dark current.
  
  if keyword_set(dark) then begin
    print, 'subtracting the dark current set on'
    original1 = original1 - dark
    original2 = original2 - dark
    
    file_basename += '_darksub'
  endif

;---------------------------------------------------------------------- 

  ;; Sum the ramps.
  
  sum = (original1 + original2)
  if keyword_set(sumdiff_fits) then begin
    print, 'generating sum and diff fits files set on'
    sfile = strmid(infile1, 0, strlen(infile1)-5)+'_'+strmid(infile2, 0, strlen(infile2)-5)+'_sumfile.fits'
    fits_open, sfile, f1, /write
    for oo=0,13 do fits_write, f1, reform(sum[oo,*,*])
    fits_close, f1
  endif

  ;; Difference the ramps.

  diff = (original1 - original2)
  if keyword_set(sumdiff_fits) then begin
    dfile = strmid(sfile, 0, strlen(sfile)-12)+'difffile.fits'
    fits_open, dfile, f2, /write
    for oo=0,13 do fits_write, f2, reform(diff[oo,*,*])
    fits_close, f2
  endif

;---------------------------------------------------------------------- 

  ;; Binning
  
  if keyword_set(binn) eq 0 then binn=1
  
  bsize = binn
  diffb = fltarr(zdim, 1014/bsize, 1014/bsize)
  sumb = fltarr(zdim, 1014/bsize, 1014/bsize)

  ;PLAY WITH VERY SMALL BOXES
  x1list = ([250,250,750,750])
  x2list = ([270,270,770,770])
  y1list = ([750,250,250,750])
  y2list = ([770,270,270,770])

  ;SMOV 512x512 SUBARRAYS
  if xdim lt 1000 and xdim gt 500 then begin
    x1list = [140,140,256,256]/bsize
    x2list = [255,255,371,371]/bsize
    y1list = [256,0,0,256]/bsize
    y2list = [511,255,255,511]/bsize
  endif

  ;SMOV 256 SUBARRAYS
  if xdim lt 500 and xdim gt 200 then begin
    x1list = [80,80,128,128]/bsize
    x2list = [127,127,255,255]/bsize
    y1list = [128,0,0,128]/bsize
    y2list = [255,127,127,255]/bsize
  endif

  ;SMOV 128 SUBARRAYS
  if xdim lt 200 and xdim gt 100 then begin
    x1list = [0,0,64,64]/bsize
    x2list = [63,63,127,127]/bsize
    y1list = [64,0,0,64]/bsize
    y2list = [127,63,63,127]/bsize
  endif

  ;SMOV 64 SUBARRAYS
  if xdim lt 100 then begin
    x1list=[0,0,32,32]/bsize
    x2list=[31,31,63,63]/bsize
    y1list=[32,0,0,32]/bsize
    y2list=[63,31,31,63]/bsize
  endif

  if bsize gt 1 then begin
    x2list = x2list - 1
    y2list = y2list - 1
    for zz=0, zdim-1 do begin
      for ii=0, 1014./bsize-1 do begin
        for jj=0, 1014./bsize-1 do begin
          diffb[zz,ii,jj] = total(diff[zz, bsize*ii:(bsize*ii)+(bsize-1), bsize*jj:bsize*jj+(bsize-1)])
            sumb[zz,ii,jj] = total(sum[zz, bsize*ii:(bsize*ii)+(bsize-1), bsize*jj:bsize*jj+(bsize-1)])
        endfor
      endfor
    endfor
    sum = sumb
    diff = diffb
  endif

;---------------------------------------------------------------------- 

  ;; Calculate Mean and Variance values for each quadrant of each read.
   
  ;; Mean is the peak value of the best-fit Gaussian to the histogram 
  ;; of the summed data values.

  ;; Variance is the square of the width of the best-fit Gaussian to the 
  ;; histogram of the differenced values.

  bsz = 80.
  bsz2 = 1.
  gain = fltarr(4,14)
  gainerr = fltarr(4,14) 
  gain30k = fltarr(4)
  gain30kerr = fltarr(4)

  chisqgauss_sum = fltarr(n_elements(original1[*,0,0]))
  chisqgauss_diff = fltarr(n_elements(original1[*,0,0]))
  chisqmp_sum = fltarr(n_elements(original1[*,0,0]))
  chisqmp_diff = fltarr(n_elements(original1[*,0,0]))

  ;; Where xdnr = length of IR detector - 10 = 1014-10 = 1004
  xstart = [0, xdnr/2, 0, xdnr/2]
  ystart = [xdnr/2, xdnr/2, 0, 0]

  ;; Boxsize, width in pixels.
  boxsize =  boxsize ;; 20 ;; 100
  nboxes = xdnr / 2 / boxsize  ;;=25
  offset = (xdnr/2) - (boxsize * nboxes)

  ;; Variance and mean values for entire detector.
  allmnsm = fltarr(4, zdim, nboxes, nboxes)
  allvarsm = fltarr(4, zdim, nboxes, nboxes)

  ;; The line fits to mean-variance plots.
  yfits = fltarr(4, zdim, nboxes, nboxes)

  ;; Loop over all quadrants. 
  for q=0, 3 do begin
    ;; To contain each quadrant's mean:
    mnsm = fltarr(zdim, nboxes, nboxes)
    ;; To contain each quadrant's variance:
    varsm = fltarr(zdim, nboxes, nboxes)
    mnssig = fltarr(n_elements(original1[*,0,0]))
    dfssig = fltarr(n_elements(original2[*,0,0]))
  
    ;; Step over each read?
    for i=1,n_elements(original1[*,0,0])-1 do begin & $
      ;; Divide the Sum and Diff arrays into quadrants and subsections.
      for xbox = 0,nboxes-1 do begin
        for ybox = 0,nboxes-1 do begin
          sumbox = reform(sum[i, xstart[q]+boxsize*xbox+offset:xstart[q]+boxsize*xbox+(boxsize+offset-1), $
                          ystart[q]+boxsize*ybox+offset:ystart[q]+boxsize*ybox+(boxsize+offset-1)])
          diffbox = reform(diff[i, xstart[q]+boxsize*xbox+offset:xstart[q]+boxsize*xbox+(boxsize+offset-1), $
                           ystart[q]+boxsize*ybox+offset:ystart[q]+boxsize*ybox+(boxsize+offset-1)])
                           
          ;; Sigclip once to clean up. 
          tmps = sumbox
          tmpd = diffbox
          if max(finite(sumbox)) eq 1 and total(finite(sumbox)) gt 100 then begin
            for ctr=0, 0 do begin  
              resistant_mean, tmps, 3, mmm    ;; 3-sigma clipping.
              mmm = [mmm, robust_sigma(tmps)]
              high = mmm[0] + 3*mmm[1]
              low = mmm[0] - 3*mmm[1]
              bads = where((tmps gt high) or (tmps lt low))
              if bads[0] ne -1 then tmps[bads] = !values.f_nan
              
              resistant_mean, tmpd, 3, mmm     ;; 3-sigma clipping.
              mmm = [mmm, robust_sigma(tmpd)]
              high = mmm[0] + 3*mmm[1]
              low = mmm[0] - 3*mmm[1]
              badd = where((tmpd gt high) or (tmpd lt low))
              if badd[0] ne -1 then tmpd[badd] = !values.f_nan              
            endfor
          endif  
          sumbox = tmps
          diffbox = tmpd
                     
          ;; Here find the mean and variance over over read, over subsection.           
          if max(finite(sumbox)) eq 1 and max(sumbox,/nan) ne min(sumbox,/nan) then begin
            resistant_mean, sumbox, 3, tmps
            mnsm[i,xbox,ybox] = tmps
            varsm[i,xbox,ybox] = (robust_sigma(diffbox)/sqrt(1.))^2   ;;variance = (std dev)^2, where robust_sigma=stddev
          endif     
                  
        endfor ;ybox  
      endfor ;xbox
    
    allvarsm[q,*,*,*] = varsm
    allmnsm[q,*,*,*] = mnsm
    
    
    
    
    endfor ;i
  

    ;; Plot mean-variance. The inverse of the line-fit slope is the gain.

    qstr = strcompress(string(q+1), /remove_all)
    slashpos1 = strpos(infile1, '/', /reverse_search)
    slashpos2 = strpos(infile2, '/', /reverse_search)

    ;; Do another 3-sigma clip. Throw out bad boxes.
    rat = varsm/mnsm
    resistant_mean,rat[where(rat gt 0)],3,ratmn
    ratdev = robust_sigma(rat[where(rat gt 0)])
    allbutzero = where(mnsm lt 24000. and mnsm gt 100)
    filtered = where(mnsm gt 24000. or mnsm lt 100); or rat gt ratmn+2.*ratdev or rat lt ratmn-2.*ratdev)
    good = where(mnsm lt 24000. and mnsm gt 100); and (rat lt ratmn+2.*ratdev and rat gt ratmn-2.*ratdev))

    print, 'LIMIT AT 24000'
    print, ''
    print, 'number of good boxes: ', n_elements(good)
    print, ''
    print, ''
  
    ;;if n_elements(good) gt 1190 then begin
    ;; The gain is this inverted. 
    ;; sig is the standard deviation of the fit's residuals.
    ;; sigma30 is the estimated standard deviation of the coefficients.
    coeff = robust_linefit(mnsm, varsm, yfit, sig, sigma30)
    
    print, 1./coeff[1]
    help, yfit
    yfits[q,*,*,*] = yfit
    gain30k[q] = 1./coeff[1] 
    up30 = 1./ (coeff[1]+sigma30[1])
    down30 = 1./ (coeff[1]-sigma30[1])
    gain30kerr[q] = abs(gain30k[q]-up30) > abs(gain30k[q]-down30)
    print,'Sigma of line-fit: ', sigma30

    ;;endif
  endfor ; q
  

;---------------------------------------------------------------------- 
  ;; Generate the mean-variance plot, if keyword is set 'y'.
  
    if keyword_set(single_gain_plots) then begin
      mean_var_plots_dir = 'mean_var_plots/' + strmid(file_basename, 1, strlen(file_basename)) + '/'
      if file_test(out_loc + mean_var_plots_dir) eq 0 then file_mkdir, out_loc + mean_var_plots_dir 
    
      plotname = out_loc + mean_var_plots_dir + $
                strmid(infile1, slashpos1+1, strlen(infile1)-5-slashpos1-1) + $
                '_' + strmid(infile2,slashpos2+1,strlen(infile2)-5-slashpos2-1) + $
                '_meanVSvar'
                    
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
	          filename = plotname+'.ps'
	  tek_color
	  !p.multi=[0, 2, 2]

      quadno = ['1','4','2','3']

      if long(zdim) ge 13 then begin
          symsize=10
          psym=3
          xrange=[0, 30000.]
          yrange=[0,20000.]
      endif
      if long(zdim) lt 13 then begin
          symsize=.5
          psym=4
          xrange=[0, 3000.]
          yrange=[0,2000.]
      endif


      for box=1, 4 do begin
        plot, allmnsm[box-1,*,*,*], allvarsm[box-1,*,*,*], $
              xtit='Mean (ADU) ', ytit='Variance (ADU!E2!N/e-)', $
              title='Quad '+quadno[box-1], $
              xrange=xrange, $
              yrange=yrange, $
              background='FFFFFF'XL, color='000000'XL, charsize=1.2, /nodata
        oplot, allmnsm[box-1,*,*,*], allvarsm[box-1,*,*,*], color=4, psym=psym, symsize=symsize
        oplot, allmnsm[box-1,*,*,*], yfits[box-1,*,*,*]  
        if zdim ge 13 then begin
            xyouts, 1400., 16000., 'gain='+strnsignif(gain30k[box-1],3), charsize=0.8, color=cgcolor('black')
        endif 
        if zdim lt 13 then begin
            xyouts, 300., 1500., 'gain='+strnsignif(gain30k[box-1],3), charsize=0.8, color=cgcolor('black')
        endif
      endfor

      !p.multi=0
      device, /close

      cgps2pdf, plotname+'.ps'
      file_delete, plotname+'.ps'
      
    
      set_plot, 'x'
    
    endif 

  
;---------------------------------------------------------------------- 

    ;; Calculating standard deviation of means and variances of the 
    ;; grid-squares of each quadrant.
    stddev_mean = fltarr(4)
    stddev_var = fltarr(4)
  
    allmnsm_resize = allmnsm[*,zdim-1,*,*]
    allvarsm_resize = allvarsm[*,zdim-1,*,*]
  
    ;; Set zeroes to NaN.
    for s=0, 3 do begin
        test_zero = where_xyz(allmnsm_resize[s,*,*] EQ 0.0, XIND=xind, YIND=yind, ZIND=zind)
        help, allmnsm_resize
        print, xind
        allmnsm_resize[s, yind, zind] = !VALUES.F_NAN
      
        test_zero = where_xyz(allvarsm_resize[s,*,*] EQ 0.0, XIND=xind, YIND=yind, ZIND=zind)
        allvarsm_resize[s,yind, zind] = !VALUES.F_NAN
    endfor
    for s=0, 3 do begin
        stddev_mean[s] = stddev(allmnsm_resize[s,*,*], /NAN)
        stddev_var[s] = stddev(allvarsm_resize[s,*,*], /NAN)
    endfor

;---------------------------------------------------------------------- 


  if keyword_set(single_gain_files) then begin
    ;; Write the means and variances of each grid-square of each quadrant
    ;; and the standard deviations.
    mean_var_lists_dir = 'mean_var_lists/' + strmid(file_basename, 1, strlen(file_basename)) + '/'
    if file_test(out_loc + mean_var_lists_dir) eq 0 then file_mkdir, out_loc + mean_var_lists_dir 

    gnam = out_loc + mean_var_lists_dir + $
           strmid(infile1, slashpos1+1, strlen(infile1)-5-slashpos1-1) + $
                  '_' + strmid(infile2,slashpos2+1,strlen(infile2)-5-slashpos2-1) $
                  + file_basename + '_means_variances.txt'
    ;if keyword_set(mimic512) then gnam = strmid(gnam,0,strlen(gnam)-4) + '_maskedto512.txt'
    openw, gainlun, gnam, /get_lun, width=170
    printf, gainlun, '#Mean and variance of grid-boxes of each quadrant in the final read.'
    printf, gainlun, '#Input files: ' + infile1 + ' ' + infile2
    printf, gainlun, '#'
    printf, gainlun, '#                     Mean1      Variance1     Mean2      Variance2      Mean3      Variance3      Mean4      Variance4'
    for xbox=0, nboxes-1 do begin
        for ybox=0, nboxes-1 do begin
            printf, gainlun, xbox, ybox, $
                  allmnsm[0,zdim-1,xbox,ybox], allvarsm[0,zdim-1,xbox,ybox], $
                  allmnsm[2,zdim-1,xbox,ybox], allvarsm[2,zdim-1,xbox,ybox], $
                  allmnsm[3,zdim-1,xbox,ybox], allvarsm[3,zdim-1,xbox,ybox], $
                  allmnsm[1,zdim-1,xbox,ybox], allvarsm[1,zdim-1,xbox,ybox]
         endfor
    endfor
    free_lun, gainlun  
  



    ;; Create file listing the uncertainties and standard deviations.
    print, ''
    print, ''
    print, ''
    print, '             Gain (e-/ADU)      Uncertainty      StdDev(mean)      StdDev(variance)      '
    print, 'Quad 1 ', gain30k[0], gain30kerr[0], stddev_mean[0], stddev_var[0]
    print, 'Quad 2 ', gain30k[2], gain30kerr[2], stddev_mean[2], stddev_var[2]
    print, 'Quad 3 ', gain30k[3], gain30kerr[3], stddev_mean[3], stddev_var[3]
    print, 'Quad 4 ', gain30k[1], gain30kerr[1], stddev_mean[1], stddev_var[1]
    print, ''
    print, ''
    print, ''

    print, gain30k
    print, 'gain = [' + strcompress(string(gain30k[0]),/remove_all) + $
                    ',' + strcompress(string(gain30k[2]),/remove_all) $
                    + ',' + strcompress(string(gain30k[3]),/remove_all) $
                    + ',' + strcompress(string(gain30k[1]),/remove_all) + ']' 



    gnam = out_loc + mean_var_lists_dir + $
           strmid(infile1, slashpos1+1, strlen(infile1)-5-slashpos1-1) + $
                '_' + strmid(infile2,slashpos2+1,strlen(infile2)-5-slashpos2-1) $
                + file_basename + '_uncertainties.txt'
    ;if keyword_set(mimic512) then gnam = strmid(gnam,0,strlen(gnam)-4) + '_maskedto512.txt'
    openw, gainlun, gnam, /get_lun, width=170
    printf, gainlun, '#Gain values output from ir_tv3_gain_small_boxes.pro'
    printf, gainlun, '#Input files: ' + infile1 + ' ' + infile2
    printf, gainlun, '#'
    printf, gainlun, '#             Gain (e-/ADU)      Uncertainty      StdDev(mean)      StdDev(variance)      '
    printf, gainlun, 'Quad 1 ', gain30k[0], gain30kerr[0], stddev_mean[0], stddev_var[0]
    printf, gainlun, 'Quad 2 ', gain30k[2], gain30kerr[2], stddev_mean[2], stddev_var[2]
    printf, gainlun, 'Quad 3 ', gain30k[3], gain30kerr[3], stddev_mean[3], stddev_var[3]
    printf, gainlun, 'Quad 4 ', gain30k[1], gain30kerr[1], stddev_mean[1], stddev_var[1]
    free_lun, gainlun
  endif

  
  ;; Create the output array
  
  out_array = make_array(17, 1, /STRING)
  
  out_array[0] = file_basename
  
  count=1
  foreach g, gain30k do begin
    out_array[count] = string(g)
    count += 1
  endforeach
  
  foreach e, gain30kerr do begin
    out_array[count] = string(e)
    count += 1
  endforeach

  foreach sm, stddev_mean do begin
    out_array[count] = string(sm)
    count += 1
  endforeach  

  foreach sv, stddev_var do begin
    out_array[count] = string(sv)
    count += 1
  endforeach  
  

  return, out_array

END