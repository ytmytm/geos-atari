; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Main Loop

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.warning "mainloop1.s - doupdatetime commented out"

;XXX.import _DoUpdateTime
.import _ExecuteProcesses
.import _MainLoop2
.import _DoCheckButtons
.import _DoCheckDelays

.import CallRoutine

.global _MainLoop
.global _MNLP

.segment "mainloop1"

_MainLoop:
	jsr _DoCheckButtons
	jsr _ExecuteProcesses
	jsr _DoCheckDelays
;XXX	jsr _DoUpdateTime
	lda appMain+0
	ldx appMain+1
_MNLP:	jsr CallRoutine
	cli
	jmp _MainLoop
