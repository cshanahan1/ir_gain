PRO gainvstime_oplot_lincorrs, nsampdir


;+
; NAME:
;        GAINVSTIME_OPLOT_LINCORRS
; 
; AUTHOR:
;        C. Gosmeyer, Apr. 2015
;
; PURPOSE:
;        Overplots the gain vs time for both linearity
;        corrections.
;
; INPUTS:
;        nsampdir = Name of nsamp directory. Plot will be generated here.
;
; OUTPUTS:
;        PDF plot.
;
; EXAMPLE:
;        IDL> gainvstime_oplot_lincorrs, '14nsamp'
;
; NOTES:
;        You will need edit the paths to the 'gainlist*.dat' files.
;-


basedir = '/grp/hst/wfc3b/cgosmeyer/Projects/IR_Gain_monitor/data/'
file_basename = '_ipc_maskbad'

if (nsampdir eq '14nsamp') then begin
    ;; ONLY goes over SPARS50 data.
    
    ;; Read in old lincorr gainlist file.
    readcol, basedir + nsampdir + '/old_lincorr/SPARS50_test/gainlist'+file_basename+'.dat', inf1_old, inf2_old, $
             g1_old, ug1_old, g2_old, ug2_old, g3_old, ug3_old, g4_old, ug4_old, $
             t1_old, t2_old, format='(a,a,f,f,f,f,f,f,f,f,f,f)' 

    ;; Read in new lincorr gainlist file.
    readcol, basedir + nsampdir + '/new_lincorr/SPARS50/gainlist'+file_basename+'.dat', inf1_new, inf2_new, $
             g1_new, ug1_new, g2_new, ug2_new, g3_new, ug3_new, g4_new, ug4_new, $
             t1_new, t2_new, format='(a,a,f,f,f,f,f,f,f,f,f,f)' 

endif else begin
    ;; Read in old lincorr gainlist file.
    readcol, basedir + nsampdir + '/old_lincorr/25x25/gainlist'+file_basename+'.dat', inf1_old, inf2_old, $
             g1_old, ug1_old, g2_old, ug2_old, g3_old, ug3_old, g4_old, ug4_old, $
             t1_old, t2_old, format='(a,a,f,f,f,f,f,f,f,f,f,f)' 

    ;; Read in new lincorr gainlist file.
    readcol, basedir + nsampdir + '/new_lincorr/gainlist'+file_basename+'.dat', inf1_new, inf2_new, $
             g1_new, ug1_new, g2_new, ug2_new, g3_new, ug3_new, g4_new, ug4_new, $
             t1_new, t2_new, format='(a,a,f,f,f,f,f,f,f,f,f,f)' 
endelse

gains_old = fltarr(4, n_elements(g1_old))
gains_new = fltarr(4, n_elements(g1_new))

gains_old[0, *] = g1_old
gains_old[1, *] = g2_old
gains_old[2, *] = g3_old
gains_old[3, *] = g4_old

help, gains_old
print, gains_old

gains_new[0, *] = g1_new
gains_new[1, *] = g2_new
gains_new[2, *] = g3_new
gains_new[3, *] = g4_new
 
 
help, gains_new
print, gains_new 
 
print, t1_old
help, t1_old

;; Set up the plot.
    
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
    
  psname = nsampdir + 'lincorr_oplot_gain_vs_time' + file_basename + '.ps'
      
  quadno = ['1','4','2','3']

  if nsampdir eq '14nsamp' then yrange=[2.0, 2.5]
  if nsampdir eq '7nsamp' then yrange=[1.8, 2.1]
  
  for box=0, 3 do begin
    plot, t1_old[*], $
          gains_old[box, *], $
          xtit='MJD ', $
          ytit='Gain [e-/ADU]', $
          title='Quad '+quadno[box], $
          xtickformat='(F7.1)', $
          background='FFFFFF'XL, $
          color='000000'XL, $
          charsize=1.2, $
          xrange=[55500, 57200], $
          yrange=yrange, $
          xstyle=1, $
          /nodata
    oplot, t1_old[*], gains_old[box, *], psym=4, color=4 
    oplot, t1_new[*], gains_new[box, *], psym=6, color=6
    legend, ['2008', '2014'], psym = [4, 6], colors = [4, 6]
  endfor

  device, /close
  file_move, 'idl.ps', psname
  cgps2pdf, psname
  file_delete, psname

  set_plot, 'x'
  
  
END