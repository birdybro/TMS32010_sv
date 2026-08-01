# tms32010-sv

Clean-room, synthesizable SystemVerilog implementation of the original Texas
Instruments TMS32010 fixed-point digital signal processor.

The long-term integration target is the Atari Hard Drivin' sound subsystem on
MiSTer. The architectural core is intentionally platform-independent.

## Status

This project is in its research and infrastructure phase. It is **not yet an
instruction-complete or cycle-accurate processor**. Architectural claims are
accepted only when they are tied to cited evidence and automated tests. See
[TASKS.md](TASKS.md), [CHANGELOG.md](CHANGELOG.md), and
[artifacts/progress.md](artifacts/progress.md) for current evidence.

The reference model and local tools currently support all sixty documented
instructions: `ABS`, `ADD`, `ADDH`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`,
`IN`, `LDP`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `OUT`, `PAC`, `ROVM`, `SACL`,
`POP`, `PUSH`, `RET`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SST`, `SUB`, `SUBC`, `SUBH`, `SUBS`, `TBLR`, `TBLW`,
`XOR`, `ZAC`, `ZALH`, and `ZALS`. The partial RTL and seeded differential
boundary support the same set except POP and PUSH, for fifty-eight shared
instructions. CALA/RET use ADR-0003's discarded-`PC+1` then selected-target
mapping, CORROBORATED for RET by a related TI patent and `INFERRED` for CALA;
PUSH/POP external address ownership
remains unresolved under `OQ-016`.
A redistribution-safe four-tap Q15 FIR program now verifies the complete local
assemble/disassemble/model workflow against independently fixed opcodes,
numeric results, twelve instruction cycles, and logical transaction traces.
The first generic `tms32010_mister` wrapper supplies standard synchronous
reset and same-clock program/I/O request-ready callbacks around the partial
explicit pipeline. It is synthesizable and directed-tested, but is not yet an
SDRAM bridge, board top level, or complete processor wrapper.
A separate ROM-free Hard Drivin' smoke program now exercises the pinned
Driver Sound Board port roles and BIO branch in the assembler/model workflow;
it does not contain game code or claim physical board qualification.
A board-specific combinational decoder now reproduces the Rev-A low-eight
port/program-RAM split and reports invalid simultaneous 68000/DSP RAM
ownership. A separate synchronous-read FPGA adapter retains the complete
4K-by-16 shared RAM as an abstract Yosys memory, supports safe whole-word host
loading while the DSP is reset, and refuses conflicting writes. These pieces
are exhaustive-tested and synthesizable. They remain usable independently of
the partial processor/RAM top and are not a 68000 bus bridge or complete
sound-board wrapper.
A partial board top now connects the processor, native decoder, shared program
RAM, communication path, a storage-free parallel sample-ROM callback, and the
raw twelve-bit DAC latch. It also exposes the primary-defined port-4
complementary `MUTE` net and latched port-5 `320IRQ` state.
It executes the host-loaded ROM-free smoke fixture with the expected 22-cycle
trace and separately proves low-address TBLW reaches physical I/O. The 68000
bridge/address decode, actual sample storage, board 1 MHz enable source, analog
audio path, loaded mute consumer, and remaining peripherals remain absent from
that integrated top.
A separate synthesizable communication-path adapter now implements the
primary-transcribed 512-by-16, CRAMEN-selected host/DSP storage relationship,
read-only DSP port-1 access, shared 16-bit sound-address counter, port-7 load,
every-input-read increment, and port-6 block latch. Its exhaustive directed
test covers all 512 words, ownership handoff, full-address wrap, and invalid
preload state; a memory-retaining Yosys target passes structural checks. The
adapter is now connected to `hard_drivin_sound_mister`: a host callback
preloads a synthetic communication word, processor port 1 reads it internally,
and the full address/block side effects survive the expected execution/reset
sequence. This is not a 68000 bus/latch implementation or physical HM6116
timing model. The independently modeled port-3 LS374 captures `TD7:TD0` on
`/CPORT` and exposes it on host `D15:D8`; explicit masks keep undriven host
`D7:D0` unresolved rather than inventing a complete read word.
A044427 sheets 5–6 now define the remaining port-0 input as a parallel
sample-ROM path: a present block and the pre-increment 16-bit sound address
select one byte, which reaches the TMS as a signed byte shifted left seven.
Pinned MAME omits the duplicated sign bit at TDI15 (`SC-026`). The board
adapter now routes port 0 to an authorized byte callback only for explicitly
present blocks and stalls/reports invalid otherwise. Exhaustive standalone and
integrated tests prove the exact mapping without embedding ROM content;
unpopulated-block electrical values remain unknown under `OQ-026`.
The same top now captures every committed port-0 output as the uncomplemented
`data[15:4]` DAC code and exposes an exact-once pulse. This implements only the
primary digital latch boundary; analog conversion and MAME's disputed bit-11
XOR remain outside RTL under `SC-019`/`OQ-020`.
The output-control adapter separately models the two resettable LS74 halves:
port 4 captures complement `TD0` onto the raw `MUTE` net, while any port-5
write asserts `320IRQ` until a host-clear callback. Rev A's only drawn mute
consumer is not loaded, so the raw state does not gate audio under
`SC-027`/`OQ-027`.
A BIO adapter now models the schematic's LS161 divide-by-50 chain,
one-microsecond active-low source pulse, and separate CLKOUT resampler using
clock enables rather than generated clocks. It preserves the counters across
board reset and exports validity for the uninitialized physical phase. The
partial board top connects it as an explicit opt-in while retaining external
raw BIO as the default. The caller supplies a noncoincident 1 MHz enable and
the top derives CLKOUT sampling from the core phase; physical independent-
crystal coincidence remains `OQ-028` rather than receiving invented behavior.
A host-control adapter now models the address-encoded LS259 `80R` behind an
explicit decoded-completion callback. The partial board top can opt into raw
Q4 `/320RES` and Q3 CRAMEN while exposing their validity and preserving the
external callbacks by default. A synthetic opposite-sentinel test qualifies
program- and communication-RAM handoff end to end. This is not the missing
`/RVAS`/DTACK, byte-lane, or complete 68000 address-decode bridge.
`ABS` is exact opcode `0x7f88`, executes in one program-only cycle, negates a
negative accumulator, and uses OVM to choose wrap or positive saturation for
`0x8000_0000`. It preserves the incoming sticky OV bit. That OV behavior is
`CORROBORATED`: SPRU013 states that an instruction's Execution block lists
affected status bits, the original ABS block lists none, the later C14/E14
variant explicitly adds OV effects, and pinned MAME independently agrees.
`ADDH=0x60xx` adds the complete selected word modulo 2^16 to `ACC[31:16]`
and always preserves `ACC[15:0]`. The original-family instruction contract
lists no OV/OVM effect while the later C14/E14 variant explicitly adds one;
the original-part implementation therefore preserves OV and ignores OVM at
`CORROBORATED` confidence under resolved `SC-017`/`OQ-011`. Boundary tests
cover both wrap directions under all four incoming OV/OVM combinations.
The 144-word internal RAM exposes verification-visible logical
`ADD`/`ADDH`/`ADDS`/`AND`/`DMOV`/`LAC`/`LAR`/`LDP`/`LST`/`LT`/`LTA`/`LTD`/`MPY`/`OR`/`SUB`/
`SUBC`/`SUBH`/`SUBS`/`XOR`/`ZALH`/`ZALS` reads and `DMOV`/`LTD`/`SACL`/`SACH`/`SAR`/`SST` writes;
an inductive symbolic proof covers read/write behavior at every qualified
word from arbitrary initial contents. The block's invalid-address indication
and zero read output are implementation policy only; original-silicon
behavior at `0x90`–`0xff` remains unknown under `OQ-002`.
MAR changes only AR/ARP and produces no data transaction; MPYK consumes its
signed immediate from the program word, PAC copies P to ACC, and APAC adds P
to ACC while SPAC subtracts P from ACC; APAC and SPAC apply sticky overflow
and OVM saturation, and none has a data transaction.
LTA combines a full-word internal-RAM load to T with previous-P accumulation
into ACC in the same documented one-cycle transaction.
LTD performs those same two operations while also copying the unchanged
source word to the next internal-RAM address; the logical verification
interface exposes separate read and write addresses for this dual-address
transaction. An LTD whose source or destination is outside the verified
144-word RAM traps provisionally rather than inventing wrap or alias behavior.
DMOV performs only that source-preserving next-address copy, leaving
ACC/T/P and arithmetic status unchanged; it follows the same explicit
unresolved-endpoint policy.
Two synthetic original-NMOS probe images now clear/scan all 144 valid words,
expose an `0x90` read through `OUT`, and preserve DMOV/LTD register results for
physical inspection. They make `OQ-014` reproducible but do not resolve it;
see [the RAM-boundary experiment](docs/research/ram_boundary_experiment.md).
`SST=0x7c00/mask 0xff00` stores the defined status fields and reserved-one
mask into internal RAM in one cycle. Its direct form forces page 1 and only
offsets 0–15 are legal on the original part; indirect forms store the old ARP
before applying AR/ARP post-updates. Bits 12:9 and 7:2 are primary-verified
ones, while reserved bit 1 is written as one at `CORROBORATED` confidence
under resolved `SC-008`/`OQ-003` and remains reserved to software. `LST`
consumes only bits 15, 14, 8, and 0 and cannot change INTM.
`DINT` and `EINT` set and clear the architectural interrupt mask in one
program-only cycle. The partial core now also exposes active-low `int_i`,
latches a request while masked, implements the tested EINT and MPY/MPYK
deferrals, dummy-fetches and stacks the return PC, masks and clears the
request, and selects vector 2. A native-phase test matches TI Figure 2-12's
external read order. The existing 32-case core/explicit matrices plus a
four-case CALA/RET explicit-pipeline test exhaust request arrival at all
represented intervals of 17 currently supported multicycle families. The
explicit tests check native
MEN/DEN/WE ownership, no midinstruction entry, one protected retirement,
dummy discard, stack entry, acknowledge state, and vector capture.
A four-case native test also checks the enabled falling-boundary sample from
each modeled subphase, including a stalled phase. Complete fetch/execute
overlap, the later-family Figure 3-20 conflict, physical pin setup/synchronizer
behavior, PUSH/POP cycles, physical
confirmation of CALA/RET address ownership, and the provisional
DINT-at-final-boundary ordering remain outside any cycle-accuracy claim. A
stable original-NMOS probe records armed/entry/resume markers and the stacked
return PC without assigning an expected result.
ADR-0002 and a standalone synthesizable fetch/execute register now establish
the required distinct fetched-word and execute-slot validity/address state.
Directed tests cover priming, overlap, stalls, branch flush, interrupt dummy
suppression, vector capture, and reset.
The separate `tms32010_sequential_pipeline_slice` connects that register to
the core for reset priming, sequential one-cycle instructions, exact B,
exact BANZ, exact BV, exact BIOZ, exact CALL, the six accumulator-conditional
branches, ADR-0003 CALA/RET, plus exact IN/OUT execution ownership. Its
fetch address stays one word ahead of the execute PC for ordinary sequential
execution,
all 46 words in the existing 41-family one-cycle stream match the previously
qualified architectural state at a one-retirement offset, and all eleven
integrated branch/call instructions retain ownership through operand and
selected-instruction fetches. BANZ selects from the old counter and decrements
only at branch retirement; the accumulator branches select from the unchanged
full 32-bit ACC; BV selects from unchanged OV and clears it only at taken
retirement; BIOZ samples raw active-low BIO at operand completion and holds
the resulting decision through the selected fetch; CALL pushes opcode-PC+2
only when its selected target fetch completes. CALA/RET discard the sequential
prefetch, retain execute ownership through the accumulator/old-TOS target
fetch, and commit stack/PC effects only when that target is captured. The
combined interval mappings
are source-derived INFERRED behavior because no dedicated original-part
branch/call pin waveform has been located. Figure 2-9 directly defines the
I/O mapping: cycle 1 asserts only DEN or WE at the encoded port, cycle 2
fetches PC+1 under MEN, and IN/OUT retires as that word enters the execute
slot. Both intervals are independently stallable, IN data is sampled at the
port boundary, and OUT data remains stable through it. Figure 2-10 table
ownership is also integrated: TBLR/TBLW retain the execute slot through the
discarded PC+1 prefetch, ACC-addressed program transfer, and repeated PC+1
prefetch. Only the repeated-prefetch boundary commits RAM, AR/ARP,
stack-bottom, and retirement effects. TBLW uses explicit program-write
direction/data outputs, and a self-modifying test proves that only the
rewritten repeated fetch executes. Figure 2-12 interrupt ownership is now
integrated for the
qualified path: one protected instruction executes while N+2 is fetched but
discarded, vector 2 is fetched during a nonexecuting entry interval, and only
the following interval executes it. MPY and MPYK in the protected slot defer
that entry until one additional instruction retires; directed tests verify
both products, bus shapes, stalls, and the resulting return PC.
Beneath two explicit sequencer assumptions, a 12-step bounded proof checks the
standalone register's transition relation for arbitrary fetch words and
boundaries, with a prime/stall/replace/flush/target cover reached at step 7.
Bounded actual-core formal harnesses check fixed EINT entry,
MPYK-extension/held-low-relatch, direct-MPY/repeated-multiply-chain,
indirect-MPY/address-update, and CALA/RET stack/PC slices across arbitrary
clock-enable stalls. Their 12/14/20/20/24-step bounds and reachable covers are documented in
`formal/README.md`. A one-step standalone proof exhaustively checks all 2^32
signed multiplier operand pairs, including TI's unique most-negative-square
exception; this is a combinational RTL result, not physical-timing evidence.
A second one-step symbolic proof exhausts all 65,536 decoder inputs against a
compact legal-family predicate. It includes CALA/RET and keeps PUSH/POP
outside RTL until their native second cycles are qualified; opcode identity still comes from
the primary-cited database, hand fixtures, and exhaustive simulation.
A 10-step actual-core reset harness separately proves the
documented reset controls and explicitly provisional unlisted-state retention,
with a nonzero-ACC/OVM cover at step 5. A separate 40-step native-program-bus
harness proves the digital reset/release transition relation for arbitrary
logical reset, clock-enable, read-qualification, and next-address inputs; its
five-cycle-reset/address-0/address-1 cover reaches step 34. This is bounded
wrapper evidence, not electrical or original-silicon qualification. Another
directed zero-pause/multiple-pause regression holds ordinary program, IN,
OUT, TBLR, and TBLW phases for a total of 16 host clocks and obtains the same
architectural and memory result with exactly 16 clocks of extension. This is
a synchronous FPGA adaptation through `clock_enable_i`, not a native READY
protocol. TI's original external-clock table instead limits the TMS32010-20
master period to 48.78–150 ns with 47.5–52.5% pulse duration; a physical
clock cannot be held indefinitely while remaining inside specified operating
conditions.
A 40-step integrated-pipeline harness also checks one direct TBLR
discarded/transfer/repeated-fetch sequence and
reaches its LACK/TBLR/LAC/NOP cover at step 34. A complementary 40-step direct-TBLW
harness proves one synchronous phase-3 program write and rewritten-word
execution, reaching cover step 35. These are bounded scenarios, not a general
interrupt, external-memory, or pipeline proof.
`LST` reads one internal word in one cycle, loads `OV`, `OVM`, `ARP`, and
`DP`, and preserves `INTM`. Its indirect next-ARP precedence is explicitly
provisional under `OQ-015`, based on later TI and independent MAME
corroboration because the original-part manuals do not state the precedence.
`SUBC` performs TI's one-cycle conditional subtract/divide step through the
common data-address path. Tests use the documented requirement that its next
instruction not consume ACC; the exact illegal-scheduling result availability
and the precise arithmetic stage that sets sticky `OV` remain explicitly
provisional under `OQ-017` and `OQ-018`. Stable noncopyrighted physical probes
now distinguish old/intermediate/final dependency visibility and
intermediate-only/final-only OV; they have no captured hardware result.
`SUBH` subtracts the selected word aligned to `ACC[31:16]`. Directed
model/RTL/native and seeded differential tests cover low-half retention,
sticky OV, both wrapped overflow directions, full-accumulator OVM
saturation, and common address updates; `SC-016` records the primary wording
that distinguishes ordinary low-half preservation from saturation.
`BANZ` is the first qualified control-flow instruction. It always performs two
normal program reads: exact opcode `0xf400`, then a canonical 12-bit target
word. It tests the old selected auxiliary-register counter, decrements only
its low nine bits, and selects the target or `PC+2` at the second sample.
Taken and untaken paths both take two cycles. A later first-generation guide's
contradictory full-register wrap example and MAME's shortened untaken timing
are recorded as `SC-011` and `SC-012`.
`B` is exact opcode `0xf900` followed by the same canonical 12-bit target-word
form. It unconditionally loads PC at the second sample, takes two cycles, and
otherwise preserves architectural state.
`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` test signed/zero ACC
conditions through that same two-read sequence. Both outcomes take two cycles;
MAME's shorter untaken abstraction is disclosed as `SC-013`.
`BV` is exact opcode `0xf500`; it uses the same mandatory second read, tests
sticky OV, and clears OV only when the target path retires. MAME's untaken
timing disagreement is `SC-014`.
`BIOZ` is exact opcode `0xf600` and exposes the raw active-low input through
the portable core. The live level at the second falling-edge target sample
selects target or `PC+2`; both paths take two cycles. MAME's shorter untaken
path is disclosed as `SC-015`.
`CALL` is exact opcode `0xf800` followed by a canonical 12-bit target word.
At the second normal program-read sample it pushes opcode-PC+2 onto the
four-level 12-bit stack and selects the target. Nested-call, stack-overflow,
target-stall, return-address-wrap, and malformed-target cases are automated.
`CALA=0x7f8c` pushes opcode-PC+1 and selects `ACC[11:0]` in two cycles;
`RET=0x7f8d` selects the old stack top and then pops the stack. Both have
primary-cited architectural effects, model/RTL/differential qualification,
and explicit bus/stall/interrupt tests. Their physical program-address
ownership follows ADR-0003's reversible discarded-`PC+1` then selected-target
mapping at `INFERRED` confidence; original-part pin confirmation remains open
under `OQ-007`/`SC-037`.
`PUSH=0x7f9c` and `POP=0x7f9d` now have primary-cited model/tool coverage for
their complete four-level stack effects and two-cycle totals. Their second
external program cycle is unknown, so neither has RTL/native or differential
qualification under `OQ-016`.
`IN` and `OUT` each perform an ordinary opcode read followed by a distinct
I/O-space cycle. IN asserts DEN and stores the live 16-bit port input into the
old resolved internal-RAM address; OUT asserts WE and drives the selected RAM
word. Both expose the three-bit port separately, apply indirect updates only
at second-cycle retirement, and have directed state, cycle, stall, bus-phase,
and differential tests.
`TBLR` and `TBLW` perform an opcode read, a discarded following-instruction
read, and an `ACC[11:0]` table transfer under MEN or WE. The following address
is then fetched again. Directed and differential tests cover program-memory
mutation, internal RAM, indirect AR/ARP updates, stalls, and the documented
stack-bottom side effect.
The exhaustive opcode audit partitions all 65,536 words, including 21,895
documented-legal words and 10,976 words that set TI's explicitly reserved
indirect-address bits. Another 372 simultaneous-update words remain under
`OQ-010`; 28,656 more are absent from TI's explicitly complete instruction
summary but are not called reserved. Unsupported opcodes,
undocumented SACH shifts, and unresolved RAM addresses currently trap as a
conservative project policy, not a claim about original-silicon behavior. A
separate native-phase wrapper qualifies the normal reads for all 41 supported
one-cycle instructions, eleven two-word control-flow instructions, the two
one-word computed-control instructions, and the two qualified I/O
instructions, plus both three-cycle table transfers; it is not a general
pipeline or cycle-accuracy claim. The legacy multicycle wrapper rejects
CALA/RET because it cannot represent ADR-0003's discarded prefetch.

