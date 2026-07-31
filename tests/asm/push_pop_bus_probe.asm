; Synthetic original-TMS32010 pin-trace fixture for OQ-016.
; No copyrighted program content is required.

        .org 0
        LACK 0x55
        PUSH
        NOP
        LACK 0xaa
        POP
        NOP
hold:
        B hold
