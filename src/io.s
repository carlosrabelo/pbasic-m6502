; ============================================================================
; PBasic m6502 - Console Character I/O and Formatted Output Primitives
; ============================================================================

.segment "CODE"

.export INCHAR, OUTCHAR, CHECK_BREAK
.export PRINT_STR, PRINT_CRLF, PRINT_OK, NEG32, PRINT_NUMBER

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

PRINT_STR:
    pha
    txa
    pha
    tya
    pha
    ldy #0
@loop:
    lda (SCR_PTR), y
    beq @done
    jsr OUTCHAR
    iny
    bne @loop
    inc SCR_PTR+1
    jmp @loop
@done:
    pla
    tay
    pla
    tax
    pla
    rts

PRINT_CRLF:
    pha
    lda #10
    jsr OUTCHAR
    pla
    rts

PRINT_OK:
    pha
    lda #<MSG_OK
    sta SCR_PTR
    lda #>MSG_OK
    sta SCR_PTR+1
    jsr PRINT_STR
    pla
    rts

NEG32:
    sec
    lda #0
    sbc SCR_ACC_0
    sta SCR_ACC_0
    lda #0
    sbc SCR_ACC_1
    sta SCR_ACC_1
    lda #0
    sbc SCR_ACC_2
    sta SCR_ACC_2
    lda #0
    sbc SCR_ACC_3
    sta SCR_ACC_3
    rts

PRINT_NUMBER:
    pha
    txa
    pha
    tya
    pha

    ; Check if negative
    lda SCR_ACC_3
    bpl @not_neg
    lda #'-'
    jsr OUTCHAR
    jsr NEG32

@not_neg:
    lda #0
    sta SCR_TMP        ; SCR_TMP = flag: printed at least one non-zero digit
    sta SCR_TMP+1      ; power index * 4 (0, 4, 8, ... 36)

@power_loop:
    ldx #0             ; current digit count = 0

@sub_loop:
    ldy SCR_TMP+1      ; offset in POWERS_OF_10
    sec
    lda SCR_ACC_0
    sbc POWERS_OF_10, y
    sta SCR_WORK_0
    lda SCR_ACC_1
    sbc POWERS_OF_10+1, y
    sta SCR_WORK_1
    lda SCR_ACC_2
    sbc POWERS_OF_10+2, y
    sta SCR_WORK_2
    lda SCR_ACC_3
    sbc POWERS_OF_10+3, y
    sta SCR_WORK_3
    bcc @cannot_sub

    ; Successful subtraction: SCR_ACC = SCR_WORK
    lda SCR_WORK_0
    sta SCR_ACC_0
    lda SCR_WORK_1
    sta SCR_ACC_1
    lda SCR_WORK_2
    sta SCR_ACC_2
    lda SCR_WORK_3
    sta SCR_ACC_3
    inx
    jmp @sub_loop

@cannot_sub:
    ; Digit is in X
    cpx #0
    bne @do_print
    lda SCR_TMP
    bne @do_print
    ; If this is the last power (offset 36), we must print '0'
    lda SCR_TMP+1
    cmp #36
    beq @do_print
    jmp @next_power

@do_print:
    lda #1
    sta SCR_TMP
    txa
    clc
    adc #'0'
    jsr OUTCHAR

@next_power:
    lda SCR_TMP+1
    clc
    adc #4
    sta SCR_TMP+1
    cmp #40
    bcc @power_loop

    pla
    tay
    pla
    tax
    pla
    rts

POWERS_OF_10:
    .byte $00, $CA, $9A, $3B   ; 1,000,000,000 ($3B9ACA00)
    .byte $00, $E1, $F5, $05   ;   100,000,000 ($05F5E100)
    .byte $80, $96, $98, $00   ;    10,000,000 ($00989680)
    .byte $40, $42, $0F, $00   ;     1,000,000 ($000F4240)
    .byte $A0, $86, $01, $00   ;       100,000 ($000186A0)
    .byte $10, $27, $00, $00   ;        10,000 ($00002710)
    .byte $E8, $03, $00, $00   ;         1,000 ($000003E8)
    .byte $64, $00, $00, $00   ;           100 ($00000064)
    .byte $0A, $00, $00, $00   ;            10 ($0000000A)
    .byte $01, $00, $00, $00   ;             1 ($00000001)
