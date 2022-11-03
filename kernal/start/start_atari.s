; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak; Michael Steil
;
; Purgeable start code; first entry

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "inputdrv.inc"
.include "atari.inc"

; ramexp.s
.import CopyRamBanksUp

; main.s
.import InitGEOEnv
.import _DoFirstInitIO
;.import _EnterDeskTop

; header.s
.import dateCopy

; irq.s
.import _IRQHandler
.import _NMIHandler
.import _BRKHandler

;.import LdApplic
;.import GetBlock
;.import EnterDeskTop
;.import GetDirHead
.import FirstInit
.import i_FillRam

.import ClrScr

; gfx debug
.import SetPattern
.import i_Rectangle
.import _i_InvertRectangle
.import i_FrameRectangle
.import FrameRectangle
.import VerticalLine
.import i_ImprintRectangle
.import i_RecoverRectangle
.import DBIcPicOK
.import DBIcPicYES
.import DBIcPicNO
.import i_BitmapUp
.import PosSprite
.import EnablSprite
.import DisablSprite
.import _EnterDT_DB

; sprites_atari.s
.import AtariPlayersInit

; ramexp1-atari.s
.import atari_nbanks
.import atari_banks

; displaylistinit.s
.import displaylistinit

; used by header.s
.global _ResetHandle

.ifdef useRTC
.import RTCSetupDateAndTime
.endif

; exported by ld65
.import __KERNALHDRREL_START__
.import __KERNALHDRREL_LAST__
.import __KERNALHDR_START__
.import __KERNALRELOCL_START__
.import __KERNALRELOCL_LAST__
.import __KERNALL_START__
.import __KERNALRELOHL_START__
.import __KERNALRELOHL_LAST__
.import __KERNALHL_START__
.import __KERNALRELOCH_START__
.import __KERNALRELOCH_LAST__
.import __KERNALH_START__
.import __INPUTDRVRELOC_START__
.import __INPUTDRVRELOC_LAST__
.import __INPUTDRV_START__
.import __CIAGAPRELOC_START__
.import __CIAGAP_START__

.segment "start"

ASSERT_NOT_IN_BANK0
ASSERT_NOT_UNDER_ROM

relocate:
	; copy data from RAM to RAM under ROMs
	; it's enough to copy whole pages
	; we can't use MoveMem yet
	ldy #0
	; $C000-$C100
	LoadW r0, __KERNALHDRREL_START__
	LoadW r1, __KERNALHDR_START__
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	; $C100-$CFFF
	inc r1H		; we know that KERNALHDR+$100 = KERNALL
	LoadW r0, __KERNALRELOCL_START__
	ldx #>(__KERNALRELOCL_LAST__ - __KERNALRELOCL_START__)
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	inc r0H
	inc r1H
	dex
	bpl :-
	; $D800-$DBFF
	LoadW r0, __KERNALRELOHL_START__
	LoadW r1, __KERNALHL_START__
	ldx #>(__KERNALRELOHL_LAST__ - __KERNALRELOHL_START__)
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	inc r0H
	inc r1H
	dex
	bpl :-
	; $DC10-$DCFF
	LoadW r0, __CIAGAPRELOC_START__
	LoadW r1, __CIAGAP_START__
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	; $DD10-$FE7F
	LoadW r0, __KERNALRELOCH_START__
	LoadW r1, __KERNALH_START__
	ldx #>(__KERNALRELOCH_LAST__ - __KERNALRELOCH_START__)
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	inc r0H
	inc r1H
	dex
	bpl :-
	; $FE80-$FFFA
	LoadW r0, __INPUTDRVRELOC_START__
	LoadW r1, __INPUTDRV_START__
:	lda (r0),y
	sta (r1),y
	IncW r0
	IncW r1
	CmpWI r0, __INPUTDRVRELOC_LAST__
	bne :-
	rts

; The original version of GEOS 2.0 has purgeable init code
; at $5000 that is run once. It does some initialization
; and handles application auto-start.

