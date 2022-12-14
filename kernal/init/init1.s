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
.import _FillRam
.import Player0Data

.global InitGEOEnv
.global _InitMachine

.segment "init1"

ASSERT_NOT_UNDER_ROM
; InitMachine can't be under ROM (because it calls DoFirstInitIO to disable ROM)

_InitMachine:
	jsr _DoFirstInitIO
InitGEOEnv:
	; clear all sprite data
	LoadB r2L, 0
	LoadW r1, Player0Data
	LoadW r0, $0400
	jsr _FillRam
	LoadW r0, InitRamTab
	jmp _InitRam
