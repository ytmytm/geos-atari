; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Atari keyboard driver, Maciej Witkowiak, 2022

.warning "keyboard2-atari unchecked"

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"

.global KbdDecodeTab
.global KbdDecodeTab_SHIFT
.global KbdDecodeTab_CTRL

.segment "keyboard2"

;	.byte "L", "J", ";", $03, $04, "K", "+", "*"
;	.byte "O", $09, "P", "U", return_c, "I", "-", "="
;	.byte "V", help_c, "C", $03, $04, "B", "X", "Z"
;	.byte "4", $09, "3", "6", esc_c, "5", "2", "1"
;	.byte ",", space_c, ".", "N", $04, "M", "/", inv_c
;	.byte "R", $09, "E", "Y", tab_c, "T", "W", "Q"
;	.byte "9", $01, "0", "7", bkspc_c, "8", "<", ">"
;	.byte "F", "H", "D", $0b, caps_c, "G", "S", "A"

; done:
; + break -> restore (do nothing)
; + caps -> RUN/STOP
; + esc -> <- (leftarrow) (not so sure)
; + delete+shift -> backspace
; + ctrl+digit -> F1-F8
; + ctrl+clear = home
; + ctrl+return = LF
; + tab->tab
; + help -> pound (not so sure)
; + ctrl+<std> -> cursors
; todo:
; - inv -> C= (modifier like ctrl/shift)

; unshifted
KbdDecodeTab:
	.byte "l", "j", ";", KEY_INVALID, KEY_INVALID, "k", "+", "*"
	.byte "o", KEY_INVALID, "p", "u", CR, "i", "-", "="
	.byte "v", KEY_BPS, "c", KEY_INVALID, KEY_INVALID, "b", "x", "z"
	.byte "4", KEY_INVALID, "3", "6", KEY_LARROW, "5", "2", "1"
	.byte ",", " ", ".", "n", KEY_INVALID, "m", "/", KEY_INVALID
	.byte "r", KEY_INVALID, "e", "y", TAB, "t", "w", "q"
	.byte "9", KEY_INVALID, "0", "7", KEY_DELETE, "8", "<", ">"
	.byte "f", "h", "d", KEY_INVALID, KEY_STOP, "g", "s", "a"

; shifted
KbdDecodeTab_SHIFT:
	.byte "L", "J", ":", KEY_INVALID, KEY_INVALID, "K", "\", "^"
	.byte "O", KEY_INVALID, "P", "U", CR, "I", "_", "|"
	.byte "V", KEY_BPS, "C", KEY_INVALID, KEY_INVALID, "B", "X", "Z"
	.byte "$", KEY_INVALID, "#", "&", KEY_LARROW, "%", $22, "!"
	.byte "[", " ", "]", "N", KEY_INVALID, "M", "?", KEY_INVALID
	.byte "R", KEY_INVALID, "E", "Y", TAB, "T", "W", "Q"
	.byte "(", KEY_INVALID, ")", "'", BACKSPACE, "@", KEY_CLEAR, KEY_INSERT
	.byte "F", "H", "D", KEY_INVALID, KEY_RUN, "G", "S", "A"

; control
KbdDecodeTab_CTRL:
	.byte "l", "j", ";", KEY_INVALID, KEY_INVALID, "k", KEY_LEFT, KEY_RIGHT
	.byte "o", KEY_INVALID, "p", "u", LF, "i", KEY_UP, KEY_DOWN
	.byte "v", KEY_BPS, "c", KEY_INVALID, KEY_INVALID, "b", "x", "z"
	.byte KEY_F4, KEY_INVALID, KEY_F3, KEY_F6, KEY_LARROW, KEY_F5, KEY_F2, KEY_F1
	.byte ",", " ", ".", "n", KEY_INVALID, "m", "/", KEY_INVALID
	.byte "r", KEY_INVALID, "e", "y", TAB, "t", "w", "q"
	.byte "9", KEY_INVALID, "0", KEY_F7, KEY_DELETE, KEY_F8, KEY_HOME, KEY_INSERT
	.byte "f", "h", "d", KEY_INVALID, KEY_STOP, "g", "s", "a"


.if 0=1

; LUnix / LNG
_keytab_normal:
	.byte $6c, $6a, ";", none_c, none_c, $6b, "+", "*"
	.byte $6f, none_c, $70, $75, return_c, $69, "-", "="
	.byte $76, help_c, $63, none_c, none_c, $62, $78, $7a
	.byte "4", none_c, "3", "6", esc_c, "5", "2", "1"
	.byte ",", space_c, ".", $6e, none_c, $6d, "/", inv_c
	.byte $72, none_c, $65, $79, tab_c, $74, $77, $71
	.byte "9", none_c, "0", "7", bkspc_c, "8", "<", ">"
	.byte $66, $68, $64, none_c, caps_c, $67, $73, $61
_keytab_shift:
	.byte $4c, $4a, ":", none_c, none_c, $4b, backslash_c, "^"
	.byte $4f, none_c, $50, $55, sreturn_c, $49, "_", "|"
	.byte $56, shelp_c, $43, none_c, none_c, $42, $58, $5a
	.byte "$", none_c, "#", "&", sesc_c, "%", $22, "!"
	.byte "[", sspace_c, "]", $4e, none_c, $4d, "?", sinv_c
	.byte $52, none_c, $45, $59, stab_c, $54, $57, $51
	.byte "(", none_c, ")", "'", del_c, "@", clear_c, insert_c
	.byte $46, $48, $44, none_c, scaps_c, $47, $53, $41

; GEOS 64/128

; unshifted
KbdDecodeTab1:
	.byte KEY_DELETE, CR, KEY_RIGHT, KEY_F7, KEY_F1, KEY_F3, KEY_F5, KEY_DOWN
	.byte "3", "w", "a", "4", "z", "s", "e", KEY_INVALID
	.byte "5", "r", "d", "6", "c", "f", "t", "x"
	.byte "7", "y", "g", "8", "b", "h", "u", "v"
	.byte "9", "i", "j", "0", "m", "k", "o", "n"
	.byte "+", "p", "l", "-", ".", ":", "@", ","
	.byte KEY_BPS, "*", ";", KEY_HOME, KEY_INVALID, "=", "^", "/"
	.byte "1", KEY_LARROW, KEY_INVALID, "2", " ", KEY_INVALID, "q", KEY_STOP

; shifted
KbdDecodeTab2:
	.byte KEY_INSERT, CR, BACKSPACE, KEY_F8, KEY_F2, KEY_F4, KEY_F6, KEY_UP
	.byte "#", "W", "A", "$", "Z", "S", "E", KEY_INVALID
	.byte "%", "R", "D", "&", "C", "F", "T", "X"
	.byte "'", "Y", "G", "(", "B", "H", "U", "V"
	.byte ")", "I", "J", "0", "M", "K", "O", "N"
	.byte "+", "P", "L", "-", ">", "[", "@", "<"
	.byte KEY_BPS, "*", "]", KEY_CLEAR, KEY_INVALID, "=", "^", "?"
	.byte "!", KEY_LARROW, KEY_INVALID, $22, " ", KEY_INVALID, "Q", KEY_RUN
.endif
