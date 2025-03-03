; ============================================================================
; PBasic m6502 - Main Entry Point and Bootstrap
; ============================================================================

.segment "BOOT"
    jmp main

.segment "CODE"

.export main

main:
    ; 1. Set Stack Pointer to top of page 1 ($01FF)
    ldx #$FF
    txs

    ; 2. Initialize memory limits (16 KB program space, limit at $8000)
    lda #<PROG_LIMIT
    sta MEM_PROG_LIMIT
    lda #>PROG_LIMIT
    sta MEM_PROG_LIMIT+1

    ; 3. Initial execution mode (REPL mode = 0)
    lda #0
    sta MEM_RUN_FLAG

    ; 4. Default PRNG seed (12345 = $3039)
    lda #<$3039
    sta MEM_RAND_SEED
    lda #>$3039
    sta MEM_RAND_SEED+1

    ; Halt until next stages are hooked (6502 unofficial KIL opcode)
    .byte $02

.segment "VECTORS"
    .word main ; NMI
    .word main ; RESET
    .word main ; IRQ/BRK
