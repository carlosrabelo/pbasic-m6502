; ============================================================================
; PBasic m6502 - GOSUB Statement Execution
; ============================================================================

.segment "CODE"

.export DO_GOSUB

DO_GOSUB:
    lda MEM_GOSUB_SP
    cmp #16
    bcc :+
    jmp REPL_SYNTAX_ERROR
:
    asl
    tax
    lda MEM_LINE_PTR
    sta MEM_GOSUB_STK, x
    lda MEM_LINE_PTR+1
    sta MEM_GOSUB_STK+1, x

    inc MEM_GOSUB_SP

    jsr EVAL_EXPR

    lda SCR_ACC_0
    sta SCR_NUM
    lda SCR_ACC_1
    sta SCR_NUM+1

    jsr LINE_FIND
    cmp #0
    bne :+
    jmp REPL_SYNTAX_ERROR
:
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
