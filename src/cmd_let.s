; ============================================================================
; PBasic m6502 - LET Statement Execution
; ============================================================================

.segment "CODE"

.export DO_LET

DO_LET:
    ldy #0
    lda (MEM_TOKEN_PTR), y

    ; 1. Verify variable token 0xD0..0xE9
    cmp #TOK_VAR_BASE
    bcc @let_syntax_err
    cmp #(TOK_VAR_BASE + 26)
    bcs @let_syntax_err

    ; 2. Save variable token and advance pointer
    pha
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ; 3. Expect '='
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #'='
    beq :+
    pla
    jmp REPL_SYNTAX_ERROR
:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ; 4. Evaluate expression into SCR_ACC
    jsr EVAL_EXPR

    ; 5. Store result to variable
    pla                  ; variable token
    jsr VAR_SET

    ; 6. Return to REPL or RUN_NEXT
    lda MEM_RUN_FLAG
    bne @let_run_next
    jmp REPL

@let_run_next:
    jmp RUN_NEXT

@let_syntax_err:
    jmp REPL_SYNTAX_ERROR