## Design principles

- Original TI documentation has precedence over secondary implementations.
- Unknown and conflicting behavior is recorded, never silently invented.
- Reference software and RTL remain structurally independent.
- Program, data, and I/O transactions remain externally observable.
- The core uses one clock, synchronous enables, and no gated clocks.
- Vendor-specific resources belong in wrappers, never in the core.
- MAME may be used as a differential oracle but is not copied into this
  MIT-licensed implementation.

## Quick start

Requirements are detected by the build. Python 3 and GNU Make are sufficient
for documentation and model tests; Verilator is used for RTL lint and
simulation; SymbiYosys plus an SMT solver run bounded formal checks; Yosys and
Quartus provide synthesis qualification.

```sh
make test
make lint
make formal
make synth-yosys
```

Use `make help` for the full command list. Missing tools are reported
explicitly. Release qualification never treats an unavailable required tool as
passing evidence.

## References

Copyrighted manuals are not committed unless redistribution permission is
clear. Metadata and hashes live in
[docs/references/manifest.yaml](docs/references/manifest.yaml); authorized
users can populate the ignored `reference-cache/` directory with:

```sh
python3 scripts/fetch_references.py
python3 scripts/verify_reference_hashes.py
```

Downloaded files are data only and are never executed.

## Licensing

Original project source is licensed under the MIT License. Third-party
documents, programs, source code, ROMs, and other materials retain their own
licenses and are not covered by this repository's license. See
[docs/references/README.md](docs/references/README.md).
