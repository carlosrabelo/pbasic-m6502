; ============================================================================
; PBasic m6502 - Command Dispatcher
; ============================================================================

.segment "CODE"

.export REPL_DISPATCH, RUN_NEXT, REPL_SYNTAX_ERROR, CMD_JUMP_TABLE
.export DO_GOTO, DO_GOSUB, DO_IF, DO_INPUT, DO_RETURN
.export DO_END, DO_RUN, DO_EXIT, DO_REM, DO_FREE

REPL_SYNTAX_ERROR:
    lda #<MSG_ERROR
    sta SCR_PTR
    lda #>MSG_ERROR
    sta SCR_PTR+1
    jsr PRINT_STR
    lda #0
    sta MEM_RUN_FLAG
    jmp REPL

REPL_DISPATCH:
    ldy #0
    lda (MEM_TOKEN_PTR), y

    ; 0x00: End of statement
    beq @disp_eol

    ; 0xC0: Stored program line
    cmp #TOK_NUMBER
    beq @disp_line_store

    ; 0xA0: Direct FREE statement
    cmp #TOK_FREE
    beq @disp_free

    ; Command tokens 0x80..0x8C
    cmp #$80
    bcc @disp_syntax_err
    cmp #$8D
    bcs @disp_syntax_err

    ; Advance MEM_TOKEN_PTR past command token
    pha
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    pla

    ; Calculate jump offset: (token - 0x80) * 2
    sec
    sbc #$80
    asl
    tax
    lda CMD_JUMP_TABLE, x
    sta SCR_PTR
    lda CMD_JUMP_TABLE+1, x
    sta SCR_PTR+1
    jmp (SCR_PTR)

@disp_syntax_err:
    jmp REPL_SYNTAX_ERROR

@disp_eol:
    lda MEM_RUN_FLAG
    bne @disp_run_next
    jmp REPL

@disp_run_next:
    jmp RUN_NEXT

@disp_line_store:
    jsr LINE_STORE
    jmp REPL

@disp_free:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp DO_FREE

RUN_NEXT:
    jmp REPL

; Command jump table for tokens 0x80..0x8C
CMD_JUMP_TABLE:
    .word DO_LET      ; 0x80
    .word DO_GOTO     ; 0x81
    .word DO_GOSUB    ; 0x82
    .word DO_PRINT    ; 0x83
    .word DO_IF       ; 0x84
    .word DO_INPUT    ; 0x85
    .word DO_RETURN   ; 0x86
    .word DO_END      ; 0x87
    .word DO_LIST     ; 0x88
    .word DO_RUN      ; 0x89
    .word DO_NEW      ; 0x8A
    .word DO_EXIT     ; 0x8B
    .word DO_REM      ; 0x8C

; Temporary stubs
DO_GOTO:    jmp REPL_SYNTAX_ERROR
DO_GOSUB:   jmp REPL_SYNTAX_ERROR
DO_IF:      jmp REPL_SYNTAX_ERROR
DO_INPUT:   jmp REPL_SYNTAX_ERROR
DO_RETURN:  jmp REPL_SYNTAX_ERROR
DO_END:     jmp REPL_SYNTAX_ERROR
DO_RUN:     jmp REPL_SYNTAX_ERROR
DO_EXIT:    jmp REPL_SYNTAX_ERROR
DO_REM:     jmp REPL_SYNTAX_ERROR
DO_FREE:    jmp REPL_SYNTAX_ERROR
