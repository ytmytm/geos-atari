; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; IRQ/NMI handlers for Atari by Maciej Witkowiak, 2022

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

; keyboard.s
.import _DoKeyboardScan

; var.s
.import KbdQueFlag
.import alarmWarnFlag
.import tempIRQAcc
.import interrupt_lock
.import jiffyCounter
.import _DoUpdateTime

.import CallRoutine

; used by boot.s
.global _IRQHandler
.global _NMIHandler
.global _BRKHandler
; used by _DoKeyboardScan (possibly more than once)?
.global tmpPOKEY_IRQST

.segment "spritebuf"
tmpPOKEY_IRQST:	.res 1				; shadow register

.segment "irq"

	; IRQ only from the keyboard or BRK
_IRQHandler:
	cld
	sta tempIRQAcc
	pla
	pha
	and #%00010000				; was that BRK?
	beq :+
	pla					; why they (BSW) put it here? with that - Panic shows correct address, but without it BRKVector can return with simple RTI to caller (providing there is a NOP after BRK)
	jmp (BRKVector)
:	lda POKEY_IRQST				; was that break/keyboard irq? (bit=0 means 'yes')
	sta tmpPOKEY_IRQST
	eor #$ff				; cleared bits are set
	and #%11000000				; our sources are set?
	beq :+					; no?
	lda #0
	sta POKEY_IRQEN				; ack interrupts
	lda #%11000000
	sta POKEY_IRQEN				; re-enable interrupts from keyboard/break key
	txa
	pha
	tya
	pha
	lda tmpPOKEY_IRQST			; bit 7=0 is BREAK, bmi over and take mapped POKEY_KBCODE
	jsr _DoKeyboardScan
	pla
	tay
	pla
	tax
:	lda tempIRQAcc
	rti

_BRKHandler:					; in principle this is Panic
	rti

	; main interrupt called on every frame
_NMIHandler:
	sta ANTIC_NMIRES			; ack interrupt
	inc jiffyCounter			; time update
	bit interrupt_lock
	beq :+
	rti
:	pha
	txa
	pha
	tya
	pha
	PushW CallRLo
	PushW returnAddress

	ldx #0
:	lda r0,x
	pha
	inx
	cpx #32
	bne :-

	lda dblClickCount
	beq :+
	dec dblClickCount

:	ldy KbdQueFlag
	beq :+
	iny
	beq :+
	dec KbdQueFlag

:;	jsr _DoKeyboardScan			; keyboard is processed only from keyboard IRQ
	lda alarmWarnFlag
	beq :+
	dec alarmWarnFlag

:	lda intTopVector
	ldx intTopVector+1
	jsr CallRoutine
	jsr _DoUpdateTime			; here, not in mainloop2.s
	lda intBotVector
	ldx intBotVector+1
	jsr CallRoutine

	ldx #31
:	pla
	sta r0,x
	dex
	bpl :-

	PopW returnAddress
	PopW CallRLo
	pla
	tay
	pla
	tax
	pla
	rti
