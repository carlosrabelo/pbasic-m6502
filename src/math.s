; ============================================================================
; PBasic m6502 - Mathematical Engine (16-bit Arithmetic)
; ============================================================================

.segment "CODE"

.export MUL16

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
