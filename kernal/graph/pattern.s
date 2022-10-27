; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: SetPattern syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import PatternTab
.import atari_banks
.import interrupt_lock

.global _SetPattern

.segment "ramexp2"
ASSERT_NOT_IN_BANK0
curPatternBuf:	.res 8, 0

.segment "graph2l2"

ASSERT_NOT_IN_BANK0
;---------------------------------------------------------------
; SetPattern                                              $C139
;
; Pass:      a pattern nbr (0-33)
; Return:    currentPattern - updated
; Destroyed: a
;---------------------------------------------------------------
_SetPattern:
	asl
	asl
	asl
	adc #<PatternTab
	sta curPattern
	lda #0
	adc #>PatternTab
	sta curPattern+1
	tya
	pha
	PushB PIA_PORTB
	LoadB interrupt_lock, $ff
	MoveB atari_banks+0, PIA_PORTB	; patterns are in bank 0
	ldy #0
:	lda (curPattern),y
	sta curPatternBuf,y
	iny
	cpy #8
	bne :-
	PopB PIA_PORTB
	LoadB interrupt_lock, 0
	pla
	tay
	LoadW curPattern, curPatternBuf
	rts


.global _GetScanLineDummy
.import _GetScanLine
_GetScanLineDummy:
	; 320-bytes long scratch buffer
	.warning "this could just point to backbuffer"
	PushB dispBufferOn
	LoadB dispBufferOn, ST_WR_BACK
	jsr _GetScanLine
	PopB dispBufferOn
	rts

