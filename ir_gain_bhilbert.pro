pro ir_gain_bhilbert,infile,infile2,darkfile=darkfile,lowth=lowth,binn=binn,mimic512=mimic512
!p.font=1
device,decompose=0
loadct,39

if keyword_set(binn) eq 0 then binn=1


lowt=0.4
if keyword_set(lowth) then lowt=lowth

;--------------------------------------------------
;PURPOSE: Calculate the gain associated with a WFC3-IR
;         ramp.  This script uses a method similar to
;         that used for the ir_tv_readnoise.pro calculation,
;         where pixels are scaled to the same level 
;         relative to one another.
;
;INPUTS:  infile,infile2
;
;KEYOWRDS: darkfile
;
;OUTPUTS: variance vs signal plot, and resulting gain
;HISTORY:
;
;27 June 2007 - BNH - created
;28 Nov. 2014 - CMG - took over
;----------------------------------------------------

;MAP OF UNSTABLE PIXELS TO USE AS A MASK
unstab_file = ''

;MAKE SURE WE HAVE IR DATA
if strcompress(sxpar(headfits(infile),'DETECTOR'),/remove_all) eq 'UVIS' then begin
    print,'WARNING! ' + infile + ' is listed as a UVIS file,'
    print,'in the header. Aborting.'
    ;return,0
endif


if strcompress(sxpar(headfits(infile),'DETECTOR'),/remove_all) ne 'IR' then begin
    print,'WARNING! ' + infile + ' is not explicitly'
    print,'listed as an IR file in the header.'  
    print,'Attempting to proceed...'
endif

;READ IN DATA AND DARK
orig = ramp_read(infile)
orig2 = ramp_read(infile2)
;orig3 = ramp_read(infile3)
;orig4 = ramp_read(infile4)
xd = n_elements(orig[0,*,0])
yd = n_elements(orig[0,0,*])
zd = n_elements(orig[*,0,0])


;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;TRY IPC DECONVOLUTION
for i=0,n_elements(orig[*,0,0])-1 do begin
    tmp = reform(orig[i,*,*])
    ipcdecon,tmp,alpha=0.01712,beta=0.01256
;    ipcdecon_4vals,tmp,alphaleft=0.01700,alpharight=0.01724,betaabove=0.01249,betabelow=0.01264
    orig[i,*,*] = tmp

    tmp = reform(orig2[i,*,*])
;    ipcdecon_4vals,tmp,alphaleft=0.01700,alpharight=0.01724,betaabove=0.01249,betabelow=0.01264
    ipcdecon,tmp,alpha=0.01712,beta=0.01256
    orig2[i,*,*] = tmp

;;    tmp = reform(orig3[i,*,*])
;;    ipcdecon,tmp,alpha=0.01
;;    orig3[i,*,*] = tmp
;;
;;    tmp = reform(orig4[i,*,*])
;;    ipcdecon,tmp,alpha=0.01
;;    orig4[i,*,*] = tmp
endfor

print,''
print,'IPC DECON PERFORMED ON INPUT RAMPS, ONE READ AT A TIME'
print,''

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

orig = orig[*,5:xd-6,5:yd-6]
orig2 = orig2[*,5:xd-6,5:yd-6]
;orig3 = orig3[*,5:xd-6,5:yd-6]
;orig4 = orig4[*,5:xd-6,5:yd-6]

;===========================
;rescale imas to dn from dn/sec
;because i reprocessed in calwf3 with
;crcorr and unitcorr on

;print,'RESCALING DATA BY EXPTIME TO MAKE UP FOR CRCORR/UNITCORR BOTH ON'
;print,''
;times = ramp_times(infile)
;for i=0,zd-1 do begin 
;    orig[i,*,*] = orig[i,*,*] * times[i]
;    orig2[i,*,*] = orig2[i,*,*] * times[i]
;    orig3[i,*,*] = orig3[i,*,*] * times[i]
;    orig4[i,*,*] = orig4[i,*,*] * times[i]
;endfor
;===========================

if keyword_set(darkfile) then begin
    dark = ramp_read(darkfile)
    dark = dark[*,5:xd-6,5:yd-6]
endif


;=====================================================
;FLAT FIELD FOR FIXED PATTERN NOISE REMOVAL
;F125W
;;fits_read,'/grp/hst/cdbs/iref/sca20262i_pfl.fits',flat1
;;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11433/gain/smov_f125w_medflat_thruVisit48.fits',exten=1,flat
;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11420/gain/smov_11420_f125w_medflat.fits',exten=1,flat
;;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11433/light_leak/F125W_SMOVmedianFlat_exclLightLeak.fits',exten=1,flat

;F140W for Cycle 17 data
;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11433/median_SMOV_flats/F140W_SMOVmedianFlat_exclLightLeak.fits',exten=1,flat
;fits_read,'/grp/hst/wfc3d/hilbert/cycle17/11930/calwf3_reproc/F139M/ibbv03saq_flt.fits',exten=1,flat


;F139M
;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11433/median_SMOV_flats/F139M_SMOVmedianFlat_exclLightLeak.fits',exten=1,flat
;fits_read,'/grp/hst/wfc3d/hilbert/cycle17/11930/calwf3_reproc/F139M/ibbv02s1q_flt.fits',exten=1,flat

;F126N
;;fits_read,'/grp/hst/cdbs/iref/sca20263i_pfl.fits',flat
;fits_read,'../Visit31/iabg31frq_ima.fits',exten=1,flat
;;extime = sxpar(headfits('../Visit31/iabg31frq_ima.fits'),'EXPTIME')
;;flat = flat * 1.
;;print,'F126N FLAT SET TO 1.0'
;;flat = flat / extime
;print,'USING F126N SMOV FLAT TO REMOVE FPN'

;=================
;;fits_read,'/grp/hst/wfc3c/hilbert/SMOV/11420/Visit31/iabg31e5q_ima.fits',exten=1,flat
;resistant_mean,flat[300:500,550:750],3,tmp
;flat = flat / tmp

;flat = flat * flat1

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
;TRY IPC DECONVOLUTION
;ipcdecon,flat,alpha=0.01
;print,''
;print,'IPC DECON PERFORMED ON THE NORMALIZING FLAT FIELD'
;print,''
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


;=================

;print,'USING E5Q RAMP AS FLAT TO MATCH TO E8Q, TO REMOVE FPN'
;print,'USING 11433 median F125W SMOV FLAT TO REMOVE FPN'

;APPLY FLAT
;flat = flat[5:1018,5:1018]

;EXTRACT SUBARRAY IF NECESSARY
subsize = sxpar(headfits(infile,exten=1),'NAXIS1')
;if subsize eq 522 then flat = flat[251:762,251:762]
;if subsize eq 266 then flat = flat[379:674,379:674]
;;if subsize eq 138 then flat = flat[]
;;if subsize eq 74 then flat = flat[]

;stop
;for i=0,zd-1 do begin & $
;    orig[i,*,*] = orig[i,*,*] / flat & $
;    orig2[i,*,*] = orig2[i,*,*] / flat & $
;    orig3[i,*,*] = orig3[i,*,*] / flat & $
;    orig4[i,*,*] = orig4[i,*,*] / flat & $
;endfor
;stop    
;=====================================================
;print,'after flat app ',n_elements(where(finite(orig) eq 1))


;=====================================================
;FLAT FIELD *RAMP* FOR FIXED PATTERN NOISE REMOVAL?
;F125W

;print,'USING F125W SMOV FLAT RAMP TO REMOVE FPN'
;flat = ramp_read('F125W_medianflatramp_11420.fits')


;APPLY FLAT
;flat = flat[*,5:1018,5:1018]

;EXTRACT SUBARRAY IF NECESSARY
;subsize = sxpar(headfits(infile,exten=1),'NAXIS1')
;if subsize eq 522 then flat = flat[*,251:762,251:762]
;if subsize eq 266 then flat = flat[*,379:674,379:674]

;for i=0,zd-1 do begin & $
;    resistant_mean,flat[i,400:500,400:500],3,fmn
;    orig[i,*,*] = orig[i,*,*] / (flat[i,*,*] / fmn) & $
;    orig2[i,*,*] = orig2[i,*,*] / (flat[i,*,*] / fmn) & $
;endfor    
;=====================================================
;stop

;=====================================================
;TRY SUBTRACTING FIRST READ RATHER THAN 0TH, WHICH MAY
;BE SCREWY DUE TO CALWF3
;orig = orig[1:*,*,*]
;orig2 = orig2[1:*,*,*]
;orig3 = orig3[1:*,*,*]
;orig4 = orig4[1:*,*,*]
;zd = zd - 1
;for i=0,zd-1 do begin & $
;    orig[i,*,*] = orig[i,*,*] - orig[0,*,*] & $
;    orig2[i,*,*] = orig2[i,*,*] - orig2[0,*,*] & $
;    orig3[i,*,*] = orig3[i,*,*] - orig3[0,*,*] & $
;    orig4[i,*,*] = orig4[i,*,*] - orig4[0,*,*] & $
;endfor    
;=====================================================
;stop


