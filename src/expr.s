; ============================================================================
; PBasic m6502 - Expression Evaluator
; ============================================================================

.segment "CODE"

.export EVAL_FACTOR, EVAL_TERM, EVAL_EXPR, EVAL_COND

; ============================================================================
; Factor Evaluation
; ============================================================================

EVAL_FACTOR:
    ldy #0
    lda (MEM_TOKEN_PTR), y

    ; 1. Number literal (0xC0)
    cmp #TOK_NUMBER
    bne :+
    jmp @ef_number
:
    ; 2. Variable (0xD0..0xE9)
    cmp #TOK_VAR_BASE
    bcc @ef_not_var
    cmp #(TOK_VAR_BASE + 26)
    bcs @ef_not_var

    ; Advance MEM_TOKEN_PTR by 1
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp VAR_GET

@ef_not_var:
    ; 3. TOK_FREE (0xA0)
    cmp #TOK_FREE
    bne :+
    jmp @ef_free
:
    ; 4. TOK_RND (0xA1)
    cmp #TOK_RND
    bne :+
    jmp @ef_rnd
:
    ; 5. TOK_ABS (0xA2)
    cmp #TOK_ABS
    bne :+
    jmp @ef_abs
:
    ; 6. Parenthesized expression '(' ($28)
    cmp #$28
    bne :+
    jmp @ef_paren
:
    ; 7. Unary minus '-' ($2D)
    cmp #$2D
    bne :+
    jmp @ef_unary_minus
:
    ; 8. Unary plus '+' ($2B)
    cmp #$2B
    bne :+
    jmp @ef_unary_plus
:
    ; Unexpected token -> return SCR_ACC = 0
    lda #0
    sta SCR_ACC_0
    sta SCR_ACC_1
    sta SCR_ACC_2
    sta SCR_ACC_3
    rts

@ef_number:
    ; Advance past $C0
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    sta SCR_ACC_0
    iny
    lda (MEM_TOKEN_PTR), y
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3

    ; Advance past 2 value bytes
    clc
    lda MEM_TOKEN_PTR
    adc #2
    sta MEM_TOKEN_PTR
    bcc :+
    inc MEM_TOKEN_PTR+1
:
    rts

@ef_free:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
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
    rts

@ef_rnd:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #$28
    bne @ef_rnd_noparen
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@ef_rnd_noparen:
    jsr EVAL_EXPR

    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #$29
    bne @ef_rnd_close_done
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@ef_rnd_close_done:
    lda SCR_ACC_0
    ora SCR_ACC_1
    bne @ef_rnd_nonzero
    jmp RAND16

@ef_rnd_nonzero:
    lda SCR_ACC_0
    sta SCR_TMP
    lda SCR_ACC_1
    sta SCR_TMP+1

    jsr RAND16

    lda SCR_ACC_0
    sta SCR_NUM
    lda SCR_ACC_1
    sta SCR_NUM+1

    jsr MOD16

    clc
    lda SCR_ACC_0
    adc #1
    sta SCR_ACC_0
    bcc :+
    inc SCR_ACC_1
:
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3
    rts

@ef_abs:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #$28
    bne @ef_abs_noparen
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@ef_abs_noparen:
    jsr EVAL_EXPR

    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #$29
    bne @ef_abs_close_done
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@ef_abs_close_done:
    jmp ABS

@ef_paren:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_EXPR

    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #$29
    bne @ef_paren_done
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
@ef_paren_done:
    rts

@ef_unary_minus:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_FACTOR
    jmp NEG32

@ef_unary_plus:
    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jmp EVAL_FACTOR

; ============================================================================
; Term Evaluation (* and / with 16-bit MUL16 and DIV16)
; ============================================================================

; EVAL_TERM:
; Evaluates multiplicative terms with * and / left-to-right precedence
; Output: SCR_ACC = 32-bit evaluated term
EVAL_TERM:
    jsr EVAL_FACTOR

@et_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #'*'
    beq @et_mul
    cmp #'/'
    beq @et_div
    rts

@et_mul:
    lda SCR_ACC_0
    pha
    lda SCR_ACC_1
    pha

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_FACTOR

    lda SCR_ACC_0
    sta SCR_TMP
    lda SCR_ACC_1
    sta SCR_TMP+1

    pla
    sta SCR_NUM+1
    pla
    sta SCR_NUM

    jsr MUL16
    jmp @et_loop

@et_div:
    lda SCR_ACC_0
    pha
    lda SCR_ACC_1
    pha

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_FACTOR

    lda SCR_ACC_0
    sta SCR_TMP
    lda SCR_ACC_1
    sta SCR_TMP+1

    pla
    sta SCR_NUM+1
    pla
    sta SCR_NUM

    jsr DIV16
    jmp @et_loop

; ============================================================================
; Expression Evaluation (+ and -)
; ============================================================================

EVAL_EXPR:
    jsr EVAL_TERM

@ee_loop:
    ldy #0
    lda (MEM_TOKEN_PTR), y
    cmp #'+'
    beq @ee_add
    cmp #'-'
    beq @ee_sub
    rts

@ee_add:
    lda SCR_ACC_0
    pha
    lda SCR_ACC_1
    pha
    lda SCR_ACC_2
    pha
    lda SCR_ACC_3
    pha

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_TERM

    lda SCR_ACC_0
    sta SCR_OP_0
    lda SCR_ACC_1
    sta SCR_OP_1
    lda SCR_ACC_2
    sta SCR_OP_2
    lda SCR_ACC_3
    sta SCR_OP_3

    pla
    sta SCR_ACC_3
    pla
    sta SCR_ACC_2
    pla
    sta SCR_ACC_1
    pla
    sta SCR_ACC_0

    clc
    lda SCR_ACC_0
    adc SCR_OP_0
    sta SCR_ACC_0
    lda SCR_ACC_1
    adc SCR_OP_1
    sta SCR_ACC_1
    lda SCR_ACC_2
    adc SCR_OP_2
    sta SCR_ACC_2
    lda SCR_ACC_3
    adc SCR_OP_3
    sta SCR_ACC_3

    jmp @ee_loop

