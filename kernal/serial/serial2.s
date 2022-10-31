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

.import SerialNumber

.global __GetSerialNumber
.global _GetSerialNumber2

.segment "serial2"

ASSERT_IN_BANK0

;---------------------------------------------------------------
; GetSerialNumber                                         $C196
;
; Pass:      nothing
; Return:    r0  serial nbr of your kernal
; Destroyed: a
;---------------------------------------------------------------
__GetSerialNumber:
	lda SerialNumber
	sta r0L
_GetSerialNumber2:
	lda SerialNumber+1
	sta r0H
	rts

.if (!.defined(wheels_size)) && (!.defined(bsw128))
	.byte 1, $60 ; ???
.endif
