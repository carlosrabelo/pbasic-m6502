; ============================================================================
; PBasic m6502 - Program Line Management & Lookup
; ============================================================================

.segment "CODE"

.export LINE_FIND, TOKEN_LEN, NODE_LEN, LINE_STORE

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

; ============================================================================
; Node and Token Length Calculation
; ============================================================================

; TOKEN_LEN:
; Input: SCR_WORK = pointer to token stream start
; Output: SCR_LEN = byte count including terminating 0x00
TOKEN_LEN:
    pha
    txa
    pha
    tya
    pha

    lda #0
    sta SCR_LEN
    sta SCR_LEN+1

@tl_loop:
    ldy #0
    lda (SCR_WORK), y
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    inc SCR_LEN
    bne :+
    inc SCR_LEN+1
:
    cmp #0
    beq @tl_done

    cmp #TOK_NUMBER
    bne @tl_not_num

    ; Skip 2 bytes of number payload
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    inc SCR_LEN
    bne :+
    inc SCR_LEN+1
:
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    inc SCR_LEN
    bne :+
    inc SCR_LEN+1
:
    jmp @tl_loop

@tl_not_num:
    cmp #TOK_STRING
    beq @tl_str_loop
    jmp @tl_loop

@tl_str_loop:
    ldy #0
    lda (SCR_WORK), y
    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    inc SCR_LEN
    bne :+
    inc SCR_LEN+1
:
    cmp #0
    beq @tl_done
    cmp #TOK_STRING
    bne @tl_str_loop
    jmp @tl_loop

@tl_done:
    pla
    tay
    pla
    tax
    pla
    rts

; NODE_LEN:
; Input: SCR_WORK = pointer to token stream start
; Output: SCR_LEN = total node size (4-byte header + token length)
NODE_LEN:
    jsr TOKEN_LEN
    clc
    lda SCR_LEN
    adc #4
    sta SCR_LEN
    bcc :+
    inc SCR_LEN+1
:
    rts

; ============================================================================
; Line Deletion Helper
; ============================================================================

; DELETE_NODE_AT_PTR:
; Input: SCR_PTR = address of node to delete
DELETE_NODE_AT_PTR:
    pha
    txa
    pha
    tya
    pha

    ; Compute NODE_LEN for node at SCR_PTR (tokens start at SCR_PTR + 4)
    clc
    lda SCR_PTR
    adc #4
    sta SCR_WORK
    lda SCR_PTR+1
    adc #0
    sta SCR_WORK+1

    jsr NODE_LEN
    ; SCR_LEN now holds total node size; save to SCR_NLEN
    lda SCR_LEN
    sta SCR_NLEN
    lda SCR_LEN+1
    sta SCR_NLEN+1

    ; Adjust following pointers: FIX_NEXT_SUB(SCR_PTR, SCR_LEN)
    jsr FIX_NEXT_SUB

    ; Close hole: MEM_CLOSE_HOLE(SCR_PTR, SCR_LEN)
    jsr MEM_CLOSE_HOLE

    pla
    tay
    pla
    tax
    pla
    rts

; ============================================================================
; Line Storage Engine
; ============================================================================

LINE_STORE:
    pha
    txa
    pha
    tya
    pha

    ; 1. Extract 16-bit line number from MEM_TOKEN_BUF + 1 into SCR_NUM
    lda MEM_TOKEN_BUF + 1
    sta SCR_NUM
    lda MEM_TOKEN_BUF + 2
    sta SCR_NUM + 1

    ; 2. Check if token stream at offset 3 is empty (0x00)
    lda MEM_TOKEN_BUF + 3
    bne @ls_insert

    ; Empty line -> delete existing line
    jsr LINE_FIND
    cmp #0
    bne :+
    jmp @ls_done
:
    jsr DELETE_NODE_AT_PTR
    jmp @ls_done

@ls_insert:
    ; If line already exists, delete old line first
    jsr LINE_FIND
    cmp #0
    beq @ls_find_ins
    jsr DELETE_NODE_AT_PTR

