; ============================================================================
; PBasic m6502 - Program Memory Management & Allocation
; ============================================================================

.segment "CODE"

.export PROG_INIT, MEM_OPEN_HOLE, MEM_CLOSE_HOLE, FIX_NEXT_ADD, FIX_NEXT_SUB

PROG_INIT:
    pha
    ; 1. Initialize sentinel: write 0x0000 at MEM_PROG_START
    lda #0
    sta MEM_PROG_START
    sta MEM_PROG_START+1

    ; 2. Set MEM_PROG_END = MEM_PROG_START + 2 ($4002)
    lda #<(MEM_PROG_START + 2)
    sta MEM_PROG_END
    lda #>(MEM_PROG_START + 2)
    sta MEM_PROG_END+1

    ; 3. Set MEM_PROG_LIMIT = $8000
    lda #<PROG_LIMIT
    sta MEM_PROG_LIMIT
    lda #>PROG_LIMIT
    sta MEM_PROG_LIMIT+1

    pla
    rts

; ============================================================================
; Dynamic Memory Block Shifting
; ============================================================================

; MEM_OPEN_HOLE:
; Input: SCR_INS = target address, SCR_LEN = byte count
; Output: A = 1 on success, A = 0 on overflow
MEM_OPEN_HOLE:
    pha
    txa
    pha
    tya
    pha

    lda SCR_PTR
    sta SCR_INS
    lda SCR_PTR+1
    sta SCR_INS+1

    ; 1. Check if MEM_PROG_END + SCR_LEN > MEM_PROG_LIMIT
    clc
    lda MEM_PROG_END
    adc SCR_LEN
    sta SCR_WORK
    lda MEM_PROG_END+1
    adc SCR_LEN+1
    sta SCR_WORK+1

    ; Compare SCR_WORK with MEM_PROG_LIMIT
    lda SCR_WORK+1
    cmp MEM_PROG_LIMIT+1
    bne :+
    lda SCR_WORK
    cmp MEM_PROG_LIMIT
:
    bcc @moh_ok
    beq @moh_ok

    ; Overflow!
    pla
    tay
    pla
    tax
    pla
    lda #0
    rts

@moh_ok:
    ; 2. Bytes to shift = MEM_PROG_END - SCR_INS
    sec
    lda MEM_PROG_END
    sbc SCR_INS
    sta SCR_NLEN
    lda MEM_PROG_END+1
    sbc SCR_INS+1
    sta SCR_NLEN+1

    ; If shift count == 0, skip copying
    lda SCR_NLEN
    ora SCR_NLEN+1
    beq @moh_update_end

    ; 3. Source SCR_WORK = MEM_PROG_END - 1
    sec
    lda MEM_PROG_END
    sbc #1
    sta SCR_WORK
    lda MEM_PROG_END+1
    sbc #0
    sta SCR_WORK+1

    ; Destination SCR_WORK_2 = new MEM_PROG_END - 1 = (MEM_PROG_END + SCR_LEN) - 1
    clc
    lda MEM_PROG_END
    adc SCR_LEN
    sta SCR_WORK_2
    lda MEM_PROG_END+1
    adc SCR_LEN+1
    sta SCR_WORK_2+1

    sec
    lda SCR_WORK_2
    sbc #1
    sta SCR_WORK_2
    lda SCR_WORK_2+1
    sbc #0
    sta SCR_WORK_2+1

    ; 4. Copy loop rightwards
@moh_copy_loop:
    ldy #0
    lda (SCR_WORK), y
    sta (SCR_WORK_2), y

    ; Decrement SCR_WORK
    lda SCR_WORK
    bne :+
    dec SCR_WORK+1
:
    dec SCR_WORK

    ; Decrement SCR_WORK_2
    lda SCR_WORK_2
    bne :+
    dec SCR_WORK_2+1
:
    dec SCR_WORK_2

    ; Decrement SCR_NLEN
    lda SCR_NLEN
    bne :+
    dec SCR_NLEN+1
:
    dec SCR_NLEN

    lda SCR_NLEN
    ora SCR_NLEN+1
    bne @moh_copy_loop

@moh_update_end:
    clc
    lda MEM_PROG_END
    adc SCR_LEN
    sta MEM_PROG_END
    lda MEM_PROG_END+1
    adc SCR_LEN+1
    sta MEM_PROG_END+1

    pla
    tay
    pla
    tax
    pla
    lda #1
    rts