;=====================================================
;TRY DOUBLE DIFFERENCES
;testorig = fltarr(6,1014,1014)
;testorig2 = fltarr(6,1014,1014)
;for i=0,5 do begin
;    testorig[i,*,*]=(orig[(2*i)+4,*,*]-orig[(2*i)+3,*,*])-(orig[2,*,*]-orig[1,*,*])
;    testorig2[i,*,*]=(orig2[(2*i)+4,*,*]-orig2[(2*i)+3,*,*])-(orig2[2,*,*]-orig2[1,*,*])
;endfor
;orig = testorig
;orig2 = testorig2
;zd = 6
;=====================================================



;=====================================================
;TRY CREATING CDS PAIRS????
;cds1 = fltarr(zd/2,xd-10,yd-10)
;cds2 = fltarr(zd/2,xd-10,yd-10)
;for i=0,zd/2-1 do begin & $
;    cds1[i,*,*] = orig[(2*i)+1,*,*] - orig[2*i,*,*] & $
;    cds2[i,*,*] = orig2[(2*i)+1,*,*] - orig2[2*i,*,*] & $
;endfor
;orig = cds1
;orig2 = cds2
;zd = n_elements(cds1[*,0,0])
;=====================================================


;=====================================================
;NORMALIZE THE MEAN SIGNAL LEVELS TO ONE ANOTHER
;USE THE MEAN OF THE LAST READ TO NORMALIZE
;GO QUAD BY QUAD AND READ BY READ
x1list=([391,391,507,507])
x2list=([506,506,728,622])
y1list=([507,251,0,507])
y2list=([762,506,265,762])
xdnr = xd - 10
;
;if subsize eq 522 then begin
;    x1list=[140,140,256,256]
;    x2list=[255,255,477,371]
;    y1list=[256,0,0,256]
;    y2list=[511,255,140,511]
;endif
;
;if subsize eq 266 then begin
;    x1list=[12,12,128,128]
;    x2list=[127,127,243,243]
;    y1list=[128,0,0,128]
;    y2list=[243,127,127,243]
;endif


;for i=1,zd-1 do begin & $

;;    resistant_mean,orig[i,100:506,507:950],3,o1q1mean & $
;;    resistant_mean,orig2[i,100:506,507:950],3,o2q1mean & $
;
;;    resistant_mean,orig[i,100:506,100:506],3,o1q2mean & $
;;    resistant_mean,orig2[i,100:506,100:506],3,o2q2mean & $
;
;;    resistant_mean,orig[i,682:837,80:250],3,o1q3mean & $
;;    resistant_mean,orig2[i,682:837,80:250],3,o2q3mean & $
;
;;    resistant_mean,orig[i,610:800,722:837],3,o1q4mean & $
;;    resistant_mean,orig2[i,610:800,722:837],3,o2q4mean & $
;
;i=7
;    resistant_mean,orig[i,x1list[0]:x2list[0],y1list[0]:y2list[0]],3,o1q1mean & $
;    resistant_mean,orig2[i,x1list[0]:x2list[0],y1list[0]:y2list[0]],3,o2q1mean & $
;;    resistant_mean,orig3[i,x1list[0]:x2list[0],y1list[0]:y2list[0]],3,o3q1mean & $
;;    resistant_mean,orig4[i,x1list[0]:x2list[0],y1list[0]:y2list[0]],3,o4q1mean & $

;    resistant_mean,orig[i,x1list[1]:x2list[1],y1list[1]:y2list[1]],3,o1q2mean & $
;    resistant_mean,orig2[i,x1list[1]:x2list[1],y1list[1]:y2list[1]],3,o2q2mean & $
;;    resistant_mean,orig3[i,x1list[1]:x2list[1],y1list[1]:y2list[1]],3,o3q2mean & $
;;    resistant_mean,orig4[i,x1list[1]:x2list[1],y1list[1]:y2list[1]],3,o4q2mean & $

;    resistant_mean,orig[i,x1list[2]:x2list[2],y1list[2]:y2list[2]],3,o1q3mean & $
;    resistant_mean,orig2[i,x1list[2]:x2list[2],y1list[2]:y2list[2]],3,o2q3mean & $
;;    resistant_mean,orig3[i,x1list[2]:x2list[2],y1list[2]:y2list[2]],3,o3q3mean & $
;;    resistant_mean,orig4[i,x1list[2]:x2list[2],y1list[2]:y2list[2]],3,o4q3mean & $

;    resistant_mean,orig[i,x1list[3]:x2list[3],y1list[3]:y2list[3]],3,o1q4mean & $
;    resistant_mean,orig2[i,x1list[3]:x2list[3],y1list[3]:y2list[3]],3,o2q4mean & $
;;    resistant_mean,orig3[i,x1list[3]:x2list[3],y1list[3]:y2list[3]],3,o3q4mean & $
;;    resistant_mean,orig4[i,x1list[3]:x2list[3],y1list[3]:y2list[3]],3,o4q4mean & $
;for i=1,zd-1 do begin & $
;BRING OTHER RAMPS UP/DOWN TO THE LEVEL OF RAMP2
;    orig[i,0:xdnr/2-1,xdnr/2:*] = orig[i,0:xdnr/2-1,xdnr/2:*] * o2q1mean / o1q1mean & $
;    orig[i,0:xdnr/2-1,0:xdnr/2-1] = orig[i,0:xdnr/2-1,0:xdnr/2-1] * o2q2mean / o1q2mean& $
;    orig[i,xdnr/2:*,0:xdnr/2-1] = orig[i,xdnr/2:*,0:xdnr/2-1] * o2q3mean / o1q3mean & $    
;    orig[i,xdnr/2:*,xdnr/2:*] = orig[i,xdnr/2:*,xdnr/2:*] * o2q4mean / o1q4mean & $
;
;;    orig3[i,0:xdnr/2-1,xdnr/2:*] = orig3[i,0:xdnr/2-1,xdnr/2:*] * o2q1mean / o3q1mean & $
;;    orig3[i,0:xdnr/2-1,0:xdnr/2-1] = orig3[i,0:xdnr/2-1,0:xdnr/2-1] * o2q2mean / o3q2mean & $
;;    orig3[i,xdnr/2:*,0:xdnr/2-1] = orig3[i,xdnr/2:*,0:xdnr/2-1] * o2q3mean / o3q3mean & $
;;    orig3[i,xdnr/2:*,xdnr/2:*] = orig3[i,xdnr/2:*,xdnr/2:*] * o2q4mean / o3q4mean & $
;
;;    orig4[i,0:xdnr/2-1,xdnr/2:*] = orig4[i,0:xdnr/2-1,xdnr/2:*] * o2q1mean / o4q1mean & $
;;    orig4[i,0:xdnr/2-1,0:xdnr/2-1] = orig4[i,0:xdnr/2-1,0:xdnr/2-1] * o2q2mean / o4q2mean & $
;;    orig4[i,xdnr/2:*,0:xdnr/2-1] = orig4[i,xdnr/2:*,0:xdnr/2-1] * o2q3mean / o4q3mean & $
;;    orig4[i,xdnr/2:*,xdnr/2:*] = orig4[i,xdnr/2:*,xdnr/2:*] * o2q4mean / o4q4mean & $
;
;;    orig[i,0:xdnr/2-1,xdnr/2:*] = orig[i,0:xdnr/2-1,xdnr/2:*] * o4q1mean / o1q1mean & $
;;    orig[i,0:xdnr/2-1,0:xdnr/2-1] = orig[i,0:xdnr/2-1,0:xdnr/2-1] * o4q2mean / o1q2mean & $
;;    orig[i,xdnr/2:*,0:xdnr/2-1] = orig[i,xdnr/2:*,0:xdnr/2-1] * o4q3mean / o1q3mean & $
;;    orig[i,xdnr/2:*,xdnr/2:*] = orig[i,xdnr/2:*,xdnr/2:*] * o4q4mean / o1q4mean & $
;
;;    orig2[i,0:xdnr/2-1,xdnr/2:*] = orig2[i,0:xdnr/2-1,xdnr/2:*] * o4q1mean / o2q1mean & $
;;    orig2[i,0:xdnr/2-1,0:xdnr/2-1] = orig2[i,0:xdnr/2-1,0:xdnr/2-1] * o4q2mean / o2q2mean & $
;;    orig2[i,xdnr/2:*,0:xdnr/2-1] = orig2[i,xdnr/2:*,0:xdnr/2-1] * o4q3mean / o2q3mean & $
;;    orig2[i,xdnr/2:*,xdnr/2:*] = orig2[i,xdnr/2:*,xdnr/2:*] * o4q4mean / o2q4mean & $
;
;;    orig3[i,0:xdnr/2-1,xdnr/2:*] = orig3[i,0:xdnr/2-1,xdnr/2:*] * o4q1mean / o3q1mean & $
;;    orig3[i,0:xdnr/2-1,0:xdnr/2-1] = orig3[i,0:xdnr/2-1,0:xdnr/2-1] * o4q2mean / o3q2mean & $
;;    orig3[i,xdnr/2:*,0:xdnr/2-1] = orig3[i,xdnr/2:*,0:xdnr/2-1] * o4q3mean / o3q3mean & $
;;    orig3[i,xdnr/2:*,xdnr/2:*] = orig3[i,xdnr/2:*,xdnr/2:*] * o4q4mean / o3q4mean & $

