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

; sprites_atari.s
.import AtariPlayersInit

; ramexp1-atari.s
.import atari_nbanks
.import atari_banks

; displaylistinit.s
.import displaylistinit

; used by header.s
.global _ResetHandle

; ramexp1-atari.s
.import DetectRamExp

.ifdef useRamExp
.import LoadDeskTop
.endif

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
.import __KERNALRELOCH_START__
.import __KERNALRELOCH_LAST__
.import __KERNALH_START__
.import __KERNALRELOCIO_START__
.import __KERNALRELOCIO_LAST__
.import __KERNALIO_START__
.import __INPUTDRVRELOC_START__
.import __INPUTDRVRELOC_LAST__
.import __INPUTDRV_START__
.import __BANK0RELOC_START__
.import __BANK0RELOC_LAST__
.import __BANK0_START__

.segment "start"

relocatebank0:
	; DetectRamExp must have been already called and atari_banks contains banks
	; PIA memory setup must be already set
	; IRQ/NMI must be disabled
.assert * < $4000 || * > $8000, error, "bank0 relocator code can't overlap with banked space"
.assert * < $c000, error, "bank0 relocator code can't be under ROM"
	PushB PIA_PORTB
	LoadW r0, __BANK0RELOC_START__
	LoadW r1, __BANK0_START__
	MoveB atari_banks+0, PIA_PORTB			; load bank0 memory config
	ldy #0
	ldx #>(__BANK0RELOC_LAST__ - __BANK0RELOC_START__)
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	inc r0H
	inc r1H
	dex
	bpl :-
	PopB PIA_PORTB
	rts

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
	LoadW r0, __KERNALRELOCIO_START__
	LoadW r1, __KERNALIO_START__
	ldx #>(__KERNALRELOCIO_LAST__ - __KERNALRELOCIO_START__)
:	lda (r0),y
	sta (r1),y
	iny
	bne :-
	inc r0H
	inc r1H
	dex
	bpl :-
	; $E000-$FE7F ($D800-$DFFF can't be used - it's color RAM on C64 and apps can touch it)
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

	; check if we have at least 128K and how to program bank bits
	jsr DetectRamExp
	lda atari_nbanks
	bne :+
	jmp ($fffc)

:	sei
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

	; copy banked kernal code
	jsr relocatebank0
	; copy high RAM area code so it's safe to call following Kernal functions
	jsr relocate

	; setup hardware, registers, IRQ/NMI vectors and enable all as RAM
	jsr _DoFirstInitIO


	; LUnix had PAL/NTSC detection here, could be used for timers?
;	jsr displaylistinit

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

	; XXX this needs to stay here until DoDlgBox is ready to be Panic() call
	LoadW BRKVector, _BRKHandler	; InitRam would make this Panic, but we don't have Panic yet

;	cli	; firstinit does sei, but MainLoop or DoneWithIO do cli anyway

	;; WE ARE RUNNING GEOS NOW!

	;; test routines follow, normally we would load autoexecs here
	;; with override for EnterDeskTop jumptable address to come back here

	jsr ClrScr

	jsr i_ImprintRectangle
	.byte 0   ; y1
	.byte 199 ; y2
	.word 0   ; x1
	.word 160 ; x2

	LoadB dispBufferOn, ST_WR_FORE

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
mAboutTxt: .byte "about",0
mNothTxt: .byte "nothing",0
mNot2Txt: .byte "not2",0

menuGeos:
	.byte 15,15+2*15-1
	.word 8,52 ;; 56-1 byloby ok
	.byte 2 | VERTICAL

	.word mAboutTxt
	.byte MENU_ACTION
	.word goLoop

	.word mNothTxt
	.byte MENU_ACTION
	.word goRTS

menuFile:
	.byte 15,30
	.word 42,80;40,79
	.byte 1 | VERTICAL

	.word mNot2Txt
	.byte MENU_ACTION
	.word goRTS

; L:
; 40 = ok z lewej
; 41-47 = zostaje lewa
; 48 = ok

; R:
; 79 = ok
; 80 = zostaje prawa

;;;;
goRTS:	jsr GotoFirstMenu
rtsonly:rts
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
; XXX todo atari: setup 1 drive, RAM type
	lda #1
	sta NUMDRV
	ldy $BA
	sty curDrive
	lda #DRV_TYPE ; see config.inc
	sta curType
	sta _driveType,y
.ifdef useRamExp
; XXX todo atari: this should happen earlier, before relocate, maybe during XEX chunk load
	jsr DetectRamExp
.endif

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
