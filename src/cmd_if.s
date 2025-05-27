; ============================================================================
; PBasic m6502 - IF/THEN Statement Execution
; ============================================================================

.segment "CODE"

.export DO_IF

DO_IF:
    jsr EVAL_COND
    cmp #0
    bne :+
    jmp @dif_false
:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #TOK_THEN
    beq :+
    jmp REPL_SYNTAX_ERROR
:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldy #0
    lda (MEM_TOKEN_PTR), y

    cmp #TOK_FREE
    beq @dif_free

    cmp #$80
    bcc @dif_syntax_err
    cmp #$8D
    bcs @dif_syntax_err

    pha
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    pla

    sec
    sbc #$80
    asl
    tax
    lda CMD_JUMP_TABLE, x
    sta SCR_PTR
    lda CMD_JUMP_TABLE+1, x
    sta SCR_PTR+1
    jmp (SCR_PTR)

@dif_free:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp DO_FREE

@dif_syntax_err:
    jmp REPL_SYNTAX_ERROR

@dif_false:
    lda MEM_RUN_FLAG
    bne @dif_run_next
    jmp REPL

@dif_run_next:
    jmp RUN_NEXT
