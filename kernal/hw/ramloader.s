; GEOS Atari port
; Maciej 'YTM/Elysium' Witkowiak, 2022

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
;.include "config.inc"
;.include "kernal.inc"
.include "atari.inc"

.import DetectRamExp
.import CopyRamBanksUp
.import atari_nbanks_lo
.import atari_banks_lo
.import atari_pia_portb

.global RamLoaderInit
.global RamLoaderNextChunk
.global RamLoaderLastChunk

.segment "rambank0"
.incbin "../../tools/image00.bin"

.segment "rambank1"
.incbin "../../tools/image01.bin"

.segment "rambank2"
.incbin "../../tools/image02.bin"

.segment "ramloader"

RamLoaderInit:
	; remember
	MoveB PIA_PORTB, atari_pia_portb

	; check if we have at least 128K and how to program bank bits
	jsr DetectRamExp
	jsr CopyRamBanksUp		; copy to target location under ROM
	lda atari_nbanks_lo
	bne :+
	jmp ($fffc)

	; keep chunk number in VLIR record pointer, outside banked space
:	LoadB curRecord, $ff
	; switch bank so that OS will load data into banked area
	; fall into...
	;jsr RamLoaderNextChunk
	;rts

	; OS loader will jump here
RamLoaderNextChunk:
	inc curRecord
	ldy curRecord
	lda atari_banks_lo,y
	bne :+
	jmp ($fffc)			; no bank? something went wrong
:	ora #1				; keep ROM enabled
	sta PIA_PORTB
	rts

	;; restore memory config
RamLoaderLastChunk:
	MoveB atari_pia_portb, PIA_PORTB
	rts


