; ============================================================================
; PBasic m6502 - Mathematical Engine (16-bit Arithmetic)
; ============================================================================

.segment "CODE"

.export MUL16, DIV16, MOD16, DIVMOD16

; MUL16:
; Input: SCR_NUM = multiplicand, SCR_TMP = multiplier
; Output: SCR_ACC = 16-bit unsigned product (SCR_NUM * SCR_TMP) & 0xFFFF
MUL16:
    pha
    txa
    pha

    ; Initialize product in SCR_ACC = 0
    lda #0
    sta SCR_ACC_0
    sta SCR_ACC_1
    sta SCR_ACC_2
    sta SCR_ACC_3

    ; 16 iterations
    ldx #16

@mul16_loop:
    ; Shift multiplier SCR_TMP right: test lowest bit
    lsr SCR_TMP+1
    ror SCR_TMP
    bcc @mul16_no_add

    ; Add multiplicand SCR_NUM into SCR_ACC
    clc
    lda SCR_ACC_0
    adc SCR_NUM
    sta SCR_ACC_0
    lda SCR_ACC_1
    adc SCR_NUM+1
    sta SCR_ACC_1

@mul16_no_add:
    ; Shift multiplicand SCR_NUM left
    asl SCR_NUM
    rol SCR_NUM+1

    dex
    bne @mul16_loop

    pla
    tax
    pla
    rts

; ============================================================================
; 16-bit Division and Modulo
; ============================================================================

; DIV16:
; Input: SCR_NUM = dividend, SCR_TMP = divisor
; Output: SCR_ACC = 16-bit quotient, or 0xFFFF if divisor is 0
DIV16:
    lda SCR_TMP
    ora SCR_TMP+1
    bne @div16_nonzero

    ; Division by zero: return 0xFFFF
    lda #$FF
    sta SCR_ACC_0
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3
    rts

@div16_nonzero:
    jsr DIVMOD16
    rts

; MOD16:
; Input: SCR_NUM = dividend, SCR_TMP = divisor
; Output: SCR_ACC = 16-bit remainder, or SCR_NUM if divisor is 0
MOD16:
    lda SCR_TMP
    ora SCR_TMP+1
    bne @mod16_nonzero

    ; Modulo by zero: return dividend unchanged
    lda SCR_NUM
    sta SCR_ACC_0
    lda SCR_NUM+1
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3
    rts

@mod16_nonzero:
    jsr DIVMOD16
    ; Remainder was returned in SCR_NUM
    lda SCR_NUM
    sta SCR_ACC_0
    lda SCR_NUM+1
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3
    rts

; DIVMOD16:
; Input: SCR_NUM = dividend, SCR_TMP = divisor
; Output: SCR_ACC = quotient (low 16 bits), SCR_NUM = remainder (low 16 bits)
DIVMOD16:
    pha
    txa
    pha

    ; Initialize 16-bit remainder SCR_WORK = 0
    lda #0
    sta SCR_WORK
    sta SCR_WORK+1

    ldx #16

@dm16_loop:
    ; Shift dividend (SCR_NUM) left into remainder (SCR_WORK)
    asl SCR_NUM
    rol SCR_NUM+1
    rol SCR_WORK
    rol SCR_WORK+1

    ; Trial subtraction: SCR_WORK - SCR_TMP
    sec
    lda SCR_WORK
    sbc SCR_TMP
    tay                 ; save candidate low byte in Y
    lda SCR_WORK+1
    sbc SCR_TMP+1

    bcc @dm16_next      ; if borrow, remainder < divisor, skip restore

    ; Remainder >= divisor: commit subtraction and set quotient bit
    sta SCR_WORK+1
    sty SCR_WORK
    inc SCR_NUM

@dm16_next:
    dex
    bne @dm16_loop

    ; SCR_NUM contains quotient. Move to SCR_ACC:
    lda SCR_NUM
    sta SCR_ACC_0
    lda SCR_NUM+1
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3

    ; SCR_WORK contains remainder. Move to SCR_NUM:
    lda SCR_WORK
    sta SCR_NUM
    lda SCR_WORK+1
    sta SCR_NUM+1

    pla
    tax
    pla
    rts