_ResetHandle:

	; atari ramloader does setup before
	sei
	cld
	ldx #$FF
	txs

	; these parts of _DoFirstInitIO are repeated because
	; NMI from ANTIC will run even when we are not ready yet
	LoadB ANTIC_NMIEN, %00000000                    ; no interrupts from ANTIC
	LoadB POKEY_IRQEN, %00000000                    ; no interrupts from POKEY

	LoadW NMI_VECTOR, _NMIHandler
	LoadW IRQ_VECTOR, _IRQHandler

	LoadB PIA_PBCTL, %00110000                      ; no interrupts from PIA, PORTB as DDR
	LoadB PIA_PORTB, %11111111                      ; all PORTB pins as output
	LoadB PIA_PBCTL, %00110100                      ; no interrupts from PIA, PORTB as I/O
	LoadB PIA_PORTB, %10110010                      ; only RAM, main RAM in $4000-$8000 for CPU (ANTIC irrelevant)

	; stop all timers, and disable all (known) interrupts
	LoadB PIA_PACTL, %00110000                      ; no interrupts from PIA, PORTA as DDR
	LoadB PIA_PORTA, %00000000                      ; all PORTA pins as input
	LoadB PIA_PACTL, %00110100                      ; no interrupts from PIA, PORTA as I/O (joystick I/O)

	jsr CopyRamBanksUp		; copy detected banks to target location under ROM (also it's cleared if we don't put it into BSS segment)

	; copy high RAM area code so it's safe to call following Kernal functions
	jsr relocate

	; setup hardware, registers, IRQ/NMI vectors and enable all as RAM
	jsr _DoFirstInitIO

	; PAL/NTSC detection here?

	; this is mostly about memory cleanup, registers are already set
	jsr AtariPlayersInit

	; clear OS_VARS space (repeated below, after firstinit), delete it after debug
	jsr i_FillRam
	.word $0500
	.word dirEntryBuf
	.byte 0

	; set date and time to default
	ldy #2
:	lda dateCopy,y
	sta year,y
	dey
	bpl :-
.ifdef useRTC
	; or from RTC if available
	jsr RTCSetupDateAndTime
.endif

	jsr FirstInit
	jsr MouseInit

	jsr InitGEOEnv

	; fake Commodore drive
	LDY #8
	STY curDevice
	STY curDrive
	LDA #DRV_1541 | $80		; RAM 1541 (DESKTOP will check track 18 for directory)
	STA _driveType,y
	lda #1
	sta NUMDRV

	; XXX this needs to stay here until DoDlgBox is ready to be Panic() call
	;LoadW BRKVector, _BRKHandler	; InitRam would make this Panic, but we don't have Panic yet

;	cli	; firstinit does sei, but MainLoop or DoneWithIO do cli anyway

	;; WE ARE RUNNING GEOS NOW!

	;; test routines follow, normally we would load autoexecs here
	;; with override for EnterDeskTop jumptable address to come back here

	jsr ClrScr

	jmp EnterDeskTop

;;
jsr testDiskOps
;;

	jsr i_ImprintRectangle
	.byte 0   ; y1
	.byte 199 ; y2
	.word 0   ; x1
	.word 160 ; x2

	LoadB dispBufferOn, ST_WR_FORE | ST_WR_BACK

	lda #3
	jsr SetPattern
	jsr i_Rectangle
	.byte 2   ; y1
	.byte 20 ; y2
	.word 8   ; x1
	.word 30 ; x2

	lda #4
	jsr SetPattern
	jsr i_Rectangle
	.byte 30   ; y1
	.byte 50 ; y2
	.word 50   ; x1
	.word 80 ; x2

	lda #5
	jsr SetPattern
	jsr i_Rectangle
	.byte 51   ; y1
	.byte 90 ; y2
	.word 110   ; x1
	.word 317 ; x2

	lda #6
	jsr SetPattern
	jsr i_Rectangle
	.byte 180   ; y1
	.byte 190 ; y2
	.word 160   ; x1
	.word 168 ; x2

	lda #7
	jsr SetPattern
	jsr i_Rectangle
	.byte 190   ; y1
	.byte 199 ; y2
	.word 180   ; x1
	.word 200 ; x2

