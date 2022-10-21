; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Main Loop

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

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
	lda appMain+0
	ldx appMain+1
_MNLP:	jsr CallRoutine
	cli
	jmp _MainLoop
