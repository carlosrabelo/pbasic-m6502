; ============================================================================
; PBasic m6502 - Bytecode Tokenizer Engine
; ============================================================================

.segment "CODE"

.export TOKENIZE

TOKENIZE:
    pha
    txa
    pha
    tya
    pha

    lda #<MEM_INPUT_BUF
    sta SCR_PTR
    lda #>MEM_INPUT_BUF
    sta SCR_PTR+1

    lda #<MEM_TOKEN_BUF
    sta SCR_PTR2
    lda #>MEM_TOKEN_BUF
    sta SCR_PTR2+1

@tok_loop:
    ldy #0
    lda (SCR_PTR), y

    ; End of line check
    beq @tok_end

    ; Skip spaces
    cmp #' '
    bne @tok_non_space
    inc SCR_PTR
    bne @tok_loop
    inc SCR_PTR+1
    jmp @tok_loop

@tok_non_space:
    ; Default: emit character directly to token buffer
    sta (SCR_PTR2), y
    inc SCR_PTR2
    bne :+
    inc SCR_PTR2+1
:
    inc SCR_PTR
    bne @tok_loop
    inc SCR_PTR+1
    jmp @tok_loop

@tok_end:
    lda #0
    sta (SCR_PTR2), y
    pla
    tay
    pla
    tax
    pla
    rts
