; ============================================================================
; PBasic m6502 - REM Statement Execution
; ============================================================================

.segment "CODE"

.export DO_REM

DO_REM:
@drem_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    beq @drem_done
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp @drem_loop

@drem_done:
    lda MEM_RUN_FLAG
    bne @drem_run_next
    jmp REPL

@drem_run_next:
    jmp RUN_NEXT