;;;;

	LoadB r3L, 2
	LoadB r3H, 20
	LoadW r4, 8
	lda #%11011011
	jsr VerticalLine
	LoadB r3L, 2
	LoadB r3H, 20
	LoadW r4, 30
	lda #%11111111
	jsr VerticalLine

	LoadB r2L, 2
	LoadB r2H, 25
	LoadW r3, 108
	LoadW r4, 130
	lda #%11111111
	jsr FrameRectangle

;jmp *

;jmp @there2

	lda #3
	jsr SetPattern
	jsr i_FrameRectangle
	.byte 1   ; y1
	.byte 21 ; y2
	.word 7   ; x1
	.word 31 ; x2
	.byte $ff

	lda #3
	jsr SetPattern
	jsr i_FrameRectangle
	.byte 1   ; y1
	.byte 50 ; y2
	.word 7   ; x1
	.word 31 ; x2
	.byte $ff

	jsr i_FrameRectangle
	.byte 30   ; y1
	.byte 50 ; y2
	.word 50   ; x1
	.word 80 ; x2
	.byte $01

	jsr i_FrameRectangle
	.byte 51   ; y1
	.byte 90 ; y2
	.word 110   ; x1
	.word 317 ; x2
	.byte $f0

	jsr i_FrameRectangle
	.byte 180   ; y1
	.byte 190 ; y2
	.word 160   ; x1
	.word 168 ; x2
	.byte $0f

	jsr i_FrameRectangle
	.byte 190   ; y1
	.byte 199 ; y2
	.word 180   ; x1
	.word 200 ; x2
	.byte $33


;;;;
@there2:

	lda #3
	jsr SetPattern
	.repeat 8, xx
	jsr i_Rectangle
	.byte 10+xx*5,10+xx*5+4
	.word 0, xx
	jsr i_Rectangle
	.byte 50+xx*5,50+xx*5+4
	.word xx, 8
	jsr i_Rectangle
	.byte 100+xx*5,100+xx*5+4
	.word xx, 8+xx
	.endrepeat

	lda #1
	jsr SetPattern
	jsr i_Rectangle
	.byte 10, 10+8*5+4
	.word 31, 32+7
	jsr i_Rectangle
	.byte 50, 50+8*5+4
	.word 32, 32+8
	jsr i_Rectangle
	.byte 100, 100+8*5+4
	.word 31, 32+15
	jsr i_Rectangle
	.byte 150, 150+8*5+4
	.word 32, 32+16

	jsr i_RecoverRectangle
	.byte 0   ; y1
	.byte 100 ; y2
	.word 100 ; x1
	.word 160 ; x2

;;;;
	jsr i_BitmapUp
	.word DBIcPicOK
	.byte 20-3
	.byte 100-8+1
	.byte 6, 16

	jsr i_BitmapUp
	.word DBIcPicYES
	.byte 20-7
	.byte 100-8-16
	.byte 6, 16
	jsr i_BitmapUp
	.word DBIcPicNO
	.byte 20+1
	.byte 100-8-16
	.byte 6, 16

; point
.import DrawLine
.import DrawPoint

	lda #0
	jsr SetPattern
	jsr i_Rectangle
	.byte 0
	.byte 100
	.word 0
	.word 100

	LoadW r3,10
	LoadW r4,305;90
	LoadB r11L, 5
	LoadB r11H, 95
	lda #0
	sec
	jsr DrawLine

	LoadW r3,10
	LoadW r4,90
	LoadB r11L, 5
	LoadB r11H, 95
	lda #0
	sec
	jsr DrawLine

	LoadW r3,0
	LoadB r11L, 0
:	lda #0
	sec
	jsr DrawPoint
	IncW r3
	inc r11L
	CmpBI r11L, 100
	bne :-

