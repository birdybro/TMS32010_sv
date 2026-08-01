# TI patent US4577282A architectural evidence

## Purpose and authority boundary

US4577282A, *Microcomputer System for Digital Signal Processing*, was filed
by Texas Instruments engineers Edward R. Caudel and Surendar S. Magar on
1982-02-22. It describes a contemporary TI fixed-point DSP embodiment with a
12-bit program counter, a four-level stack, two auxiliary registers, a 32-bit
accumulator, a 16-by-16 multiplier, separate program and data paths, and
quarter-cycle control. These characteristics make it useful architectural
background for first-generation TMS320 research
[ti-dsp-microcomputer-patent-us4577282a, abstract, Figures 1-3 and patent
columns 5-18 (PDF pp. 1, 3-8, and 29-35)].

The patent is not an original-TMS32010 production specification. Its
preferred embodiment includes on-chip program ROM, uses some names and
timings that differ from the production manuals, and describes an instruction
table that is not the complete documented TMS32010 set. Project claims may
therefore use it only as authority-level-4 background or corroboration. It
cannot override SPRU001B, a production data sheet, an erratum, or original
hardware observation.

## Corroborated control facts

The disclosed embodiment supplies unusually explicit logical timing:

- External program read clock `RCLK-` is active for possible instruction
  access in every machine state except states with active `DEN-` or `WE-`. This
  independently matches SPRU001B's original-part `MEN` rule
  [ti-dsp-microcomputer-patent-us4577282a, patent cols. 5-6 (PDF p. 29)].
- An ordinary fetch starts as PC is loaded in Q3, is read during Q4/Q1, reaches
  the program bus in Q2, and enters the decoders in Q3. Execution overlaps
  later fetches [same source, patent cols. 15-16 (PDF p. 34)].
- A taken branch prevents the already fetched address word from being decoded,
  loads that word into PC, and decodes the selected target one state later.
  `CALL` follows that sequence while pushing its return PC
  [same source, patent cols. 17-18 (PDF p. 35)].
- `RET` is described exactly: the sequential fetch started by the S1 PC
  increment is discarded; the stack is popped into PC in Q3/S1; the return
  target is fetched during Q4/S1-Q1/S2; and the target begins decode/execution
  at Q3/S2 [same source, patent cols. 17-18 (PDF p. 35), Figure 3u].
- `IN`/`OUT` hold the PC across their two states, while TBL suppresses execution
  of the sequential word and redirects through the accumulator
  [same source, patent cols. 17-18 (PDF p. 35), Figures 3y-3dd].

These points corroborate the clean-room pipeline structure. In particular,
the production-manual constraints plus the patent RET description raise the
ADR-0003 RET sequence from a generic inference to **CORROBORATED**. They do
not make its exact original-TMS32010 pin waveform `VERIFIED_PRIMARY`. CALA's
matching RTL ownership remains `INFERRED`: the patent describes its state
operation but does not give an equally explicit state-by-state CALA waveform.

## RAM-move background and its limit

The disclosed RAM uses a move control to connect sensed data to an adjacent
column during Q4 and retain it for a Q2 write in the following state. An even
source complements the column-select bit; an odd source also increments the
row decoder. This supplies a plausible related-embodiment mechanism for an
ordinary next-higher-word move without consuming the ALU or D bus
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 25-26 (PDF p. 39),
Figures 5i-5j].

It supplies no production boundary result. Patent columns 17-18 describe a
1-of-144 row decoder plus a 1-of-2 column decoder while also saying eight
address bits suffice; columns 25-26 again describe 144 row lines plus an
even/odd word select. Those statements are not a self-consistent 144-word
map, and no last-row or absent-row behavior is specified. The patent therefore
cannot decide whether original-part `DMOV`/`LTD` source `0x8f` suppresses,
aliases, or otherwise performs the requested write to `0x90`. See
`docs/research/ram_boundary_experiment.md` and `SC-038`.

## SUBC staging background and its limit

The disclosed accumulator gives a concrete reason for the production
programming restriction after `SUBC`. Its unshifted ALU result is accepted at
Q4, passes the accumulator input stage at Q1, and recirculates at Q2. A
separate accumulator path then shifts that value and inserts the quotient bit
at Q3 of the following state. The prose assumes that following state is a
non-ALU instruction or NOP. Overflow status is sourced from the ALU
output/carry path, whereas the final shift is local to the accumulator
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 21-24 (PDF pp. 37-38),
Figure 5c]. This is **CORROBORATED RELATED-EMBODIMENT** evidence for a delayed
final shift and an intermediate-ALU overflow hypothesis.

It is not production TMS32010 timing proof. Table A and the instruction prose
call SUBC a two-state instruction, while both original production guides call
it one cycle; the accounting or implementation differs
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 13-14 and 34-36 (PDF
pp. 33 and 43-44)]. The patent also does not define what a violating successor
actually samples. Pinned IKA32010 independently stages its result but assigns
overflow from the later shifted/add result, while pinned MAME commits the
final result immediately and contains an intermediate-overflow expression
that cannot set `OV`. Those conflicts prevent either secondary implementation
from upgrading the patent hypothesis. The physical probes in
`docs/research/subc_pipeline_experiment.md` remain necessary for `OQ-017` and
`OQ-018`.

## Why PUSH/POP remains unresolved

The patent's Table A contains `CALLA` and `RET`, but it does not contain the
production TMS32010 accumulator `PUSH` or `POP` instructions. Searches of the
full patent identify only subroutine-stack push/pop controls. They do not
identify opcodes that move ACC to or from the stack. The prose also says that,
within the disclosed Table A, only branches, calls, table lookup, and I/O take
more than one state
[ti-dsp-microcomputer-patent-us4577282a, patent cols. 11-12 and 34-36 (PDF
pp. 32 and 43-44)].

Consequently, this source strengthens the general active-read constraint but
cannot distinguish the externally measurable `OQ-016` hypotheses:

- an inactive first interval despite that general rule;
- an active repeated/discarded read of `N+1`; or
- an active advancing prefetch at another PC address.

No accumulator PUSH/POP bus sequence will be derived from the patent. The
original-device capture in `docs/research/push_pop_bus_experiment.md` remains
the smallest evidence needed to choose among those hypotheses.

## Known scope differences and cautions

- The preferred embodiment has on-chip program ROM and mode/test behavior not
  established for the original production TMS32010.
- Table A is incomplete relative to the documented production instruction set;
  accumulator PUSH/POP are a concrete omission.
- OCR of Table A is poor and several encodings/names are visibly corrupted.
  It must not supply opcode fixtures.
- The RAM row/column capacity statements are internally inconsistent and do
  not establish the original production 144-word decoder or its array edge.
- The prose's general one-state statement and Table A's two-state `SUBC` entry
  are internally awkward and differ from the production TMS32010's documented
  one-cycle SUBC. Its Q3 following-state shift and ALU-derived overflow path
  are useful hypotheses, but this is further reason not to merge the
  embodiments silently.
- `RCLK-` is the patent embodiment's name. Repository native-interface claims
  continue to use the production TMS32010 manual's `MEN` terminology.

**Result:** useful contemporary TI corroboration for general fetch control and
the RET discard/redirect sequence; no resolution of `OQ-016`; no production
opcode or electrical-timing authority.
