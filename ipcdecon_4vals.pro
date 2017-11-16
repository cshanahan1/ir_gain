;+
;
; Experiments with direct Fourier inversion of convolution to remove
; IPC (interpixel capacitance) from images.
;
; To demonstrate it, type "ipcecon_demo" at an IDL prompt.
; This also requires the usual Goddard IDL library for FITS files, etc.
;
; P. R. McCullough 2007
;-
;
;11 Nov 2010 - BNH - separated the ipc psf into 4 independent values
;                    to investigate wfc3/ir ipc

pro ipcdecon_4vals,im,ipcpsf,alphaleft=alphaleft,alpharight=alpharight,betaabove=betaabove,betabelow=betabelow

; as a convenience to the user, create the ipcpsf as a [3,3] matrix
; from alpha and optionally also beta if different than alpha.
if n_elements(alphaleft) gt 0 then begin
  if n_elements(betaabove) eq 0 then begin
     betaabove = alphaleft
     betabelow = alphaleft
  endif
  ipcdim = 3
  ipcpsf = [0,betaabove,0,alphaleft,1.-(betaabove+betabelow+alphaleft+alpharight),alpharight,0,betabelow,0]
  ipcpsf = reform(ipcpsf,ipcdim,ipcdim)
endif

si1 = size(im)
si2 = size(ipcpsf)

; bias the image to avoid negative pixel values in the image, which the
; FFT method of deconvolution has trouble with.

min_im = min(im)
im     = im - min_im

ipc_big = im*0.
sx = si1[1]/2 - si2[1]/2
sy = si1[2]/2 - si2[2]/2
ipc_big[sx:sx+si2[1]-1,sy:sy+si2[2]-1] = ipcpsf

ft_im  = fft(im)
ft_psf = fft(ipc_big)
im = shift(fft(ft_im/ft_psf,/inverse),-si1[1]/2,-si1[2]/2)/(float(si1[1])*float(si1[2]))

; convert from Complex to Real
im = float(im)

; restore by removing the bias
im = im + min_im

return
end
