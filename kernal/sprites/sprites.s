; Atari sprite driver
; Maciej Witkowiak, 2022

; Player/Missile gfx is really limited:
; Player0 is mouse cursor at $dc00
; Player1 is text cursor at $dd00
; Player2 is user sprite 0 at $de00
; Player3 is user sprite 1 at $df00
; missiles (unused) would be at $db00
;
; we emulate VIC sprites here but show only 8x21 (intead of 24x21) and additionally it appears doubled in X
;
; there is no hope of redeeming it unless this is rewritten as software sprite engine like VDC
; then more RAM is needed for buffers
;

; memory map:
;
; COLOR_MATRIX + 1000 = spritebuf $8fd8-$8fff free for use
; $DC00-$DFFF         = space for drawing 4 sprites 0/1/2/3 in Y
; spr0pic-spr3pic     = probably used
; spr4pic-spr7pic     = never used, free



.include "config.inc"
.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "kernal.inc"
.include "atari.inc"

; syscalls
.global _DisablSprite
.global _DrawSprite
.global _EnablSprite
.global _PosSprite

; start.s
.import InitMsePic
.global AtariPlayersInit
; conio5.s - InitTextPrompt
.global curYSize

; VIC equivalent of this is in const.inc
GTIA_X_POS_OFF		= 48			; left edge of playfield for Players
GTIA_Y_POS_OFF		= 24+8			; top edge of playfield (8+24 blank lines from displaylist)


; like for VDC engine - Y pos of currently drawn sprite
.segment "spritebuf"
curYPos0:	.res 4
curXPos0L:	.res 4
curXPos0H:	.res 4
curEnable:	.res 4	; bytes not bits for faster access
curYSize:	.res 4	; needed for tall text cursor only
tmpYSize:	.res 1	; to save on push/pop
tmpYPos:	.res 1	; to save on push/pop

; sprite gfx data based on PMBASE
PLAYER0_OFFS = $0400
PLAYER1_OFFS = $0500
PLAYER2_OFFS = $0600
PLAYER3_OFFS = $0700

.segment "players"
Player0Data:	.res $0100
Player1Data:	.res $0100
Player2Data:	.res $0100
Player3Data:	.res $0100

.global GEOS_PMBASE
; InitGEOEnv
.global Player0Data
; InitTextPrompt
.global Player1Data

.import __PLAYERS_START__
GEOS_PMBASE = __PLAYERS_START__ - PLAYER0_OFFS
.assert (GEOS_PMBASE & $03ff) = 0, error, "Atari PMBASE must be on 1K boundary"

.segment "start"

; this is repeatd in DoFirstInitIO

; colors
; $00 - black
; $06 - gray
; $0a - light gray
; $c4 - green
; $24 - brown
; $3c - peach

AtariPlayersInit:
; this must run after displaylist (or include it there - ANTIC_PMBASE, DMACTL, NMIEN are overwritten there)
	LoadB ANTIC_PMBASE, >GEOS_PMBASE
	LoadB ANTIC_DMACTL, %00111010		; DL DMA, 1scanline PMG, P DMA, no M DMA, normal playfield
	LoadB GTIA_GRACTL,  %00000010		; don't latch joystick triggers, P DMA, no M DMA
	LoadB GTIA_PRIOR,   %00000001		; priority, pm0 then pm2, then playfield
	LoadB GTIA_SIZEP0,  %00000000		; no X stretch
	sta GTIA_SIZEP1
	LoadB GTIA_COLPM0,  $3c			; hue/lum
	LoadB GTIA_COLPM1,  $c4			; hue/lum

	; clear all sprites gfx buffers
	ldy #0
	tya
:	sta Player0Data,y
	sta Player1Data,y
	sta Player2Data,y
	sta Player3Data,y
	iny
	bne :-
.if 0=1
	; XXX initialize mouse pointer (this belongs to FirstInit)
	LoadB r3L, 0
	LoadW r4, InitMsePic
	jsr _DrawSprite

	LoadB r3L, 0
	jsr _EnablSprite

	LoadB r3L, 0
	LoadW r4, 0
	LoadB r5L, 0
	jsr _PosSprite
.endif
	rts

.segment "sprites"

;---------------------------------------------------------------
; DrawSprite                                              $C1C6
;
; Pass:      r3L sprite nbr (2-7)
;            r4  ptr to picture data
; Return:    graphic data transfer to VIC chip
; Destroyed: a, y, r5
;---------------------------------------------------------------
_DrawSprite:
	lda r3L
	and #%11111100			; support only 0-3
	beq :+
	rts

:	ldy r3L
	; default size the same as on C64, but InitTextPrompt can modify this
	lda #21
	sta curYSize,y
	sta tmpYSize

	lda SprTabL,Y
	sta r5L
	lda SprTabH,Y
	sta r5H

	PushW r6

	; copy from r4 to r5 but only first column (every 3rd byte)
	; this way max Y size is 64 rows per Player
	; relevant only for text cursor and InitTextPrompt will do it
	lda #0
	sta r6L
	sta r6H

:	ldy r6L
	lda (r4),y
	iny
	iny
	iny
	sty r6L
	ldy r6H
	sta (r5),y
	inc r6H
	lda r6H
	cmp tmpYSize
	bne :-

	PopW r6
	; XXX sprite on screen will not be updated until PosSprite/EnablSprite call
	rts

