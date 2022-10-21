; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Graphics library: inline syscalls

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.import __GetInlineDrwParms
.import DoInlineReturn
.import _InvertRectangle

.global _i_InvertRectangle

.segment "graph2b"

_i_InvertRectangle:
	jsr __GetInlineDrwParms
	jsr _InvertRectangle
.ifdef wheels_size
.global DoInlineReturn7
DoInlineReturn7:
.endif
	php
	lda #7
	jmp DoInlineReturn

