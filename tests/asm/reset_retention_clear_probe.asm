; Original-NMOS TMS32010 physical-reset retention probe, clear-pattern case.
;
; Hold BIO high for initial execution. The program exports the complete state
; vector below, restores every destructively observed item, then emits 0x00a2.
; After that marker, hold BIO low, assert RS for at least five complete CLKOUT
; cycles, release RS, and retain BIO low until POST_RESET is selected.
;
; Project-model port-7 sequence if every TI-unlisted register is retained:
;   003c 0000 0056 0078 3efe 00aa 0000 0022 0000
;   0088 0077 0066 0055 00a2
;   003c 0000 0056 0078 3efe 00aa 0000 0022 0000
;   0088 0077 0066 0055 00af
;
; This complements the set-pattern case: OV, OVM, ARP, and DP are all zero,
; while every multi-bit register uses a second nonzero value. Status word 3efc
; would differ only in OQ-003's reserved bit 1 and remains a valid sample.

        .org 0x000
        BIOZ    POST_RESET
        B       INIT

        .org 0x010
INIT:
        DINT
        LDPK    0
        LACK    0xa2
        SACL    9
        LDPK    1
        SACL    9
        LDPK    0

        LACK    0x22
        SACL    10
        LT      10
        MPYK    5

        LACK    0x55
        PUSH
        LACK    0x66
        PUSH
        LACK    0x77
        PUSH
        LACK    0x88
        PUSH

        LARK    AR0,0x56
        LARK    AR1,0x78
        LACK    0
        SACL    11
        LST     11              ; clear OV, OVM, ARP, and DP; preserve INTM
        ROVM
        LACK    0x3c

; Capture the pre-reset vector, then reconstruct P, stack, ACC, and status.
        SST     0
        LDPK    0
        SACL    0
        SACH    1,0
        SAR     AR0,2
        SAR     AR1,3
        OUT     0,PA7
        OUT     1,PA7
        OUT     2,PA7
        OUT     3,PA7
        LDPK    1
        OUT     0,PA7
        PAC
        LDPK    0
        SACL    4
        SACH    5,0
        OUT     4,PA7
        OUT     5,PA7
        MPYK    1
        PAC
        SACL    6
        SACH    7,0
        OUT     6,PA7
        OUT     7,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7

        LDPK    1
        LST     0
        MPYK    5
        LACK    0x55
        PUSH
        LACK    0x66
        PUSH
        LACK    0x77
        PUSH
        LACK    0x88
        PUSH
        LACK    0x3c
        OUT     9,PA7           ; 0x00a2: state restored, safe to assert RS
ARMED:
        B       ARMED

; BIO alone chooses this path after PC is documented to reset to zero. SST is
; first, so DP/ARP/OV/OVM are captured before LDPK establishes scratch page 0.
        .org 0x100
POST_RESET:
        SST     0
        LDPK    0
        SACL    0
        SACH    1,0
        SAR     AR0,2
        SAR     AR1,3
        OUT     0,PA7
        OUT     1,PA7
        OUT     2,PA7
        OUT     3,PA7
        LDPK    1
        OUT     0,PA7
        PAC
        LDPK    0
        SACL    4
        SACH    5,0
        OUT     4,PA7
        OUT     5,PA7
        MPYK    1
        PAC
        SACL    6
        SACH    7,0
        OUT     6,PA7
        OUT     7,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7
        POP
        SACL    8
        OUT     8,PA7
        LACK    0xaf
        SACL    12
        OUT     12,PA7
HOLD:
        B       HOLD