@ls_find_ins:
    ; Recalculate insertion point
    jsr LINE_FIND
    ; SCR_PTR is now the insertion point; save to SCR_INS
    lda SCR_PTR
    sta SCR_INS
    lda SCR_PTR+1
    sta SCR_INS+1

    ; Calculate node length (tokens start at MEM_TOKEN_BUF + 3)
    lda #<(MEM_TOKEN_BUF + 3)
    sta SCR_WORK
    lda #>(MEM_TOKEN_BUF + 3)
    sta SCR_WORK+1
    jsr NODE_LEN
    ; Save node length to SCR_NLEN
    lda SCR_LEN
    sta SCR_NLEN
    lda SCR_LEN+1
    sta SCR_NLEN+1

    ; Check capacity: MEM_PROG_END + SCR_NLEN > MEM_PROG_LIMIT
    clc
    lda MEM_PROG_END
    adc SCR_NLEN
    sta SCR_WORK
    lda MEM_PROG_END+1
    adc SCR_NLEN+1
    sta SCR_WORK+1

    ; Compare SCR_WORK with MEM_PROG_LIMIT
    lda SCR_WORK+1
    cmp MEM_PROG_LIMIT+1
    bne :+
    lda SCR_WORK
    cmp MEM_PROG_LIMIT
:
    bcc @ls_cap_ok
    beq @ls_cap_ok

    ; Out of memory!
    lda #<MSG_OUT_OF_MEM
    sta SCR_PTR
    lda #>MSG_OUT_OF_MEM
    sta SCR_PTR+1
    jsr PRINT_STR
    jmp @ls_done

@ls_cap_ok:
    ; Adjust successor pointers: FIX_NEXT_ADD(SCR_INS, SCR_NLEN)
    lda SCR_INS
    sta SCR_PTR
    lda SCR_INS+1
    sta SCR_PTR+1
    lda SCR_NLEN
    sta SCR_LEN
    lda SCR_NLEN+1
    sta SCR_LEN+1
    jsr FIX_NEXT_ADD

    ; Open hole at SCR_INS: MEM_OPEN_HOLE(SCR_INS, SCR_NLEN)
    lda SCR_INS
    sta SCR_PTR
    lda SCR_INS+1
    sta SCR_PTR+1
    lda SCR_NLEN
    sta SCR_LEN
    lda SCR_NLEN+1
    sta SCR_LEN+1
    jsr MEM_OPEN_HOLE

    ; Write node at (SCR_INS):
    ; 1. Next pointer = SCR_INS + SCR_NLEN
    clc
    lda SCR_INS
    adc SCR_NLEN
    sta SCR_WORK
    lda SCR_INS+1
    adc SCR_NLEN+1
    sta SCR_WORK+1

    ldy #0
    lda SCR_WORK
    sta (SCR_INS), y
    iny
    lda SCR_WORK+1
    sta (SCR_INS), y

    ; 2. Line number (16-bit LE)
    iny
    lda SCR_NUM
    sta (SCR_INS), y
    iny
    lda SCR_NUM+1
    sta (SCR_INS), y

    ; 3. Token stream bytes (SCR_NLEN - 4 bytes)
    sec
    lda SCR_NLEN
    sbc #4
    sta SCR_TLEN
    lda SCR_NLEN+1
    sbc #0
    sta SCR_TLEN+1

    lda #<(MEM_TOKEN_BUF + 3)
    sta SCR_WORK
    lda #>(MEM_TOKEN_BUF + 3)
    sta SCR_WORK+1

    clc
    lda SCR_INS
    adc #4
    sta SCR_WORK_2
    lda SCR_INS+1
    adc #0
    sta SCR_WORK_2+1

@ls_copy_tok:
    lda SCR_TLEN
    ora SCR_TLEN+1
    beq @ls_done

    ldy #0
    lda (SCR_WORK), y
    sta (SCR_WORK_2), y

    inc SCR_WORK
    bne :+
    inc SCR_WORK+1
:
    inc SCR_WORK_2
    bne :+
    inc SCR_WORK_2+1
:
    lda SCR_TLEN
    bne :+
    dec SCR_TLEN+1
:
    dec SCR_TLEN

    jmp @ls_copy_tok

@ls_done:
    pla
    tay
    pla
    tax
    pla
    rts
