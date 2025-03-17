; ============================================================================
; PBasic m6502 - PRINT Statement Execution
; ============================================================================

.segment "CODE"

.export DO_PRINT

PRINT_SUPPRESS: .byte 0

DO_PRINT:
    lda #0
    sta PRINT_SUPPRESS   ; Newline suppression flag (0 = emit, 1 = suppress)

@dp_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    bne :+
    jmp @dp_done
:
    ; Semicolon ';'
    cmp #';'
    bne :+
    jmp @dp_semicolon
:
    ; Comma ','
    cmp #','
    bne :+
    jmp @dp_comma
:
    ; Item being printed: clear suppress flag
    pha
    lda #0
    sta PRINT_SUPPRESS
    pla

    ; String literal 0xC1
    cmp #TOK_STRING
    bne :+
    jmp @dp_string
:
    ; Arithmetic / variable expression
    jsr EVAL_EXPR
    jsr PRINT_NUMBER
    jmp @dp_loop

@dp_semicolon:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    lda #1
    sta PRINT_SUPPRESS
    jmp @dp_loop

@dp_comma:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldx #8
@dp_spaces:
    lda #' '
    jsr OUTCHAR
    dex
    bne @dp_spaces

    lda #1
    sta PRINT_SUPPRESS
    jmp @dp_loop

@dp_string:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@dp_str_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #TOK_STRING
    beq @dp_str_end
    cmp #0
    beq @dp_done

    jsr OUTCHAR

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp @dp_str_loop

@dp_str_end:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp @dp_loop

@dp_done:
    lda PRINT_SUPPRESS
    bne @dp_exit
    jsr PRINT_CRLF

@dp_exit:
    lda MEM_RUN_FLAG
    bne @dp_run_next
    jmp REPL

@dp_run_next:
    jmp RUN_NEXT
