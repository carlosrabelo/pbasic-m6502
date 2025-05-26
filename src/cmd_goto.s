; ============================================================================
; PBasic m6502 - GOTO Statement Execution
; ============================================================================

.segment "CODE"

.export DO_GOTO

DO_GOTO:
    jsr EVAL_EXPR

    lda SCR_ACC_0
    sta SCR_NUM
    lda SCR_ACC_1
    sta SCR_NUM+1

    jsr LINE_FIND
    cmp #0
    beq @goto_syntax_err

    lda #1
    sta MEM_RUN_FLAG

    lda SCR_PTR
    sta MEM_LINE_PTR
    lda SCR_PTR+1
    sta MEM_LINE_PTR+1

    clc
    lda SCR_PTR
    adc #4
    sta MEM_TOKEN_PTR
    lda SCR_PTR+1
    adc #0
    sta MEM_TOKEN_PTR+1

    jmp REPL_DISPATCH

@goto_syntax_err:
    jmp REPL_SYNTAX_ERROR
