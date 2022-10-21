; GEOS Atari port
; Maciej 'YTM/Elysium' Witkowiak, 2022

; Atari display list init, done only once (unless we move it to FirstInit)

.include "const.inc"
;.include "geossym.inc"
.include "geosmac.inc"
;.include "config.inc"
;.include "kernal.inc"
.include "atari.inc"

.import displaylist

.global displaylistinit

.segment "displaylistinit"

displaylistinit:
	; init ANTIC
;	LoadB ANTIC_DMACTL, %00100010			; normal screen
;	LoadB ANTIC_CHACTL, %00000010			; normal characters

	; displaylist address (display list defines screen position at SCREEN_BASE)
	LoadW ANTIC_DLISTL, displaylist

	LoadB ANTIC_HSCROL, 0
	sta ANTIC_VSCROL
;	sta ANTIC_PMBASE
;	sta ANTIC_NMIEN

	; init GTIA
	ldx #0
	txa
:	sta GTIA,x
	inx
	cpx #32
	bne :-

	; set colors - atari default blue (but dark on light)
	LoadB GTIA_COLPF1, $94
	LoadB GTIA_COLPF2, $9a
	LoadB GTIA_COLBK, 0
	rts
