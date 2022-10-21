
; Atari RAM drive (130XE or otherwise)

; Based on C64 RamCart/C128 InternalRAM drive by Maciej Witkowiak, 1997-1999

; Maciej Witkowiak, 2022

; Atari layout:
; 1 track per bank = 64 sectors per track
; at least 3 tracks, track 0 doesn't exist (first bank reserved for GEOS Kernal)
; up to 64 tracks

; read/write
; - use z8b to vector inside ATARI_EXPBASE

;$0000		- boot up ($100)
;$0100		- dir head1 (name & compressed BAM or name&dirtrackBAM)
;		  1) $04-$48/$88 - BAM (128/256K), $c0/$c1 - dirtrackBAM
;		  2) 				   $c0...  - dirtrackBAM

;constant defines (high bytes only)
dirHeadPos		= $01
dirLength		= $04			;up to 15 (+1 for header)
						;if more - change AddDirBlock

;should be exported
driverSpace	= dirHeadPos+dirLength+1;start of swapspace
driverSwapLgh	= $05			;length of swapspace

diskStart		= driverSpace+driverSwapLgh
; if any changes above - change SetRAMCBam

MAXBLK		= 512-diskStart	; this will not be fixed
BAMLength		= 64			;total, first few reserved on bootup
						;(last sector ever reserved as border-dir)
OFF_TO_DIRBAM		= $c0			;BAM of DIR_TRACK

z8b			= $8b			;($8b/$8c) - from kernal.inc

.include "inc/const.inc"
.include "inc/jumptab.inc"
.include "inc/geossym.inc"
.include "inc/geosmac.inc"
.include "inc/atari.inc"

; GEOS will fill those in
.import atari_nbanks
.import atari_banks

.warning "ramdrv-atari.s - read/write unimplemented, t&s unimplemented, bam code and offsets not checked"

.segment "drive"

.assert * = $9000, error, "Disk driver not at $9000"

;-------------------------------------------------
_InitForIO:		.word __InitForIO		;9000
_DoneWithIO:		.word __DoneWithIO		;9002
_ExitTurbo:		.word __ExitTurbo		;9004
_PurgeTurbo:		.word __PurgeTurbo		;9006
_EnterTurbo:		.word __EnterTurbo		;9008
_ChangeDiskDevice:	.word __ChangeDiskDevice	;900a
_NewDisk:		.word __NewDisk 		;900c
_ReadBlock:		.word __ReadBlock		;900e
_WriteBlock:		.word __WriteBlock		;9010
_VerWriteBlock:		.word __VerWriteBlock		;9012
_OpenDisk:		.word __OpenDisk		;9014
_GetBlock:		.word __GetBlock		;9016
_PutBlock:		.word __PutBlock		;9018
_GetDirHead:		.word __GetDirHead		;901a
_PutDirHead:		.word __PutDirHead		;901c
_GetFreeDirBlk:		.word __GetFreeDirBlk		;901e
_CalcBlksFree:		.word __CalcBlksFree		;9020
_FreeBlock:		.word __FreeBlock		;9022
_SetNextFree:		.word __SetNextFree		;9024
_FindBAMBit:		.word __FindBAMBit		;9026
_NxtBlkAlloc:		.word __NxtBlkAlloc		;9028
_BlkAlloc:		.word __BlkAlloc		;902a
_ChkDkGEOS:		.word __ChkDkGEOS		;902c
_SetGEOSDisk:		.word __SetGEOSDisk		;902e

Get1stDirEntry:		JMP _Get1stDirEntry		;9030
GetNxtDirEntry:		JMP _GetNxtDirEntry		;9033
GetBorder:		JMP _GetBorder			;9036
AddDirBlock:		JMP _AddDirBlock		;9039
ReadBuff:		JMP _ReadBuff			;903c
WriteBuff:		JMP _WriteBuff			;903f
			JMP __I9042			;9042
			JMP GetDOSError 		;9045
AllocateBlock:		JMP _AllocateBlock		;9048
ReadLink:		JMP _ReadLink			;904b

;---------------------------------------
_Get1stDirEntry:
		LoadB r1L, DIR_TRACK
		LoadB r1H, 1
		JSR ReadBuff
		LoadW r5, diskBlkBuf+FRST_FILE_ENTRY
		LoadB borderFlag, 0
		RTS

