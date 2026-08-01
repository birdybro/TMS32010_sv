; Original-NMOS TMS32010 indirect-LST ARP-precedence probe.
;
; The fixture deliberately makes the encoded next ARP disagree with status
; word bit 8 in both directions. Port 7 writes are:
;   0x0033, 0x00a0, 0x00b1   memory-word ARP wins both cases
;   0x0033, 0x00a1, 0x00b0   encoded next ARP wins both cases
; Any mixed or different sequence is retained as an observation. The project
; assigns no passing original-silicon result.

.org 0x000
        LDPK    0

        LACK    0x33
        SACL    0x00            ; fixture-armed marker

        LACK    0xa0
        SACL    0x11            ; case A memory-word winner marker
        LACK    0xa1
        SACL    0x12            ; case A encoded-field winner marker

        LACK    0xb1
        SACL    0x21            ; case B memory-word winner marker
        LACK    0xb0
        SACL    0x22            ; case B encoded-field winner marker

        LACK    0
        SACL    0x10            ; status word with ARP bit 8 clear
        LACK    1
        SACL    0x30
        LAC     0x30,8
        SACL    0x20            ; status word with ARP bit 8 set

        OUT     0x00,PA7

CASE_MEMORY_ZERO_ENCODED_ONE:
        LARK    AR0,0x10
        LARK    AR1,0x12
        LARP    0
        LST     *+,1            ; old AR0 -> 0x11; bit8=0 versus next ARP=1
        OUT     *,PA7           ; exports RAM[0x11] or RAM[0x12]

CASE_MEMORY_ONE_ENCODED_ZERO:
        LARK    AR0,0x22
        LARK    AR1,0x20
        LARP    1
        LST     *+,0            ; old AR1 -> 0x21; bit8=1 versus next ARP=0
        OUT     *,PA7           ; exports RAM[0x21] or RAM[0x22]

HOLD:
        B       HOLD
