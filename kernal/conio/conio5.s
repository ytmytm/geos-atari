; GEOS KERNAL by Berkeley Softworks
;
; Atari version, Maciej Witkowiak, 2022
;
; Console I/O: PromptOn, PromptOff, InitTextPrompt syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import _DisablSprite
.import _EnablSprite
.import _PosSprite
.import curYSize

.global _PromptOn
.global _PromptOff
.global _InitTextPrompt

.segment "conio5"

_PromptOn:
	lda #%01000000
	ora alphaFlag
	sta alphaFlag
	LoadB r3L, 1
	MoveW stringX, r4
	MoveB stringY, r5L
	jsr _PosSprite
	jsr _EnablSprite
	bra PrmptOff1
_PromptOff:
	lda #%10111111
	and alphaFlag
	sta alphaFlag
	LoadB r3L, 1
	jsr _DisablSprite
PrmptOff1:
	lda alphaFlag
	and #%11000000
	ora #%00111100
	sta alphaFlag
	rts


_InitTextPrompt:
	tay

	; clear the buffer
	ldx #64
	lda #0
:	sta spr1pic-1,x
	dex
	bne :-

	; remember Y size
	sty curYSize+1
	; put as many bars as necessary
	ldx #0
	lda #%10000000
:	sta spr1pic,x
	inx
	dey
	bne :-

	; C64/128 also copies color from pointer (sprite0 to sprite1)
	LoadB alphaFlag, %10000011
	rts

