; Original-NMOS TMS32010 read-only absent-data-select probe for OQ-002.
;
; Port 7 emits marker 0x0031, then 112 (predecessor, absent-read) pairs
; for addresses 0x90 through 0xff with predecessor 0x0000. Marker 0x0032
; separates a second sweep with predecessor 0xffff. Marker 0x003f terminates
; the observation. No absent-read value is assigned a passing expectation.

        .org 0
        LDPK    0
        ROVM

        ZAC
        SACL    0x00            ; controlled zero predecessor
        LACK    1
        SACL    0x05
        ZAC
        SUB     0x05
        SACL    0x01            ; controlled 0xffff predecessor

        LACK    0x31
        SACL    0x02
        LACK    0x32
        SACL    0x03
        LACK    0x3f
        SACL    0x04

        OUT     0x02,PA7
        LARK    AR0,0x90
        LARK    AR1,0x6f
zero_history:
        LARP    AR0
        OUT     0x00,PA7
        OUT     *+,PA7,AR1
        BANZ    zero_history

        OUT     0x03,PA7
        LARK    AR0,0x90
        LARK    AR1,0x6f
one_history:
        LARP    AR0
        OUT     0x01,PA7
        OUT     *+,PA7,AR1
        BANZ    one_history

        OUT     0x04,PA7
        NOP
hold:
        B       hold
