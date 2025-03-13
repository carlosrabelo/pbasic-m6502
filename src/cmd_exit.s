; ============================================================================
; PBasic m6502 - EXIT Statement Execution
; ============================================================================

.segment "CODE"

.export DO_EXIT

DO_EXIT:
    .byte $02            ; 6502 KIL / JAM opcode: terminates mojave emulator
    rts