; string
.import UseSystemFont
.import i_PutString
.import PutChar
	jsr UseSystemFont

	LoadW windowTop, 0
	LoadW leftMargin, 0
	LoadW windowBottom, 199
	LoadW rightMargin, 319

	LoadB r1H, 40
	LoadW r11, 0
	lda #$41
	jsr PutChar


	LoadB r1H, 41
	LoadW r11, 8
	lda #$42
	jsr PutChar

	LoadB r1H, 42
	LoadW r11, 16
	lda #$43
	jsr PutChar

	jsr i_PutString
	.word 0
	.byte 9
	.byte "0Hello world!"
	.byte BOLDON,"BOLD "
	.byte OUTLINEON, "OUTLINE", PLAINTEXT
	.byte $60
	.byte 0

	jsr i_PutString
	.word 16
	.byte 9+16
	.byte "16Hello world!"
	.byte $60
	.byte 0

	jsr i_PutString
	.word 32
	.byte 9+32
	.byte "32Hello world!"
	.byte $60
	.byte 0

	jsr i_PutString
	.word 64
	.byte 9+64
	.byte "64Hello world!"
	.byte $60
	.byte 0

	jsr i_PutString
	.word 192
	.byte 9+32
	.byte "192Hello world!"
	.byte $60
	.byte 0

	jsr i_PutString
	.word 240
	.byte 9+64
	.byte "240Hello world!"
	.byte $60
	.byte 0

	jsr i_PutString
	.word 300
	.byte 9+32
	.byte "300Hello world!"
	.byte $60
	.byte 0

jmp @n
;
.import GetNextChar

@l:	jsr GetNextChar
	tax
	beq @l
	cmp #CR
	beq @n
	sta @t
	jsr i_PutString
	.word 10
	.byte 10
@t:	.byte " "
	.byte 0
	jmp @l

@n:	
;jmp @n2

; getstring
	lda #'A'
	sta $1000
	lda #'B'
	sta $1001
	lda #'C'
	sta $1002
	lda #0
	sta $1003

.import GetString
	LoadW r0, $1000
	LoadB r1H, 100
	LoadW r11, 100
	LoadB r2L, 50		; max 50 characters
	LoadW r4, 0
	LoadB r1L, $40
	LoadW keyVector, rtsonly	; we don't have a routine to handle this
	jsr GetString

@n2:

; move pointer

.import GraphicsString
	LoadB dispBufferOn, ST_WR_FORE | ST_WR_BACK

	LoadW r0, ClearScreenString
	jsr GraphicsString

; DoIcons
.import DoIcons
	LoadW r0, iconDesc
	jsr DoIcons

; Panic
.import Panic
	;jsr Panic
	;brk
	nop

; DoMenu

.import DoMenu
.import GotoFirstMenu
.import ToBASIC

	LoadW r0, menuDesc
	lda #0
	jsr DoMenu

.import MainLoop
jmp MainLoop

ClearScreenString:
	.byte NEWPATTERN, 2
	.byte MOVEPENTO
	.word 0
	.byte 0
	.byte RECTANGLETO
	.word 319
	.byte 199
	.byte NULL

iconDesc:
	.byte 2
	.word 0
	.byte 0

	.word DBIcPicYES
	.byte 20-7
	.byte 100-8-16
	.byte 6, 16
	.word goLoop

	.word DBIcPicNO
	.byte 20+1
	.byte 100-8-16
	.byte 6, 16
	.word ToBASIC

menuDesc:
	.byte 0, 14
	.word 0, 100
	.byte 3 | HORIZONTAL
	
	.word mGeosTxt
	.byte VERTICAL
	.word menuGeos

	.word mFileTxt
	.byte VERTICAL
	.word menuFile

	.word mQuitTxt
	.byte MENU_ACTION
	.word ToBASIC

mGeosTxt: .byte "geos",0
mFileTxt: .byte "file",0
mQuitTxt: .byte "quit",0
mAboutTxt: .byte "loop",0
mNothTxt: .byte "DlgBox",0
mNot2Txt: .byte "Desktop",0

menuGeos:
	.byte 15,15+2*15-1
	.word 8,52 
	.byte 2 | VERTICAL

	.word mAboutTxt
	.byte MENU_ACTION
	.word goLoop

	.word mNothTxt
	.byte MENU_ACTION
	.word goDlgBox

menuFile:
	.byte 15,30
	.word 42,80
	.byte 1 | VERTICAL

	.word mNot2Txt
	.byte MENU_ACTION
	.word goDeskTOP

