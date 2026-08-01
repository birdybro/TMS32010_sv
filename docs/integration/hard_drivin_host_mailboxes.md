# Hard Drivin' Driver Sound main/sound mailboxes

## Scope

This document traces the two 16-bit word latches and their pending flags on
Atari drawing A044427 Rev A. They exchange data between the external main
system and the board's local 68000 sound CPU; they are not TMS32010 registers.
The TMS port-3 latch is a separate path documented in
`hard_drivin_host_reads.md`.

The standalone boundary accepts same-clock transaction-completion pulses. The
board top can derive the local 68000-side pulses from an opt-in logical
`/RVAS`/DTACK adapter and normalize original-MC68000 byte writes before
capture. It does not implement the main-system bridge, raw-pin CDC,
interrupt-level connection, or nanosecond strobe closure.

## Primary wiring

The two physical directions are symmetric
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4; ti-sn74ls374-datasheet-sdls165b, description, pinout, and
positive-edge behavior, printed pp. 1–3]:

| direction | latch inputs | capture edge | read output | data reset |
|---|---|---|---|---|
| main system to sound CPU | `ED15:ED0` into LS374 `10L`/`10N` | trailing positive edge of active-low `/MAINWR` | `/SOUNDRD` enables all local `D15:D0` | none drawn |
| sound CPU to main system | local `D15:D0` into LS374 `20L`/`20N` | trailing positive edge of active-low `/SOUNDWR` | `/MAINRD` enables all `ED15:ED0` | none drawn |

Each write clocks a complete 16-bit word into two octal edge-triggered
latches. Neither data-latch pair has a clear or board-reset connection, so
board reset cannot qualify or clear its stored word. **Confidence:
VERIFIED_PRIMARY for the wiring and absence of a reset connection; UNKNOWN
for physical power-up contents.**

The two halves of LS74 `20S` implement the handshake
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4; ti-sn74ls74a-datasheet-sdls119, description and function table,
printed pp. 1–3]:

| flag | asynchronous set | synchronous clear | board reset |
|---|---|---|---|
| `MAINFLAG` | active-low `/MAINWR` drives preset | trailing edge of active-low `/SOUNDRD` clocks grounded D | active-low clear |
| `SOUNDFLAG` | active-low `/SOUNDWR` drives preset | trailing edge of active-low `/MAINRD` clocks grounded D | active-low clear |

Nominally, a write makes the associated flag high and the opposite-side read
makes it low. `/READSTAT` exposes raw `MAINFLAG` and `SOUNDFLAG` on local host
bits 15 and 14, respectively. `MAINFLAG` also participates in the local 68000
interrupt network; that interrupt adaptation remains outside this standalone
module. **Confidence: VERIFIED_PRIMARY for wiring, polarity, and nominal
sequence.**

## Original-MC68000 byte writes

Both byte paths are resolved by primary sources. A044427 LS138 `20P` generates
`/MAINWR` locally for the physical `0x840000..0x843fff` expansion alias and
does not use connector byte enables `/EWEU` or `/EWEL`. The local sound-CPU
decode likewise clocks both LS374 devices with one `/SOUNDWR` and does not use
its `/WEU` or `/WEL` at the mailbox. SP-327 shows the main CPU's
UDS/LDS-derived byte strobes reaching J7, so their absence from the latch
clock is meaningful rather than an unavailable upstream contract
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 1–3 of 10,
PDF pp. 1–6; atari-hard-drivin-schematic-package-sp327, SP-327 sheets 4 and 7,
PDF pp. 5 and 8].

Motorola Table 3-1 states that the original MC68000's “current implementation”
drives a selected byte on both halves of `D15:D0`: an
upper-byte transfer therefore captures `{2{D15:D8}}`, and a lower-byte
transfer captures `{2{D7:D0}}`. A word write preserves all sixteen bits. The
manual footnote warns that this current implementation behavior need not
appear on future devices, so a substitute 68k core must reproduce it
explicitly [motorola-m68000-users-manual-ninth, Table 3-1 and footnote,
printed pp. 3-5 through 3-6].

See `docs/research/hard_drivin_mailbox_byte_audit.md` for the complete decode
audit. **Confidence: VERIFIED_PRIMARY for original-MC68000 byte data and both
Rev-A mailbox paths; UNKNOWN for production-firmware byte-write use.**

Pinned MAME instead merges the selected local byte with retained emulator
state. `SC-031` preserves that behavioral conflict; MAME's merge is not the
physical `{byte, byte}` result.

## Flag conditions the sources do not fully resolve

The LS74 function table establishes that preset dominates the clock while
preset remains low and clear remains high. A read edge fully inside a write
strobe therefore leaves Q set. Simultaneous low preset and reset clear is an
invalid asynchronous-control state. The reviewed data sheet does not provide
a digital result for a positive read-clock edge at write-preset release, and
the two independent 68000 buses can place those edges arbitrarily close.

`hard_drivin_sound_mailboxes` therefore captures the independently clocked
word but emits a zero flag carrier with flag validity false when the
same-clock callback observes either:

- a direction's write and opposite-side read completing together; or
- a direction's write completing while board reset asserts the flag clear.

