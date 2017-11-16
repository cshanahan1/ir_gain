function ramp_read,infile

;---------------------------------------------------------------
;PURPOSE: reads in a WFC3 ramp, composed of a multi-dimensional
;         fits file
;
;INPUTS: infile - filename of a fits file containing a multi-extension
;                 FITS file.
;
;OUTPUTS: im_cube - 3D array of the read-in data.
;
;
;created 2002-09-26 BNH
;modified 2006-12-19 - BNH added ability to look into the headers,
;                          and return the data in chronological order.
;                          OPUS and QL data are always saved in reverse
;                          chronological order. This saves the user from
;                          having to remember that.
;---------------------------------------------------------------

;OPEN FITS FILE
fits_open,infile,f1

;GET INDICIES WHERE DATA IS LISTED AS SCIENCE DATA
;AND READ IN THEESE EXTENSIONS
sciexts = where(f1.extname eq 'SCI')
xdim = f1.axis[0,sciexts[0]]
ydim = f1.axis[1,sciexts[0]]
datatype = f1.bitpix[sciexts[0]]
;if abs(datatype) eq 16 then im_cube = intarr(n_elements(sciexts),xdim,ydim)
;if abs(datatype) eq 32 then im_cube = fltarr(n_elements(sciexts),xdim,ydim)

im_cube = fltarr(n_elements(sciexts),xdim,ydim)


;IF THE DATA COMES FROM OPUS OR QUICKLOOK, IT'S ORIGINALLY SAVED
;IN REVERSE CHRONOLOGICAL ORDER. CHECK THE HEADERS TO 
;CONFIRM WHAT DIRECTION THE DATA IS SAVED IN, AND THEN
;READ IT IN AND RETURN IT IN CHRONOLOGICAL ORDER

;IF SXPAR RETURNS THE INTEGER 0, THEN THE KEYWORD DOESN'T EXIST.
;IF IT RETURNS A FLOAT OR DOUBLE PRECISION 0.00, THEN WE HAVE THE
;INITIAL READ OF THE RAMP

;SAMPTIME used for dcl and opus data, and exptime for Quicklook data

ex1 = sxpar(headfits(infile,exten=sciexts[0],/silent),'SAMPTIME',/silent)
ex1type = size(ex1,/type)
if ex1type eq 2 then begin 
    ex1 = sxpar(headfits(infile,exten=sciexts[0],/silent),'EXPTIME',/silent)
    ex2 = sxpar(headfits(infile,exten=sciexts[n_elements(sciexts)-1],/silent),'EXPTIME',/silent)
endif else ex2 = sxpar(headfits(infile,exten=sciexts[n_elements(sciexts)-1],/silent),'SAMPTIME',/silent)

;DETERMINE THE ORDER TO READ IN THE FILE 
idx1 = n_elements(sciexts)-1
if ex1 lt ex2 then idx1 = 0

;READ IN
for i=0,n_elements(sciexts)-1 do begin
    fits_read,infile,exten=sciexts[i],tmp,/no_pdu
    im_cube[abs(idx1-i),*,*] = tmp
endfor    

;CLOSE THE FITS FILE
fits_close,f1

;RETURN THE ARRAY TO THE CALLING PROGRAM
return,im_cube
end



