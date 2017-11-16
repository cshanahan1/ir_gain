function ramp_header,infile

;---------------------------------------------------------
;PURPOSE: return the headers for all the science extensions
;         in a given WFC3-IR ramp. This is designed to be 
;         used in concert with ramp_read, and therefore will
;         return the headers in chronological order, following
;         the way ramp_read treats the science data.
;
;INPUTS: infile - filename of the ramp to use
;
;OUTPUTS: string array of the science extension headers in 
;         infile
;
;19 Dec 2006 - BNH created
;
;5 March 2013 - fits_open fix. ST changed the default value of the
;               INHERIT keyword, which now causes headers from
;               multiple extensions to be combined automatically. This
;gives fits_open problems, which come out as error messages about
;sxpar finding multiple instances of the naxis keyword. fits_open, and
;the old version of ramp_header still work, but the error messages are
;very annoying. Re-writing, avoiding the use of fits_open.
;---------------------------------------------------------

;OPEN FILE

;need a substitute for fits_open, because the stupid inherit
;keyword is screwing things up. fxread?

;numext = sxpar(headfits(infile),'NEXTEND')

;;if nextend isn't in the header then quit
;if numext le 0 then begin
;   print,'WARNING: File '+infile+' has no NEXTEND keyword, or zero extensions. Quitting.'
;   stop
;endif

;Locate the science extensions and keep a tally
;scicount = 0
;sciexts = -1
;
;for i=0,numext do begin
;
;   hh=headfits(infile,exten=i)
;   fits_read,infile,0,hh,exten_no=i,/header_only,/no_pdu
;   ;for oo=0,n_elements(hh)-1 do print,hh[oo]
;;stop
;   datatype = sxpar(hh,'EXTNAME')
;   datatype = strcompress(string(datatype),/remove_all)
;   if datatype eq 'SCI' then begin
;      scicount = scicount + 1
;      sciexts = [sciexts,i]
;
;
;   endif
;endfor
;sciexts = sciexts[1:*]

fits_open,infile,f1

;FIND SCIENCE EXTENSIONS AND
;CREATE CORRESPONDING HEADER ARRAY
sciexts = where(strcompress(strupcase(f1.extname),/remove_all) eq 'SCI')
;stop
h1 = headfits(infile,exten=sciexts[0],/silent)
;stop
headers = strarr(n_elements(sciexts),n_elements(h1))

;CHECK EXPOSURE TIMES TO DETERMINE WHAT ORDER THE SCIENCE 
;EXTENSIONS ARE IN
ex1 = sxpar(h1,'SAMPTIME')
ex1type = size(ex1,/type)
if ex1type eq 2 then begin 
;stop
    ex1 = sxpar(headfits(infile,exten=sciexts[0]),'EXPTIME',/silent)
;stop
    ex2 = sxpar(headfits(infile,exten=sciexts[n_elements(sciexts)-1]),'EXPTIME',/silent)
;stop
endif else ex2 = sxpar(headfits(infile,exten=sciexts[n_elements(sciexts)-1]),'SAMPTIME',/silent)

idx1 = n_elements(sciexts)-1
if ex1 lt ex2 then idx1 = 0

;READ HEADERS INTO HEADER ARRAY
for i=0,n_elements(sciexts)-1 do begin
;   stop
   tmp = headfits(infile,exten=sciexts[i],/silent)
;   stop
   headers[abs(idx1-i),*] = tmp
endfor    

;CLOSE THE FITS FILE
fits_close,f1

;RETURN THE ARRAY TO THE CALLING PROGRAM
return,headers
end
