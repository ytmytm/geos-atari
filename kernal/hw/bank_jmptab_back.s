; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Michael Steil, Maciej Witkowiak
;
; Jump table to dispatch back bank functions

.include "config.inc"
.include "geosmac.inc"

.import __HorizontalLine, __InvertLine, __RecoverLine, __VerticalLine, __Rectangle, __FrameRectangle, __InvertRectangle, __RecoverRectangle, __DrawLine, __DrawPoint, __GetScanLine, __TestPoint;, __BitmapUp
.import __ImprintRectangle ;, __BitmapClip, __BitOtherClip
.import __Dabs, __Dnegate
.import __InitTextPrompt
.import __PromptOn, __PromptOff
.import __SetPattern

.global njumps

.segment "bank_jmptab_back"
ASSERT_IN_BANK0

	.assert * = $4000, error, "This code must be placed at $4000 in back RAM."
jumpstart:
	jmp __HorizontalLine	;+
	jmp __InvertLine	;+
	jmp __RecoverLine	;+
	jmp __VerticalLine	;+
	jmp __Rectangle		;+
	jmp __FrameRectangle	;+
	jmp __InvertRectangle	;+
	jmp __RecoverRectangle	;+
	jmp __DrawLine		;+
	jmp __DrawPoint		;+
	jmp __GetScanLine	;+
	jmp __TestPoint		;+
;	jmp __BitmapUp
;	jmp _GetRealSize
;	jmp _GetCharWidth
;	jmp __UseSystemFont
;	jmp __LoadCharSet
	jmp __ImprintRectangle	;+
;	jmp __BitmapClip
;	jmp __BitOtherClip
	jmp __InitTextPrompt
	jmp __PromptOn
	jmp __PromptOff
;	jmp _BackBankFunc_23
;	jmp FontPutChar
;	jmp _TempHideMouse
;	jmp _SetMsePic
;	jmp _BldGDirEntry
;	jmp _SetColorMode
;	jmp _ColorCard
;	jmp _ColorRectangle
;	jmp _SwapDiskDriver
;	jmp _MoveBData
;	jmp _CopyCmdToBack
;	jmp ToBASIC2
;	jmp _SwapBData
;	jmp _VerifyBData
;	jmp _DoBOp
;	jmp _AccessCache
;	jmp _HideOnlyMouse
	jmp __Dabs	;+
	jmp __Dnegate	;+
	jmp __SetPattern

njumps = * - jumpstart

	.assert *-jumpstart < $100, error, "jump table too long"

