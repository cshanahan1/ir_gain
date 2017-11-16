PRO ir_gain_pers_plots

;+
; NAME:
;      IR_GAIN_PERS_PLOTS
;
; PURPOSE: 
;      Generates plots to aid in diagnosing persistance in 14nsamp
;      ramps.
;      Uses flags that are located in text file, 'persistence_flags.txt'
;
; INPUTS: 
;      None.
;
; OUTPUTS:   
;      PDF plots.
;      'gain_vs_index.pdf'
;      'gain_vs_mjd.pdf'
;
; EXAMPLE: 
;      idl> ir_gain_per_plots
;
; NOTES:
;      These plots were created primarily for 2015 IR Gain ISR, to see if there were
;      a correlation with gain values with perceived persistence and other affects.
;-  


out_loc = '/grp/hst/wfc3b/cgosmeyer/Projects/IR_Gain_monitor/data/14nsamp/old_lincorr/persistence_tests/'

persistence_flagstxt = out_loc + 'persistence_flags.txt'
gainlistdat = '/grp/hst/wfc3b/cgosmeyer/Projects/IR_Gain_monitor/outputs/finalresults/14nsamp/07.08.2015_16.13.16_old_lincorr/gainlist_ipc_maskbad.dat'

;; First read in the persistence flags. 
;; Every two rows are a pair.
FMT = 'A,F,I,I,I,I,A'
readcol, persistence_flagstxt, F=FMT, name_pers, mjd_pers, flag1, flag2, flag3, flag4, comment

help, name_pers
print, name_pers
help, flag1
print, flag1

;; Second read in the gain list.
FMT = 'A,A,F,F,F,F,F,F,F,F,F,F'
readcol, gainlistdat, F=FMT, name_a, name_b, gain1, uncert1, gain2, uncert2, gain3, uncert3, gain4, uncert4, mjd_a, mjd_b

;; Sort the gains of each quadrant by persistence flag.

print, "----------0---------"
print, where(flag1 eq 0)
print, (where(flag1 eq 0))/2
print, gain1[(where(flag1 eq 0))/2]

print, "----------1--------"
print, where(flag1 eq 1)
print, (where(flag1 eq 1))/2
print, gain1[(where(flag1 eq 1))/2]

print, "----------2---------"
print, where(flag1 eq 2)
print, (where(flag1 eq 2))/2
print, gain1[(where(flag1 eq 2))/2]

print, "----------3---------"
print, where(flag1 eq 3)
print, (where(flag1 eq 3))/2
print, gain1[(where(flag1 eq 3))/2]

gains_flag0 = [list(gain1[(where(flag1 eq 0))/2]), list(gain2[(where(flag2 eq 0))/2]), $
               list(gain3[(where(flag3 eq 0))/2]), list(gain4[(where(flag4 eq 0))/2])]
gains_flag0_ind = [list((where(flag1 eq 0))/2), list((where(flag2 eq 0))/2), $
                   list((where(flag3 eq 0))/2), list((where(flag4 eq 0))/2)]
mjds_flag0 = [list(mjd_a[(where(flag1 eq 0))/2]), list(mjd_a[(where(flag2 eq 0))/2]), $
               list(mjd_a[(where(flag3 eq 0))/2]), list(mjd_a[(where(flag4 eq 0))/2])]
               
gains_flag1 = [list(gain1[(where(flag1 eq 1))/2]), list(gain2[(where(flag2 eq 1))/2]), $
               list(gain3[(where(flag3 eq 1))/2]), list(gain4[(where(flag4 eq 1))/2])]
gains_flag1_ind = [list((where(flag1 eq 1))/2), list((where(flag2 eq 1))/2), $
                   list((where(flag3 eq 1))/2), list((where(flag4 eq 1))/2)]    
mjds_flag1 = [list(mjd_a[(where(flag1 eq 1))/2]), list(mjd_a[(where(flag2 eq 1))/2]), $
               list(mjd_a[(where(flag3 eq 1))/2]), list(mjd_a[(where(flag4 eq 1))/2])]
               
gains_flag2 = [list(gain1[(where(flag1 eq 2))/2]), list(gain2[(where(flag2 eq 2))/2]), $
               list(gain3[(where(flag3 eq 2))/2]), list(gain4[(where(flag4 eq 2))/2])]
