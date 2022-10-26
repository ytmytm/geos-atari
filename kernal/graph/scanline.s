;
; Graphics library: GetScanLine syscall
;
; Atari code based on Beamracer version
; Maciej 'YTM/Elysium' Witkowiak

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import Panic

.global __GetScanLine

.segment "graph2n"
.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"
;---------------------------------------------------------------
; GetScanLine                                             $C13C
;
; Function:  Returns the address of the beginning of a scanline

; Pass:      x   scanline nbr
; Return:    r5  add of 1st byte of foreground scr
;            r6  add of 1st byte of background scr
; Destroyed: a
;---------------------------------------------------------------
__GetScanLine:
	lda LineTabL, x
	sta r5L
	sta r6L
	lda LineTabH, x
	sta r5H
	sta r6H

	bbrf 7, dispBufferOn, @4	; !ST_WR_FORE
	bvs @3				; ST_WR_FORE | ST_WR_BACK
@1:	AddVB >SCREEN_BASE, r5H		; ST_WR_FORE
	sta r6H
	rts

@3:	AddVB >SCREEN_BASE, r5H		; ST_WR_FORE | ST_WR_BACK
	AddVB >BACK_SCR_BASE, r6H
	rts

@4:	bvc @5				; ST_WR_BACK
	AddVB >BACK_SCR_BASE, r5H
	sta r6H
	rts

@5:	;AddVW br_screen_base+$0F00, r5	; !ST_WR_FORE && !ST_WR_BACK ?!
	;bra @1
	jmp Panic			; impossible combination, panic

	.segment "scanline"

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "scanline tables not in bank0"

LineTabL:
	.repeat 200, line
	.lobytes 56 + line * 40
	.endrep

LineTabH:
	.repeat 200, line
	.hibytes 56 + line * 40
	.endrep
