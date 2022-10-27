; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Michael Steil, Maciej Witkowiak
;
; Jump table for front-to-back bank calls
;
; Jump table to call back bank functions from the front bank
; There is a jump table at the same location at the back bank.

; This is adapted for Atari: front bank is in $E000 all the time, back bank is in $4000 switched on/off as needed

.include "config.inc"

.import CallBackBank

.global _HorizontalLine, _InvertLine, _RecoverLine, _VerticalLine, _Rectangle, _FrameRectangle, _InvertRectangle, _RecoverRectangle, _DrawLine, _DrawPoint, _GetScanLine, _TestPoint;, _BitmapUp
.global _ImprintRectangle;, _BitmapClip, _BitOtherClip
.global _Dabs, _Dnegate
.global _UseSystemFont
.global _GetCharWidth
.global _LoadCharSet
.global _InitTextPrompt
.global _PromptOn, _PromptOff

.segment "bank_jmptab_front"

	.assert * = $D800, error, "This code must be placed at $D800 in front RAM (start of page actually)."

_HorizontalLine:	jsr CallBackBank
_InvertLine:		jsr CallBackBank
_RecoverLine:		jsr CallBackBank
_VerticalLine:		jsr CallBackBank
_Rectangle:		jsr CallBackBank
_FrameRectangle:	jsr CallBackBank
_InvertRectangle:	jsr CallBackBank
_RecoverRectangle:	jsr CallBackBank
_DrawLine:		jsr CallBackBank
_DrawPoint:		jsr CallBackBank
_GetScanLine:		jsr CallBackBank
_TestPoint:		jsr CallBackBank
;_BitmapUp:		jsr CallBackBank
;_GetRealSize:		jsr CallBackBank
;_GetCharWidth:		jsr CallBackBank
_UseSystemFont:		jsr CallBackBank
_LoadCharSet:		jsr CallBackBank
_ImprintRectangle:	jsr CallBackBank
;_BitmapClip:		jsr CallBackBank
;_BitOtherClip:		jsr CallBackBank
_InitTextPrompt:	jsr CallBackBank
_PromptOn:		jsr CallBackBank
_PromptOff:		jsr CallBackBank
;_BackBankFunc_23:	jsr CallBackBank
;FontPutChar:		jsr CallBackBank
;_TempHideMouse:		jsr CallBackBank
;_SetMsePic:		jsr CallBackBank
;_BldGDirEntry:		jsr CallBackBank
;_SetColorMode:		jsr CallBackBank
;_ColorCard:		jsr CallBackBank
;_ColorRectangle:	jsr CallBackBank
;_SwapDiskDriver:	jsr CallBackBank
;_MoveBData:		jsr CallBackBank
;_CopyCmdToBack:		jsr CallBackBank
;ToBASIC2:		jsr CallBackBank
;_SwapBData:		jsr CallBackBank
;_VerifyBData:		jsr CallBackBank
;_DoBOp:			jsr CallBackBank
;_AccessCache:		jsr CallBackBank
;_HideOnlyMouse:		jsr CallBackBank
_Dabs:			jsr CallBackBank
_Dnegate:		jsr CallBackBank

