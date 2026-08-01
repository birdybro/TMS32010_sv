; Original-NMOS TMS32010 DINT/interrupt-entry race probe.
;
; Supply a one-CLKOUT active-low INT pulse during the program fetch labeled
; ARM_WINDOW, meeting the documented setup time. Original Figure 2-12 then
; places DINT in the already-fetched N+1 execution slot while N+2 is fetched.
;
; Port 7 marker order:
;   0x0033               fixture armed
;   0x0022                         DINT canceled entry; request remains masked
;   0x001c, 0x0011, then 0x0022    original Figure 2-12 entry won; N+2 stacked
;   0x001b, 0x0011, then 0x0022    earlier entry stacked N+1; DINT runs on RET
; Any other order or repeated marker is retained as an observation.

.org 0x000
        B       INIT

.org 0x002
        B       ISR

.org 0x010
INIT:
        LDPK    0
        LACK    0x11
        SACL    0
        LACK    0x22
        SACL    1
        LACK    0x33
        SACL    2
        EINT
        NOP                     ; documented post-EINT protected instruction
        OUT     2,PA7           ; fixture-armed marker
ARM_WINDOW:
        NOP                     ; pulse INT while this word is fetched
RACING_DINT:
        DINT                    ; Figure 2-12 N+1 protected slot
RESUME_N_PLUS_2:
        OUT     1,PA7           ; cancellation/return marker
        B       HOLD
HOLD:
        B       HOLD

.org 0x030
ISR:
        POP                     ; expose stacked return PC without ROM data
        SACL    3
        PUSH                    ; restore return PC for RET
        OUT     3,PA7           ; stacked-PC observation (expected 0x1b/0x1c)
        OUT     0,PA7           ; entry marker
        EINT
        RET
