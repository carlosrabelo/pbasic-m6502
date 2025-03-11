; ============================================================================
; PBasic m6502 - System Strings and Messages
; ============================================================================

.segment "CODE"

.export MSG_BANNER, MSG_OK, MSG_ERROR, MSG_NO_PROGRAM, MSG_OUT_OF_MEM, STR_PROMPT

MSG_BANNER:     .byte "PBasic", 10, 0
MSG_OK:         .byte "OK", 10, 0
MSG_ERROR:      .byte "?SYNTAX ERROR", 10, 0
MSG_NO_PROGRAM: .byte "?NO PROGRAM", 10, 0
MSG_OUT_OF_MEM: .byte "?OUT OF MEMORY", 10, 0
STR_PROMPT:     .byte "> ", 0