; MEM_CLOSE_HOLE:
; Input: SCR_INS = target address, SCR_LEN = byte count to remove
MEM_CLOSE_HOLE:
    pha
    txa
    pha
    tya
    pha

    lda SCR_PTR
    sta SCR_INS
    lda SCR_PTR+1
    sta SCR_INS+1

    ; 1. Source SCR_WORK = SCR_INS + SCR_LEN
    clc
    lda SCR_INS
    adc SCR_LEN
    sta SCR_WORK
    lda SCR_INS+1
    adc SCR_LEN+1
    sta SCR_WORK+1

    ; 2. Destination SCR_WORK_2 = SCR_INS
    lda SCR_INS
    sta SCR_WORK_2
    lda SCR_INS+1
    sta SCR_WORK_2+1

    ; 3. Count SCR_NLEN = MEM_PROG_END - SCR_WORK
    sec
    lda MEM_PROG_END
    sbc SCR_WORK
    sta SCR_NLEN
    lda MEM_PROG_END+1
    sbc SCR_WORK+1
    sta SCR_NLEN+1

    lda SCR_NLEN
    ora SCR_NLEN+1
    beq @mch_update_end

    ; 4. Copy loop leftwards
@mch_copy_loop:
    ldy #0
    lda (SCR_WORK), y
    sta (SCR_WORK_2), y

    ; Increment SCR_WORK
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    ; Increment SCR_WORK_2
    inc SCR_WORK_2
    bne :+
    inc SCR_WORK_2+1
:
    ; Decrement SCR_NLEN
    lda SCR_NLEN
    bne :+
    dec SCR_NLEN+1
:
    dec SCR_NLEN

    lda SCR_NLEN
    ora SCR_NLEN+1
    bne @mch_copy_loop

@mch_update_end:
    sec
    lda MEM_PROG_END
    sbc SCR_LEN
    sta MEM_PROG_END
    lda MEM_PROG_END+1
    sbc SCR_LEN+1
    sta MEM_PROG_END+1

    pla
    tay
    pla
    tax
    pla
    rts

; ============================================================================
; Pointer Fixups
; ============================================================================

; FIX_NEXT_ADD:
; Input: SCR_TMP = threshold address, SCR_LEN = delta
FIX_NEXT_ADD:
    pha
    txa
    pha
    tya
    pha

    lda SCR_PTR
    sta SCR_TMP
    lda SCR_PTR+1
    sta SCR_TMP+1

    lda #<MEM_PROG_START
    sta SCR_WORK
    lda #>MEM_PROG_START
    sta SCR_WORK+1

@fna_loop:
    ; Read next pointer at (SCR_WORK)
    ldy #0
    lda (SCR_WORK), y
    sta SCR_NUM
    iny
    lda (SCR_WORK), y
    sta SCR_NUM+1

    ; Check sentinel
    lda SCR_NUM
    ora SCR_NUM+1
    beq @fna_done

    ; Compare SCR_NUM with threshold SCR_TMP
    lda SCR_NUM+1
    cmp SCR_TMP+1
    bne :+
    lda SCR_NUM
    cmp SCR_TMP
:
    bcc @fna_skip

    ; SCR_NUM >= SCR_TMP -> add delta SCR_LEN
    clc
    lda SCR_NUM
    adc SCR_LEN
    ldy #0
    sta (SCR_WORK), y
    lda SCR_NUM+1
    adc SCR_LEN+1
    iny
    sta (SCR_WORK), y

@fna_skip:
    ; Advance SCR_WORK to next node (using old SCR_NUM)
    lda SCR_NUM
    sta SCR_WORK
    lda SCR_NUM+1
    sta SCR_WORK+1
    jmp @fna_loop

@fna_done:
    pla
    tay
    pla
    tax
    pla
    rts

; FIX_NEXT_SUB:
; Input: SCR_TMP = threshold address, SCR_LEN = delta
FIX_NEXT_SUB:
    pha
    txa
    pha
    tya
    pha

    lda SCR_PTR
    sta SCR_TMP
    lda SCR_PTR+1
    sta SCR_TMP+1

    lda #<MEM_PROG_START
    sta SCR_WORK
    lda #>MEM_PROG_START
    sta SCR_WORK+1

@fns_loop:
    ; Read next pointer at (SCR_WORK)
    ldy #0
    lda (SCR_WORK), y
    sta SCR_NUM
    iny
    lda (SCR_WORK), y
    sta SCR_NUM+1

    ; Check sentinel
    lda SCR_NUM
    ora SCR_NUM+1
    beq @fns_done

    ; Compare SCR_NUM with threshold SCR_TMP (strictly greater: SCR_NUM > SCR_TMP)
    lda SCR_NUM+1
    cmp SCR_TMP+1
    bne :+
    lda SCR_NUM
    cmp SCR_TMP
:
    bcc @fns_skip
    beq @fns_skip

    ; SCR_NUM > SCR_TMP -> subtract delta SCR_LEN
    sec
    lda SCR_NUM
    sbc SCR_LEN
    ldy #0
    sta (SCR_WORK), y
    lda SCR_NUM+1
    sbc SCR_LEN+1
    iny
    sta (SCR_WORK), y

@fns_skip:
    ; Advance SCR_WORK to next node (using old SCR_NUM)
    lda SCR_NUM
    sta SCR_WORK
    lda SCR_NUM+1
    sta SCR_WORK+1
    jmp @fns_loop

@fns_done:
    pla
    tay
    pla
    tax
    pla
    rts
