; ============================================================================
; PBasic m6502 - Command Dispatcher
; ============================================================================

.segment "CODE"

.export REPL_DISPATCH, RUN_NEXT

REPL_DISPATCH:
    jmp REPL

RUN_NEXT:
    jmp REPL
