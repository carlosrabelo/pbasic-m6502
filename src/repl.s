; ============================================================================
; PBasic m6502 - Read-Eval-Print Loop (REPL)
; ============================================================================

.segment "CODE"

.export REPL

REPL:
    ; 1. Check MEM_RUN_FLAG
    lda MEM_RUN_FLAG
    bne @repl_run_program

    ; 2. Emit interactive prompt '> '
    lda #<STR_PROMPT
    sta SCR_PTR
    lda #>STR_PROMPT
    sta SCR_PTR+1
    jsr PRINT_STR

    ; 3. Read line into MEM_INPUT_BUF
    jsr READ_LINE

    ; 4. Tokenize input line into MEM_TOKEN_BUF
    jsr TOKENIZE

    ; 5. Initialize MEM_TOKEN_PTR to MEM_TOKEN_BUF
    lda #<MEM_TOKEN_BUF
    sta MEM_TOKEN_PTR
    lda #>MEM_TOKEN_BUF
    sta MEM_TOKEN_PTR+1

    ; 6. Dispatch command
    jmp REPL_DISPATCH

@repl_run_program:
    jmp RUN_NEXT
