; Project-authored, ROM-free Driver Sound Board I/O smoke program.
; The harness seeds internal RAM and supplies synthetic port responses.

        .org 0
        OUT  0x10,PA0
        IN   0x20,PA1
        OUT  0x11,PA3
        OUT  0x12,PA4
        OUT  0x13,PA5
        OUT  0x14,PA6
        OUT  0x15,PA7
        IN   0x21,PA0
        IN   0x22,PA2
        BIOZ bio_seen
        LACK 0xee
bio_seen:
        LAC  0x20
        NOP
