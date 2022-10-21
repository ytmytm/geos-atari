; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/CIA clock driver

.global pingTab
.global pingTabEnd

.warning "This doesn't work for Atari"

.segment "time2"

pingTab:
	.byte $00, $10, $00, $08, $40, $08, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $0f
pingTabEnd:

