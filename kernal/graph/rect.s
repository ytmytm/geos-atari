; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: rectangles

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import __HorizontalLine
.import __InvertLine
.import __RecoverLine
.import __VerticalLine
.import __ImprintLine

.import __HorizontalLineDo
.import __InvertLineDo
.import __RecoverLineDo
.import __PrepareXCoord

.global __Rectangle
.global __InvertRectangle
.global __RecoverRectangle
.global __ImprintRectangle
.global __FrameRectangle

.segment "graph2c"

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"

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
__RecoverRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr __PrepareXCoord
	PopB dispBufferOn
	ldy #%01000000				; bit 6 = OP call recover line
	bne DoRectangleLoop

__ImprintRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr __PrepareXCoord
	PopB dispBufferOn
	lda r5L					; imprint is recover with source<->destination swapped
	ldy r6L
	sta r6L
	sty r5L
	lda r5H
	ldy r6H
	sta r6H
	sty r5H
	ldy #%01000000				; bit 6 = OP call recover line
	bne DoRectangleLoop

__Rectangle:
	ldy #0					; zero  = OP call horizontal line
	beq _DoRectangle

__InvertRectangle:
	ldy #%10000000				; bit 7 = OP call invert line
;	bne _DoRectangle

_DoRectangle:
	PushB r2L
	sta r11L
	sty r2L
	PushW r3
	PushW r4
	jsr __PrepareXCoord

DoRectangleLoop:				; all rectangle functions call horizontal line drawing
	lda r2L
	beq @hor
	bmi @inv
;	bvs @rec				; fall into recover if not 0 and not bit 7
;	bra @cont

@rec:	jsr __RecoverLineDo			; call one of internal line routines to avoid recalculation of coordinates
	bra @cont

@hor:	lda r11L				; only Rectangle needs pattern update
	and #%00000111
	tay
	lda (curPattern),Y
	sta r7L
	jsr __HorizontalLineDo
	bra @cont

@inv:	jsr __InvertLineDo

@cont:	lda r11L
	cmp r2H					; all lines done?
	beq @end
	inc r11L				; next line
	lda #SC_BYTE_WIDTH			; next row
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

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"
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
__FrameRectangle:
	sta r9H
	ldy r2L
	sty r11L
	jsr __HorizontalLine
	MoveB r2H, r11L
	lda r9H
	jsr __HorizontalLine
	PushW r3
	PushW r4
	MoveW r3, r4
	MoveW r2, r3
	lda r9H
	jsr __VerticalLine
	PopW r4
	lda r9H
	jsr __VerticalLine
	PopW r3
	rts
