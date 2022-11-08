; Joystick input driver
; Atari version, Maciej Witkowiak, 2022

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "jumptab.inc"
.include "atari.inc"

.segment "inputdrv"

.assert * = $FE80, error, "Input driver not at $FE80"

MouseInit:
	jmp _MouseInit
SlowMouse:
	jmp _SlowMouse
UpdateMouse:
	jmp _UpdateMouse

lastFire:	.byte 0

lastFire2:	.byte 0

joyStat0:	.byte 0
joyStat1:	.byte 0
joyStat2:	.byte 0
joyStat3:	.byte 0
joyStat4:	.byte 0
joyStat5:	.byte 0
joyStat6:	.byte 0
joyStat7:	.byte 0

_MouseInit:
	LoadW mouseXPos, 0
	sta mouseYPos
	LoadB inputData, $ff
	rts

_SlowMouse:
	LoadB mouseSpeed, NULL
SlowMse0:
	rts

_UpdateMouse:
	jsr readJoystickPort
	bbrf MOUSEON_BIT, mouseOn, SlowMse0

	lda joyStat7
	lsr
	bcc :+
	dec mouseYPos
:	lsr
	bcc :+
	inc mouseYPos
:	lsr
	bcc :+
	pha
	SubVW 2, mouseXPos
	pla
:	lsr
	bcc :+
	AddVW 2, mouseXPos
:	rts

readJoystickPort:
	lda GTIA_TRIG0
	and #%00000001
	tay
	cmp lastFire
	beq :+
	sta lastFire
	smbf MOUSE_BIT, pressFlag
	lda JoyMouseData,y
	sta mouseData

:	lda PIA_PORTA
	and #%00001111
	ora JoyTrigToggle,y
	eor #$ff
	cmp joyStat7
	sta joyStat7
	bne :+
	and #%00001111
	cmp joyStat6
	beq :+
	sta joyStat6
	tay
	lda JoyDirectionTab,y
	sta inputData
	smbf INPUT_BIT, pressFlag
:
	rts

; to speedup joystick trigger translation
JoyTrigToggle:
	.byte %11100000, %11110000
JoyMouseData:
	.byte %10000000, %00000000


;.segment "mouseptr"
; this could be shared among drivers, besides we ran out of space
JoyDirectionTab:
	.byte $ff, $02, $06, $ff
	.byte $04, $03, $05, $ff
	.byte $00, $01, $07, $ff
	.byte $ff, $ff, $ff, $ff
