; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Serial number

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.global SerialNumber

.segment "serial1"

ASSERT_IN_BANK0

SerialNumber:
.ifdef atari
	.word $1CD5	; YTM's cracked GEOS
.else
	; This matches the serial in the cbmfiles.com GEOS64.D64
	.word $58B5
.endif

