PRO make_ratio_png, read_data, read_name

;+
; NAME:
;       MAKE_RATIO_PNG
;
; AUTHORS:
;        Catherine M. Gosmeyer, Mar. 2015
;
; PURPOSE:
;        Makes a diagnostic PNG image. 
;
; NOTES:
;        Moved out of ratio_ramps.pro on 27 Jan. 2016.
;        This appears to cause plots following it to flip to
;        portrait. Not sure how to flush out that setting.
;-

  print, "Generating ratio PNG"

  ;; Extract read + pathname of the FITs image name
  print, read_name
  read_name = (strsplit(read_name, '.fits', /extract, /regex))[0]
  print, read_name

  ;; Extract the filename so can prepend to it.
  rootname = strmid(read_name, strlen(read_name)-21)

  ;; Extract the pathname.
  pathname = strmid(read_name, 0, strlen(read_name)-21)

  read_name_temp = pathname + 'temp_' + rootname

  ;; Set page dimensions
  page_width = 44
  page_height = 44

  plot_left = 0
  plot_bottom = 0

  set_plot,'ps'

  ;; Load greyscale color table
  loadct,0, /silent

  !p.thick=2
  !p.charthick=4
  !x.thick=2
  !y.thick=2

  !p.thick=5
  !p.charthick=5

  !p.multi=0
  landscape=0
  device, /encapsulated, $
          /color, $
          /portrait, $
          filename=read_name_temp+'.eps',xsize=page_width,ysize=page_height

  img_sz = size(read_data, /dim)
  help, img_sz
  print, img_sz

  ;; Scale the image
  range=zscale_range(read_data)
  data = 255b - bytscl(read_data, min = range[0], max = range[1])
   
  ;; Define plot size (in cm)
  xsize = 44
  ysize = 22 

  ;; Plot greyscale image.
  cgimage, data, /keep_aspect_ratio, $
           position = [plot_left / page_width, plot_bottom / page_height, (plot_left + xsize) / page_width, (plot_bottom + ysize) / page_height] 

  device, /close_file

  device, /close

  ;; Convert eps to png.
  spawn, "convert "+ read_name_temp + '.eps '+ read_name + '.png'

  ;; Remove the eps file.
  file_delete, read_name_temp + '.eps'

  set_plot, 'x'


END