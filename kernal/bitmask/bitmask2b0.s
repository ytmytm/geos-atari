; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Common bitmasks

.include "config.inc"
.include "atari.inc"

.global __BitMaskPow2

.segment "bitmask2b0"

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"

__BitMaskPow2:
	.byte %00000001
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000
