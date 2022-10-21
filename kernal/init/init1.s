; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Machine initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import InitRamTab
.import _DoFirstInitIO
.import _InitRam

.global InitGEOEnv
.global _InitMachine

.segment "init1"

.assert * < $c000, error, "InitMachine can't be under ROM (because it calls DoFirstInitIO to disable ROM)"
_InitMachine:
	jsr _DoFirstInitIO
InitGEOEnv:
	LoadW r0, InitRamTab
	jmp _InitRam
