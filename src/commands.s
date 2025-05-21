; ============================================================================
; PBasic m6502 - Command Dispatcher
; ============================================================================

.segment "CODE"

.export REPL_DISPATCH, RUN_NEXT

REPL_DISPATCH:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    beq @disp_eol
    cmp #TOK_NUMBER
    beq @disp_line_store
    jmp REPL

@disp_eol:
    lda MEM_RUN_FLAG
    bne @disp_run_next
    jmp REPL

@disp_run_next:
    jmp RUN_NEXT

@disp_line_store:
    jsr LINE_STORE
    jmp REPL

RUN_NEXT:
    jmp REPL
