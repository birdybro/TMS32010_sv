# Memory model

## Separate architectural spaces

The TMS32010 uses a modified Harvard architecture: program and data spaces are
architecturally separate, while special table instructions move values
between them. The physical pins multiplex some of these transactions, which
does not make the spaces interchangeable in the model or native RTL interface
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.3, printed pp. 2-1–2-3,
2-15–2-18 (PDF pp. 25–27, 39–42)]. **Confidence: VERIFIED_PRIMARY.**

| Space | Architectural range | Original TMS32010 storage |
|---|---:|---|
| program | `0x000`–`0xfff`, 16-bit words | external, ROMless |
| data page 0 | `0x00`–`0x7f`, 16-bit words | internal RAM |
| data page 1 | `0x80`–`0x8f`, 16-bit words | internal RAM |
| I/O input | ports 0–7, 16-bit | external |
| I/O output | ports 0–7, 16-bit | external |

Sources: [ti-tms32010-users-guide-spru001b, §§2.1.1, 2.3, printed
pp. 2-3, 2-15–2-18 (PDF pp. 27, 39–42)]. **Confidence:
VERIFIED_PRIMARY.**

The behavior of data addresses `0x90`–`0xff` is not assigned (`OQ-002`).
Expanded RAM in the TMS320C15 is outside the default device scope.

All ordinary non-immediate data operands reside in the 144-word on-chip RAM.
The original part has no ordinary external-data-memory transaction: software
moves off-chip data through `TBLR`/`TBLW` program-space transfers or `IN`/`OUT`
peripheral transfers. A reusable core may expose internal-data transactions
for verification, but those signals are not physical TMS32010 pins
[ti-tms32010-users-guide-spru001b, §2.3, printed p. 2-7 (PDF p. 31)].
**Confidence: VERIFIED_PRIMARY.**

## Program/data bridges

`TBLR` reads a program word addressed by the low 12 bits of `ACC` into a data
RAM location. `TBLW` transfers a data RAM word to program space at that
address. Each is listed as three cycles. The intervening prefetched instruction
is discarded and fetched again
[ti-tms32010-users-guide-spru001b, §2.3 and Table 3-2, printed pp. 2-17,
3-7 (PDF pp. 41, 57)]. **Confidence: VERIFIED_PRIMARY.**

Self-modifying program RAM is consequently architecturally meaningful and
must remain observable. Program images are word-addressed; byte order belongs
to file/wrapper formats, not to the CPU architecture.

## Current RTL boundary

The partial RTL implements exactly 144 addressable 16-bit words and refuses to
retire `ADD`, `ADDS`, `AND`, `LAC`, `LAR`, `LDP`, `LT`, `MPY`, `OR`, `SACL`, `SACH`,
`SAR`, `SUB`, `SUBS`, `XOR`, `ZALH`, or `ZALS` when its effective address is
`0x90`–`0xff`. It exposes the effective address, operation-valid
indication, and read/write data for verification without creating a physical
data-memory strobe. Direct and indirect tests cover both data pages, the final
physical word, pre-modification indirect addressing, and write-to-read
ordering.
**Implementation evidence; unresolved-address policy: PROVISIONAL under
OQ-002.**

`MPYK` uses a signed immediate carried in the program word and therefore
performs no logical or physical data-memory access. Directed and native-phase
tests require both data strobes to remain inactive
[ti-tms32010-users-guide-spru001b, `MPYK`, printed p. 3-44 (PDF p. 94)].
**Confidence: VERIFIED_PRIMARY.**

`PAC` similarly requires only its program-word fetch: it transfers P
internally to ACC and has no data-memory access
[ti-tms32010-users-guide-spru001b, `PAC`, printed p. 3-48 (PDF p. 98)].
**Confidence: VERIFIED_PRIMARY.**

`APAC` also requires only its program-word fetch: both operands are internal
registers, and the full-width P-plus-ACC operation has no data-memory access
[ti-tms32010-users-guide-spru001b, `APAC`, printed p. 3-14 (PDF p. 64)].
**Confidence: VERIFIED_PRIMARY.**

The current array has an asynchronous read because the temporary execution
slice samples program data and commits a one-cycle instruction at one
boundary. This is an implementation convenience, not evidence about the
physical TMS32010 RAM. It consequently synthesizes as registers and muxes in
the qualified Yosys and Quartus flows. Replacing it with an FPGA block-RAM
implementation is deferred until the documented pipeline phases can preserve
the same externally visible cycle without speculative latency.

An explicit synchronous preload port exists for simulation and integration
debug only. It is forbidden during live CPU execution, does not run on
physical reset, and does not imply deterministic hardware power-up contents.
`SACL`, `SACH`, and `SAR` supply architectural write paths; assertions exclude
simultaneous CPU/debug writes and invalid CPU write addresses.
