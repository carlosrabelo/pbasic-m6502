; ============================================================================
; PBasic m6502 - RETURN Statement Execution
; ============================================================================

.segment "CODE"

.export DO_RETURN

DO_RETURN:
    lda MEM_GOSUB_SP
    bne :+
    jmp REPL_SYNTAX_ERROR
:
    dec MEM_GOSUB_SP
    lda MEM_GOSUB_SP
    asl
    tax

    lda MEM_GOSUB_STK, x
    sta SCR_PTR
    lda MEM_GOSUB_STK+1, x
    sta SCR_PTR+1

    lda SCR_PTR
    ora SCR_PTR+1
    bne :+
    jmp RUN_END
:
    lda SCR_PTR
    sta MEM_LINE_PTR
    lda SCR_PTR+1
    sta MEM_LINE_PTR+1

    jmp RUN_NEXT
