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

SPRU001B prints page 1 once as locations 128-144 even though the same section
says there are 144 total words. SPRU002B and the later TI family guide use the
arithmetically consistent original-part range 128-143. `SC-038` retains the
outlier; it is not evidence for address `0x90` or a 145th word
[ti-tms32010-users-guide-spru001b, Sections 2.3-2.3.1.2, printed pp. 2-7-2-8
(PDF pp. 31-32); ti-tms32010-assembly-guide-spru002b, `LDP`/`LDPK`, printed
pp. 3-36-3-37 (PDF pp. 57-58); ti-first-generation-users-guide-1987,
Section 3.4.6, printed p. 3-19 (PDF p. 48)]. **Confidence: VERIFIED_PRIMARY
for 144 words and `0x00`-`0x8f`; UNKNOWN outside that range.**

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
[ti-tms32010-users-guide-spru001b, §§2.3 and 2.8.2, Figure 2-10,
Table 3-2, and `TBLR`/`TBLW`, printed pp. 2-17, 3-7, and 3-64–3-67
(PDF pp. 41, 57, and 114–117)]. **Confidence: VERIFIED_PRIMARY.**

Self-modifying program RAM is consequently architecturally meaningful and
must remain observable. Program images are word-addressed; byte order belongs
to file/wrapper formats, not to the CPU architecture.

The qualified model and RTL resolve the internal address before entering the
discarded-prefetch state, capture `ACC[11:0]` as the table address, then
perform the program-space transfer in cycle 3. `TBLR` exposes a logical
program read concurrent with an internal-RAM write; `TBLW` exposes an
internal-RAM read and a distinct program write. The final temporary-stack
effect discards the old bottom and duplicates the old level-2 value there.
Directed tests also prove that TBLW may replace the discarded following word,
which is then fetched in its new form. **Implementation evidence consistent
with the cited primary sequence.**

## Current RTL boundary

The partial RTL implements exactly 144 addressable 16-bit words and refuses to
retire `ADD`, `ADDH`, `ADDS`, `AND`, `DMOV`, `LAC`, `LAR`, `LDP`, `LST`, `LT`,
`LTA`, `LTD`, `MPY`, `OR`, `SACL`, `SACH`, `SAR`, `SUB`, `SUBC`, `SUBS`,
`TBLR`, `TBLW`, `XOR`, `ZALH`, or `ZALS` when its effective address is
`0x90`–`0xff`. It exposes the effective address, operation-valid
indication, and read/write data for verification without creating a physical
data-memory strobe. Direct and indirect tests cover both data pages, the final
physical word, pre-modification indirect addressing, and write-to-read
ordering.
**Implementation evidence; unresolved-address policy: PROVISIONAL under
OQ-002.**

An inductive standalone proof quantifies a symbolic address across all 144
qualified words while leaving initial contents and legal CPU/debug writes
arbitrary. It proves read-after-write for either port, preservation under
writes to other words, exact `< 144` validity for every eight-bit address, and
the portable block's zero read output when invalid. The last result is only
the current verification-interface policy: it does not establish an
original-chip value for `0x90`–`0xff` or weaken the core's trap-before-effects
boundary under `OQ-002` [`formal/tms32010_internal_ram.sby`].

`LST` performs one ordinary internal-RAM read and uses the old DP or old
selected AR to resolve that source before replacing status fields. It never
writes data RAM. Out-of-range sources trap before status or indirect-address
effects, consistent with the partial core's explicit `OQ-002` boundary
[ti-tms32010-users-guide-spru001b, `LST`, printed p. 3-38 (PDF p. 88)].
**Confidence: VERIFIED_PRIMARY except indirect next-ARP precedence, which is
PROVISIONAL under `OQ-015`.**

`SUBC` performs one ordinary internal-RAM read through the same old-address
and post-update ordering. The selected 16-bit word is treated as an unsigned
divisor and aligned by 15 bits for the conditional subtraction; it never
writes data RAM
[ti-tms32010-users-guide-spru001b, `SUBC`, printed p. 3-61 (PDF p. 111)].
**Confidence: VERIFIED_PRIMARY for the memory transaction and operand
alignment; see `OQ-017`/`OQ-018` for execution-stage uncertainties.**

