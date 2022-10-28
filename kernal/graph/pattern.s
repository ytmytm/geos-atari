; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: SetPattern syscall

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import PatternTab

.global __SetPattern

.segment "ramexp2"
ASSERT_NOT_IN_BANK0
curPatternBuf:	.res 8, 0

.segment "graph2l2"

ASSERT_IN_BANK0
;---------------------------------------------------------------
; SetPattern                                              $C139
;
; Pass:      a pattern nbr (0-33)
; Return:    currentPattern - updated
; Destroyed: a
;---------------------------------------------------------------
__SetPattern:
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
	ldy #0
:	lda (curPattern),y
	sta curPatternBuf,y
	iny
	cpy #8
	bne :-
	pla
	tay
	LoadW curPattern, curPatternBuf
	rts