;---------------------------------------
_GetNxtDirEntry:
		LDX #0
		LDY #0
		AddVW OFF_NXT_FILE, r5
		CmpWI r5, diskBlkBuf+$ff		; overflow?
		BCC GNDirEntry1
		LDY #$ff
		MoveW diskBlkBuf, r1
		BNE GNDirEntry0
		LDA borderFlag
		BNE GNDirEntry1
		LoadB borderFlag, $ff
		JSR GetBorder
		bnex GNDirEntry1
		TYA
		BNE GNDirEntry1
GNDirEntry0:	JSR ReadBuff
		LDY #0
		LoadW r5, diskBlkBuf+FRST_FILE_ENTRY
GNDirEntry1:	RTS

;---------------------------------------
_GetBorder:
		JSR GetDirHead
		bnex GetBord2
		LoadW r5, curDirHead
		JSR ChkDkGEOS
		BNE GetBord0
		LDY #$ff
		BNE GetBord1
GetBord0:	MoveW curDirHead+OFF_OP_TR_SC, r1
		LDY #0
GetBord1:	LDX #0
GetBord2:	RTS

;---------------------------------------
ClearAndWrite:	LDA #0
		TAY
:		STA diskBlkBuf,y
		INY
		BNE :-
		DEY
		STY diskBlkBuf+1
		JMP WriteBuff

;---------------------------------------
;---------------------------------------
__CalcBlksFree:
		LoadW r4, 0
		LDY #OFF_TO_BAM
CBlksFre0:	LDA (r5),y
		BEQ CBlksFre3
		LDX #0
CBlksFre1:	LSR
		BCC CBlksFre2
		IncW r4
CBlksFre2:	INX
		CPX #8
		BNE CBlksFre1
CBlksFre3:	INY
		CPY #BAMLength+OFF_TO_BAM
		BNE CBlksFre0
		LoadW r3, MAXBLK
		RTS

;---------------------------------------
__SetNextFree:	MoveW r3, r6
		JSR FindBAMBit
		BNE AlloBlk0
SNF_Search:	LDA curDirHead,x
		BNE SNF_FoundByte
		INX
		CPX #BAMLength+OFF_TO_BAM
		BNE SNF_Search
		LDX #INSUFF_SPACE
		RTS

SNF_FoundByte:	LDY #0
SNF_Search2:	LSR
		BCS SNF_FoundBit
		INY
		CPY #7
		BNE SNF_Search2

SNF_FoundBit:	TXA
		SEC
		SBC #OFF_TO_BAM
		TAX
		LSR
		LSR
		LSR
		LSR
		STA r3L
		INC r3L
		TXA
		AND #%00001111
		ASL
		ASL
		ASL
		STA r3H
		TYA
		CLC
		ADC r3H
		STA r3H
		MoveW r3, r6

_AllocateBlock:	JSR FindBAMBit
		BEQ AlloBlk1
AlloBlk0:	LDA r8H
		EOR #$ff
		AND curDirHead,x
		STA curDirHead,x
		LDX #0
		RTS
AlloBlk1:	LDX #BAD_BAM
		RTS

;---------------------------------------
__FreeBlock:
		JSR FindBAMBit
		BNE FreeBlk0
		LDA r8H
		EOR curDirHead,x
		STA curDirHead,x
		LDX #0
		RTS
FreeBlk0:	LDX #BAD_BAM
		RTS

;---------------------------------------
__FindBAMBit:
		LDA r6L
		TAX
		DEX
		TXA
		ASL
		ASL
		ASL
		ASL
		STA r7H
		LDA r6H
		AND #%00000111
		TAX
		LDA FBBBitTab,x
		STA r8H
		LDA r6H
		LSR
		LSR
		LSR
		add r7H
		ADC #OFF_TO_BAM
		TAX
		LDA curDirHead,x
		AND r8H
		RTS

FBBBitTab:	.byte $01, $02, $04, $08
		.byte $10, $20, $40, $80