;endfor
;=====================================================

;print,'after rescale ',n_elements(where(finite(orig) eq 1))



;MASK PIXELS WITH NON-LIN CORRECTION OF >5% 
;compfile1 = strmid(infile,0,strlen(infile)-9)+'.fits'
;compfile2 = strmid(infile2,0,strlen(infile2)-9)+'.fits'
;fits_read,compfile1,exten=1,comp1
;fits_read,compfile2,exten=1,comp2
;comp1 = comp1[5:1018,5:1018]
;comp2 = comp2[5:1018,5:1018]

;diff1 = (comp1-orig[zd-1,*,*])/comp1
;diff2 = (comp2-orig2[zd-1,*,*])/comp2

;bad1 = where(diff1 ge .04)
;bad2 = where(diff2 ge .04)
;print,'% of pixels with >5% nonlin corr: ',n_elements(bad1)/(1014.*1014)*100,n_elements(bad2)/(1014.*1014)*100
;APPLY THESE IN THE STEP BELOW


;TRY MASKING THE UNSTABLE PIXELS FOUND IN THE LINEARITY STUDY
;fits_read,'unstable_pix_from_linfits_5sigma.fits',mask
;fits_read,'/grp/hst/wfc3/analysis_files/IR/badpix_mask/TV3_IR_bad_pix_mask.fits',mask
;fits_read,'/user/hilbert/WFC3/IR_badpixmask/ir_badpixel_mask_fromcdbscode.fits',masktmp
fits_read,infile,exten=3,masktmp
fits_read,infile2,exten=3,masktmp2


binmasktmp = reform(binary(fix(masktmp)),16,xd,xd)
binmasktmp2 = reform(binary(fix(masktmp2)),16,xd,xd)
print,''
print,'# PIXELS WITH DQ VALUES:'
print,'0 - ' + strcompress(string(n_elements(where(masktmp eq 0))),/remove_all)
print,'1 - ' + strcompress(string(n_elements(where(binmasktmp[15,*,*] eq 1))),/remove_all)
print,'2 - ' + strcompress(string(n_elements(where(binmasktmp[14,*,*] eq 1))),/remove_all)
print,'4 - ' + strcompress(string(n_elements(where(binmasktmp[13,*,*] eq 1))),/remove_all)
print,'8 - ' + strcompress(string(n_elements(where(binmasktmp[12,*,*] eq 1))),/remove_all)
print,'16 - ' + strcompress(string(n_elements(where(binmasktmp[11,*,*] eq 1))),/remove_all)
print,'32 - ' + strcompress(string(n_elements(where(binmasktmp[10,*,*] eq 1))),/remove_all)
print,'64 - ' + strcompress(string(n_elements(where(binmasktmp[9,*,*] eq 1))),/remove_all)
print,'128 - ' + strcompress(string(n_elements(where(binmasktmp[8,*,*] eq 1))),/remove_all)
print,'256 - ' + strcompress(string(n_elements(where(binmasktmp[7,*,*] eq 1))),/remove_all)
print,'512 - ' + strcompress(string(n_elements(where(binmasktmp[6,*,*] eq 1))),/remove_all)
print,'1024 - ' + strcompress(string(n_elements(where(binmasktmp[5,*,*] eq 1))),/remove_all)
print,'2048 - ' + strcompress(string(n_elements(where(binmasktmp[4,*,*] eq 1))),/remove_all)
print,'4096 - ' + strcompress(string(n_elements(where(binmasktmp[3,*,*] eq 1))),/remove_all)
print,'8192 - ' + strcompress(string(n_elements(where(binmasktmp[2,*,*] eq 1))),/remove_all)
print,'16384 - ' + strcompress(string(n_elements(where(binmasktmp[1,*,*] eq 1))),/remove_all)
print,'32768 - ' + strcompress(string(n_elements(where(binmasktmp[0,*,*] eq 1))),/remove_all)
print,''


;print,''
;print,'# PIXELS WITH DQ VALUES:'
;print,'0 - ' + strcompress(string(n_elements(where(masktmp eq 0))),/remove_all)
;print,'1 - ' + strcompress(string(n_elements(where(masktmp eq 1))),/remove_all)
;print,'2 - ' + strcompress(string(n_elements(where(masktmp eq 2))),/remove_all)
;print,'4 - ' + strcompress(string(n_elements(where(masktmp eq 4))),/remove_all)
;print,'8 - ' + strcompress(string(n_elements(where(masktmp eq 8))),/remove_all)
;print,'16 - ' + strcompress(string(n_elements(where(masktmp eq 16))),/remove_all)
;print,'32 - ' + strcompress(string(n_elements(where(masktmp eq 32))),/remove_all)
;print,'64 - ' + strcompress(string(n_elements(where(masktmp eq 64))),/remove_all)
;print,'128 - ' + strcompress(string(n_elements(where(masktmp eq 128))),/remove_all)
;print,'256 - ' + strcompress(string(n_elements(where(masktmp eq 256))),/remove_all)
;print,'512 - ' + strcompress(string(n_elements(where(masktmp eq 512))),/remove_all)
;print,'1024 - ' + strcompress(string(n_elements(where(masktmp eq 1024))),/remove_all)
;print,'2048 - ' + strcompress(string(n_elements(where(masktmp eq 2048))),/remove_all)
;print,'4096 - ' + strcompress(string(n_elements(where(masktmp eq 4096))),/remove_all)
;print,'8192 - ' + strcompress(string(n_elements(where(masktmp eq 8192))),/remove_all)
;print,''
;mask=fltarr(xd,xd)
;mask2=fltarr(xd,yd)
;mask[5:1018,5:1018]=masktmp
;if strlen(unstab_file) gt 1 then begin
;    fits_read,unstab_file,mask
mask = masktmp[5:xd-6,5:xd-6]
mask2 = masktmp2[5:xd-6,5:yd-6]
;MASK OUT PIXELS MARKED AS REED-SOLOMAN ERROR, FILL ERROR, DEAD, PERM
;BAD 0TH READ, HOT, UNSTABLE, WARM, BAD REFPIX, SATURATED, AND BAD IN
;FLAT

    for i=0,n_elements(orig[*,0,0])-1 do begin
        tmp = reform(orig[i,*,*])
        tmp[where((mask ne 0) and (mask ne 2048) and (mask2 ne 0) and (mask2 ne 2048))] = !values.f_nan
;        tmp[bad1] = !values.f_nan
;        tmp[bad2] = !values.f_nan
        orig[i,*,*] = tmp
        
        tmp = reform(orig2[i,*,*])
        tmp[where((mask ne 0) and (mask ne 2048) and (mask2 ne 0) and (mask2 ne 2048))] = !values.f_nan
;        tmp[bad1] = !values.f_nan
;        tmp[bad2] = !values.f_nan
        orig2[i,*,*] = tmp

;        tmp = reform(orig3[i,*,*])
;        tmp[where(mask lt 257)] = !values.f_nan
;;        tmp[bad2] = !values.f_nan
;        orig3[i,*,*] = tmp

;        tmp = reform(orig4[i,*,*])
;        tmp[where(mask lt 257)] = !values.f_nan
;        orig4[i,*,*] = tmp
    endfor
;endif


;======================================================
;TRY MASKING WEIRD PORTIONS OF THE DETECTOR. SET THOSE
;PIXELS YOU WANT TO AVOID EQUAL TO ZERO.

if subsize gt 1000 then begin

;exclude edges to match 512x512 subarray
;    if keyword_set(mimic512) then begin
;        print,'MASKING EDGES TO MATCH 512 SUBARRAY'
;        orig[*,0:250,*] = !values.f_nan
;        orig[*,*,0:250] = !values.f_nan
;        orig[*,763:*,*] = !values.f_nan
;        orig[*,*,763:*] = !values.f_nan
;        
;        orig2[*,0:250,*] = !values.f_nan
;        orig2[*,*,0:250] = !values.f_nan
;        orig2[*,763:*,*] = !values.f_nan
;        orig2[*,*,763:*] = !values.f_nan
;    endif

