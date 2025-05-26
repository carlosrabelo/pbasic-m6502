; ============================================================================
; PBasic m6502 - END Statement Execution
; ============================================================================

.segment "CODE"

.export DO_END

DO_END:
    lda #0
    sta MEM_RUN_FLAG
    jmp REPL
