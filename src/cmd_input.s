; ============================================================================
; PBasic m6502 - INPUT Statement Execution
; ============================================================================

.segment "CODE"

.export DO_INPUT

DO_INPUT:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #TOK_STRING
    bne @di_check_var

    ; 1. Print prompt string
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@di_prompt_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #TOK_STRING
    beq @di_prompt_end
    cmp #0
    bne :+
    jmp REPL_SYNTAX_ERROR
:
    jsr OUTCHAR
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp @di_prompt_loop

@di_prompt_end:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #';'
    beq :+
    jmp REPL_SYNTAX_ERROR
:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:

@di_check_var:
    ; 2. Verify variable token 0xD0..0xE9
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #TOK_VAR_BASE
    bcc :+
    cmp #(TOK_VAR_BASE + 26)
    bcc @di_var_ok
:
    jmp REPL_SYNTAX_ERROR

@di_var_ok:
    ; 3. Save variable token and advance pointer
    pha                  ; stack: [var_token]
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ; 4. Read user input line into MEM_INPUT_BUF
    jsr READ_LINE

    ; 5. Parse MEM_INPUT_BUF as signed decimal integer
    lda #<MEM_INPUT_BUF
    sta SCR_PTR
    lda #>MEM_INPUT_BUF
    sta SCR_PTR+1

@di_skip_spaces:
    ldy #0
    lda (SCR_PTR), y
    cmp #' '
    bne @di_check_sign
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    jmp @di_skip_spaces

@di_check_sign:
    ldy #0
    lda (SCR_PTR), y
    cmp #'-'
    bne @di_not_neg
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    lda #1               ; 1 = negative
    jmp @di_parse_init

@di_not_neg:
    lda #0               ; 0 = positive

@di_parse_init:
    pha                  ; stack: [var_token, sign_flag]

    lda #0
    sta SCR_ACC_0
    sta SCR_ACC_1
    sta SCR_ACC_2
    sta SCR_ACC_3

@di_digit_loop:
    ldy #0
    lda (SCR_PTR), y
    cmp #'0'
    bcc @di_digits_done
    cmp #('9' + 1)
    bcs @di_digits_done

    sec
    sbc #'0'
    pha                  ; stack: [var_token, sign_flag, digit]

    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    ; SCR_WORK = SCR_ACC * 2
    lda SCR_ACC_0
    sta SCR_WORK_0
    lda SCR_ACC_1
    sta SCR_WORK_1
    lda SCR_ACC_2
    sta SCR_WORK_2
    lda SCR_ACC_3
    sta SCR_WORK_3

    asl SCR_WORK_0
    rol SCR_WORK_1
    rol SCR_WORK_2
    rol SCR_WORK_3

    ; SCR_ACC = SCR_ACC * 8
    asl SCR_ACC_0
    rol SCR_ACC_1
    rol SCR_ACC_2
    rol SCR_ACC_3

    asl SCR_ACC_0
    rol SCR_ACC_1
    rol SCR_ACC_2
    rol SCR_ACC_3

    asl SCR_ACC_0
    rol SCR_ACC_1
    rol SCR_ACC_2
    rol SCR_ACC_3

    ; SCR_ACC = SCR_ACC * 10 = (SCR_ACC * 8) + (SCR_WORK * 2)
    clc
    lda SCR_ACC_0
    adc SCR_WORK_0
    sta SCR_ACC_0
    lda SCR_ACC_1
    adc SCR_WORK_1
    sta SCR_ACC_1
    lda SCR_ACC_2
    adc SCR_WORK_2
    sta SCR_ACC_2
    lda SCR_ACC_3
    adc SCR_WORK_3
    sta SCR_ACC_3

    ; Add digit
    pla                  ; pop digit
    clc
    adc SCR_ACC_0
    sta SCR_ACC_0
    bcc :+
    inc SCR_ACC_1
    bne :+
    inc SCR_ACC_2
    bne :+
    inc SCR_ACC_3
:
    jmp @di_digit_loop

@di_digits_done:
    pla                  ; pop sign_flag
    cmp #0
    beq @di_store_val
    jsr NEG32

@di_store_val:
    pla                  ; pop var_token
    jsr VAR_SET

    ; 6. Resume execution
    lda MEM_RUN_FLAG
    bne @di_run_next
    jmp REPL

@di_run_next:
    jmp RUN_NEXT
