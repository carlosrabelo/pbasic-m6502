; ============================================================================
; PBasic m6502 - LIST Command Handler
; ============================================================================

.segment "CODE"

.export LIST, DO_LIST

LIST:
DO_LIST:
    pha
    txa
    pha
    tya
    pha

    lda #<MEM_PROG_START
    sta SCR_BODY
    lda #>MEM_PROG_START
    sta SCR_BODY+1

@list_loop:
    ; Read next pointer at (SCR_BODY)
    ldy #0
    lda (SCR_BODY), y
    sta SCR_PTR2
    iny
    lda (SCR_BODY), y
    sta SCR_PTR2+1

    ; Check if sentinel (0x0000)
    lda SCR_PTR2
    ora SCR_PTR2+1
    beq @list_done

    ; 1. Print line number at SCR_BODY + 2 in decimal
    ldy #2
    lda (SCR_BODY), y
    sta SCR_ACC_0
    iny
    lda (SCR_BODY), y
    sta SCR_ACC_1
    lda #0
    sta SCR_ACC_2
    sta SCR_ACC_3
    jsr PRINT_NUMBER

    ; 2. Print space separator
    lda #' '
    jsr OUTCHAR

    ; 3. Call PRINT_TOKENS with pointer to token body at SCR_BODY + 4
    clc
    lda SCR_BODY
    adc #4
    sta SCR_PTR
    lda SCR_BODY+1
    adc #0
    sta SCR_PTR+1
    jsr PRINT_TOKENS

    ; 4. Print newline
    jsr PRINT_CRLF

    ; Advance to next line node (SCR_BODY = SCR_PTR2)
    lda SCR_PTR2
    sta SCR_BODY
    lda SCR_PTR2+1
    sta SCR_BODY+1
    jmp @list_loop

@list_done:
    pla
    tay
    pla
    tax
    pla
    rts
