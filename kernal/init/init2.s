; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Machine initialization: FirstInit syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.warning "init2.s needs EnterDesktop"

.import InitMsePic
;.import _EnterDeskTop
.import _InitMachine

;.import EnterDeskTop

.global _FirstInit

.segment "init2"

;---------------------------------------------------------------
; FirstInit                                               $C271
;
; Function:  Initialize GEOS
;
; Pass:      nothing
; Destroyed: a, y, r0 - r2l
;---------------------------------------------------------------
.assert * < $c000, error, "_FirstInit calls InitMachine to enable ROM, can't be under ROM"
_FirstInit:
	sei
	cld
	jsr _InitMachine
;	LoadW EnterDeskTop+1, _EnterDeskTop
	LoadB maxMouseSpeed, iniMaxMouseSpeed
	LoadB minMouseSpeed, iniMinMouseSpeed
	LoadB mouseAccel, iniMouseAccel

	LoadB GTIA_COLPM0,  $3c			; hue/lum
	LoadB GTIA_COLPM1,  $c4			; hue/lum

	ldy #62
@2:	lda #0
	sta mousePicData,y
	dey
	bpl @2
	ldx #24
@3:	lda InitMsePic-1,x
	sta mousePicData-1,x
	dex
	bne @3
	rts