.define SprTab spr0pic, spr1pic, spr2pic, spr3pic, spr4pic, spr5pic, spr6pic, spr7pic
SprTabL:
	.lobytes SprTab
SprTabH:
	.hibytes SprTab

;---------------------------------------------------------------
; PosSprite                                               $C1CF
;
; Pass:      r3L sprite nbr (0-7)
;            r4  x pos (0-319)
;            r5L y pos (0-199)
; Return:    r3L unchanged
; Destroyed: a, x, y, r6
;---------------------------------------------------------------
_PosSprite:
	lda r3L
	and #%11111100			; support only 0-3
	bne :+
	ldy r3L
	lda curEnable,y
	bne _PosSpriteDo		; if sprite is not visible, just store value in shadow

	lda r5L
	sta curYPos0,y
	lda r4L
	sta curXPos0L,y
	lda r4H
	sta curXPos0H,y

:	rts

_PosSpriteDo:

	lda #>Player0Data
	add r3L
	sta r6H
	LoadB r6L, 0			; r6 = vector to start of sprite buffer

	; clear at old Y position
	lda curYPos0,y			; is current Y pos the same as old Y pos?
	cmp r5L
	beq @sameYPos			; skip and save time if Y pos didn't change
	tax
	lda curYSize,y			; how many rows in sprite? (relevant for text cursor)
	sta tmpYSize

	txa				; current Y pos
	addv GTIA_Y_POS_OFF		; Player offset to top of the screen
	tay

	ldx #0
	txa
:	sta (r6),y
	iny
	beq :+				; end of buffer?
	inx
	cpx tmpYSize			; up to 64 lines
	bne :-

:	ldy r3L
	lda r5L
	sta curYPos0,y			; shadow new position
	addv GTIA_Y_POS_OFF		; Player offset to top of the screen
	sta r6L

	PushW r7			; we need a second vector

	lda SprTabL,y			; r7 = sprite image
	sta r7L
	lda SprTabH,y
	sta r7H

	; draw at new Y position
	ldx #0
:	txa
	tay
	lda (r7),y
	ldy #0
	sta (r6),y
	inc r6L				; target every byte
	beq :+				; end of buffer
	inx
	cpx tmpYSize			; up to 64 lines
	bne :-

:	PopW r7

	; set new X position in hardware
@sameYPos:
	ldy r3L
	MoveB r4H, r6H
	sta curXPos0H,y			; shadow
	lda r4L				; divide X by 2
	sta curXPos0L,y			; shadow
	lsr r6H
	ror
	addv GTIA_X_POS_OFF		; Player offset to left edge
	ldy r3L 			; which player?
	sta GTIA_HPOSP0,y
	rts

;---------------------------------------------------------------
; EnablSprite                                             $C1D2
;
; Pass:      r3L sprite nbr (0-7)
; Return:    sprite activated
; Destroyed: a, x
;---------------------------------------------------------------

_EnablSprite:
	lda r3L
	and #%11111100			; support only 0-3
	bne :+

	; just in case this is destroyed
;	LoadB ANTIC_PMBASE, >GEOS_PMBASE
;	LoadB ANTIC_DMACTL, %00111010		; DL DMA, 1scanline PMG, P DMA, no M DMA, normal playfield
;	LoadB GTIA_GRACTL,  %00000010		; don't latch joystick triggers, P DMA, no M DMA
	; restore these registers, GeoWrite will overwrite them
	LoadB GTIA_PRIOR,   %00000001		; priority, pm0 then pm2, then playfield
	LoadB GTIA_SIZEP0,  %00000000		; no X stretch
	sta GTIA_SIZEP1
;	LoadB GTIA_COLPM0,  $3c			; hue/lum
;	LoadB GTIA_COLPM1,  $c4			; hue/lum


	ldx r3L
	lda #$ff
	cmp curEnable,x
	beq :+				; already enabled
	sta curEnable,x

	tya
	pha
	PushW r4
	PushW r6
	PushB r5L

	ldx r3L
	lda curYPos0,x
	sta r5L
	dec curYPos0,x			; change it to force Y redraw, sprite was disabled, so whole buffer is empty
	lda curXPos0L,x
	sta r4L
	lda curXPos0H,x
	sta r4H
	ldy r3L
	jsr _PosSpriteDo

	PopB r5L
	PopW r6
	PopW r4
	pla
	tay
:	rts

;---------------------------------------------------------------
; DisablSprite                                            $C1D5
;
; Pass:      r3L sprite nbr (0-7)
; Return:    VIC register set to disable
;            sprite.
; Destroyed: a, x
;---------------------------------------------------------------
_DisablSprite:
	ldx r3L
	txa
	and #%11111100			; support only 0-3
	bne @end

	lda #0
	sta curEnable,x
	lda curYSize,x
	sta tmpYSize

	; clear at old position
	tya
	pha
	PushW r6

	lda #>Player0Data
	add r3L
	sta r6H
	LoadB r6L, 0			; r6 = vector to sprite buffer

	; clear at old position
	lda curYPos0,x
	addv GTIA_Y_POS_OFF		; Player offset to top of the screen
	tay
	ldx #0
	txa
:	sta (r6),y
	iny
	beq :+				; end of buffer?
	inx
	cpx tmpYSize			; up to 64 lines
	bne :-

:	PopW r6
	pla
	tay
@end:	rts
