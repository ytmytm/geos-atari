; Maciej Witkowiak, 2022
; Atari code based on LNG

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.global __ToBASIC

.segment "tobasic2"

ASSERT_IN_BANK0

__ToBASIC:
	; this can't be under ROM, copy trapoline before running
	sei
	ldx #$ff
	txs
	inx
:	lda @tobasic,x
	sta $0100,x
	inx
	cpx #(@tobasicend-@tobasic+1)
	bne :-
	jmp $0100

@tobasic:
	lda #%10000011			; enable OS & BASIC or only OS?
	sta PIA_PORTB
	sta $033d			; make sure it's a cold boot
	jmp ($fffc)			; jump through RESET vector  
@tobasicend:
