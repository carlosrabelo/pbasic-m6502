; ============================================================================
; PBasic m6502 - FREE Statement Execution
; ============================================================================

.segment "CODE"

.export DO_FREE

DO_FREE:
    sec
    lda MEM_PROG_LIMIT
    sbc MEM_PROG_END
    sta SCR_ACC_0
    lda MEM_PROG_LIMIT+1
    sbc MEM_PROG_END+1
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3

    jsr PRINT_NUMBER
    jsr PRINT_CRLF

    lda MEM_RUN_FLAG
    bne @dfree_run_next
    jmp REPL

@dfree_run_next:
    jmp RUN_NEXT