;exclude wagon wheel area   
    orig[*,818:*,0:595] = !values.f_nan
    orig2[*,818:*,0:595] = !values.f_nan
;;    orig3[*,762:*,*] = !values.f_nan
;;    orig4[*,762:*,*] = !values.f_nan
    
;exclude left side light leak from low
;irradiance flats
;    orig[*,0:160,*] = !values.f_nan
;    orig2[*,0:160,*] = !values.f_nan
;;    orig3[*,0:160,*] = !values.f_nan
;;    orig4[*,0:160,*] = !values.f_nan
    
;lose the death star
    orig[*,290:425,0:130] = !values.f_nan
    orig2[*,290:425,0:130] = !values.f_nan
;;    orig3[*,290:425,0:130] = !values.f_nan
;;    orig4[*,290:425,0:130] = !values.f_nan
    
;weird area to the right of the death star
    orig[*,290:545,0:130] = !values.f_nan
    orig2[*,290:545,0:130] = !values.f_nan
;;    orig3[*,290:545,0:130] = !values.f_nan
;;    orig4[*,290:545,0:130] = !values.f_nan
    
;glow on upper edge of quad 1
    orig[*,370:563,974:*] = !values.f_nan
    orig2[*,370:563,974:*] = !values.f_nan
;;    orig3[*,370:563,974:*] = !values.f_nan
;;    orig4[*,370:563,974:*] = !values.f_nan

endif
;======================================================







;TRY MASKING USING 3X3SIGMA MASK FROM INF[1]
;fits_read,'/data/thing14/WFC3/TV2/IR_gain/ir02s11_absgain_meb2/july02/3Sigma3Times_mask_1isbad_from_file2.fits',mask
;mask = mask[5:1018,5:1018]
;for i=0,n_elements(orig[*,0,0])-1 do begin
;    tmp = reform(orig[i,*,*])
;    tmp[where(mask eq 1)] = !values.f_nan
;    orig[i,*,*] = tmp
;
;    tmp = reform(orig2[i,*,*])
;    tmp[where(mask eq 1)] = !values.f_nan
;    orig2[i,*,*] = tmp
;endfor



;GET THE EXPOSURE TIMES
seq = strupcase(strcompress(sxpar(headfits(infile),'SAMP_SEQ',count=seqcount),/remove_all))
xd = xd - 10
yd = yd - 10

if xd eq 1014 then xdt = xd + 10 else xdt = xd
;if (seqcount ne 0) then exptime = sample_times(seq,zd,xdt) else $
  exptime = ramp_times(infile)


;NORMALIZE THE MEAN DARK SIGNAL TO THE MEAN DATA SIGNAL
;PIXEL-BY-PIXEL
orignorm = orig
orignorm2= orig2
;for i=0,n_elements(orig[0,*,0])-1 do begin  
;    for j=0,n_elements(orig[0,*,0])-1 do begin
;        resistant_mean,orig[*,i,j],3,norm 
;        orignorm[*,i,j] = orig[*,i,j] - norm
;        resistant_mean,dark[*,i,j],3,tmp1 
;        dark[*,i,j] = dark[*,i,j] - tmp1
;        resistant_mean,orig2[*,i,j],3,norm 
;        orignorm2[*,i,j] = orig2[*,i,j] - norm
;    endfor 
;endfor

;-----------------------------------------------------------

;SIGMA CLIP 3 TIMES AT 3-SIGMA A LA SYLVIA

;this step yeilds no improvement in the results


;for i=1,n_elements(orignorm[*,0,0])-1 do begin

;try masking with the same set of pixels in all cases.

;run this once on a file, collect the bad pixel mask
;write it to a file, and then put in a section to read
;that mask in and apply it in all cases.

;i=12

;    tmp = reform(orignorm[i,*,*])
;    tmp2 = reform(orignorm2[i,*,*])
;    for ctr = 0,2 do begin
;        resistant_mean,tmp,3,mmm
;;;        mmm = moment(tmp,/nan)
;        k = robust_sigma(tmp)
;        mmm = [mmm,k]
;        high = mmm[0] + 3*sqrt(mmm[1])
;        low = mmm[0] - 3*sqrt(mmm[1])
;        bad = where((tmp gt high) or (tmp lt low))
;        if bad[0] ne -1 then tmp[bad] = !values.f_nan
;print,high,low,n_elements(bad)
;        resistant_mean,tmp2,3,mmm
;;;        mmm = moment(tmp2,/nan)
;        k = robust_sigma(tmp2)
;        mmm = [mmm,k]
;        high = mmm[0] + 3*sqrt(mmm[1])
;        low = mmm[0] - 3*sqrt(mmm[1])
;        bad2 = where((tmp2 gt high) or (tmp2 lt low))
;        if bad2[0] ne -1 then tmp2[bad2] = !values.f_nan
;print,high,low,n_elements(bad)
;        
;    endfor
;    orignorm[i,*,*] = tmp
;    orignorm2[i,*,*] = tmp2


;newmask = fltarr(1014,1014)
;newmask[where(finite(tmp) eq 0)] = 1
;fullnewmask = fltarr(1024,1024)
;fullnewmask[5:1018,5:1018] = newmask
;fits_open,'3Sigma3Times_mask_1isbad_from_file2.fits',f,/write
;fits_write,f,fullnewmask
;fits_close,f
;stop

;endfor
;-----------------------------------------------------



;for ll=0,8 do print,moment(orignorm[ll,0:506,507:*],/nan)

;goto,fini



;origsub = orignorm
;origsub2 = orignorm2
;SUBTRACT DARK CURRENT
if keyword_set(darkfile) then begin
    orig = orig - dark
    orig2 = orig2 - dark
;    orig3 = orig3 - dark
;    orig4 = orig4 - dark
endif

;SUM AND DIFFERENCE IMAGES
diff = (orig - orig2); - (orig3 - orig4)
sum = (orig + orig2); + (orig3 + orig4)) / 2.
;diff2 = (orig - orig2) - (orig3 - orig4)
;stop

sfile = strmid(infile,0,strlen(infile)-5)+'_'+strmid(infile2,0,strlen(infile2)-5)+'_sumfile.fits'
dfile = strmid(sfile,0,strlen(sfile)-12)+'difffile.fits'
fits_open,sfile,loony,/write
for oo=0,13 do fits_write,loony,reform(sum[oo,*,*])
fits_open,dfile,loony2,/write
for oo=0,13 do fits_write,loony2,reform(diff[oo,*,*])
fits_close,loony
fits_close,loony2


scheck=fltarr(9)
dcheck=fltarr(9)
dcheck2=fltarr(9)
;for i=1,9 do begin & resistant_mean,sum[i,161:506,512:973],3,tmp & scheck[i-1]=tmp & dcheck[i-1]=robust_sigma(diff[i,161:506,512:973]) & dcheck2[i-1]=robust_sigma(diff2[i,161:506,512:973]) & endfor
;plot,scheck,dcheck,psym=4,yr=[50,120]
;oplot,scheck,dcheck2/sqrt(2),psym=5

;h1 = histogram(diff[8,161:500,131:500],locations=b1,/nan,max=300,min=-300,binsize=0.2)
;h2 = histogram(diff2[8,161:500,131:500],locations=b2,/nan,max=300,min=-300,binsize=0.2)
;plot,b1,h1
;oplot,b2,h2,color=100
;print,robust_sigma(diff[8,161:500,131:500])
;print,robust_sigma(diff2[8,161:500,131:500])/sqrt(2)
;stop

;window,3,xsize=800,ysize=800
;tmp = reform(diff[14,*,*])
;tmpc = congrid(tmp[161:700,426:973],800,800)
;tmpc[where(tmpc gt 500)] = 500
;tmpc[where(tmpc lt -500)] = -500
;tmph = adapt_hist_equal(tmpc,nregions=25)
;loadct,26
;tvscl,tmph

;window,4,xsize=800,ysize=800
;tmp2 = reform(diff2[14,*,*])
;tmpc2 = congrid(tmp2[161:700,426:973],800,800)
;tmpc2[where(tmpc2 gt 500)] = 500
;tmpc2[where(tmpc2 lt -500)] = -500
;tmph2 = adapt_hist_equal(tmpc2,nregions=25)
;loadct,26
;tvscl,tmph2

;stop



;++++++++++++++++++++++++++++++++++++++++++++++
;DIFF OF DIFF
;diff56 = fltarr(15,1014,1014)
;for i=0,14 do begin
;    fits_read,'difframp56.fits',exten=i+1,hh
;    diff56[i,*,*]=hh
;endfor
;diff = diff-diff56
;++++++++++++++++++++++++++++++++++++++++++++++



