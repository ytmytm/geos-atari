; GEOS System build configuration
; by Maciej Witkowiak

.ifndef config_inc
config_inc = 1

;------------------------
; which variant to build
;------------------------
; use "make TARGET=<variant>" to build a specific variant

.ifdef atari
	; make use of all reusable Wheels optimizations and fixes
;	wheels_size = 1
;	wheels_size_and_speed = 1
;	wheels_remove_BootGEOS = 1
;	wheels_fixes = 1

	remove_dead_bytes = 1
.endif

; Feel (almost) free to change values below:
iniMaxMouseSpeed        = $7f                           ; range from $00-$7f
iniMinMouseSpeed        = $1e                           ;
iniMouseAccel           = $7f                           ;

currentInterleave       = 8                             ; 8 for 1541, 6 for 1571
SelectFlashDelay        = 10                            ; 10 in 1/50 s

; if both menu separator patterns are null, then kernal menu code
; will be a bit optimized for speed and space
menuVSeparator  = %10101010                     ; %10101010 ;both=0 -> speed&space
menuHSeparator  = %01010101                     ; %01010101

; these are overriden by DeskTop, changing to null gives nothing
backPattern1    = %01010101                     ; %01010101 ;overriden by DeskTop
backPattern2    = %10101010                     ; %10101010

; better do not change below
REUOsVarBackup  =    $7900                      ; base for OS_VARS_LGH bytes for reboot
REUDskDrvSPC    =    $8300                      ; base for 4*DISK_DRV_LGH disk drivers

; Atari doesn't have REU and RAM expansion is occupied by OS by default, so no support for REU-like RAM OPs for apps
.if .defined(atari)
;REUPresent = 1
;useRamExp = 1
.endif

.endif
