; GEOS Atari port
; Maciej 'YTM/Elysium' Witkowiak, 2022

; Atari display list, must not be overwritten

.include "geossym.inc"

.global displaylist

.segment "displaylist"

displaylist:
	.byte $70, $70, $70		; 24 blank lines (3*8)
	.byte $4F			; display 1 line of mode 15 & load memory counter...
	.word SCREEN_BASE+56		; ...screen base
	.res 100, 15			; 100 lines more of mode 15, 101 lines total * 40 = 4040 bytes, offset by 56 to match 4096=$1000=end of 4K region
	.byte $4F			; display 102nd line of mode 15 & load memory counter
	.word SCREEN_BASE+$1000
	.res 98, 15			; 98 lines more
	.byte $41			; jump to
	.word displaylist		; the begining

.assert (displaylist & $fc00) = (* & $fc00), error, "Atari display list can't cross 1K boundary"