;BINNING------------
bsize=binn
diffb=fltarr(zd,1014/bsize,1014/bsize)
sumb=fltarr(zd,1014/bsize,1014/bsize)
;x1list=[200,200,507,507]/bsize
;x2list=[506,506,913,913]/bsize
;y1list=[507,100,100,507]/bsize
;y2list=[1013,506,506,1013]/bsize

;SMOV test - full frame
;x1list=[300,300,633,633]/bsize
;x2list=[506,506,886,886]/bsize
;y1list=[507,120,126,633]/bsize
;y2list=[900,506,379,886]/bsize


;SMOV have full frames mimic 512x512 subarray
;to see if we get the same answer
;x1list=([140,140,256,256]+251)/bsize
;x2list=([255,255,477,371]+251)/bsize
;y1list=([256,0,-251,256]+251)/bsize
;y2list=([511,255,14,511]+251)/bsize

;PLAY WITH VERY SMALL BOXES
x1list=([250,250,750,750])
x2list=([270,270,770,770])
y1list=([750,250,250,750])
y2list=([770,270,270,770])


;SMOV 512x512 SUBARRAYS
if xd lt 1000 and xd gt 500 then begin
    x1list=[140,140,256,256]/bsize
    x2list=[255,255,371,371]/bsize
    y1list=[256,0,0,256]/bsize
    y2list=[511,255,255,511]/bsize
endif

;SMOV 256 SUBARRAYS
if xd lt 500 and xd gt 200 then begin
    x1list=[80,80,128,128]/bsize
    x2list=[127,127,255,255]/bsize
    y1list=[128,0,0,128]/bsize
    y2list=[255,127,127,255]/bsize
endif

;SMOV 128 SUBARRAYS
if xd lt 200 and xd gt 100 then begin
    x1list=[0,0,64,64]/bsize
    x2list=[63,63,127,127]/bsize
    y1list=[64,0,0,64]/bsize
    y2list=[127,63,63,127]/bsize
endif

;SMOV 64 SUBARRAYS
if xd lt 100 then begin
    x1list=[0,0,32,32]/bsize
    x2list=[31,31,63,63]/bsize
    y1list=[32,0,0,32]/bsize
    y2list=[63,31,31,63]/bsize
endif

if bsize gt 1 then begin
    x2list = x2list - 1
    y2list = y2list - 1
    for zz = 0,zd-1 do begin
        for ii=0,1014./bsize-1 do begin
            for jj=0,1014./bsize-1 do begin
                diffb[zz,ii,jj] = total(diff[zz,bsize*ii:(bsize*ii)+(bsize-1),bsize*jj:bsize*jj+(bsize-1)])
                sumb[zz,ii,jj] = total(sum[zz,bsize*ii:(bsize*ii)+(bsize-1),bsize*jj:bsize*jj+(bsize-1)])
            endfor
        endfor
    endfor
    sum = sumb
    diff=diffb
endif
;-------------------

;SIGMA CLIP 3 TIMES
;for i=1,n_elements(orignorm[*,0,0])-1 do begin
;
;    tmp = reform(sum[i,*,*])
;    tmp2 = reform(diff[i,*,*])
;    for ctr = 0,2 do begin
;        resistant_mean,tmp,3,mmm
;;        mmm = moment(tmp,/nan)
;        mmm = [mmm,robust_sigma(tmp)]
;;        mmm = [mmm,stdev(tmp)]
;        high = mmm[0] + 3*mmm[1]
;        low = mmm[0] - 3*mmm[1]
;        bad = where((tmp gt high) or (tmp lt low))
;        if bad[0] ne -1 then tmp[bad] = !values.f_nan
;
;        resistant_mean,tmp2,3,mmm
;;        mmm = moment(tmp2,/nan)
;        mmm = [mmm,robust_sigma(tmp)]
;;        mmm = [mmm,stdev(tmp)]
;        high = mmm[0] + 3*mmm[1]
;        low = mmm[0] - 3*mmm[1]
;        bad2 = where((tmp2 gt high) or (tmp2 lt low))
;        if bad2[0] ne -1 then tmp2[bad2] = !values.f_nan
;        
;    endfor
;    sum[i,*,*] = tmp
;    diff[i,*,*] = tmp2
;endfor


;print,''
;print,infile,' ',infile2
;for ll=0,8 do print,moment(sum[ll,0:506,507:*],/nan)
;print,''
;for ll=0,8 do print,moment(diff[ll,0:506,507:*],/nan)
;print,''
;goto,fini


;FIND THE VARIANCE AND MEAN IN EACH READ
;x1list=[0,0,507,507]
;x2list=[506,506,913,1013]
;y1list=[507,0,0,507]
;y2list=[1013,506,506,1013]
;x1list=[231,254,507,507]
;x2list=[506,506,506+311,506+277]
;y1list=[507,230,235,506+186]
;y2list=[506+384,506,506,1013]
;x1list=[0,0,506+311,506+277]
;x2list=[231,254,1013,1013]
;y1list=[507,0,0,506]
;y2list=[1013,230,235,506+186]
bsz=80.
bsz2=1.
gain = fltarr(4,14)
gainerr = fltarr(4,14)
gain30k = fltarr(4)
gain30kerr = fltarr(4)

chisqgauss_sum = fltarr(n_elements(orig[*,0,0]))
chisqgauss_diff = fltarr(n_elements(orig[*,0,0]))
chisqmp_sum = fltarr(n_elements(orig[*,0,0]))
chisqmp_diff = fltarr(n_elements(orig[*,0,0]))


;print,infile

quadno = ['1','4','2','3']
xstart = [0,xdnr/2,0,xdnr/2]
ystart = [xdnr/2,xdnr/2,0,0]
;window,1
;;!p.multi=[0,2,2]

;BOXSIZE - WIDTH IN PIXELS
boxsize = 20
nboxes = xdnr / 2 / boxsize
offset = (xdnr/2) - (boxsize * nboxes)


;variance and mean values for entire detector
allmnsm = fltarr(4,zd,nboxes,nboxes)
allvarsm = fltarr(4,zd,nboxes,nboxes)


;loop over quadrants
;;window,2
for ll=0,3 do begin

    mnsm = fltarr(zd,nboxes,nboxes)
    varsm = fltarr(zd,nboxes,nboxes)

;    x1 = x1list[ll]
;    x2 = x2list[ll]
;    y1 = y1list[ll]
;    y2 = y2list[ll]


;;    mnsg = fltarr(n_elements(orig[*,0,0]))
;;    varsg = fltarr(n_elements(orig[*,0,0]))
;    mnsm = fltarr(n_elements(orig[*,0,0]))
;    varsm = fltarr(n_elements(orig[*,0,0]))
    mnssig = fltarr(n_elements(orig[*,0,0]))
    dfssig = fltarr(n_elements(orig[*,0,0]))
    for i=1,n_elements(orig[*,0,0])-1 do begin & $

        for xbox = 0,nboxes-1 do begin
            for ybox = 0,nboxes-1 do begin
                
                sumbox = reform(sum[i,xstart[ll]+boxsize*xbox+offset:xstart[ll]+boxsize*xbox+(boxsize+offset-1),ystart[ll]+boxsize*ybox+offset:ystart[ll]+boxsize*ybox+(boxsize+offset-1)])
                diffbox = reform(diff[i,xstart[ll]+boxsize*xbox+offset:xstart[ll]+boxsize*xbox+(boxsize+offset-1),ystart[ll]+boxsize*ybox+offset:ystart[ll]+boxsize*ybox+(boxsize+offset-1)])


;SIGMA CLIP ONCE TO CLEAN UP===============================
                tmp = sumbox
                tmp2 = diffbox
                
                if max(finite(sumbox)) eq 1 and total(finite(sumbox)) gt 100 then begin
                    for ctr=0,0 do begin  
                        resistant_mean,tmp,3,mmm
;        mmm = moment(tmp,/nan)
                        mmm = [mmm,robust_sigma(tmp)]
;        mmm = [mmm,stdev(tmp)]
                        high = mmm[0] + 3*mmm[1]
                        low = mmm[0] - 3*mmm[1]
                        bad = where((tmp gt high) or (tmp lt low))
                        if bad[0] ne -1 then tmp[bad] = !values.f_nan
                        
                        resistant_mean,tmp2,3,mmm
;        mmm = moment(tmp2,/nan)
                        mmm = [mmm,robust_sigma(tmp)]
;        mmm = [mmm,stdev(tmp)]
                        high = mmm[0] + 3*mmm[1]
                        low = mmm[0] - 3*mmm[1]
                        bad2 = where((tmp2 gt high) or (tmp2 lt low))
                        if bad2[0] ne -1 then tmp2[bad2] = !values.f_nan
                    endfor
                endif
                sumbox = tmp
                diffbox = tmp2
                