;---------------------------------------
__GetFreeDirBlk:
		PHP
		SEI
		PushB r6L
		PushW r2
		LDX r10L
		INX
		STX r6L
		LoadB r1L, DIR_TRACK
		LoadB r1H, 1
GFDirBlk0:	JSR ReadBuff
GFDirBlk1:	bnex GFDirBlk5
		DEC r6L
		BEQ GFDirBlk3
GFDirBlk11:	LDA diskBlkBuf
		BNE GFDirBlk2
		JSR AddDirBlock
		bra GFDirBlk1
GFDirBlk2:	STA r1L
		MoveB diskBlkBuf+1, r1H
		bra GFDirBlk0
GFDirBlk3:	LDY #FRST_FILE_ENTRY
		LDX #0
GFDirBlk4:	LDA diskBlkBuf,y
		BEQ GFDirBlk5
		TYA
		addv $20
		TAY
		BCC GFDirBlk4
		LoadB r6L, 1
		LDX #FULL_DIRECTORY
		LDY r10L
		INY
		STY r10L
		CPY #$12
		BCC GFDirBlk11
GFDirBlk5:	PopW r2
		PopB r6L
		PLP
		RTS

;---------------------------------------
_AddDirBlock:
		PushW r6
		LDY #OFF_TO_DIRBAM
		LDX #FULL_DIRECTORY
		LDA curDirHead,y
		BNE ADirBlkGot
		INY
		LDA curDirHead,y
		BEQ ADirBlkEnd

ADirBlkGot:	LDX #0
ADirBlkLp:	LSR
		BCS ADirBlkFree
		INX
		CPX #7
		BNE ADirBlkLp

ADirBlkFree:	TXA
		CPY #OFF_TO_DIRBAM
		BEQ ADirBlkCont
		CLC
		ADC #8
ADirBlkCont:	STA r3H
		LDA #DIR_TRACK
		STA r3L

		LDA FBBBitTab,x
		STA r8H
		TYA
		TAX
		JSR AlloBlk0

		MoveW r3, diskBlkBuf
		JSR WriteBuff
		bnex ADirBlkEnd
		MoveW r3, r1
		JSR ClearAndWrite
ADirBlkEnd:	PopW r6
		RTS

;---------------------------------------
__BlkAlloc:
		LDY #1
		STY r3L
		DEY
		STY r3H
__NxtBlkAlloc:	PushW r9
		PushW r3
		LoadW r3, $00fe
		LDX #r2
		LDY #r3
		JSR Ddiv
		LDA r8L
		BEQ BlkAlc0
		IncW r2
BlkAlc0:	LoadW r5, curDirHead
		JSR CalcBlksFree
		PopW r3
		LDX #INSUFF_SPACE
		CmpW r2, r4
		BEQ BlkAlc1
		BCS BlkAlc4
BlkAlc1:	MoveW r6, r4
		MoveW r2, r5
BlkAlc2:	JSR SetNextFree
		bnex BlkAlc4
		LDY #0
		LDA r3L
		STA (r4),y
		INY
		LDA r3H
		STA (r4),y
		AddVW 2, r4
		LDA r5L
		BNE *+4			; over r5H? DecW?
		DEC r5H
		DEC r5L
		LDA r5L
		ORA r5H
		BNE BlkAlc2
		LDY #0
		TYA
		STA (r4),y
		INY
		LDA r8L
		BNE BlkAlc3
		LDA #$fe
BlkAlc3:	addv 1
		STA (r4),y
		LDX #0
BlkAlc4:	PopW r9
		RTS

;---------------------------------------
;---------------------------------------
__ChangeDiskDevice:			;these are unused
		STA curDrive
		STA curDevice
__NewDisk:
__PurgeTurbo:
__ExitTurbo:
GetDOSError:
__I9042:
__SetGEOSDisk:
		LDX #0
		RTS
;---------------------------------------
__EnterTurbo:
		LDA curDrive
		JMP SetDevice		; needed?
;---------------------------------------
__ChkDkGEOS:
		LoadB isGEOS, $ff	;RAMDISK is always in GEOS
	 	LDA isGEOS		;format
		RTS

