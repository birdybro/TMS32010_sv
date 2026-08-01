; Synthetic original-TMS32010 data-RAM boundary probe for OQ-014.
; No copyrighted program content is required.

        .org 0
        LDPK 0
        LARP AR0
        LARK AR0,0x8f
        ZAC
clear:
        SACL *
        BANZ clear

        LARK AR0,0x8f
        LACK 0x5a
        SACL *

        LDPK 0
        LACK 3
        SACL 0
        LT 0
        MPYK 5
        LACK 7

        LDPK 1
boundary:
        LTD 0x0f

        LARK AR0,0x8f
scan:
        OUT *,PA7
        BANZ scan

        OUT 0x10,PA7
        NOP
hold:
        B hold
