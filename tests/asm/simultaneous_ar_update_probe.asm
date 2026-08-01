; Original-NMOS TMS32010 simultaneous INC/DEC control probe.
;
; The raw 0x68b8 word is the indirect MAR pattern with both control bits set,
; reserved bits clear, ARP preserved, and no assembler mnemonic assigned.
; Port 7 writes are:
;   0x0033, 0x0000, 0x01ff   no net auxiliary-register update
;   0x0033, 0x0001, 0x0000   increment has priority
;   0x0033, 0x01ff, 0x01fe   decrement has priority
; Any other sequence or missing marker is retained as an observation. The
; project assigns no passing original-silicon result.

.org 0x000
        LDPK    0

        LACK    0x33
        SACL    0x00            ; fixture-armed marker

        LACK    1
        SACL    0x10
        LACK    0xff
        SACL    0x11
        LAC     0x10,8
        ADD     0x11
        SACL    0x12            ; RAM[0x12] = 0x01ff

        OUT     0x00,PA7

CASE_ZERO:
        LARK    AR0,0
        LARP    0
        .word   0x68b8          ; forced indirect MAR with INC=DEC=1
        SAR     AR0,0x20
        OUT     0x20,PA7

CASE_ONE_FF:
        LAR     AR0,0x12
        LARP    0
        .word   0x68b8          ; repeat across the nine-bit wrap boundary
        SAR     AR0,0x21
        OUT     0x21,PA7

HOLD:
        B       HOLD
