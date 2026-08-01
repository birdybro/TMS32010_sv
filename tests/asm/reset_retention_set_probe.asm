; Original-NMOS TMS32010 physical-reset retention probe, set-pattern case.
;
; Hold BIO high for initial execution. The program exports the complete state
; vector below, restores every destructively observed item, then emits 0x00a1.
; After that marker, hold BIO low, assert RS for at least five complete CLKOUT
; cycles, release RS, and retain BIO low until POST_RESET is selected.
;
; Project-model port-7 sequence if every TI-unlisted register is retained:
;   00a5 0000 0012 0034 ffff 00ff 0000 0055 0000
;   0044 0033 0022 0011 00a1
;   00a5 0000 0012 0034 ffff 00ff 0000 0055 0000
;   0044 0033 0022 0011 00af
;
; Vector order is ACC low/high, AR0, AR1, SST status, P low/high, T low/high,
; stack top through bottom. The post-reset vector has no repository passing
; expectation until an original device is captured. Status word fffd would
; differ only in OQ-003's reserved bit 1 and remains a valid hardware sample.

        .org 0x000
        BIOZ    POST_RESET
        B       INIT

        .org 0x010
INIT:
        DINT
        LDPK    0
        LACK    0xa1
        SACL    9
        LDPK    1
        SACL    9
        LDPK    0

        LACK    0x55
        SACL    10
        LT      10
        MPYK    3

        LACK    0x11
        PUSH
        LACK    0x22
        PUSH
        LACK    0x33
        PUSH
        LACK    0x44
        PUSH

        LARK    AR0,0x12
        LARK    AR1,0x34

        LACK    0x7f
        SACL    12
        LACK    0xff
        ADD     12,8
        SACL    13
        LACK    1
        SACL    14
        LAC     13,15
        ADD     13,15
        ADD     14,15
        ADD     13
        SOVM
        ADD     14              ; set sticky OV with OVM enabled

        LACK    0xa5
        LARP    AR1
        LDPK    1

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
        MPYK    3
        LACK    0x11
        PUSH
        LACK    0x22
        PUSH
        LACK    0x33
        PUSH
        LACK    0x44
        PUSH
        LACK    0xa5
        OUT     9,PA7           ; 0x00a1: state restored, safe to assert RS
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
