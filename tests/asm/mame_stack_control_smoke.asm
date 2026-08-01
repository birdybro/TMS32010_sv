; ROM-free MAME architectural-boundary fixture.
; The standalone original-part PUSH/POP pin probe remains separate because
; MAME exposes no bus phases and cannot resolve OQ-016 or ADR-0003.

        .org 0
        LACK 0x55
        PUSH
        NOP
        LACK 0xaa
        POP
        LACK 0x0c
        CALA
        LACK 0x33
        NOP
hold:
        B hold

        .org 0x00c
subroutine:
        LACK 0x77
        RET
