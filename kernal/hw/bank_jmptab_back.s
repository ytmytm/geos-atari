; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Michael Steil, Maciej Witkowiak
;
; Jump table to dispatch back bank functions

.include "config.inc"

.import __HorizontalLine, __InvertLine, __RecoverLine, __VerticalLine, __Rectangle, __FrameRectangle, __InvertRectangle, __RecoverRectangle, __DrawLine, __DrawPoint, __GetScanLine, __TestPoint;, __BitmapUp
.import __ImprintRectangle ;, __BitmapClip, __BitOtherClip
.import __Dabs, __Dnegate

.segment "bank_jmptab_back"

	.assert * = $4000, error, "This code must be placed at $4000 in back RAM."

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
;	jmp _UseSystemFont
;	jmp _GetRealSize
;	jmp _GetCharWidth
;	jmp _LoadCharSet
	jmp __ImprintRectangle	;+
;	jmp __BitmapClip
;	jmp __BitOtherClip
;	jmp _InitTextPrompt
;	jmp _PromptOn
;	jmp _PromptOff
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

