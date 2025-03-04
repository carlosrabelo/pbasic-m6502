; ============================================================================
; PBasic m6502 - Variable Subsystem Initialization
; ============================================================================

.segment "CODE"

.export VAR_INIT

VAR_INIT:
    pha
    tya
    pha
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
