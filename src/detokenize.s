; ============================================================================
; PBasic m6502 - Bytecode Detokenizer (PRINT_TOKENS)
; ============================================================================

.segment "CODE"

.export PRINT_TOKENS, PKW_TABLE, PFN_TABLE, PREL_TABLE

PRINT_TOKENS:
    pha
    txa
    pha
    tya
    pha

@dtok_loop:
    ldy #0
    lda (SCR_PTR), y
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    cmp #0
    bne :+
    jmp @dtok_end
:
    ; 1. Number literal ($C0 <lo> <hi>)
    cmp #TOK_NUMBER
    bne @dtok_not_num

    ldy #0
    lda (SCR_PTR), y
    sta SCR_ACC_0
    iny
    lda (SCR_PTR), y
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3

    lda #2
    clc
    adc SCR_PTR
    sta SCR_PTR
    bcc :+
    inc SCR_PTR+1
:
    jsr PRINT_NUMBER
    jmp @dtok_loop

@dtok_not_num:
    ; 2. String literal ($C1 ... $C1)
    cmp #TOK_STRING
    bne @dtok_not_str

    lda #'"'
    jsr OUTCHAR

@dtok_str_loop:
    ldy #0
    lda (SCR_PTR), y
    beq @dtok_str_done
    cmp #TOK_STRING
    beq @dtok_str_done
    jsr OUTCHAR
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    jmp @dtok_str_loop

@dtok_str_done:
    ldy #0
    lda (SCR_PTR), y
    cmp #TOK_STRING
    bne :+
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    lda #'"'
    jsr OUTCHAR
    jmp @dtok_loop

@dtok_not_str:
    ; 3. Keywords ($80 - $8D)
    cmp #TOK_LET
    bcc @dtok_not_kw
    cmp #TOK_THEN + 1
    bcs @dtok_not_kw

    sec
    sbc #TOK_LET
    jsr PRINT_KW
    jmp @dtok_loop

@dtok_not_kw:
    ; 4. Built-in functions ($A0 - $A2)
    cmp #TOK_FREE
    bcc @dtok_not_fn
    cmp #TOK_ABS + 1
    bcs @dtok_not_fn

    sec
    sbc #TOK_FREE
    jsr PRINT_FN
    jmp @dtok_loop

@dtok_not_fn:
    ; 5. Multi-character relational operators ($B0 - $B2)
    cmp #TOK_NEQ
    bcc @dtok_not_rel
    cmp #TOK_GTE + 1
    bcs @dtok_not_rel

    sec
    sbc #TOK_NEQ
    jsr PRINT_REL
    jmp @dtok_loop

@dtok_not_rel:
    ; 6. Single-letter variables ($D0 - $E9)
    cmp #TOK_VAR_BASE
    bcc @dtok_not_var
    cmp #TOK_VAR_BASE + 26
    bcs @dtok_not_var

    sec
    sbc #TOK_VAR_BASE
    clc
    adc #'A'
    jsr OUTCHAR
    jmp @dtok_loop

@dtok_not_var:
    ; 7. Other bytes emitted directly
    jsr OUTCHAR
    jmp @dtok_loop

@dtok_end:
    pla
    tay
    pla
    tax
    pla
    rts

; ============================================================================
; Token Printing Helpers
; ============================================================================

PRINT_KW:
    tax
    lda #<PKW_TABLE
    sta SCR_WORK
    lda #>PKW_TABLE
    sta SCR_WORK+1
    txa
    jmp PRINT_INDEXED_TABLE

PRINT_FN:
    tax
    lda #<PFN_TABLE
    sta SCR_WORK
    lda #>PFN_TABLE
    sta SCR_WORK+1
    txa
    jmp PRINT_INDEXED_TABLE

PRINT_REL:
    tax
    lda #<PREL_TABLE
    sta SCR_WORK
    lda #>PREL_TABLE
    sta SCR_WORK+1
    txa
    jmp PRINT_INDEXED_TABLE

PRINT_INDEXED_TABLE:
    tax                 ; X = index
    ; Save SCR_PTR on stack
    lda SCR_PTR
    pha
    lda SCR_PTR+1
    pha

    cpx #0
    beq @print_it

@skip_loop:
    ldy #0
    lda (SCR_WORK), y
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    cmp #0
    bne @skip_loop
    dex
    bne @skip_loop

@print_it:
    lda SCR_WORK
    sta SCR_PTR
    lda SCR_WORK+1
    sta SCR_PTR+1
    jsr PRINT_STR

    ; Restore SCR_PTR
    pla
    sta SCR_PTR+1
    pla
    sta SCR_PTR
    rts

PKW_TABLE:
    .byte "LET ", 0
    .byte "GOTO ", 0
    .byte "GOSUB ", 0
    .byte "PRINT ", 0
    .byte "IF ", 0
    .byte "INPUT ", 0
    .byte "RETURN", 0
    .byte "END", 0
    .byte "LIST", 0
    .byte "RUN", 0
    .byte "NEW", 0
    .byte "EXIT", 0
    .byte "REM ", 0
    .byte "THEN ", 0

PFN_TABLE:
    .byte "FREE", 0
    .byte "RND", 0
    .byte "ABS", 0

PREL_TABLE:
    .byte "<> ", 0
    .byte "<= ", 0
    .byte ">= ", 0
