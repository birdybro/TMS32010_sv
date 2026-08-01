; Synthetic original-TMS32010 SUBC dependency-hazard probe for OQ-017.
; The first SACL deliberately violates TI's scheduling prohibition.

        .org 0
        LDPK 0
        LACK 2
        SACL 0
        LACK 5
        SACL 1
        LACK 3
        SACL 2
        ZAC
        SACL 3
        SACL 4

        ZALH 0
        ADDS 1
violating_subc:
        SUBC 2
        SACL 3
        NOP

        ZALH 0
        ADDS 1
legal_subc:
        SUBC 2
        NOP
        SACL 4

        OUT 3,PA7
        NOP
        OUT 4,PA7
        NOP
hold:
        B hold