@ee_sub:
    lda SCR_ACC_0
    pha
    lda SCR_ACC_1
    pha
    lda SCR_ACC_2
    pha
    lda SCR_ACC_3
    pha

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    jsr EVAL_TERM

    lda SCR_ACC_0
    sta SCR_OP_0
    lda SCR_ACC_1
    sta SCR_OP_1
    lda SCR_ACC_2
    sta SCR_OP_2
    lda SCR_ACC_3
    sta SCR_OP_3

    pla
    sta SCR_ACC_3
    pla
    sta SCR_ACC_2
    pla
    sta SCR_ACC_1
    pla
    sta SCR_ACC_0

    sec
    lda SCR_ACC_0
    sbc SCR_OP_0
    sta SCR_ACC_0
    lda SCR_ACC_1
    sbc SCR_OP_1
    sta SCR_ACC_1
    lda SCR_ACC_2
    sbc SCR_OP_2
    sta SCR_ACC_2
    lda SCR_ACC_3
    sbc SCR_OP_3
    sta SCR_ACC_3

    jmp @ee_loop

; ============================================================================
; Relational Condition Evaluation (=, <>, <, >, <=, >=)
; ============================================================================

EVAL_COND:
    jsr EVAL_EXPR

    ldy #0
    lda (MEM_TOKEN_PTR), y

    cmp #'='
    beq @ec_relop
    cmp #TOK_NEQ
    beq @ec_relop
    cmp #'<'
    beq @ec_relop
    cmp #'>'
    beq @ec_relop
    cmp #TOK_LTE
    beq @ec_relop
    cmp #TOK_GTE
    beq @ec_relop

    ; No relational operator: test if SCR_ACC != 0
    lda SCR_ACC_0
    ora SCR_ACC_1
    ora SCR_ACC_2
    ora SCR_ACC_3
    beq @ec_false
    lda #1
    rts
@ec_false:
    lda #0
    rts

@ec_relop:
    pha                 ; save operator token

    inc MEM_TOKEN_PTR
    bne :+
    inc MEM_TOKEN_PTR+1
:
    lda SCR_ACC_0
    pha
    lda SCR_ACC_1
    pha
    lda SCR_ACC_2
    pha
    lda SCR_ACC_3
    pha

    jsr EVAL_EXPR

    lda SCR_ACC_0
    sta SCR_OP_0
    lda SCR_ACC_1
    sta SCR_OP_1
    lda SCR_ACC_2
    sta SCR_OP_2
    lda SCR_ACC_3
    sta SCR_OP_3

    pla
    sta SCR_ACC_3
    pla
    sta SCR_ACC_2
    pla
    sta SCR_ACC_1
    pla
    sta SCR_ACC_0

    jsr CMP32

    pla                 ; restore operator token

    cmp #'='
    beq @ec_op_eq
    cmp #TOK_NEQ
    beq @ec_op_neq
    cmp #'<'
    beq @ec_op_lt
    cmp #'>'
    beq @ec_op_gt
    cmp #TOK_LTE
    beq @ec_op_lte
    cmp #TOK_GTE
    beq @ec_op_gte
    lda #0
    rts

@ec_op_eq:
    cpx #0
    beq @ec_ret_true
    bne @ec_ret_false

@ec_op_neq:
    cpx #0
    bne @ec_ret_true
    beq @ec_ret_false

@ec_op_lt:
    cpx #$FF
    beq @ec_ret_true
    bne @ec_ret_false

@ec_op_gt:
    cpx #1
    beq @ec_ret_true
    bne @ec_ret_false

@ec_op_lte:
    cpx #1
    bne @ec_ret_true
    beq @ec_ret_false

@ec_op_gte:
    cpx #$FF
    bne @ec_ret_true
    beq @ec_ret_false

@ec_ret_true:
    lda #1
    rts
@ec_ret_false:
    lda #0
    rts

; ============================================================================
; 32-bit Signed Comparison (SCR_ACC vs SCR_OP)
; Output: X = 0 (equal), X = $FF (SCR_ACC < SCR_OP), X = 1 (SCR_ACC > SCR_OP)
; ============================================================================

CMP32:
    lda SCR_ACC_3
    eor SCR_OP_3
    bmi @cmp_diff_sign

    ; Same sign: compare SCR_ACC - SCR_OP
    sec
    lda SCR_ACC_0
    sbc SCR_OP_0
    lda SCR_ACC_1
    sbc SCR_OP_1
    lda SCR_ACC_2
    sbc SCR_OP_2
    lda SCR_ACC_3
    sbc SCR_OP_3
    bcc @cmp_lt

    bne @cmp_gt
    lda SCR_ACC_0
    cmp SCR_OP_0
    bne @cmp_gt
    lda SCR_ACC_1
    cmp SCR_OP_1
    bne @cmp_gt
    lda SCR_ACC_2
    cmp SCR_OP_2
    bne @cmp_gt

    ldx #0
    rts

@cmp_diff_sign:
    lda SCR_ACC_3
    bmi @cmp_lt

@cmp_gt:
    ldx #1
    rts

@cmp_lt:
    ldx #$FF
    rts
