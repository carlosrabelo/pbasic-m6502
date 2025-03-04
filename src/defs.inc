; ============================================================================
; PBasic m6502 - Core Definitions and Memory Map
; ============================================================================

; Console I/O Memory-Mapped Addresses (Mojave Virtual TTY on m6502)
TTY_DATA        = $FFE0
TTY_STATUS      = $FFE1
STATUS_RX_READY = $01
STATUS_TX_READY = $02
STATUS_BREAK    = $04

; ----------------------------------------------------------------------------
; Zero Page Allocations ($0000 - $00FF)
; ----------------------------------------------------------------------------
; $0000 - $0002 reserved for initial BOOT jump

; Scratchpad registers (16-bit pointers and counters in Zero Page)
SCR_PTR         = $03   ; 2 bytes: generic memory pointer
SCR_PTR2        = $05   ; 2 bytes: generic memory pointer 2
SCR_LEN         = $07   ; 2 bytes: block length
SCR_TLEN        = $09   ; 2 bytes: token count
SCR_NLEN        = $0B   ; 2 bytes: node length
SCR_NUM         = $0D   ; 2 bytes: 16-bit line number / parsed constant
SCR_TMP         = $0F   ; 2 bytes: temporary calculation storage

; 32-bit Accumulator and Operand in Zero Page
SCR_ACC         = $11   ; 4 bytes: 32-bit evaluation accumulator
SCR_ACC_0       = $11   ; byte 0 (bits 0..7)
SCR_ACC_1       = $12   ; byte 1 (bits 8..15)
SCR_ACC_2       = $13   ; byte 2 (bits 16..23)
SCR_ACC_3       = $14   ; byte 3 (bits 24..31)

SCR_OP          = $15   ; 4 bytes: 32-bit second operand
SCR_OP_0        = $15
SCR_OP_1        = $16
SCR_OP_2        = $17
SCR_OP_3        = $18

SCR_BODY        = $19   ; 2 bytes: program line body pointer
SCR_INS         = $1B   ; 2 bytes: program line insertion pointer

; Execution state and system pointers in Zero Page
MEM_TOKEN_PTR   = $1D   ; 2 bytes: pointer to current token
MEM_LINE_PTR    = $1F   ; 2 bytes: pointer to current line node
MEM_PROG_END    = $21   ; 2 bytes: pointer to current end of program
MEM_PROG_LIMIT  = $23   ; 2 bytes: pointer to upper limit of program space
MEM_RUN_FLAG    = $25   ; 1 byte:  0 = REPL, 1 = running program
MEM_GOSUB_SP    = $26   ; 1 byte:  call stack pointer index (depth 0..16)
MEM_RAND_SEED   = $27   ; 2 bytes: PRNG seed (initial 12345)
SCR_WORK        = $29   ; 4 bytes: 32-bit temporary work register
SCR_WORK_0      = $29
SCR_WORK_1      = $2A
SCR_WORK_2      = $2B
SCR_WORK_3      = $2C

; ----------------------------------------------------------------------------
; Static RAM Buffers ($0200 - $07FF)
; ----------------------------------------------------------------------------
MEM_INPUT_BUF   = $0200 ; 128 bytes (Raw line input buffer)
MEM_TOKEN_BUF   = $0280 ; 160 bytes (Tokenized bytecode representation)
MEM_VARS        = $0320 ; 104 bytes (26 variables A..Z, 4 bytes each)
MEM_GOSUB_STK   = $0388 ; 32 bytes (16 frames of 2 bytes)

; ----------------------------------------------------------------------------
; Program Storage Area ($4000 - $7FFF)
; ----------------------------------------------------------------------------
MEM_PROG_START  = $4000 ; 16 KiB program store
PROG_CAPACITY   = $4000 ; 16384 bytes
PROG_LIMIT      = $8000 ; Upper memory limit (MEM_PROG_START + PROG_CAPACITY)

; ----------------------------------------------------------------------------
; Bytecode Token Definitions
; ----------------------------------------------------------------------------
; Keywords ($80 - $8D)
TOK_LET         = $80
TOK_GOTO        = $81
TOK_GOSUB       = $82
TOK_PRINT       = $83
TOK_IF          = $84
TOK_INPUT       = $85
TOK_RETURN      = $86
TOK_END         = $87
TOK_LIST        = $88
TOK_RUN         = $89
TOK_NEW         = $8A
TOK_EXIT        = $8B
TOK_REM         = $8C
TOK_THEN        = $8D

; Built-in functions ($A0 - $A2)
TOK_FREE        = $A0
TOK_RND         = $A1
TOK_ABS         = $A2

; Multi-character operators ($B0 - $B2)
TOK_NEQ         = $B0   ; <>
TOK_LTE         = $B1   ; <=
TOK_GTE         = $B2   ; >=

; Literals & variables
TOK_NUMBER      = $C0   ; Followed by 2 bytes: <lo> <hi>
TOK_STRING      = $C1   ; Enclosed between $C1 and $C1
TOK_VAR_BASE    = $D0   ; Variables A..Z ($D0 - $E9)
TOK_EOL         = $00   ; End of statement stream
