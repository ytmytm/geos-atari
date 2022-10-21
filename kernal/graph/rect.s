; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: rectangles

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import _HorizontalLine
.import _InvertLine
.import _RecoverLine
.import _VerticalLine
.import ImprintLine

.import __HorizontalLineDo
.import __InvertLineDo
.import __RecoverLineDo
.import PrepareXCoord

.global _Rectangle
.global _InvertRectangle
.global _RecoverRectangle
.global _ImprintRectangle
.global _FrameRectangle

.segment "graph2c"

;---------------------------------------------------------------
; Rectangle                                               $C124
;
; Pass:      r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    draws the rectangle
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
_RecoverRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr PrepareXCoord
	PopB dispBufferOn
	ldy #%01000000
	bne DoRectangleLoop
_ImprintRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr PrepareXCoord
	PopB dispBufferOn
	lda r5L
	ldy r6L
	sta r6L
	sty r5L
	lda r5H
	ldy r6H
	sta r6H
	sty r5H
	ldy #%01000000
	bne DoRectangleLoop
_Rectangle:
	ldy #0
	beq _DoRectangle
_InvertRectangle:
	ldy #%10000000
;	bne _DoRectangle

_DoRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	jsr PrepareXCoord

DoRectangleLoop:
	lda r11L
	and #%00000111
	tay
	lda (curPattern),Y
	sta r7L
	lda r2L
	beq @hor
	bmi @inv
;	bvs @rec
;	bra @cont
@rec:	jsr __RecoverLineDo
	bra @cont
@hor:	jsr __HorizontalLineDo
	bra @cont
@inv:	jsr __InvertLineDo
@cont:	lda r11L
	cmp r2H
	beq @end
	inc r11L
	lda #SC_BYTE_WIDTH
	add r5L
	sta r5L
	sta r6L
	bcc DoRectangleLoop
	inc r5H
	inc r6H
	bne DoRectangleLoop
@end:	PopW r4
	PopW r3
	PopB r2L
	rts

.segment "graph2i1"

;---------------------------------------------------------------
; FrameRectangle                                          $C127
;
; Pass:      a   GEOS pattern
;            r2L top (0-199)
;            r2H bottom (0-199)
;            r3  left (0-319)
;            r4  right (0-319)
; Return:    r2L, r3H unchanged
; Destroyed: a, x, y, r5 - r9, r11
;---------------------------------------------------------------
_FrameRectangle:
	sta r9H
	ldy r2L
	sty r11L
	jsr _HorizontalLine
	MoveB r2H, r11L
	lda r9H
	jsr _HorizontalLine
	PushW r3
	PushW r4
	MoveW r3, r4
	MoveW r2, r3
	lda r9H
	jsr _VerticalLine
	PopW r4
	lda r9H
	jsr _VerticalLine
	PopW r3
	rts