;;;;
goRTS:	jsr GotoFirstMenu
rtsonly:rts

.import EnterDeskTop
goDeskTOP:
	jsr GotoFirstMenu
	jmp EnterDeskTop

goDlgBox:
.import DoDlgBox
	jsr GotoFirstMenu
	LoadW r0, _EnterDT_DB
	jsr DoDlgBox
	rts

goLoop:
@loop:
	.repeat 16, xx
	jsr _i_InvertRectangle
	.byte 0+xx*5,0+xx*5+4
	.word 0, xx
	jsr _i_InvertRectangle
	.byte 0+xx*5,0+xx*5+4
	.word xx, 8
;	jsr _i_InvertRectangle
;	.byte 100+xx*5,100+xx*5+4
;	.word xx, 8+xx

	jsr _i_InvertRectangle
	.byte 0+xx*5,0+xx*5+4
	.word 63+xx, 63+8+xx

	jsr _i_InvertRectangle
	.byte 0+xx*5,0+xx*5+4
	.word 63+9+xx, 63+9+8+xx

	jsr _i_InvertRectangle
	.byte 0+(1+xx)*5,0+(1+xx)*5+4
	.word 92+xx, 92+10+xx

	.endrepeat

	jsr _i_InvertRectangle
	.byte 10, 10+8*5+4
	.word 31, 32+7
	jsr _i_InvertRectangle
	.byte 50, 50+8*5+4
	.word 32, 32+8
	jsr _i_InvertRectangle
	.byte 100, 100+8*5+4
	.word 31, 32+15
	jsr _i_InvertRectangle
	.byte 150, 150+8*5+4
	.word 32, 32+16

;	jsr _i_InvertRectangle
;	.byte 51   ; y1
;	.byte 92 ; y2
;	.word 104   ; x1
;	.word 317 ; x2


	MoveW a0, r4
	MoveW a1L, r5L
	LoadB r3L, 1
;	jsr PosSprite


;	LoadB r3L, 1
;	lda a1L
;	bmi :+
;jsr PromptOn
;	jsr EnablSprite
;	bra :++
;:;	jsr DisablSprite
;	brk			; irq/brk test - trigger BRK vector
;	.byte 0
;	jsr PromptOff
;:

	lda mouseData
	bpl :+

	jsr _i_InvertRectangle
	.byte 100-8+1, 100-8+1+16
	.word (20-3)*8, (20-3+6)*8

:

;	IncW mouseXPos
;	dec mouseYPos

	IncW a0
	inc a1L

jmp @loop

; normal boot would fall-in here

OrigResetHandle:
	sei
	cld
	ldx #$ff
	txs
	jsr _DoFirstInitIO
	jsr InitGEOEnv

; autoexec code for loading and executing goes here, until the very last when we run DeskTop

@end:	jmp @end
;	jmp EnterDeskTop


;.segment "start"

.import CalcBlksFree
.import ReadFile
.import FollowChain
.import PutBlock
.import SetNextFree
.import SetGEOSDisk
.import PutDirHead
.import FreeBlock
.import OpenDisk
.import ChkDkGEOS

.global maxTrack
.global maxSector
.global maxResult
.global testDiskOps

diskName:	.byte "RAMDISKWITKOWIAK"
                      ;1234567890123456
		.byte $A0,$A0,"64",$A0,"2A",$A0,$A0,$A0,$A0,0

formatDlgBox:
	.byte DEF_DB_POS | 1
	.byte YES, DBI_X_0, DBI_Y_2
	.byte NO, DBI_X_2, DBI_Y_2
	.byte DBVARSTR, 10, 32, a0
	.byte DBVARSTR, 10, 48, a1
	.byte NULL

newRAMDlgBox:
	.byte DEF_DB_POS | 1
	.byte OK, DBI_X_2, DBI_Y_2
	.byte DBVARSTR, 10, 32, a0
	.byte DBVARSTR, 10, 48, a1
	.byte NULL

oldDiskL0:
	.byte "Found RAM Disk. Format anyway?",0