;======================================================
                
                
                if max(finite(sumbox)) eq 1 and max(sumbox,/nan) ne min(sumbox,/nan) then begin
                    resistant_mean,sumbox,3,tmp
                    mnsm[i,xbox,ybox] = tmp
                    varsm[i,xbox,ybox] = (robust_sigma(diffbox)/sqrt(1.))^2
                endif                
                
            endfor
        endfor

        allvarsm[ll,*,*,*] = varsm
        allmnsm[ll,*,*,*] = mnsm




;++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;AGGRESSIVELY CUT OUT BOXES WHERE THE VARIANCE IS ABNORMALLY HIGH OR
;LOW - THIS SHOULD HELP WITH EDGE EFFECTS WHERE A BOX INTERSECTS AN
;      AREA SET TO NAN

;;        if i gt 0 then begin
;            !p.multi=0
;            window,0
;            plot,varsm[i,*,*],psym=4,yr=[0,50000]
;;            tmp = reform(varsm[i,*,*])
;;            resistant_mean,tmp[where(tmp gt 100)],3,mn
;print,''
;print,''
;print,'***********************'
;print,'Use line 936 and 944 for non-256 data'
;print,'***********************'
;print,''
;            resistant_mean,tmp,3,mn
;;            dev = robust_sigma(tmp[where(tmp gt 100)])
;            dev = robust_sigma(tmp)
;;            bad = where(tmp gt (mn+3.*dev) or tmp lt (mn-3.*dev))
;;            if bad[0] ne -1 then tmp[bad] = -1000.
;            oplot,tmp,color=100,psym=4
;;            varsm[i,*,*] = tmp
;            wait,1
;;        endif
;stop
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++







;        resistant_mean,sum[i,x1:x2,y1:y2],3,tmp
;        mmm = moment(sum[i,x1:x2,y1:y2],/nan)
;        dev = sqrt(mmm[1])
;
;;        nobins = 14*54.*5  ;factor of 5 added for nozerosub data
;;        if bsize gt 1 then nobins = 14*54./(bsize*1.7)
;
;;;         h=histogram(sum[i,x1:x2,y1:y2],/nan,locations=b,max=tmp+5*dev,min=tmp-5*dev,nbins=nobins)
;
;;        h=histogram(sum[i,x1:x2,y1:y2],/nan,locations=b,max=8.5e4,min=-2e4,binsize=10)
;
;;        h=histogram(sum[i,x1:x2,y1:y2],/nan,locations=b,max=8.5e4*bsize^2,min=-2e4*bsize^2,binsize=robust_sigma(sum[i,x1:x2,y1:y2])/8.)
;
;        h=histogram(sum[i,x1:x2,y1:y2],/nan,locations=b,max=8.5e4*bsize^2,min=-2e4*bsize^2,binsize=robust_sigma(sum[i,x1:x2,y1:y2])/3.)
;
;
;;         fixed = histogram_smooth(b,h)
;;         b = fixed[*,0]
;;         h = fixed[*,1]
;
;;;        h=histogram(sum[i,x1:x2,y1:y2],nbins=1000,/nan,locations=b);,binsize=bsz)
;;;;        b=findgen(n_elements(h))*bsz + min(sum[i,x1:x2,y1:y2],/nan)
;
;
;        rrange = where(h ge .005*max(h))
;;        h = histogram(sum[i,x1:x2,y1:y2],nbins=500,min=b[rrange[0]],max=b[rrange[n_elements(rrange)-1]],locations=b)
;
;
;
;        good = where(h gt 0.4*max(h))
;;        if ll eq 2 or ll eq 1 then good = where(h gt 0.6*max(h))
;        locut = where(h gt lowt*max(h))
;;        if ll eq 0 then begin
;;            locut = where(h gt 0.7*max(h))
;;;            if bsize gt 1 then locut = where(h gt 0.7*max(h))
;;        endif
;        good = good[where(good eq locut[0]):*]
;        pind = where(h ge .01*max(h))
;        plow = b[pind[0]]
;        phigh = b[pind[n_elements(pind)-1]]
;        plot,b,h,xr=[plow,phigh],xstyle=1,psym=-4;[tmp-5*dev,tmp+5*dev]
;;        plot,b,h,xr=[mmm[0]-0.5*dev,mmm[0]+0.5*dev],xstyle=1
;;    gfitg = gaussfit(b[good],h[good],nterms=3,gcoeffg,sigma=sigmamns,chisq=chisqmns_g)
;;        fixed = histogram_smooth(b,h)
;;        b = fixed[*,0]
;;        h = fixed[*,1]
;        gfitm = mpfitpeak(b[good],h[good],gcoeffm,sigma=sigmamns,chisq=chisqmns_m,nterms=5)
;;;        oplot,b[good],gfitg,color=200,thick=2
;        oplot,b[good],gfitm,color=100,thick=2
;;stop
;;        oplot,[median(sum[i,x1:x2,y1:y2]),median(sum[i,x1:x2,y1:y2])],[0,max(h)]

;--------------------------------------
;CHECK
;gcoeffm = [0.,median(sum[i,x1:x2,y1:y2]),robust_sigma(sum[i,x1:x2,y1:y2])]
;--------------------------------------


;;print,'sum',ll,' ',i,' ',gcoeffm


;;        chisqgauss_sum[i] = chisqmns_g
;        chisqmp_sum[i] = chisqmns_m / (n_elements(b[good])-3)
;
;wait,.5
;;if i eq n_elements(orig[*,0,0])-1 then stop

;;        mnsg[i] = gcoeffg[1]
;;        mnsm[i] = gcoeffm[1]
;        mnsm[i] = tmp
;        mnssig[i] = sigmamns[1]
;;        wait,1
;        resistant_mean,diff[i,x1:x2,y1:y2],3,tmp
;        mmm = moment(diff[i,x1:x2,y1:y2],/nan)
;        dev = sqrt(mmm[1])

;        varsm[i] = (robust_sigma(diff[i,x1:x2,y1:y2]))^2
;
;;        h=histogram(diff[i,x1:x2,y1:y2],/nan,locations=b,max=mmm[0]+7*dev,min=mmm[0]-7*dev,nbins=14*13.)
;;        h=histogram(diff[i,x1:x2,y1:y2],/nan,locations=b,max=tmp+5*dev,min=tmp-5*dev,nbins=10*8.)
;
;        h=histogram(diff[i,x1:x2,y1:y2],/nan,locations=b,max=2000,min=-2000,binsize=robust_sigma(diff[i,x1:x2,y1:y2])/6.)
;
;;256x256
;;print,'256x256'
;;        h=histogram(diff[i,x1:x2,y1:y2],/nan,locations=b,max=2000,min=-2000,binsize=robust_sigma(diff[i,x1:x2,y1:y2])/4.)
;
;
;;        fixed = histogram_smooth(b,h)
;;        b = fixed[*,0]
;;        h = fixed[*,1]
       

;;        rrange = where(h ge .005*max(h))



;        good = where(h gt 0.2*max(h))
;        pind = where(h ge .01*max(h))
;        plow = b[pind[0]]
;        phigh = b[pind[n_elements(pind)-1]]        
;        plot,b,h,xr=[plow,phigh],xstyle=1,psym=-4;[tmp-5*dev,tmp+5*dev]
;
;        gfit = mpfitpeak(b,h,gcoeff2m,sigma=sigmadfs,chisq=chisqdfs_m,nterms=3)
;        oplot,b,gfit,color=200,thick=2
;        chisqmp_diff[i] = chisqdfs_m / (n_elements(b)-3)
;
;;        oplot,[median(diff[i,x1:x2,y1:y2]),median(diff[i,x1:x2,y1:y2])],[0,max(h)]
;        upper = median(diff[i,x1:x2,y1:y2]) + stdev(diff[i,x1:x2,y1:y2])
;        lower = median(diff[i,x1:x2,y1:y2]) - stdev(diff[i,x1:x2,y1:y2])
;;        oplot,[upper,upper],[0,max(h)]
;;        oplot,[lower,lower],[0,max(h)]
;
;wait,.5
;;if i eq n_elements(orig[*,0,0])-1 then stop

;--------------------------------------
;CHECK
;;gcoeff2m = [0.,median(diff[i,x1:x2,y1:y2]),robust_sigma(diff[i,x1:x2,y1:y2])]
;--------------------------------------
;
;
;
;;print,'diff',ll,' ',i,' ',gcoeff2m


;        varsg[i] = gcoeff2g[2]^2
;        varsm[i] = gcoeff2m[2]^2


;varsm[i] = robust_sigma(diff[i,x1:x2,y1:y2])^2.

;        dfssig[i] = sigmadfs[2]^2

        ;correct error propagation
;        dfssig[i] = 2. * gcoeff2m[2] * sigmadfs[2]


