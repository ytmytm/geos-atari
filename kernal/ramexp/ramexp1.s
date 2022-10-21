; GEOS KERNAL by Berkeley Softworks
;
; Atari RAM expansion support by Maciej Witkowiak
; detection code from http://atariki.krap.pl/index.php/Obs%C5%82uga_standardowego_rozszerzenia_pami%C4%99ci_RAM

; banks (16k, 64 pages)
; 0	reserved for OS: space for 2-4 (28-56 pages) disk drivers and sio stuff / OS cache for real drives
;	(InitForIO/DoneWithIO should be part of GEOS Kernal, not disk driver)
; 1	start of RAM drive, directory on track 1
; 2,3	RAM drive continues, has at least 192 pages total

; RAM drive: 64 sectors/track, track==bank number - there is no track0 so bank0 is reserved

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "atari.inc"

.global DetectRamExp
.global atari_banks
.global atari_nbanks

; stored banks
.segment "ramexp2"

atari_nbanks:	.res 1
atari_banks:	.res 64

; XXX todo: setup RAM drive (directory 1st block+header+BAM according to mem size)

; detection code
.segment "ramexp1"

.assert * < $4000 || * > $8000, error, "Ram Expansion detection code can't overlap with banked space"
.assert * < $c000, error, "Ram Expansion detection code can't be under ROM"

DetectRamExp:
	; detect 130XE and/or memory expansions

	PushB PIA_PORTB
	LoadB PIA_PORTB, %11111111
	PushB ATARI_EXPBASE

	ldx #15			;zapamiętanie bajtów ext (z 16 bloków po 64k)
:	jsr setpb
	lda ATARI_EXPBASE
	sta bsav,x
	dex
	bpl :-

	ldx #15			;wyzerowanie ich (w oddzielnej pętli, bo nie wiadomo
:	jsr setpb		;które kombinacje bitów PIA_PORTB wybierają te same banki)
	LoadB ATARI_EXPBASE, 0
	dex
	bpl :-

	stx PIA_PORTB		;eliminacja pamięci podstawowej (X=$FF)
	stx ATARI_EXPBASE
	stx CPU_DDR		;niezbędne dla niektórych rozszerzeń do 256k

	ldy #0			;pętla zliczająca bloki 64k
	ldx #15
_p2:	jsr setpb
	lda ATARI_EXPBASE	;jeśli ATARI_EXPBASE jest różne od zera, blok 64k już zliczony
	bne _n2

	dec ATARI_EXPBASE	;w przeciwnym wypadku zaznacz jako zliczony

	lda ATARI_EXPBASE	;sprawdz, czy sie zaznaczyl; jesli nie -> cos nie tak ze sprzetem
	bpl _n2

	lda PIA_PORTB		;wpisz wartość PIA_PORTB do tablicy dla banku 0
	sta atari_banks,y
	eor #%00000100		;uzupełnij wartości dla banków 1, 2, 3
	sta atari_banks+1,y
	eor #%00001100
	sta atari_banks+2,y
	eor #%00000100
	sta atari_banks+3,y
	iny
	iny
	iny
	iny

_n2:	dex
	bpl _p2

	ldx #15			;przywrócenie zawartości ext
:	jsr setpb
	lda bsav,x
	sta ATARI_EXPBASE
	dex
	bpl :-

	stx PIA_PORTB		;X=$FF

	PopB ATARI_EXPBASE
	PopB PIA_PORTB

	sty atari_nbanks	; number of 16K banks
	tya
	lsr
	lsr
	sta ramExpSize		; number of 64K banks
	rts

setpb:
	txa			;zmiana kolejności bitów: %0000dcba -> %cba000d0
	lsr
	ror
	ror
	ror
	adc #1			;ustawienie bitu nr 1 w zaleznosci od stanu C
;	ora #$01       ;ustawienie bitu sterującego OS ROM na wartosc domyslna [1]
	and #%11111110
	sta PIA_PORTB
	rts

bsav:	.res 16
