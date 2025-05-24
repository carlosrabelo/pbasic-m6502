; ============================================================================
; PBasic m6502 - NEW Command Execution
; ============================================================================

.segment "CODE"

.export DO_NEW

DO_NEW:
    jsr PROG_INIT
    jsr VAR_INIT
    jsr PRINT_OK
    jmp REPL
