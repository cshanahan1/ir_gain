FUNCTION rmreads, infile, remove, nsamp, h, outfile

;+
; NAME:
;      RMREADS
;
; PURPOSE: 
;      Removes given reads of infile.
;
; INPUTS: 
;      infile = name of original raw file
;      remove = list of reads to remove
;      nsamp = header keyword denoting total number of reads
;      h = primary header of original raw file
;      outfile = name of the new raw file
;
; OUTPUTS:   
;      <outfile>. New RAW file with given reads removed.      
;
; MODIFICATION HISTORY:
;     24 Nov. 2014: Original script written by R. Ryan
;     25 Nov. 2014: Modified for IR photom stability tests by C.M. Gosmeyer.
;-  

  nrem=n_elements(remove)       ;number of samples to remove

  ;make a new header
  newh=h
  sxaddpar,newh,'NSAMP',nsamp-nrem,' updated by CMG'

  ;start building the new file
  file_delete,outfile,/allow_non
  mwrfits,0,outfile,newh,/create,silent=silent

  ;have two counters for sample number and extension number/set.  
  ;could be combined into a single counter.
  samp=nsamp-nrem               ;a sample counter, the IMA/RAW file is 
                                ;backward.  last read comes first.
  extver=1
  for i=0,nsamp-1 do begin

     ;define the extensions to read
     sci=5*i+1
     err=5*i+2
     dqa=5*i+3
     smp=5*i+4
     tme=5*i+5
     
     ;check if this read is to be removed
     g=where(i eq remove,n)
     if n eq 0 then begin

        ;read and transfer the SCI extension
        img=readfits(infile,ext=sci,hdr,/silent)
        sxaddpar,hdr,'SAMPNUM',samp-1,' updated by RER'
        sxaddpar,hdr,'EXTVER',extver,' updated by RER'
        mwrfits,img,outfile,hdr,silent=silent
        
        ;read and transfer the error extension
        hdr=headfits(infile,ext=err)
        sxaddpar,hdr,'EXTVER',extver,' updated by RER'
        mwrfits,0,outfile,hdr,silent=silent


        ;read and transfer the DQ extension
        hdr=headfits(infile,ext=dqa)
        sxaddpar,hdr,'EXTVER',extver,' updated by RER'
        mwrfits,0,outfile,hdr,silent=silent
      
        ;read and transfer the SAMPLE extension
        hdr=headfits(infile,ext=smp)
        sxaddpar,hdr,'EXTVER',extver,' updated by RER'
        sxaddpar,hdr,'PIXVALUE',samp,' updated by RER'
        mwrfits,0,outfile,hdr,silent=silent
        
        ;read and transfer the TIME extension
        hdr=headfits(infile,ext=tme)
        sxaddpar,hdr,'EXTVER',extver,' updated by RER'
        mwrfits,0,outfile,hdr,silent=silent
      
      
        ;update counters
        samp--                  ;sample number 
        extver++                ;extension number 
      
     endif

     
  endfor
  
  return, 1
  
end




PRO rmreads_wrapper_gain
  
;+
; NAME:
;      RMREADS_WRAPPER
;
; PURPOSE: 
;      Wraps rmreads function. Modified for gain data.
;
; INPUTS: 
;      None.
;
; OUTPUTS:   
;      RAWs with specified decrease number of reads. 
;
; EXAMPLE: 
;      idl> rmreads_wrapper_gain
;
; MODIFICATION HISTORY:
;     24 Nov. 2014: Original script written by R. Ryan
;     25 Nov. 2014: Modified for IR photom stability tests by C.M. Gosmeyer.
;-  

  infile_list = file_search('', '*raw.fits')
  print, infile_list
  
  ; move infiles to subdirectory so to have pristine originals
  file_mkdir, 'orig_raws'
  foreach infile, infile_list do begin
    file_copy, infile, 'orig_raws'
  endforeach

  ; remove reads
  foreach infile, infile_list do begin
  
    print, '---------------'
    print, infile

    ;read the old header and NSAMP
    h=headfits(infile,ext=0)
    nsamp=sxpar(h,'NSAMP')
    
    print, nsamp
    
    ; decide how many reads to remove based on nsamp
    if nsamp lt 6 then begin
      print, "Less than 6 reads. Leave as is."
      file_copy, 'orig_raws/'+infile, infile
    
    endif else begin
      
      remove = [0,1]
      
      ;if nsamp ge 16 then
      ;  remove = [1,2,3,4,5,6]
      ;if (nsamp ge 12) && (nsamp lt 16) then
      ;  remove = [1,2,3,4]
      ;if (nsamp ge 6) && (nsamp lt 12) then
      ;  remove = [1,2]
    
      print, "Deleting reads " + remove
      out = rmreads('orig_raws/'+infile, remove, nsamp, h, infile)
      
    endelse

  endforeach
  
  print,'Now run calwf3. See runcalwf3.py'


end



