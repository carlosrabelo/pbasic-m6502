; ============================================================================
; PBasic m6502 - Utility Functions & PRNG
; ============================================================================

.segment "CODE"

.export RAND16, ABS

; RAND16:
; 16-bit Linear Congruential Generator (LCG):
; seed = (seed * 25173 + 13849) mod 65536
; Output: SCR_ACC = new 16-bit pseudo-random word (0..65535)
RAND16:
    pha

    lda MEM_RAND_SEED
    sta SCR_NUM
    lda MEM_RAND_SEED+1
    sta SCR_NUM+1

    lda #<25173
    sta SCR_TMP
    lda #>25173
    sta SCR_TMP+1

    jsr MUL16

    clc
    lda SCR_ACC_0
    adc #<13849
    sta MEM_RAND_SEED
    sta SCR_ACC_0
    lda SCR_ACC_1
    adc #>13849
    sta MEM_RAND_SEED+1
    sta SCR_ACC_1

    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3

    pla
    rts

; ABS:
; Input: SCR_ACC = 32-bit signed integer
; Output: SCR_ACC = absolute value
ABS:
    lda SCR_ACC_3
    and #$80
    beq @abs_pos
    jmp NEG32
@abs_pos:
    rts
