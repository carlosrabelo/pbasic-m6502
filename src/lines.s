; ============================================================================
; PBasic m6502 - Program Line Management & Lookup
; ============================================================================

.segment "CODE"

.export LINE_FIND

; LINE_FIND:
; Input: SCR_NUM = target line number (16-bit)
; Output:
;   If found: A = 1, SCR_PTR points to matching line node
;   If not found: A = 0, SCR_PTR points to insertion point (or sentinel)
LINE_FIND:
    pha
    tya
    pha

    lda #<MEM_PROG_START
    sta SCR_PTR
    lda #>MEM_PROG_START
    sta SCR_PTR+1

@lf_loop:
    ; Read next pointer at (SCR_PTR)
    ldy #0
    lda (SCR_PTR), y
    sta SCR_TMP
    iny
    lda (SCR_PTR), y
    sta SCR_TMP+1

    ; Check if sentinel (next == 0x0000)
    lda SCR_TMP
    ora SCR_TMP+1
    beq @lf_sentinel

    ; Read line number at offset 2
    ldy #2
    lda (SCR_PTR), y
    sta SCR_WORK
    iny
    lda (SCR_PTR), y
    sta SCR_WORK+1

    ; Compare candidate SCR_WORK with target SCR_NUM
    lda SCR_WORK+1
    cmp SCR_NUM+1
    bne :+
    lda SCR_WORK
    cmp SCR_NUM
:
    beq @lf_found
    bcs @lf_greater

    ; Candidate < Target: advance SCR_PTR = next pointer (SCR_TMP)
    lda SCR_TMP
    sta SCR_PTR
    lda SCR_TMP+1
    sta SCR_PTR+1
    jmp @lf_loop

@lf_found:
    pla
    tay
    pla
    lda #1
    rts

@lf_greater:
@lf_sentinel:
    pla
    tay
    pla
    lda #0
    rts
