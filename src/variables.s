; ============================================================================
; PBasic m6502 - Variables Storage & Management
; ============================================================================

.segment "CODE"

.export VAR_INIT, VAR_ADDR, VAR_GET, VAR_SET

VAR_INIT:
    pha
    tya
    pha
    ; Zero all 104 bytes in MEM_VARS (26 variables A..Z, 4 bytes each)
    ldy #104
    lda #0
@var_init_loop:
    dey
    sta MEM_VARS, y
    bne @var_init_loop
    pla
    tay
    pla
    rts

; VAR_ADDR:
; Input: A = variable token ($D0..$E9)
; Output: SCR_PTR = address of variable in MEM_VARS
VAR_ADDR:
    sec
    sbc #TOK_VAR_BASE
    asl
    asl
    clc
    adc #<MEM_VARS
    sta SCR_PTR
    lda #>MEM_VARS
    adc #0
    sta SCR_PTR+1
    rts

; VAR_GET:
; Input: A = variable token ($D0..$E9)
; Output: SCR_ACC (4 bytes) = 32-bit value
VAR_GET:
    jsr VAR_ADDR
    pha
    tya
    pha
    ldy #0
    lda (SCR_PTR), y
    sta SCR_ACC_0
    iny
    lda (SCR_PTR), y
    sta SCR_ACC_1
    iny
    lda (SCR_PTR), y
    sta SCR_ACC_2
    iny
    lda (SCR_PTR), y
    sta SCR_ACC_3
    pla
    tay
    pla
    rts

; VAR_SET:
; Input: A = variable token ($D0..$E9), SCR_ACC = 32-bit value
VAR_SET:
    jsr VAR_ADDR
    pha
    tya
    pha
    ldy #0
    lda SCR_ACC_0
    sta (SCR_PTR), y
    iny
    lda SCR_ACC_1
    sta (SCR_PTR), y
    iny
    lda SCR_ACC_2
    sta (SCR_PTR), y
    iny
    lda SCR_ACC_3
    sta (SCR_PTR), y
    pla
    tay
    pla
    rts

