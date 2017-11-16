function ramp_times,infile

;----------------------------------------------------
;PURPOSE: retrieve the exposure time for each read
;         of a given WFC3-IR ramp from the headers.
;
;INPUTS: infile - filename of IR ramp
;
;OUTPUTS: array of exposure times
;
;20 Dec 2006 - BNH created
;
;----------------------------------------------------

mhead = headfits(infile,/silent)
headers = ramp_header(infile)
etimes = fltarr(n_elements(headers[*,0]))

searchvar = 'SAMPTIME'
test = sxpar(reform(headers[0,*]),searchvar)
if test eq 0 and size(test,/type) eq 2 then $
  searchvar = 'EXPTIME'

for i = 0,n_elements(headers[*,0])-1 do $
  etimes[i] = sxpar(reform(headers[i,*]),searchvar)

;IF THE DATA IS FROM DCL, ADD IN CHIP READ-OUT TIMES
;SINCE DCL DOES NOT INCLUDE THOSE NUMBERS IN THEIR 
;REPORTED EXPOSURE TIMES

dcl = strcompress(sxpar(mhead,'ORG'),/remove_all)
if dcl eq 'DCL' then begin
    rotime = findgen(n_elements(etimes)) * 2.6
    etimes = etimes + rotime
endif

return,etimes
end

