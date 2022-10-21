; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; KERNAL header and reboot from BASIC

.include "const.inc"
.include "config.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "kernal.inc"
.include "c64.inc"

; start.s
.import _ResetHandle

.import systemVectorMagic

.global BootGEOS
.global dateCopy
.global sysFlgCopy

.segment "header"

; XXX!!! .assert * = $C000, error, "Header not at $C000"

BootGEOS:
.if .defined(wheels_remove_BootGEOS) || .defined(atari)
	rts
	nop
	nop
.else
	jmp _BootGEOS
.endif
ResetHandle:
.if .defined(wheels) || .defined(atari)
	rts
	nop
	nop
.else
	jmp _ResetHandle
.endif

bootName:
.ifdef gateway
	.byte "GATEWAY "
	.byte 5 ; PADDING
.else
	.byte "GEOS BOOT"
.endif
version:
.ifdef wheels
	.byte $41
.else
	.byte $20
.endif
nationality:
.ifdef wheels
	.word 1 ; GERMAN
.else
	.word 0
.endif
sysFlgCopy:
	.byte 0
c128Flag:
.ifdef bsw128
	.byte $80
.else
	.byte 0
.endif

.ifdef wheels
	.byte 0
.elseif .defined(bsw128)
	.byte 4
.else
	.byte 5
.endif
	.byte 0, 0, 0 ; ???

dateCopy:
.ifdef wheels
	.byte 99,1,1
.elseif .defined(cbmfiles) || .defined(gateway) || .defined(bsw128)
	; The cbmfiles version was created by dumping
	; KERNAL from memory after it had been running,
	; so it a different date here.
	.byte 92,3,23
.else
	.byte 88,4,20
.endif