`DMOV` captures the selected source word and writes it unchanged to the
numerically next internal-RAM address in the same documented cycle. It uses
distinct logical source and destination addresses but has no T, P, ACC, or
arithmetic-status effect
[ti-tms32010-users-guide-spru001b, `DMOV`, printed p. 3-28 (PDF p. 78);
ti-first-generation-users-guide-1987, §3.4.3 and `DMOV`, printed pp. 3-13 and
4-33 (PDF pp. 42 and 114)]. **Confidence: VERIFIED_PRIMARY.**

`LTA` consumes one selected internal data word for its T-register load while
its previous-P accumulation remains internal to the register datapath. The
logical read uses the same old-address/post-update ordering as LT
[ti-tms32010-users-guide-spru001b, `LTA`, printed p. 3-40 (PDF p. 90)].
**Confidence: VERIFIED_PRIMARY.**

`LTD` reads the selected internal word, loads it into T, adds the unchanged
previous P value to ACC, and copies the source unchanged to the next higher
internal-RAM location. The RTL therefore exposes distinct logical source and
write addresses even though both transactions retire with the same
instruction. The common indirect update still uses the old selected AR for
the source address and occurs after the access
[ti-tms32010-users-guide-spru001b, `LTD`, printed p. 3-41 (PDF p. 91);
ti-first-generation-users-guide-1987, §3.4.3 and `LTD`, printed pp. 3-13 and
4-46 (PDF pp. 42 and 127)]. **Confidence: VERIFIED_PRIMARY.**

The original-part sources do not establish what happens when DMOV or LTD
selects source `0x8f`, whose next higher destination is outside the documented
144-word RAM. The current model and RTL reject either unresolved endpoint
before instruction-specific state, AR/ARP, or RAM changes. This is an
explicitly provisional implementation boundary under `OQ-002` and `OQ-014`.
The related TI patent describes the ordinary adjacent-column move mechanism
but has internally inconsistent row/column capacity statements and no array-
edge result; pinned MAME and IKA make different storage-policy choices. A
reproducible original-NMOS experiment now clears/scans every valid word,
observes `0x90` through an external `OUT`, and separately checks DMOV/LTD
register effects [`docs/research/ram_boundary_experiment.md`, `SC-038`].

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

`SPAC` likewise operates only on internal ACC and P state, so its full-width
ACC-minus-P operation requires no data-memory access
[ti-tms32010-users-guide-spru001b, `SPAC`, printed p. 3-58 (PDF p. 108)].
**Confidence: VERIFIED_PRIMARY.**

The standalone core keeps an asynchronous read because it supplies no
subphase lead between a new instruction word and its execution enable.
ADR-0004 permits the explicit fetch/execute wrapper to select a synchronous
read instead: its registered execute ownership holds an effective address for
multiple FPGA subphases before architectural consumption. The operand is
valid by phase 1, and explicit same-address forwarding exposes a just-written
word during the following owner's phase-0 setup interval. Thus `IN` followed
by `OUT` establishes the new output word before the active `WE` phase. The
qualified Cyclone V flow maps this mode to one 144-by-16 M10K without changing
a documented machine cycle. Independent source-read and destination-write
addresses continue to support DMOV/LTD's documented dual-address operation.
This is implementation evidence, not evidence about the physical TMS32010 RAM
or its internal read-during-write topology.

The phase-aware wrapper's `data_address_o` is combinational, while its
diagnostic `data_read_data_o` may still reflect the preceding address during
the single phase-0 edge at which a new execute owner is installed. It must
match the owned address from phase 1 through architectural consumption;
same-address forwarding is the exception that deliberately supplies the new
word already at phase 0. The signals are not original package pins.
Read capture is gated by the same enable that advances the wrapper subphase,
so a global pause holds both the registered output and forwarding metadata.

An explicit synchronous preload port exists for simulation and integration
debug only. It is forbidden during live CPU execution, does not run on
physical reset, and does not imply deterministic hardware power-up contents.
`DMOV`, `SACL`, `SACH`, `SAR`, and `LTD` supply architectural write paths; assertions exclude
simultaneous CPU/debug writes and invalid CPU write addresses.
The registered mode additionally has directed and inductive tests for
capture, persistence, invalid qualification, debug preload, and same-address
forwarding, including disabled-capture stability
[`sim/unit/tb_internal_ram_registered.sv`,
`formal/tms32010_internal_ram_registered.sby`].