;---------------------------------------
__OpenDisk:	JSR NewDisk
		bnex :+
		JSR GetDirHead
		bnex :+
		LoadW r5, curDirHead
		JSR ChkDkGEOS
		LoadW r4, curDirHead+OFF_DISK_NAME
		LDX #r5
		JSR GetPtrCurDkNm
		LDX #r4
		LDY #r5
		LDA #18
		JSR CopyFString
:		RTS
;---------------------------------------
__PutDirHead:	JSR SetDirHead
		JSR SetRAMCBAM
		BNE __PutBlock
_WriteBuff:	JSR SetBufVector
__PutBlock:	JSR InitForIO
		JSR WriteBlock
		JMP DoneWithIO
;---------------------------------------
__GetDirHead:	JSR SetDirHead
		BNE __GetBlock
_ReadBuff:	JSR SetBufVector
__GetBlock:	JSR InitForIO
		JSR ReadBlock
		JMP DoneWithIO
;---------------------------------------
_ReadLink:	JSR InitForRAM
		LDY #0
		LDA ATARI_EXPBASE,Y	; XXX !!!!
		STA (r4),Y
		INY
		LDA ATARI_EXPBASE,Y	; XXX !!!!
		STA (r4),Y
		JSR DoneWithRAM
		LDX #0
		RTS
;---------------------------------------
__ReadBlock:	JSR InitForRAM
		LDY #0
:		LDA ATARI_EXPBASE,Y	; XXX !!!!
		STA (r4),Y
		INY
		BNE :-
		JSR DoneWithRAM
		LDX #0
		RTS
;---------------------------------------
__VerWriteBlock:
__WriteBlock:	JSR InitForRAM
		LDY #0
:		LDA (r4),Y
		STA ATARI_EXPBASE,Y	; XXX !!!!
		CMP ATARI_EXPBASE,Y	; XXX !!!!
		BNE :+
		INY
		BNE :-
		LDX #0
		BEQ :++
:		LDX #31
:		JMP DoneWithRAM
;---------------------------------------
SetBufVector:	LoadW r4, diskBlkBuf
		RTS
;---------------------------------------
SetDirHead:	LoadB r1L, DIR_TRACK
		LoadB r1H, 0
		STA r4L
		LoadB r4H, (>curDirHead)
		RTS
;---------------------------------------
SetRAMCBAM:	LDY #OFF_TO_BAM		;allocate system area
		LDA #0
		STA (r4),y
;		INY
;		STA (r4),y
		INY
		LDA (r4),y
		AND #%11111000
		STA (r4),y
		LDY #OFF_TO_BAM+BAMLength-1
		LDA (r4),y
		AND #%01111111
		STA (r4),y
		TYA
		RTS

;---------------------------------------
__InitForIO:
; do nothing - if that is supposed to enable OS ROM functions
; it should be part of GEOS Kernal, not the disk driver (that was required on C64/128)
; IRQ and NMIs are halted/restarted in InitForRAM/DoneWithRAM
		PHP
		PopB tmpPS
		SEI
		RTS
;---------------------------------------
__DoneWithIO:	SEI
		PushB tmpPS
		PLP
		RTS
;---------------------------------------
InitForRAM:	MoveW r1, z8b			; preserve r1 in z8b, why?

		; stop ANTIC NMIs here?

		LDX r1H
		LDY r1L
		CPY #DIR_TRACK			; 18? there will be up to 16 banks (tracks) on Atari
		BEQ InitFRAM1
		DEY
		LDA #0
		STA r1L
		STY r1H
		LSR r1H
		ROR r1L
		TXA
		CLC
		ADC r1L
;XXX		STA RAMC_BASE			; r1L/r1H is t&s of memory block
		LDA r1H
;XXX		STA RAMC_BASE+1			; translate to Atari blocks!
		RTS

InitFRAM1:	TXA
		CLC
		ADC #dirHeadPos			; directory track is handled in a special way
;XXX		STA RAMC_BASE
		LDA #0
;XXX		STA RAMC_BASE+1
		RTS
;---------------------------------------
DoneWithRAM:	MoveW z8b, r1
		;reenable ANTIC NMIs here?
		;this procedure can't change X register (error code)
		RTS
;---------------------------------------
borderFlag:	.res 1		; do we have border directory sector?
tmpPS:		.res 1		; CPU flags after DoneWithIO
