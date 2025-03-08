; ============================================================================
; PBasic m6502 - Variables Storage & Management
; ============================================================================

.segment "CODE"

.export VAR_INIT

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

