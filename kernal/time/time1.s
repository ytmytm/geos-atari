; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import alarmWarnFlag
.import dateCopy

.global _DoUpdateTime
.global jiffyCounter

.segment "ramexp2"
; increased on VBLANK interrupt
jiffyCounter:	.res 1, 0

.segment "time1"

; called from mainloop
_DoUpdateTime:
	lda jiffyCounter			; at least one second passed?
	cmp #50					; XXX this depends on PAL/NTSC!
	bcs :+
	rts

:	ldx #0
	subv 50					; XXX this depends on PAL/NTSC
	sta jiffyCounter
	bpl :+
	stx jiffyCounter			; negative? we might lose a second here
:	inc seconds				; next second
	lda seconds
	cmp #60
	bcc :+
	stx seconds				; next minute
	inc minutes
	lda minutes
	cmp #60
	bcc :+
	stx minutes				; next hour
	inc hour
	lda hour
	cmp #24
	bcc :+
	stx hour
	jsr DateUpdate				; next day
:	rts 

.if 0=1
	ldy #2					; this is done for RBoot, but does it even make sense on Atari?
:	lda year,y
	sta dateCopy,y
	dey
	bpl :-
.endif

.if 0=1
	; does this even work? how that alarm is enabled?
	bbrf 7, alarmSetFlag, @5
	and #ALARMMASK
	beq @6
	lda #$4a
	sta alarmSetFlag
	lda alarmTmtVector
	ora alarmTmtVector+1
	beq @5
	jmp (alarmTmtVector)
@5:	bbrf 6, alarmSetFlag, @6
	jsr DoClockAlarm
@6:	rts
.endif

DateUpdate:
	jsr CheckMonth
	cmp day
	beq @1
	inc day
	rts
@1:	ldy #1
	sty day
	inc month
	lda month
	cmp #13
	bne @2
	sty month
	inc year
; The implementation disagrees with the documentation,
; which says years are 1900-based: This code implies
; that "2000" is stored as 0, which is the "Excel" way
; of storing dates. With a cutoff year of 1980, numbers
; 80-99 would be 1980-1999, and 0-79 would be 2000-2079.
; It is unknown what the cutoff year should be.
	lda year
	cmp #100
.ifdef wheels
	bcc @2 ; new years with an illegal new year? store "0".
.else
	bne @2 ; 1999->2000: store "0" as year
.endif
	dey
	sty year ; year 0
@2:	rts

CheckMonth:
	ldy month
	lda daysTab-1, y
; This code is correct for the years 1901-2099.
; This is another reason why the year probably should
; not be considered 1900-based, since this logic is
; incorrect for 1900, but it would be correct for any
; cutoff year.
	cpy #2
	bne @2
	tay
	lda year
	and #3
	bne @1
	iny
@1:	tya
@2:	rts

daysTab:
	.byte 31, 28, 31, 30, 31, 30
	.byte 31, 31, 30, 31, 30, 31

.if 0=1
DoClockAlarm:
	lda alarmWarnFlag
	bne @3
.warning "time1.s - alarm ping sound not implemented"
	; XXX ping sound using POKEY goes here
	ldx #$21
	lda alarmSetFlag
	and #%00111111
	bne @2
	tax
@2:	;stx sidbase+4 ???
	END_IO_Y
	lda #$1e
	sta alarmWarnFlag
	dec alarmSetFlag
@3:	rts
.endif

