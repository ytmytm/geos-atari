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
	;0th left,right+8,top,bottom+8
	jsr CalcDialogCoordsWithShadow
	jsr ImprintRectangle

	ldy #0
	lda (DBoxDesc),y
	and #%00011111
	beq @noshadow

	jsr SetPattern
	;1st: right,right+8,top+8,bottom
	jsr CalcDialogCoords
	AddVB 8, r2L
	MoveW r4, r3
	AddVW 8, r4
	jsr Rectangle
	;2nd: left+8,right+8,bottom,bottom+8
	jsr CalcDialogCoords
	AddVW 8, r3
	AddVW 8, r4
	MoveB r2H, r2L
	AddVB 8, r2H
	jsr Rectangle

@noshadow:
	lda #0
	jsr SetPattern
	jsr CalcDialogCoords
	MoveW r4, rightMargin
	jsr Rectangle
	lda #$ff
	jsr FrameRectangle
	LoadB defIconTab, 0
	rts

RecoverDialogBox:
	jsr CalcDialogCoordsWithShadow
	jmp RcvrMnu0

CalcDialogCoordsWithShadow:
	jsr CalcDialogCoords
	AddVB 8, r2H		; bottom+8
	AddVW 8, r4		; right+8
	rts

CalcDialogCoords:
	ldy #0
	lda (DBoxDesc),y
	bmi @def_db_pos
	ldx #0
	ldy #1
:	lda (DBoxDesc),y
	sta r2L,x
	iny
	inx
	cpx #6
	bne :-
	rts

@def_db_pos:
	ldx #0
:	lda DBDefinedPos,x
	sta r2L,x
	inx
	cpx #6
	bne :-
	rts

DBDefinedPos:
	.byte DEF_DB_TOP
	.byte DEF_DB_BOT
	.word DEF_DB_LEFT
	.word DEF_DB_RIGHT

_RstrFrmDialogue:
	jsr Dialog_2
	jsr RecoverDialogBox
	MoveB sysDBData, r0L
	ldx dlgBoxCallerSP
	txs
	PushW dlgBoxCallerPC
	rts

