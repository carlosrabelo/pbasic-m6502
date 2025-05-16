; ============================================================================
; PBasic m6502 - Bytecode Tokenizer Engine and Keyword Matching
; ============================================================================

.segment "CODE"

.export TOKENIZE, MATCH_KEYWORD, TRY_MATCH_KEYWORD, PARSE_NUMBER

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
    bne @tok_check_keyword
    inc SCR_PTR
    bne @tok_loop
    inc SCR_PTR+1
    jmp @tok_loop

@tok_check_keyword:
    jsr TRY_MATCH_KEYWORD
    cmp #0
    beq @tok_check_number

    ; Keyword matched! Token in A
    tax
    ldy #0
    txa
    sta (SCR_PTR2), y
    inc SCR_PTR2
    bne :+
    inc SCR_PTR2+1
:
    ; Check if REM ($8C)
    cpx #TOK_REM
    bne @tok_loop

    ; REM: copy all remaining characters until 0x00
@tok_rem_copy:
    ldy #0
    lda (SCR_PTR), y
    beq @tok_end
    sta (SCR_PTR2), y
    inc SCR_PTR
    bne :+
    inc SCR_PTR+1
:
    inc SCR_PTR2
    bne @tok_rem_copy
    inc SCR_PTR2+1
    jmp @tok_rem_copy

@tok_check_number:
    ldy #0
    lda (SCR_PTR), y
    cmp #'0'
    bcc @tok_fallback
    cmp #'9'+1
    bcs @tok_fallback

    jsr PARSE_NUMBER
    jmp @tok_loop

@tok_fallback:
    ; Default: emit character directly to token buffer
    ldy #0
    lda (SCR_PTR), y
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
    ldy #0
    lda #0
    sta (SCR_PTR2), y
    pla
    tay
    pla
    tax
    pla
    rts

; ============================================================================
; Keyword Matching Primitives
; ============================================================================

TRY_MATCH_KEYWORD:
    pha
    txa
    pha
    tya
    pha

    lda #<KEYWORD_TABLE
    sta SCR_WORK
    lda #>KEYWORD_TABLE
    sta SCR_WORK+1

@tmk_table_loop:
    ldy #0
    lda (SCR_WORK), y
    beq @tmk_no_match
    sta SCR_WORK_2      ; Save token in SCR_WORK_2

    ; Advance SCR_WORK past token byte
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    jsr MATCH_KEYWORD
    cmp #0
    bne @tmk_found

    ; Skip to next entry in table: find null terminator
@tmk_skip_str:
    ldy #0
    lda (SCR_WORK), y
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    cmp #0
    bne @tmk_skip_str
    jmp @tmk_table_loop

@tmk_found:
    pla
    tay
    pla
    tax
    pla
    lda SCR_WORK_2      ; Return token in A
    rts

@tmk_no_match:
    pla
    tay
    pla
    tax
    pla
    lda #0
    rts

; MATCH_KEYWORD: Compares string at SCR_PTR against SCR_WORK
; Returns A = 1 (and advances SCR_PTR) if matched, A = 0 if not matched.
MATCH_KEYWORD:
    pha
    tya
    pha
    ldy #0

@mk_loop:
    lda (SCR_WORK), y
    beq @mk_matched_word
    cmp (SCR_PTR), y
    bne @mk_failed
    iny
    jmp @mk_loop

@mk_matched_word:
    ; Boundary check: next character in input must NOT be 'A'..'Z'
    lda (SCR_PTR), y
    cmp #'A'
    bcc @mk_success
    cmp #'Z'+1
    bcc @mk_failed

@mk_success:
    ; Advance SCR_PTR by Y
    tya
    clc
    adc SCR_PTR
    sta SCR_PTR
    bcc :+
    inc SCR_PTR+1
:
    pla
    tay
    pla
    lda #1
    rts

@mk_failed:
    pla
    tay
    pla
    lda #0
    rts

KEYWORD_TABLE:
    .byte TOK_LET,   "LET", 0
    .byte TOK_GOTO,  "GOTO", 0
    .byte TOK_GOSUB, "GOSUB", 0
    .byte TOK_PRINT, "PRINT", 0
    .byte TOK_IF,    "IF", 0
    .byte TOK_INPUT, "INPUT", 0
    .byte TOK_RETURN,"RETURN", 0
    .byte TOK_END,   "END", 0
    .byte TOK_LIST,  "LIST", 0
    .byte TOK_RUN,   "RUN", 0
    .byte TOK_NEW,   "NEW", 0
    .byte TOK_EXIT,  "EXIT", 0
    .byte TOK_REM,   "REM", 0
    .byte TOK_THEN,  "THEN", 0
    .byte TOK_FREE,  "FREE", 0
    .byte TOK_RND,   "RND", 0
    .byte TOK_ABS,   "ABS", 0
    .byte 0

PARSE_NUMBER:
    pha
    txa
    pha
    tya
    pha

    ; 1. Emit TOK_NUMBER ($C0)
    ldy #0
    lda #TOK_NUMBER
    sta (SCR_PTR2), y
    inc SCR_PTR2
    bne :+
    inc SCR_PTR2+1
:
    ; 2. Initialize 16-bit accumulator SCR_NUM = 0
    lda #0
    sta SCR_NUM
    sta SCR_NUM+1

@pn_loop:
    ldy #0
    lda (SCR_PTR), y
    cmp #'0'
    bcc @pn_done
    cmp #'9'+1
    bcs @pn_done

    sec
    sbc #'0'
    sta SCR_WORK_3     ; digit

    ; SCR_TMP = SCR_NUM * 2
    lda SCR_NUM
    asl a
    sta SCR_TMP
    lda SCR_NUM+1
    rol a
    sta SCR_TMP+1

    ; SCR_NUM = SCR_NUM * 8
    asl SCR_NUM
    rol SCR_NUM+1
    asl SCR_NUM
    rol SCR_NUM+1
    asl SCR_NUM
    rol SCR_NUM+1

    ; SCR_NUM = (SCR_NUM * 8) + (SCR_TMP * 2) = * 10
    clc
    lda SCR_NUM
    adc SCR_TMP
    sta SCR_NUM
    lda SCR_NUM+1
    adc SCR_TMP+1
    sta SCR_NUM+1

    ; SCR_NUM = SCR_NUM + digit
    clc
    lda SCR_NUM
    adc SCR_WORK_3
    sta SCR_NUM
    bcc :+
    inc SCR_NUM+1
:
    inc SCR_PTR
    bne @pn_loop
    inc SCR_PTR+1
    jmp @pn_loop

@pn_done:
    ; 3. Emit 16-bit word in little-endian order (<lo> <hi>)
    ldy #0
    lda SCR_NUM
    sta (SCR_PTR2), y
    inc SCR_PTR2
    bne :+
    inc SCR_PTR2+1
:
    lda SCR_NUM+1
    sta (SCR_PTR2), y
    inc SCR_PTR2
    bne :+
    inc SCR_PTR2+1
:
    pla
    tay
    pla
    tax
    pla
    rts

