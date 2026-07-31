# Programmer's model

## Register inventory

| State | Width | Documented role | Reset/power-up evidence | Confidence |
|---|---:|---|---|---|
| `PC` | 12 | next program address | reset clears to 0 | VERIFIED_PRIMARY |
| `ACC` | 32 | ALU operand/result with guard half | unspecified here | VERIFIED_PRIMARY |
| `P` | 32 | signed multiplier product | unspecified here | VERIFIED_PRIMARY |
| `T` | 16 | multiplier operand | unspecified here | VERIFIED_PRIMARY |
| `AR0`, `AR1` | 16 each | indirect address/counter registers | unspecified here | VERIFIED_PRIMARY |
| `ARP` | 1 | selects active auxiliary register | status bit; reset value unresolved | VERIFIED_PRIMARY |
| `DP` | 1 | selects direct-address data page | status bit; reset value unresolved | VERIFIED_PRIMARY |
| `OV` | 1 | sticky arithmetic overflow | reset behavior unresolved (`OQ-012`) | VERIFIED_PRIMARY for role; UNKNOWN for reset |
| `OVM` | 1 | saturation enable | unchanged by reset | VERIFIED_PRIMARY |
| `INTM` | 1 | interrupt mask | set by reset and `DINT` | VERIFIED_PRIMARY |
| stack | 4 × 12 | PC return stack | contents unspecified | VERIFIED_PRIMARY |

Sources: [ti-tms32010-users-guide-spru001b, §§2.1–2.5, Figures 2-1–2-12,
printed pp. 2-1–2-19 (PDF pp. 25–43)].

Unknown values remain unknown in the architectural specification. Tests may
seed them explicitly. The software reference model may use deterministic
constructor defaults for reproducibility, but those defaults are not physical
reset claims. The RTL's separate `initialize_i` test/FPGA control establishes
the same deterministic modeled state, while physical reset leaves unlisted
state without an assigned reset value; retention is provisional under
`OQ-012`.

## Status register

The five architecturally described status bits are `OV`, `OVM`, `INTM`, `ARP`,
and `DP`. `SST` stores them in a documented 16-bit layout. `LST` loads all
status fields except `INTM`; interrupt masking is controlled by reset,
`DINT`, `EINT`, and interrupt entry
[ti-tms32010-users-guide-spru001b, §2.2.3 and Figure 2-9, printed
pp. 2-14–2-15 (PDF pp. 38–39)]. **Confidence: VERIFIED_PRIMARY.**

The exact values of reserved bits in an `SST` result are still being
transcribed from Figure 2-9 (`OQ-003`) and will not be guessed.

The qualified functional slice writes `INTM=1` for exact opcode `DINT`
(`0x7f81`) and `INTM=0` for exact opcode `EINT` (`0x7f82`). DINT takes effect
immediately. EINT's architectural bit write is immediate, but interrupt
service remains inhibited until the following instruction completes. Current
model/RTL tests verify the bit write and preservation of unrelated state; the
service deferral awaits interrupt recognition and entry under `CTRL-002`
[ti-tms32010-users-guide-spru001b, §2.4.1 and `DINT`/`EINT`, printed
pp. 2-18–2-19 and 3-27/3-29 (PDF pp. 42–43, 77, and 79)].
**Confidence: VERIFIED_PRIMARY for the architectural rule; service timing not
yet implemented.**

## Addressing

Direct operands concatenate `DP` with the instruction's seven-bit `D` field.
Page 0 spans addresses 0–127; only addresses 128–143 are implemented on page
1 in the original TMS32010. Access outside the physical 144-word internal RAM
requires explicit primary-source resolution before a model or RTL behavior is
assigned
[ti-tms32010-users-guide-spru001b, §§2.1.1, 3.3, printed pp. 2-3,
3-1–3-3 (PDF pp. 27, 51–53)]. **Confidence: VERIFIED_PRIMARY.**

Indirect addressing uses the low eight bits of the AR selected by `ARP`, then
performs the encoded post-modification. The instruction may increment,
decrement, preserve, or update `ARP`. Reserved indirect-mode bits must be zero.
The memory access uses the pre-modification address
[ti-tms32010-users-guide-spru001b, §3.3 and Figure 3-1, printed pp. 3-1–3-3
(PDF pp. 51–53)]. **Confidence: VERIFIED_PRIMARY.**

Auto-increment and auto-decrement modify the low nine bits as a circular
counter, not the whole 16-bit register: incrementing `AR[8:0]=0x1ff` produces
zero and decrementing zero produces `0x1ff`, while `AR[15:9]` is unchanged
[ti-tms32010-users-guide-spru001b, §2.4.1 and Figure 2-3, printed
pp. 2-9–2-10 (PDF pp. 33–34)]. **Confidence: VERIFIED_PRIMARY.**

## Program sequencing

Program address 0 is the reset entry and address 2 is the interrupt vector.
Absolute branches carry their 12-bit target in the second program word.
`CALA` obtains the target from the low 12 accumulator bits
[ti-tms32010-users-guide-spru001b, §§2.2.1–2.2.2, printed pp. 2-13–2-14
(PDF pp. 37–38)]. **Confidence: VERIFIED_PRIMARY.**
