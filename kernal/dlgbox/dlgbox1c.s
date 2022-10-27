; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Dialog box: RstrFrmDialogue and misc

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import DialogRestore
.import dlgBoxCallerPC
.import dlgBoxCallerSP
.import RcvrMnu0
.import defIconTab
.import DialogSave
.import InitGEOEnv

.import FrameRectangle
.import Rectangle
.import SetPattern
.ifdef atari
.import ImprintRectangle
.endif

.global CalcDialogCoords
.global DlgBoxPrep
.global DrawDlgBox
.global Dialog_2
.global _RstrFrmDialogue

.segment "dlgbox1c"

DlgBoxPrep:
	sec
	jsr DlgBoxPrep2
	LoadB sysDBData, NULL
	jmp InitGEOEnv

Dialog_2:
	clc
DlgBoxPrep2:
	LoadW r4, dlgBoxRamBuf
	bcc :+
	jmp DialogSave
:	jmp DialogRestore

DrawDlgBox:
	LoadB dispBufferOn, ST_WR_FORE | ST_WRGS_FORE
	ldy #0
	lda (DBoxDesc),y
	and #%00011111
.ifdef speedupDlgBox
	bne DrwDlgSpd0
	jmp @1
DrwDlgSpd0:
	;1st: right,right+8,top+8,bottom
	;2nd: left+8,right+8,bottom,bottom+8
	jsr SetPattern
	PushW DBoxDesc
	ldy #0
	lda (DBoxDesc),y
	bpl DrwDlgSpd1
	LoadW DBoxDesc, DBDefinedPos-1
DrwDlgSpd1:
	ldy #1
	lda (DBoxDesc),y
	addv 8
	sta r2L
	iny
	lda (DBoxDesc),y
	sta r2H
	iny
	iny
	iny
	lda (DBoxDesc),y
	sta r3L
	tax
	iny
	lda (DBoxDesc),y
	sta r3H
	txa
	addv 8
	sta r4L
	lda r3H
	adc #0
	sta r4H
.ifdef atari
	; imprint/recover should be done on dlgbox+shadow (8 added to X/Y)
	; standard BSW code draws two shifted rectangles, imprint on the second one (front) would overwrite backscreen with shadow
	; for now it's close enough
	jsr ImprintRectangle	; imprint shadow
.endif
	jsr Rectangle
	MoveB r2H, r2L
	addv 8
	sta r2H
	ldy #1+2
	lda (DBoxDesc),y
	sta r3L
	iny
	lda (DBoxDesc),y
	sta r3H
	AddVW 8, r3
.ifdef atari
	jsr ImprintRectangle
.endif
	jsr Rectangle
	PopW DBoxDesc
.else
	beq @1
	jsr SetPattern
	sec
	jsr CalcDialogCoords
.ifdef atari
	jsr ImprintRectangle
.endif
	jsr Rectangle
.endif
@1:	lda #0
	jsr SetPattern
	clc
	jsr CalcDialogCoords
	MoveW r4, rightMargin
.ifdef atari
	;jsr ImprintRectangle	; not the front
.endif
	jsr Rectangle
	lda #$ff
	jsr FrameRectangle
	lda #0
	sta defIconTab
	rts

Dialog_1:
	ldy #0
	lda (DBoxDesc),y
	and #%00011111
	beq @1
	sec
	jsr @2
@1:	clc
@2:	jsr CalcDialogCoords
	jmp RcvrMnu0

CalcDialogCoords:
.ifdef speedupDlgBox
	LoadB r1H, 0
.else
	lda #0
	bcc @1
	lda #8
@1:	sta r1H
.endif
	PushW DBoxDesc
	ldy #0
	lda (DBoxDesc),y
	bpl @2
	LoadW DBoxDesc, DBDefinedPos-1
@2:	ldx #0
	ldy #1
@3:	lda (DBoxDesc),y
	clc
	adc r1H
	sta r2L,x
	iny
	inx
	cpx #2
	bne @3
@4:	lda (DBoxDesc),y
	clc
	adc r1H
	sta r2L,x
	iny
	inx
	lda (DBoxDesc),y
	bcc @5
	adc #0
@5:	sta r2L,x
	iny
	inx
	cpx #6
	bne @4
	PopW DBoxDesc
	rts

DBDefinedPos:
	.byte DEF_DB_TOP
	.byte DEF_DB_BOT
	.word DEF_DB_LEFT
	.word DEF_DB_RIGHT

_RstrFrmDialogue:
	jsr Dialog_2
	jsr Dialog_1
	MoveB sysDBData, r0L
	ldx dlgBoxCallerSP
	txs
	PushW dlgBoxCallerPC
	rts

