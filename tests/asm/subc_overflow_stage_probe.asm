; Synthetic original-TMS32010 SUBC overflow-stage probe for OQ-018.
; Both SUBC instances obey TI's required ACC-free successor rule.

        .org 0
        LDPK 0
        LARP 0
        ZAC
        SACL 0
        LACK 1
        SACL 1
        ZAC
        SUBS 1
        SACL 2
        LACK 0x80
        SACL 3
        LAC 3,8
        SACL 4
        LACK 0x40
        SACL 5
        LAC 5,8
        SACL 6

        ZALH 4
        SOVM
intermediate_only:
        SUBC 2
        NOP
        SST 0

        LST 0
        ZALH 6
        SOVM
final_shift_only:
        SUBC 0
        NOP
        SST 1

        LDPK 1
        OUT 0,PA7
        NOP
        OUT 1,PA7
        NOP
hold:
        B hold
