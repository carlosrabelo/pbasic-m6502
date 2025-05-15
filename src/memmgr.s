; ============================================================================
; PBasic m6502 - Program Memory Initialization
; ============================================================================

.segment "CODE"

.export PROG_INIT

PROG_INIT:
    pha
    ; Write 0x0000 sentinel at MEM_PROG_START ($4000)
    lda #0
    sta MEM_PROG_START
    sta MEM_PROG_START+1

    ; Set MEM_PROG_END = MEM_PROG_START + 2 ($4002)
    lda #<(MEM_PROG_START + 2)
    sta MEM_PROG_END
    lda #>(MEM_PROG_START + 2)
    sta MEM_PROG_END+1

    ; Set MEM_PROG_LIMIT = $8000
    lda #<PROG_LIMIT
    sta MEM_PROG_LIMIT
    lda #>PROG_LIMIT
    sta MEM_PROG_LIMIT+1

    pla
    rts