The module reports each condition on a separate conflict output. A later
nonconflicting write, read, or reset requalifies the affected flag. This is a
conservative digital interface policy for the unresolved release-edge case,
not a claim that every temporal overlap is unknown or that physical Q becomes
zero. **Confidence: VERIFIED_PRIMARY for preset dominance while asserted and
the invalid simultaneous asynchronous preset/clear row; UNKNOWN for the exact
release/read-clock edge; VERIFIED_SIMULATION for the callback policy.**

## Secondary behavioral comparison

Pinned MAME independently corroborates the nominal software handshake:

- `hd68k_snd_data_w` schedules a complete main-to-sound word and sets
  `m_mainflag`;
- `hdsnd68k_data_r` returns that word and clears `m_mainflag`;
- `hdsnd68k_data_w` updates the sound-to-main word and sets `m_soundflag`;
- `hd68k_snd_data_r` returns that word and clears `m_soundflag`; and
- the modeled board reset clears both flags.

It models logical handler calls rather than LS374/LS74 strobe edges and uses
`COMBINE_DATA` for a local sound-CPU write
[mame-harddriv-audio-030fefc, `hd68k_snd_data_r`, `delayed_68k_w`,
`hd68k_snd_data_w`, `hdsnd68k_data_r`, `hdsnd68k_data_w`, and
`hd68k_snd_reset_w`]. **Confidence: CORROBORATED for the ordinary
software-visible handshake; CONFLICT for local byte writes; not physical
timing evidence.**

## FPGA boundary

`rtl/wrappers/hard_drivin_sound_mailboxes.sv` exposes each direction as:

- a complete captured-word write pulse and 16-bit write data;
- an opposite-side read-completion pulse;
- retained 16-bit data plus independent data validity;
- retained pending flag plus independent flag validity; and
- a combinational flag-conflict indication.

`initialize_i` creates deterministic zero carriers with all validity false.
Board reset clears and qualifies the flags but deliberately preserves both
data latches.

`rtl/wrappers/hard_drivin_mc68000_write_word.sv` separately converts an
original-MC68000 word or byte bus transfer into the complete word captured by
an unqualified LS374 pair. Keeping normalization outside the generic mailbox
storage lets a future main bridge and any substitute-CPU policy remain
explicit.

## Board-top integration

`hard_drivin_sound_mister` instantiates the standalone adapter behind four
decoded-completion callbacks: main-system write/read and local sound-CPU
write/read. The main-system side remains an explicit already-captured-word
contract. The local side selects either the original explicit callbacks or
the same-clock host-timing adapter.

In timing mode, S7 `/SOUNDRD` clears `MAINFLAG`; S7 `/SOUNDWR` preserves a
word transfer or duplicates the selected MC68000 byte and sets `SOUNDFLAG`.
`host_timing_partial_sound_write_o` reports an accepted byte write for one
trace event; it is not a rejection indication. Each accepted write captures
one complete word; each read clears only the opposite-side pending flag. The
top exports both retained words, both data-valid bits, both flags, both
flag-valid bits, and both conflict indications.

The integrated flags directly feed `hard_drivin_sound_read_status`, so raw
`MAINFLAG` and `SOUNDFLAG` appear only on status bits 15 and 14 when their
individual validity is true. `SOUND.TEST` and `/TIRDY` remain external raw
inputs. The same-clock S7 callbacks are explicitly derived from `/RVAS`,
DTACK, and the captured byte strobes, while the default callbacks retain their
older abstract contract. A future original-MC68000 main bridge can reuse the
normalizer before asserting its callback. The raw main-system bridge and CDC
remain outside the top. **Confidence: VERIFIED_SIMULATION for the same-clock
integration; VERIFIED_PRIMARY for the original-MC68000 byte mapping; UNKNOWN
for the release-edge collision retained by `OQ-031`.**

## Verification and synthesis

`tb_hard_drivin_sound_mailboxes` exhausts all 65,536 words in both directions,
giving 131,072 nominal write/read transitions. It checks full-word capture,
flag set and read-clear, data persistence, board-reset independence,
deterministic initialization, both simultaneous write/read conflicts, both
reset/write conflicts, and later flag requalification. Ten retained RTL checks
independently cover exact data/state transitions and the rule that an invalid
flag carrier cannot be high.

Standalone Yosys reports 259 abstract cells, ten retained checks, no memory or
latch, and zero structural problems. This is a pre-technology synthesis smoke,
not 68000 bus timing or a Cyclone V fit.

`tb_hard_drivin_mc68000_write_word` additionally exhausts all 65,536 bus words
in word, upper-byte, and lower-byte modes plus the no-strobe state. Standalone
Yosys 0.67+111 reports 39 mapped cells, three retained checks, no memory or
latch, and zero structural problems.

The integrated board regression verifies nominal traffic in both directions,
exact timed S7 local read/write effects, accepted and duplicated upper/lower
byte writes, external-callback isolation, exact flag-to-status mapping,
both coincident write/read conflicts, independent flag invalidity and
requalification, raw peripheral validity masks, and board-reset flag clear
with both word latches retained. The board-routing BMC proves the two symbolic
byte orientations and reaches both covers.

The complete board hierarchy reports 3,773 abstract cells, 409 retained
checks, six memories, and zero structural problems. This is not a raw-pin
68000, asynchronous collision, or Cyclone V timing qualification.
