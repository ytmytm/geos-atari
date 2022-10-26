; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Michael Steil, Maciej Witkowiak
;
; GEOS Atari port, Maciej Witkowiak 2022
; Cross-bank calling, quite similar to C128 only calls functions witin ATARI_EXPBASE (bank0)

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import atari_banks
.import interrupt_lock

.global CallBackBank

;.segment "spritebuf"

; this could be zpage in C64/128 Kernal space
; locations from C128
;bank0SaveA:	.res 1
;bank0SavePS:	.res 1
bank0SavePORTB = bank0SaveRcr

.segment "banking"

.warning "banking.s - add assert that this can't be in banked space"

; called from $D800+ jumps into $4000 (ATARI_EXPBASE) with the same byte offset
CallBackBank:
	; save A and P
	sta bank0SaveA
	php
	PopB bank0SavePS
	; get JSR target from stack
	pla					; get low byte
	sub #2
	sta CallAddr2
	pla					; get high byte and ignore
	; switch banks
	LoadB interrupt_lock, $ff
	MoveB PIA_PORTB, bank0SavePORTB
	MoveB atari_banks+0, PIA_PORTB
	; restore A and P
	lda bank0SavePS
	pha
	lda bank0SaveA
	plp
	; call function
CallAddr2 = *+1
	jsr $4000
	; restore banking
	php
	pha
	MoveB bank0SavePORTB, PIA_PORTB
	LoadB interrupt_lock, 0
	pla
	plp
	rts