;;        wait,1

;;    resistant_mean,sum[i,x1:x2,y1:y2],3,tmp & $
;;    mns[i] = tmp & $
;;    mmm = moment(diff[i,x1:x2,y1:y2],/nan) & $
;;    vars[i] = mmm[1] & $

;;if i eq 8 then stop & $

    endfor



;plot variance across the quad
;        wset,11
;        plot,varsm[6,*,4]
;        oplot,varsm[6,*,8]
;        oplot,varsm[6,*,12]
;        oplot,varsm[6,*,15]
;        oplot,varsm[6,*,20]
;        stop
;        wset,0








;PLOT VARIANCES AND MEAN SIGNALS
;    set_plot,'ps'
    qstr = strcompress(string(ll+1),/remove_all)
    slashpos1 = strpos(infile,'/',/reverse_search)
    slashpos2 = strpos(infile2,'/',/reverse_search)
    onam = strmid(infile,slashpos1+1,strlen(infile)-5-slashpos1-1) + '_' + strmid(infile2,slashpos2+1,strlen(infile2)-5-slashpos2-1) + '_MeanVSVarPlot_20x20boxes_quad' + qstr + '.ps'
;    device,/portrait,/color,bits_per_pixel=8,filename=onam
;    plot,mnsm,varsm,psym=4,xtit='Mean Value, Ramp1+Ramp2 (DN)',ytit='Variance, Ramp1-Ramp2 (DN)',thick=2,color=0,background=255,charthick=2,title='Quad '+qstr,xthick=2,ythick=2
;;    coeff = linfit(mnsm[1:*],varsm[1:*],yfit=yfit,sigma=sigma,chisq=chisq)


;;try fitting up the ramp, diff't numbers of values
;;    for jj=2,12 do begin
;    for jj=2,n_elements(mnsm[*,0,0])-1 do begin
;
;        coeff = robust_linefit(mnsm[1:jj,*,*],varsm[1:jj,*,*],yfit,ss,sigma)
;
;
;;;    coeff = linfit(varsm[1:*],mnsm[1:*],yfit=yfit,sigma=sigma,chisq=chisq,measure_errors=sqrt(2.*0.5*mnsm[1:*]))
;;        oplot,mnsm[1:jj,*,*],yfit,color=0,thick=2
; 
;        
;;PLOT TO THE SCREEN
;;        plot,mnsm,varsm,psym=4,xtit='Mean Value, Ramp1+Ramp2 (DN)',ytit='Variance, Ramp1-Ramp2 (DN)',thick=2,color=0,background=255,charthick=2,title='Quad '+qstr
;;        oplot,mnsm[1:*,*,*],yfit,color=0,thick=2
; 
;        gain[ll,jj-2] = 1/coeff[1]
;        upgain = 1./ (coeff[1]+sigma[1])
;        logain = 1./ (coeff[1]-sigma[1])
;        gainerr[ll,jj-2] = abs(gain[ll,jj-2]-upgain) > abs(gain[ll,jj-2]-logain)
;        
;        print,gain[ll,jj-2],gainerr[ll,jj-2],coeff[0]
;    endfor

;;    device,/close
;;    set_plot,'x'

   
;--------------------------------------------
;see what happens when you cut off the line fitting at a signal level
;of 26.5K DN, where it looks like the difference between the two
;nonlinearity corrections is small

;dd = abs(mnsm - (2.65e4*binn^2))
;;dd = abs(mnsm - 1.3e4) ;mimic SMOV 512x512 subarrays
;;dd = abs(mnsm - 9000.) ;avoid fixed pattern noise in un-flatfielded flats
;idx = where(dd eq min(dd))
;idx=idx[0]

    rat = varsm/mnsm
    resistant_mean,rat[where(rat gt 0)],3,ratmn
    ratdev = robust_sigma(rat[where(rat gt 0)])
    allbutzero = where(mnsm lt 24000. and mnsm gt 100)
    filtered = where(mnsm gt 24000. or mnsm lt 100); or rat gt ratmn+2.*ratdev or rat lt ratmn-2.*ratdev)
    good = where(mnsm lt 24000. and mnsm gt 100); and (rat lt ratmn+2.*ratdev and rat gt ratmn-2.*ratdev))
; stop   
print,'LIMIT AT 24000'
print,''
print,'number of good boxes: ',n_elements(good)
print,''
print,''


    ;;coeff = robust_linefit(mnsm[good],varsm[good],yfit,sig,sigma30)
    coeff = robust_linefit(mnsm,varsm,yfit,sig,sigma30)

    pi = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]},2)
    ron = ([8.91,8.70,8.825,8.86])^2 ;SMOV values
    pi[0].fixed = 1
    start = [ron[ll],1/2.5]
;    start[0] = cds[ll]
    ;;coeffmp = mpfitfun('myline',mnsm[good],varsm[good],fltarr(n_elements(varsm[good]))+1.,start,PARINFO=pi)
    ;;yfitmp = coeffmp[0] + coeffmp[1]*mnsm[good]
    coeffmp = mpfitfun('myline',mnsm,varsm,fltarr(n_elements(varsm))+1.,start,PARINFO=pi)
    yfitmp = coeffmp[0] + coeffmp[1]*mnsm 

    
print,''
print,'robust:',coeff[0],' mpfit:',coeffmp[0]
print,''

;print,mnssig
;print,dfssig
;fitexy,mnsm[1:idx],varsm[1:idx],interc,slop,x_sig=mnssig,y_sig=dfssig,sigma30
;coeff = [interc,slop]
;yfit = coeff[0]+coeff[1]*mnsm[1:idx]
    
    xt = ''
    yt = ''
    if ll eq 2 then begin
        xt = 'Mean (ADU)'
        yt = 'Variance (ADU)'
    endif else begin
        xt = ''
        yt = ''
    endelse
    
;    multiplot

    ;;plot,mnsm[good],varsm[good],psym=4,xr=[0,30000],yr=[0,15000],xtit=xt,ytit=yt,color=0,background=255,charsize=2
    ;;oplot,mnsm[good],yfit,color=50
;;    plot,mnsm,varsm,psym=4,xr=[0,1500],yr=[0,1500],xtit=xt,ytit=yt,color=0,background=255,charsize=2   ;;xr=[0,30000],yr=[0,15000],
;;    oplot,mnsm,yfit,color=50
;;    oplot,mnsm[filtered],varsm[filtered],psym=4,color=100

;;    oplot,mnsm[good],yfitmp,color=150,linestyle=1
;;    oplot,mnsm,yfitmp,color=150,linestyle=1
;    xyouts,15000,4000,'MPCOEFF '+ strcompress(string(1/coeffmp[1]),/remove_all),charsize=1.4

;mark boxes containing the edge where pix have been set to zero
;    if ll eq 1 or ll eq 3 then oplot,mnsm[*,12,*],varsm[*,12,*],psym=5,color=150
;;    xyouts,1000,1200,'Quad '+quadno[ll],charsize=2,color=0    ;; 2000,12000,
;;    xyouts,8000,1000,'Gain = ' + strcompress(string(1/coeff[1]),/remove_all),charsize=2,color=0  ;; 15000,2000,
    
    print,'ALTERNATIVE GAIN (FROM MYLINE): '+ strcompress(string(1/coeffmp[1]))
    print,'intercepts: '+strcompress(string(coeff[1]))+' '+strcompress(string(coeffmp[1]))

;INCLUDING THE SIGMA-CLIPPED POINTS IN THE FITS INCREASED THE GAIN
;(IE DECREASED THE SLOPE) BY LESS THAN 0.01 E/ADU
;coeffall = robust_linefit(mnsm[allbutzero],varsm[allbutzero],yfitall,sigkunk,sigmajunk)
;oplot,mnsm[allbutzero],yfitall,color=50

;print,''
;print,'3sig-Filtered      Unfiltered'
;print,1/coeff[1],1/coeffall[1]
;print,''


;name = 'Mean_Variance_Values_20x20boxes_quad' + strcompress(string(ll+1),/remove_all)+'.txt'
;openu,lunm,name,/append,/get_lun
;nf = strcompress(string(n_elements(mnsm[1:idx])),/remove_all)
;printf,lunm,mnsm[1:idx],format='(' + nf + 'f)'
;printf,lunm,varsm[1:idx],format='(' + nf + 'f)'
;free_lun,lunm


    print,1./coeff[1]
    gain30k[ll] = 1./coeff[1] 
    up30 = 1./ (coeff[1]+sigma30[1])
    down30 = 1./ (coeff[1]-sigma30[1])
    gain30kerr[ll] = abs(gain30k[ll]-up30) > abs(gain30k[ll]-down30)
    print,'Sigma of line-fit: ',sigma30
;    wait,2.
    
endfor

