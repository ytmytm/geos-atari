; GEOS KERNAL by Berkeley Softworks
;
; Graphics library: line functions
;
; Atari version (linear addressing) by Maciej Witkowiak, 2022
; - linear addressing
; - more efficient for rectangle drawing (_...LineDo functions called without GetScanLine, by moving r5/r6 addresses)

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import __BitMaskPow2Rev
.import __BitMaskLeadingSet
.import __BitMaskLeadingClear
.import __GetScanLine

.global __ImprintLine
.global __HorizontalLine
.global __InvertLine
.global __RecoverLine
.global __VerticalLine

.global __PrepareXCoord
.global __HorizontalLineDo
.global __InvertLineDo
.global __RecoverLineDo

.segment "graph2a"

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"

; The same thing as GetLeftXAddress on C128 but optimized to 320 pixels instead of 640
; in: r3       X coord (0-319)
;     r4       X coord (0-319)
;     r11L     Y coord (0-199)
; out:
;     r3L      card number in scanline, but r5/r6 are already adjusted to it
;     r4L      distance in cards (distance divided by 8)
;     r5       address of first card of X on foreground
;     r6       address of first card of X on background
;     r8L      bitmask left card (bits set on the left)
;     r8H      bitmask right card (bits set on the right)
;     X        bit number
; Destroyed: a, x, r3H, r4H

__PrepareXCoord:
	; set r5, r6 to screen address of scanline
	ldx r11L
PrepareXCoordX:
	jsr __GetScanLine
	; bitmask right before r4 is changed
	lda r4L
	and #%00000111
	tax
	lda __BitMaskLeadingClear,x
	sta r8H
	; card number since start of the line (inclusive)
	IncW r4
	lda r4L
	lsr r4H
	ror
	lsr
	lsr
	sta r4L
	; bitmask left before r3 is changed
	lda r3L
	and #%0000111
	tax
	lda __BitMaskLeadingSet,x
	sta r8L
	; card number since start of the line
	lda r3L
	lsr r3H
	ror
	lsr
	lsr
	sta r3L
	; whole card distance
	SubB r3L, r4L
	rts

;---------------------------------------------------------------
; HorizontalLine                                          $C118
;
; Pass:      a    pattern byte
;            r11L y position in scanlines (0-199)
;            r3   x in pixel of left end (0-319)
;            r4   x in pixel of right end (0-319)
; Return:    r11L unchanged
; Destroyed: a, x, y, r5 - r8, r11
;---------------------------------------------------------------
__HorizontalLine:
	sta r7L				; temporary for pattern
	PushW r3
	PushW r4
	jsr __PrepareXCoord
	jsr __HorizontalLineDo
HLinEnd2:
	PopW r4
	PopW r3
	rts

	; common part for HorizontalLine and Rectangle
__HorizontalLineDo:
	ldy r3L				; left card offset
	ldx r4L

	lda r8L				; need to handle first card bit mask?
	beq @noleft
					; yes, handle left byte (value already in A)
	eor #$ff			; reverse screen protection bitmask
	and r7L				; take from pattern bits what we need
	sta r11H			; keep temporary
	lda (r6),y
	and r8L
	ora r11H
	sta (r5),y			; write to foreground
	sta (r6),y			; and background
	iny
	txa
	beq @nowhole
	dex

@noleft:
	txa				; any whole cards left?
	beq @nowhole

	lda r7L				; whole cards
:	sta (r5),y
	sta (r6),y
	iny
	dex
	bne :-

@nowhole:
	lda r8H				; need to handle last card?
	beq HLinEnd3

	eor #$ff
	and r7L
	sta r11H
	lda (r6),y
	and r8H
	ora r11H
HLinEnd1:
	sta (r5),y
	sta (r6),y
HLinEnd3:
	rts

;---------------------------------------------------------------
; InvertLine                                              $C11B
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos (0-199)
; Return:    r3-r4 unchanged
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
__InvertLine:
	PushW r3
	PushW r4
	jsr __PrepareXCoord
	jsr __InvertLineDo
	jmp HLinEnd2

	; common part for InvertLine and InvertRectangle
