; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Common bitmasks

.include "config.inc"
.include "atari.inc"

.import __BitMaskPow2

.global __BitMaskPow2Rev

.segment "bitmask1b0"

.assert * >= ATARI_EXPBASE && * < ATARI_EXPBASE+ATARI_EXP_WINDOW, error, "This code must be in bank0"

__BitMaskPow2Rev:
	.byte %10000000
	.byte %01000000
	.byte %00100000
	.byte %00010000
	.byte %00001000
	.byte %00000100
	.byte %00000010
	;     %00000001 shared with below

.assert * = __BitMaskPow2, error, "__BitMaskPow2Rev must run into __BitMaskPow2"

