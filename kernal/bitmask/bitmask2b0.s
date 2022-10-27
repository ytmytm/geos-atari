; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Common bitmasks

.include "config.inc"
.include "geosmac.inc"

.global __BitMaskPow2

.segment "bitmask2b0"
ASSERT_IN_BANK0

__BitMaskPow2:
	.byte %00000001
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000
