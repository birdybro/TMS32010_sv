; Original-NMOS TMS32010 ascending absent-data-write probe for OQ-002.
;
; Addresses 0x90 through 0xff receive unique full-AR sentinels 0xa06f down
; through 0xa000. Port 7 emits marker 0x0041, the 144 valid words in descending
; address order, the 112 absent addresses in ascending order, and marker
; 0x004f. No alias, corruption, or absent-read result is assumed.

        .org 0
        LDPK    0
        ROVM

        LACK    0xa0
        SACL    0x00
        LACK    0x6f
        SACL    0x01
        LAC     0x00,8
        ADD     0x01
        SACL    0x02
        LAR     AR1,0x02        ; AR1 = 0xa06f; low nine bits count down

        ZAC
        LARK    AR0,0x8f
        LARP    AR0
clear:
        SACL    *
        BANZ    clear

        LACK    0x41
        SACL    0x00
        OUT     0x00,PA7
        ZAC
        SACL    0x00            ; restore the complete valid array to zero

        LARK    AR0,0x90
write_absent:
        LARP    AR0
        SAR     AR1,*+,AR1
        BANZ    write_absent

        LARK    AR0,0x8f
        LARP    AR0
scan_valid:
        OUT     *,PA7
        BANZ    scan_valid

        LARK    AR0,0x90
        LARK    AR1,0x6f
read_absent:
        LARP    AR0
        OUT     *+,PA7,AR1
        BANZ    read_absent

        LACK    0x4f
        SACL    0x00            ; evidence scan is already complete
        OUT     0x00,PA7
        NOP
hold:
        B       hold
