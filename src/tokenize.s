; ============================================================================
; PBasic m6502 - Bytecode Tokenizer
; ============================================================================

.segment "CODE"

.export TOKENIZE

TOKENIZE:
    pha
    lda #0
    sta MEM_TOKEN_BUF
    pla
    rts
