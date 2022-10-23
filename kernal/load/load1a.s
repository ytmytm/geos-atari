; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Loading: EnterDeskTop, StartAppl syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "diskdrv.inc"

.import _MNLP
.import UNK_4
.import UNK_5
.import DeskTopName
.import _EnterDT_DB
.import TempCurDrive
.import _InitMachine
.import ClrScr
.import _UseSystemFont

.import MainLoop
.import CallRoutine
.import GetFile
.import OpenDisk
.import SetDevice
.import DoDlgBox

.global _EnterDeskTop
.global _StartAppl

.segment "load1a"

; XXX Atari has only RAM disk, so there is no search across all drives for DESK TOP
; XXX also we don't check for any version

_EnterDeskTop:
	sei
	cld
	ldx #$ff
	stx firstBoot			; save 3 bytes by moving this to boot code
	txs
	jsr ClrScr
	jsr _InitMachine
	MoveB curDrive, TempCurDrive	; we search for desktop on all drives, so remeber the caller drive to restore it later
	jsr @tryload
@tryagain:
	LoadW r0, _EnterDT_DB
	jsr DoDlgBox
	jmp @tryagain

@tryload:
	jsr OpenDisk
	beqx :+
	rts
:	sta r0L
	LoadW r6, DeskTopName
	jsr GetFile
	bnex @tryagain
	; there was a check for version number here
;	lda fileHeader+O_GHFNAME+13
;	cmp #'1'
;	bcc @tryagain
;	bne @verok
;	lda fileHeader+O_GHFNAME+15
;	cmp #'5'
;	bcc @tryagain
;@verok:	lda TempCurDrive	; restore drive which was active before EnterDeskTop
;	jsr SetDevice
	LoadB r0L, NULL
	MoveW fileHeader+O_GHST_VEC, r7
	; fall into _StartAppl

_StartAppl:
	sei
	cld
	ldx #$FF
	txs
	jsr UNK_5
	jsr _InitMachine
	jsr _UseSystemFont
	jsr UNK_4
	ldx r7H
	lda r7L
	jmp _MNLP

