PRO set_paths, path_to_data, path_to_outputs, path_to_scripts

;+ 
; NAME:
;        SET_PATHS
;
; AUTHORS:
;        Catherine M. Gosmeyer, Nov. 2015
;
; PURPOSE:
;        Sets the paths to the data, outputs, and scripts for
;        entire software suite.
;        Meant to be automatically filled out from a separate script
;        or can simply be done by hand.
;
; OUTPUTS:
;        path_to_data
;        path_to_outputs
;        path_to_scripts
;-

;; Set path to outputs directory.
path_to_outputs = '/grp/hst/wfc3t/cshanahan/IR_gain_monitor/outputs/'

;; Default. Path to data directory.
path_to_data = '/grp/hst/wfc3t/cshanahan/IR_gain_monitor/data/'

;; Download repo 'ir_gain', set the path here.
path_to_scripts = '/grp/hst/wfc3t/cshanahan/IR_gain_monitor/detectors/scripts/ir_gain/'

END