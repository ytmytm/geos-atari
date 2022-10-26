; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Math library: Dabs, Dnegate syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.global __Dabs
.global __Dnegate

.segment "math1c1"
.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"

;---------------------------------------------------------------
; Dabs                                                    $C16F
;
; Function:  Compute the absolute value of a twos-complement
;            word.
;
; Pass:      x   add. of zpage contaning the nbr
; Return:    x   zpage : contains the absolute value
; Destroyed: a
;---------------------------------------------------------------
__Dabs:
	lda zpage+1,x
	bmi __Dnegate
	rts
;---------------------------------------------------------------
; Dnegate                                                 $C172
;
; Function:  Negate a twos-complement word
;
; Pass:      x   add. of zpage : word
; Return:    destination zpage gets negated
; Destroyed: a, y
;---------------------------------------------------------------
__Dnegate:
	lda zpage+1,x
	eor #$FF
	sta zpage+1,x
	lda zpage,x
	eor #$FF
	sta zpage,x
	inc zpage,x
	bne :+
	inc zpage+1,x
:	rts
