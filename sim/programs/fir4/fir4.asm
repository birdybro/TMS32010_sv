; Project-authored synthetic four-tap Q15 FIR kernel.
; Coefficients and samples are seeded by the test harness; no TI example
; source or copyrighted program content is reproduced here.

        .org 0
        ZAC
        LT   0x23
        MPY  0x13
        LTD  0x22
        MPY  0x12
        LTD  0x21
        MPY  0x11
        LTD  0x20
        MPY  0x10
        APAC
        SACH 0x30,1
        NOP