;;slashpos = strpos(infile,'/',/reverse_search)
;;n1 = strmid(infile,slashpos+1,9)
;;n2 = strmid(infile2,slashpos+1,9)
;;plotname = 'gain_values_' + n1 + '_' + n2 + '.png'
;;if keyword_set(mimc512) then plotname = strmid(plotname,0,strlen(plotname)-4) + '_maskedto.png'
;;write_png,plotname,tvrd(true=1)

;multiplot,/reset


print,''
print,''
print,''
print,'             Gain (e-/ADU)      Uncertainty      '
print,'Quad 1 ',gain30k[0],gain30kerr[0]
print,'Quad 2 ',gain30k[2],gain30kerr[2]
print,'Quad 3 ',gain30k[3],gain30kerr[3]
print,'Quad 4 ',gain30k[1],gain30kerr[1]
print,''
print,''
print,''


;window,3,xsize=800,ysize=800
;tmp = reform(diff[14,*,*])
;tmpc = congrid(tmp[161:700,426:973],800,800)
;
;tmpc[where(tmpc gt 500)] = 500
;tmpc[where(tmpc lt -500)] = -500
;
;tmph = adapt_hist_equal(tmpc,nregions=25)
;loadct,37
;
;!p.noerase=1
;window,10,xsize=800,ysize=800
;tvscl,tmph
;boxsize=100
;nboxes=5
;plot,[0],[0],/nodata,xrange=[0,1014],yr=[0,1014],/noerase,xstyle=1,ystyle=1
;for i=0,2*nboxes-1 do begin & $
;    oplot,[nboxes/1014/2*i,nboxes/1014/2*i],[0,1014],color=0 & $
;    oplot,[0,1014],[nboxes/1014/2*i,nboxes/1014/2*i],color=0 & $
;endfor
;!p.noerase=0

;stop

;fits_open,'difframp56_89.fits',f,/write
;fits_write,f,0.
;for i=0,14 do fits_write,f,reform(diff[i,*,*])
;fits_close,f



print,gain30k
print,'gain = [' + strcompress(string(gain30k[0]),/remove_all) + ',' + strcompress(string(gain30k[2]),/remove_all) + ',' + strcompress(string(gain30k[3]),/remove_all) + ',' + strcompress(string(gain30k[1]),/remove_all) + ']' 

gnam = strmid(infile,slashpos1+1,strlen(infile)-5-slashpos1-1) + '_' + strmid(infile2,slashpos2+1,strlen(infile2)-5-slashpos2-1) + '_gain_20x20boxes.txt'
if keyword_set(mimic512) then gnam = strmid(gnam,0,strlen(gnam)-4) + '_maskedto512.txt'
openw,gainlun,gnam,/get_lun
printf,gainlun,'Gain values output from ir_tv3_gain_small_boxes.pro'
printf,gainlun,'Input files: ' + infile + ' ' + infile2
printf,gainlun,''
printf,gainlun,'             Gain (e-/ADU)      Uncertainty      '
printf,gainlun,'Quad 1 ',gain30k[0],gain30kerr[0]
printf,gainlun,'Quad 2 ',gain30k[2],gain30kerr[2]
printf,gainlun,'Quad 3 ',gain30k[3],gain30kerr[3]
printf,gainlun,'Quad 4 ',gain30k[1],gain30kerr[1]
free_lun,gainlun

;return,0.
;stop

;print,'MEANS:'
;print,mnsm
;everthang = [[[gain]],[[gainerr]]]
;return,everthang


;openu,lun,'IR_TV3_GAIN_officiallincorr_nozerosub_30kDN_secondrampperdump.txt',/get_lun,/append
;printf,lun,infile,'  ',infile2,'  ',gain30k[0],'  ',gain30kerr[0],'  ',gain30k[1],'  ',gain30kerr[1],'  ',gain30k[2],'  ',gain30kerr[2],'  ',gain30k[3],'  ',gain30kerr[3],format='(a,a,a,a,f,a,f,a,f,a,f,a,f,a,f,a,f,a,f)'
;free_lun,lun

;yfit=[0,yfit]
;    openu,lun2,'linVSnonlinFigure_inputs_lincorr.txt',/get_lun,/append
;    printf,lun2,infile,'  ',infile2,format='(a,a,a)'
;    for pp=0,n_elements(mnsm)-1 do printf,lun2,mnsm[pp],varsm[pp],yfit[pp],format='(3f)'
;    free_lun,lun2


;print,infile
;print,''

;print,'smov_gain, with gauss:'
;print,mnsm
;print,''
;print,mnssig
;print,''
;print,varsm
;print,''
;print,dfssig
;print,''
;
;set_plot,'ps'
;device,/portrait,/color,bits_per_pixel=8,filename='Gain_Per_Quad.ps'
;readcol,'IR_TV2_GAIN_gain2.5.txt',inf1,inf2,g1,e1,g2,e2,g3,e3,g4,e4,format='(a,a,f8)'
;plot,g1,psym=-4,color=0,background=255,yr=[3.0,3.4],thick=2,charthick=2,xtit='File #',ytit='Gain (e!E-!N/ADU)',linestyle=1
;oplot,g2,psym=-1,color=50,thick=2,linestyle=1
;oplot,g3,psym=-2,color=100,thick=2,linestyle=1
;oplot,g4,psym=-5,color=150,thick=2,linestyle=1
;plots,0.5,3.12,psym=4,color=0,thick=2
;xyouts,0.7,3.115,'Quad 1',charthick=2,color=0
;plots,0.5,3.09,psym=1,color=50,thick=2
;xyouts,0.7,3.085,'Quad 2',charthick=2,color=50
;plots,0.5,3.06,psym=2,color=100,thick=2
;xyouts,0.7,3.055,'Quad 3',charthick=2,color=100
;plots,0.5,3.03,psym=5,color=150,thick=2
;xyouts,0.7,3.025,'Quad 4',charthick=2,color=150
;device,/close
;set_plot,'x'

;readcol,'IR_TV2_GAIN_INPUTS_quad2_straddledump.0.txt',format='(a,a,f18)',inf1,inf2,m1,m2,m3,m4,m5,m6,m7,m8,m9,v1,v2,v3,v4,v5,v6,v7,v8,v9
;mns = [[m1],[m2],[m3],[m4],[m5],[m6],[m7],[m8],[m9]]
;vars = [[v1],[v2],[v3],[v4],[v5],[v6],[v7],[v8],[v9]]
;!p.multi=[0,1,2]
;set_plot,'ps'
;device,/color,bits_per_pixel=8,/portrait,filename='MeansAndVars.ps'
;PLOT OF THE MEAN SIGNAL IN THE FINAL READ OF ALL RAMPS
;plot,mns[*,8],psym=4,yr=[59500.,60000.],xtit='File #',ytit='Mean Signal (DN)',charthick=2,thick=2,xmargin=[14,10],color=0,background=255,title='Sept 28 Dataset'
;PLOT OF THE VARIANCE IN THE FINAL READ OF ALL RAMPS
;plot,vars[*,8],psym=4,yr=[24000,27000.],xtit='File #',ytit='Variance (DN)',thick=2,color=0,background=255,xmargin=[14,10],charthick=2
;device,/close
;set_plot,'x'
;!p.multi=0
;stop

fini:


;results of linefitting to various numbers of reads
;quad1=[2.63270,2.67272,2.68047,2.71020,2.76095,2.79835,2.82707,2.84560,2.86879,2.89520]
;quad2=[2.63566,2.55366,2.57797,2.63690,2.64240,2.64908,2.68024,2.69826,2.70334,2.73231]
;quad3=[2.65286,2.70598,2.72699,2.77155,2.77933,2.77800,2.80275,2.82675,2.85779,2.86524]
;quad4=[2.66997,2.66639,2.69445,2.71199,2.74150,2.77432,2.81416,2.83002,2.84180,2.85703]
;xs=indgen(10)+2
;set_plot,'ps'
;device,/portrait,filename='gainVSnumOfReadsInLinefit.ps'
;!p.multi=[0,2,2]
;plot,xs,quad1,psym=1,yr=[2.52,3],xr=[0,12],xtit='# of reads fit',ytit='Gain (e-/ADU)',title='Quad 1'
;plot,xs,quad4,psym=5,yr=[2.52,3],xr=[0,12],xtit='# of reads fit',ytit='Gain (e-/ADU)',title='Quad 4'
;plot,xs,quad2,psym=2,yr=[2.52,3],xr=[0,12],xtit='# of reads fit',ytit='Gain (e-/ADU)',title='Quad 2'
;plot,xs,quad3,psym=4,yr=[2.52,3],xr=[0,12],xtit='# of reads fit',ytit='Gain (e-/ADU)',title='Quad 3'
;!p.multi=0
;device,/close
;set_plot,'x'


end