reformatDiskL0:
	.byte "Formatting again.",0

newDiskL0:
	.byte "No GEOS RAM Disk found.",0
newDiskL1:
	.byte "Format will use $"
newBanks:
	.byte "00"
	.byte " banks.",0

; copied from Panic
hex2digit:
	ldx #0
        pha
        lsr
        lsr
        lsr
        lsr
        jsr hexdigit
        inx
        pla
        and #%00001111
        jsr hexdigit
        inx
        rts

hexdigit:
        cmp #10
        bcs :+
        addv '0'
        bne :++
:       addv '0'+7
:       sta newBanks,x
        rts

;---------------------------------------

testDiskOps:
	ldx atari_nbanks
	dex
	txa
	jsr hex2digit
	jsr OpenDisk	; calls ChkDkGEOS already
	lda isGEOS
	beq @notGEOS

	LoadW a0, oldDiskL0
	LoadW a1, newDiskL1
	LoadW r0, formatDlgBox
	jsr DoDlgBox
	CmpBI sysDBData, YES
	beq @reformat
	rts

@reformat:
	LoadW a0, reformatDiskL0
	bra :+
@notGEOS:
	LoadW a0, newDiskL0
:	LoadW a1, newDiskL1
	LoadW r0, newRAMDlgBox
	jsr DoDlgBox
	jsr createDirHead
	rts

createDirHead:
	jsr OpenDisk
	ldy #0
	tya
:	sta curDirHead,y
	iny
	bne :-
	dey
	sty curDirHead+1
	;;
	; disk name and ID
	ldy #0
	lda #$a0
:	sta curDirHead+OFF_DISK_NAME,y
	iny
	cpy #16+11
	bne :-
	ldy #0
:	lda diskName,y
	beq :+
	sta curDirHead+OFF_DISK_NAME,y
	iny
	bne :-
:	jsr PutDirHead
	;;
	;; we don't handle >320K expansions yet so this firts into 8 bit counter
	ldx atari_nbanks
	dex			; bank0 occupied
	txa
	asl
	asl
	asl			; *8 = *64(pages)/8
	sta r3L

	lda #$ff		; all pages are free
	ldx #0
:	sta curDirHead+OFF_TO_BAM,x
	inx
	cpx #OFF_DISK_NAME-OFF_TO_BAM	; stop if too much
	beq :+
	cpx r3L
	bne :-

:	lda #$fe		; but (1,0) must be already allocated for dirHead
	sta curDirHead+OFF_TO_BAM

.if 0=1
	;; this doesn't work because the driver checks atari_nbanks only on r/w
	;; this is not efficient but let's test these BAM functions
	LoadB r6L, 1
	sta r6H			; or remember to allocate (1,0)
	bne :++
:	LoadB r6H, 0
:	jsr FreeBlock
	bnex :+
	inc r6H
	bpl :-
	inc r6L
	bra :--
:				; doesn't check for maxbanks
.endif
	;;
	jsr PutDirHead
	jsr SetGEOSDisk		; get dir head; define border sector + format market, put dir head
	;;
	LoadB r3L, 1		; allocate space for 1st directory block
	LoadB r3H, 0
	jsr SetNextFree
	MoveW r3L, curDirHead
	jsr PutDirHead
	;;
	ldy #0
	tya
:	sta diskBlkBuf,y
	iny
	bne :-
	dey
	sty diskBlkBuf+1

	MoveW curDirHead, r1
	LoadW r4, diskBlkBuf
	jsr PutBlock
	;; disk is formatted now!

.if (0=1)
	;; debug
	LoadB r1L, 1
	LoadB r1H, 0
	LoadW r3, fileTrScTab
	jsr FollowChain		; ok 
	;;
	LoadB r1L, 1
	LoadB r1H, 0
	LoadW r7, $8c00
	LoadW r2, $ffff
	jsr ReadFile		; ok
	;;
	LoadW r5, curDirHead
	jsr CalcBlksFree
	jmp *
.endif

	rts			; end

ASSERT_NOT_IN_BANK0
ASSERT_NOT_UNDER_ROM

