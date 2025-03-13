; ============================================================================
; PBasic m6502 - RUN Command and Program Execution Loop
; ============================================================================

.segment "CODE"

.export DO_RUN, RUN_NEXT, RUN_END

DO_RUN:
    ; 1. Check if program is empty: next pointer at MEM_PROG_START
    lda MEM_PROG_START
    ora MEM_PROG_START+1
    bne @drun_start

    lda #<MSG_NO_PROGRAM
    sta SCR_PTR
    lda #>MSG_NO_PROGRAM
    sta SCR_PTR+1
    jsr PRINT_STR
    jmp REPL

@drun_start:
    ; Reset subroutine stack pointer
    lda #0
    sta MEM_GOSUB_SP

    ; Set MEM_RUN_FLAG = 1
    lda #1
    sta MEM_RUN_FLAG

    ; Initialize MEM_LINE_PTR to MEM_PROG_START
    lda #<MEM_PROG_START
    sta MEM_LINE_PTR
    lda #>MEM_PROG_START
    sta MEM_LINE_PTR+1

    ; MEM_TOKEN_PTR = MEM_PROG_START + 4
    lda #<(MEM_PROG_START + 4)
    sta MEM_TOKEN_PTR
    lda #>(MEM_PROG_START + 4)
    sta MEM_TOKEN_PTR+1

    jmp REPL_DISPATCH

RUN_NEXT:
    ; Check break condition
    jsr CHECK_BREAK
    cmp #0
    beq @rn_no_break

    ; Break detected
    lda #0
    sta MEM_RUN_FLAG
    jmp REPL

@rn_no_break:
    ; Read next pointer at offset 0 of MEM_LINE_PTR
    ldy #0
    lda (MEM_LINE_PTR), y
    sta SCR_PTR
    iny
    lda (MEM_LINE_PTR), y
    sta SCR_PTR+1

    ; If next pointer is zero, end of program
    lda SCR_PTR
    ora SCR_PTR+1
    beq RUN_END

    ; Update MEM_LINE_PTR = SCR_PTR
    lda SCR_PTR
    sta MEM_LINE_PTR
    lda SCR_PTR+1
    sta MEM_LINE_PTR+1

    ; Update MEM_TOKEN_PTR = SCR_PTR + 4
    clc
    lda SCR_PTR
    adc #4
    sta MEM_TOKEN_PTR
    lda SCR_PTR+1
    adc #0
    sta MEM_TOKEN_PTR+1

    jmp REPL_DISPATCH

RUN_END:
    lda #0
    sta MEM_RUN_FLAG
    jmp REPL