__InvertLineDo:
	ldy r3L				; left card offset
	ldx r4L

	lda r8L				; need to handle first card bit mask?
	beq @noleft
					; yes, handle left byte (value already in A)
	eor #$ff			; reverse screen protection bitmask
	eor (r5),y
	sta (r5),y
	sta (r6),y
	iny
	txa
	beq @nowhole
	dex

@noleft:
	txa				; any whole cards left?
	beq @nowhole

:	lda (r5),y			; whole cards
	eor #$ff
	sta (r5),y
	sta (r6),y
	iny
	dex
	bne :-

@nowhole:
	lda r8H				; need to handle last card?
	bne :+
	rts

:	eor #$ff
	eor (r5),y
	bra HLinEnd1


;---------------------------------------------------------------
; ImprintLine
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from foreground (r5) to
;            background screen (r6)
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------
__ImprintLine:
	PushW r3			; prefix is the same as RecoverLine...
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr __PrepareXCoord
	lda r5L				; ... just swap r5 and r6
	ldy r6L
	sta r6L
	sty r5L
	lda r5H
	ldy r6H
	sta r6H
	sty r5H
	bra RLin0

;---------------------------------------------------------------
; RecoverLine                                             $C11E
;
; Pass:      r3   x pos of left endpoint (0-319)
;            r4   x pos of right endpoint (0-319)
;            r11L y pos of line (0-199)
; Return:    copies bits of line from background (r6) to
;            foreground screen (r5)
; Destroyed: a, x, y, r5 - r8
;---------------------------------------------------------------

__RecoverLine:
	PushW r3
	PushW r4
	PushB dispBufferOn
	ora #ST_WR_FORE | ST_WR_BACK
	sta dispBufferOn
	jsr __PrepareXCoord
RLin0:
	jsr __RecoverLineDo
	PopB dispBufferOn
	jmp HLinEnd2

	; common part for Recover/ImprintLine and Recover/ImprintRectangle
__RecoverLineDo:
	ldy r3L				; left card offset
	ldx r4L

	lda r8L				; need to handle first card bit mask?
	beq @noleft

	jsr @recovercard		; yes, handle left byte (value already in A)
	iny
	txa
	beq @nowhole
	dex

@noleft:
	txa				; any whole cards left?
	beq @nowhole

:	lda (r6),y			; whole cards
	sta (r5),y
	iny
	dex
	bne :-

@nowhole:
	lda r8H				; need to handle last card?
	beq :+

@recovercard:
	tax
	and (r5),y
	sta r7L
	txa
	eor #$ff
	and (r6),y
	ora r7L
	sta (r5),y
:	rts

;---------------------------------------------------------------
; VerticalLine                                            $C121
;
; Pass:      a pattern
;            r3L top of line (0-199)
;            r3H bottom of line (0-199)
;            r4  x position of line (0-319)
; Return:    draw the line
; Destroyed: a, x, y, r4 - r8, r11
;---------------------------------------------------------------
__VerticalLine:
	tay				; Y = pattern
	ldx r3L				; X = line start
	PushW r4
	PushW r3
	tya
	pha				; pattern
	MoveW r4, r3			; r4 is X coord but we need it on the left
	jsr PrepareXCoordX		; X = bitnumber
	ldy r3L				; Y = card offset
	PopB r8L			; r8L = pattern
	PopW r3				; r3L/H = top/bottom
	MoveB r3L, r4L			; r4L = top
	; r8L = pattern, Y = left offset, r5+r6 set, lines r3L to r3H, X = bitnumber

	lda __BitMaskPow2Rev,x
	sta r7L				; bit of interest
	eor #$ff
	sta r7H				; bits to protect

	; read from background, store to back and foreground
@1:	lda r4L
	and #%00000111
	tax
	lda __BitMaskPow2Rev,x
	and r8L				; next pattern bit set or reset?
	beq :+
	lda #$ff
:	and r7L
	sta r8H

	lda (r6),y
	and r7H
	ora r8H
	sta (r5),y
	sta (r6),y

	lda r4L
	cmp r3H
	beq @end

	inc r4L
	lda #SC_BYTE_WIDTH
	add r5L
	sta r5L
	sta r6L
	bcc @1
	inc r5H
	inc r6H
	bne @1

@end:
	PopW r4
	rts