gains_flag2_ind = [list((where(flag1 eq 2))/2), list((where(flag2 eq 2))/2), $
               list((where(flag3 eq 2))/2), list((where(flag4 eq 2))/2)]
mjds_flag2 = [list(mjd_a[(where(flag1 eq 2))/2]), list(mjd_a[(where(flag2 eq 2))/2]), $
               list(mjd_a[(where(flag3 eq 2))/2]), list(mjd_a[(where(flag4 eq 2))/2])]

               
gains_flag3 = [list(gain1[(where(flag1 eq 3))/2]), list(gain2[(where(flag2 eq 3))/2]), $
               list(gain3[(where(flag3 eq 3))/2]), list(gain4[(where(flag4 eq 3))/2])]
gains_flag3_ind = [list((where(flag1 eq 3))/2), list((where(flag2 eq 3))/2), $
               list((where(flag3 eq 3))/2), list((where(flag4 eq 3))/2)]
mjds_flag3 = [list(mjd_a[(where(flag1 eq 3))/2]), list(mjd_a[(where(flag2 eq 3))/2]), $
               list(mjd_a[(where(flag3 eq 3))/2]), list(mjd_a[(where(flag4 eq 3))/2])]

;; Plot gain vs index, color-coding points by my persistence flags in
;; persistence_tests/persistence_flags.txt
  set_plot, 'ps'
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
    
  psname = out_loc + 'gain_vs_index_pers' + '.ps'
      
  quadno = ['1','4','2','3']

  for box=1, 4 do begin
    cgplot, indgen(n_elements(gain1)), (gains_flag0[box-1]).ToArray(), xtit='Index', ytit='Gain [e-/ADU]', $
            title='Quad '+quadno[box-1],  $
            background='FFFFFF'XL, color='000000'XL, charsize=1.2, /nodata, $
            xrange=[-1,35], $
            yrange=[1.8, 2.4], /xs, /ys
    oplot, (gains_flag0_ind[box-1]).ToArray(), (gains_flag0[box-1]).ToArray(), psym=4, color=5
    oplot, (gains_flag1_ind[box-1]).ToArray(), (gains_flag1[box-1]).ToArray(), psym=2, color=6
    oplot, (gains_flag2_ind[box-1]).ToArray(), (gains_flag2[box-1]).ToArray(), psym=7, color=4
    oplot, (gains_flag3_ind[box-1]).ToArray(), (gains_flag3[box-1]).ToArray(), psym=5, color=2
    
    legend, ['0', '1', '2', '3'], psym = [4, 2, 7, 5], colors = [5,6,4,2], position=[29,2.05]
  endfor

  device, /close
  file_move, 'idl.ps', psname
  cgps2pdf, psname
  file_delete, psname
  set_plot, 'x'
  

;; Plot gain vs MJD, color-coding points by my persistence flags in
;; persistence_tests/persistence_flags.txt

  set_plot, 'ps'
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
    
  psname = out_loc + 'gain_vs_mjd_pers' + '.ps'
      
  quadno = ['1','4','2','3']

  for box=1, 4 do begin
    cgplot, mjd_a, (gains_flag0[box-1]).ToArray(), xtit='MJD', ytit='Gain [e-/ADU]', $
            title='Quad '+quadno[box-1],  $
            background='FFFFFF'XL, color='000000'XL, charsize=1.2, /nodata, $
            xtickinterval=400, $
            xrange=[55400,56900], $
            yrange=[1.8, 2.4], /xs, /ys
    oplot, (mjds_flag0[box-1]).ToArray(), (gains_flag0[box-1]).ToArray(), psym=4, color=5
    oplot, (mjds_flag1[box-1]).ToArray(), (gains_flag1[box-1]).ToArray(), psym=2, color=6
    oplot, (mjds_flag2[box-1]).ToArray(), (gains_flag2[box-1]).ToArray(), psym=7, color=4
    oplot, (mjds_flag3[box-1]).ToArray(), (gains_flag3[box-1]).ToArray(), psym=5, color=2
    
    legend, ['0', '1', '2', '3'], psym = [4, 2, 7, 5], colors = [5,6,4,2], position=[56700,2.05]
  endfor

  device, /close
  file_move, 'idl.ps', psname
  cgps2pdf, psname
  file_delete, psname
  set_plot, 'x'
  
  
END