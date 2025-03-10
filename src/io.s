; ============================================================================
; PBasic m6502 - Console Character I/O Primitives
; ============================================================================

.segment "CODE"

.export INCHAR, OUTCHAR, CHECK_BREAK

INCHAR:
@wait_rx:
    lda TTY_STATUS
    and #STATUS_RX_READY
    beq @wait_rx
    lda TTY_DATA
    rts

OUTCHAR:
    pha
@wait_tx:
    lda TTY_STATUS
    and #STATUS_TX_READY
    beq @wait_tx
    pla
    sta TTY_DATA
    rts

CHECK_BREAK:
    lda TTY_STATUS
    and #STATUS_BREAK
    beq @no_break
    sta TTY_STATUS
    lda #1
    rts
@no_break:
    lda #0
    rts
