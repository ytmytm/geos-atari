; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Hardware initialization

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.import ResetMseRegion
.import KbdQueTail
.import KbdQueHead
.import KbdQueFlag
;.import KbdDBncTab	; unused, free 7 bytes on Atari
;.import KbdDMltTab	; unused, free 7 bytes on Atari

; atari
.import displaylist
.import GEOS_PMBASE
.import _NMIHandler
.import _IRQHandler

.global _DoFirstInitIO

.segment "hw1b"

_DoFirstInitIO:

ASSERT_NOT_UNDER_ROM

; _DoFirstInitIO can't be under ROM (because it turns ROM off)

	php
	sei
	LoadB ANTIC_NMIEN, %00000000                    ; no interrupts from ANTIC
	LoadB POKEY_IRQEN, %00000000                    ; no interrupts from POKEY

	LoadW NMI_VECTOR, _NMIHandler
	LoadW IRQ_VECTOR, _IRQHandler

	LoadB POKEY_IRQEN, %11000000			; enable BREAK and keyboard IRQ
	LoadB ANTIC_NMIEN, %01000000			; enable VBLANK interrupts
	plp

	LoadB PIA_PBCTL, %00110000                      ; no interrupts from PIA, PORTB as DDR
	LoadB PIA_PORTB, %11111111                      ; all PORTB pins as output
	LoadB PIA_PBCTL, %00110100                      ; no interrupts from PIA, PORTB as I/O
	LoadB PIA_PORTB, %10110010                      ; only RAM, main RAM in $4000-$8000 for CPU (ANTIC irrelevant)

	; stop all timers, and disable all (known) interrupts
	LoadB PIA_PACTL, %00110000                      ; no interrupts from PIA, PORTA as DDR
	LoadB PIA_PORTA, %00000000                      ; all PORTA pins as input
	LoadB PIA_PACTL, %00110100                      ; no interrupts from PIA, PORTA as I/O (joystick I/O)

	LoadB POKEY_SKCTL, %00000011                    ; reset serial, init keyboard scan

	; displaylist address (display list defines screen position at SCREEN_BASE)
	LoadW ANTIC_DLISTL, displaylist
	LoadB ANTIC_HSCROL, 0
	sta ANTIC_VSCROL

	; init GTIA
	ldx #0
	txa
:	sta GTIA,x
	inx
	cpx #32
	bne :-

	; set colors - atari default blue (but dark on light)
	LoadB GTIA_COLPF1, $94
	LoadB GTIA_COLPF2, $9a
	LoadB GTIA_COLBK, 0

	; P/M graphics
	LoadB ANTIC_PMBASE, >GEOS_PMBASE
	LoadB ANTIC_DMACTL, %00111010           ; DL DMA, 1scanline PMG, P DMA, no M DMA, normal playfield
	LoadB GTIA_GRACTL,  %00000010           ; don't latch joystick triggers, P DMA, no M DMA
	LoadB GTIA_PRIOR,   %00000001           ; priority, pm0 then pm2, then playfield
	LoadB GTIA_SIZEP0,  %00000000           ; no X stretch
	sta GTIA_SIZEP1
;	this is in FirstInit
;	LoadB GTIA_COLPM0,  $3c                 ; hue/lum
;	LoadB GTIA_COLPM1,  $c4                 ; hue/lum

	ldx #0
	stx KbdQueHead
	stx KbdQueTail
	dex
	stx KbdQueFlag

	jmp ResetMseRegion
