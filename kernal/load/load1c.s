; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Loading

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.global DeskTopName
.global _EnterDT_Str1
.global _EnterDT_Str0

.segment "load1c"

DeskTopName:
.warning "load1c - debug desktop name"
	.byte "filesel",0
;	.byte "DESK TOP", 0

.segment "load1d"

_EnterDT_Str0:
	.byte BOLDON, "Please insert a disk", 0
_EnterDT_Str1:
	.byte "with deskTop V1.5 or higher", 0

