# Hard Drivin' Driver Sound host read paths

## Scope

This document traces the four A044427 Rev-A low host-I/O read targets from
their decoder to the 68000 `D15:D0` bus. It distinguishes a physically driven
lane from a convenient complete software word. It does not implement a
raw-pin/CDC 68000 boundary, an open-bus policy, connector conditioning, the
TMS5220 speech interface, or the main-system bus bridge. A same-clock logical
`/RVF`/`/RVAS`/DTACK option is described below.

## Decode and driven lanes

With both active-low `/RVF` and `/RVAS` active, LS138 `30N` decodes a host
read from `RWN=1` and `A13:A12`. `/RVF` is LS138 `30P` Y4 from the asserted
`/AS`, `A23=1`, `A16:A14=100` high-address qualification; `/RVAS` supplies the
held S4-through-S7 transaction interval. The full derivation is in
`hard_drivin_host_timing.md`. The four targets and their physically driven lanes are
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 2–4 of 10,
PDF pp. 3–8]:

| `A13:A12` | strobe | driven host lanes | drawn source |
|---:|---|---|---|
| `00` | `/SOUNDRD` | `D15:D0` | LS374 `10L`/`10N`, main-to-sound word |
| `01` | `/320PORT` | `D15:D8` | LS374 `50L`, captured TMS `TD7:TD0` |
| `10` | `/SWITCHES` | `D15:D12` | LS244 `10H`, four conditioned J3 inputs |
| `11` | `/READSTAT` | `D15:D12` | LS244 `10K`, flags/test/speech-ready |

No source from the selected target is drawn for `/320PORT` host `D7:D0` or for
`/SWITCHES` and `/READSTAT` `D11:D0`. A complete digital word for those reads
therefore requires an explicit platform open-bus policy; zero, one, bus hold,
or another value must not be attributed to the Rev-A drawing without further
evidence. This is `OQ-030`. **Confidence: VERIFIED_PRIMARY for the driven
lanes; UNKNOWN for the undriven lanes.**

## Main-to-sound word and handshake

Main-system `ED15:ED0` are clocked into LS374 `10L`/`10N` by `/MAINWR` and
their outputs drive all local sound-CPU `D15:D0` lanes while `/SOUNDRD` is
active. The same main write asynchronously sets `MAINFLAG`; the trailing
positive edge of active-low `/SOUNDRD` clocks grounded D into LS74 `20S` and
clears it. Board `/RESET` clears both `MAINFLAG` and `SOUNDFLAG`. The opposite
direction uses `/SOUNDWR` and `/MAINRD` with a separate pair of LS374s and the
`SOUNDFLAG` half of the LS74
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4]. **Confidence: VERIFIED_PRIMARY for the digital wiring and
nominal handshake.**

Pinned MAME returns its complete `m_maindata` word from `hdsnd68k_data_r` and
clears `m_mainflag`, independently corroborating the software-visible
transaction but not its physical strobe timing
[mame-harddriv-audio-030fefc, `hdsnd68k_data_r`].

The complete two-direction data-latch, flag, reset, conflict, and whole-word
callback contract is in `hard_drivin_host_mailboxes.md`.

## TMS-to-host port latch

A044427 LS374 `50L` connects TMS `TD7:TD0` to its eight D inputs. The
active-low output-port-3 decode `/CPORT` connects to the positive-edge clock,
so the latch captures on strobe deassertion. Its eight true Q outputs connect
in order to host `D15:D8`; active-low `/320PORT` controls output enable. No
clear or reset input exists on this LS374 path
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 4 of 10,
PDF pp. 7–8; ti-sn74ls374-datasheet-sdls165b, description, pinout, and
positive-edge behavior, printed pp. 1–3]. **Confidence: VERIFIED_PRIMARY.**

This resolves the former `OQ-023` hypothesis that `/CPORT` was unconsumed.
Pinned MAME labels its DSP-side handler `COM port TD0-7` but only logs the
write, while its host `/320PORT` handler always returns zero. That incomplete
secondary behavior is recorded as `SC-030`; it cannot override the populated
schematic path.

## Switch and status nibbles

The `/SWITCHES` half of LS244 `10H` drives `D15:D12` from four connector J3
inputs, each shown with a 1 kOhm/0.1 uF conditioning network. The drawing does
not assign enough board-level meaning to those connector signals to name
their cabinet functions or idle levels here. The non-inverting lane order is:

| connector input | host bit |
|---|---:|
| `J3-11` | 15 |
| `J3-9` | 14 |
| `J3-8` | 13 |
| `J3-7` | 12 |

Pinned MAME's handler only logs and returns zero, so it is not wiring
evidence. It also assigns the names of its `/SWITCHES` and `/320PORT`
read handlers to the opposite low-I/O quadrants from LS138 `30N`; because
both handlers return zero, that secondary swap was software-invisible. This
is `SC-033`; exact connector semantics remain `OQ-032`
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
PDF pp. 5–6; ti-snx4ls24x-datasheet, SNx4LS244 logic/function table,
printed pp. 11–13; mame-harddriv-audio-030fefc,
`hdsnd68k_switches_r`, `hdsnd68k_320port_r`, and `driversnd_68k_map`].

The `/READSTAT` half of LS244 `10K` drives:

| host bit | source | active meaning established here |
|---:|---|---|
| 15 | `MAINFLAG` | main-to-sound word pending when high |
| 14 | `SOUNDFLAG` | sound-to-main word pending when high |
| 13 | `SOUND.TEST` | pulled high; front-panel/test contact grounds it |
| 12 | `/TIRDY` | raw active-low speech ready net |

The table preserves raw electrical polarity. Speech-device protocol and the
exact connector semantics remain future peripheral work. Pinned MAME assembles
bits 15 and 14 from its flags, forces bit 13 high, forces bit 12 low, and
returns zero in `D11:D0`; that is a software convenience, not proof of the
undriven physical lanes or a live TMS5220 ready path
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 2 of 10,
PDF pp. 3–4; mame-harddriv-audio-030fefc, `hdsnd68k_status_r`].
This live-versus-constant distinction is recorded as `SC-032`.

## FPGA boundary for `/SWITCHES`

`rtl/wrappers/hard_drivin_sound_switches.sv` is a storage-free raw connector
mapper. Its four-bit input order is `{J3-11,J3-9,J3-8,J3-7}` and therefore
maps directly, without inversion, to host `D15:D12`. It exports:

- fixed driven mask `16'hf000`;
- one validity bit for each connector input on the corresponding high lane;
- invalid-source clamping only as a deterministic interface carrier; and
- zero filler on `D11:D0` outside both masks.

The adapter deliberately has no names such as coin, test, or service, no
pull-state defaults, and no storage or reset. A later board wrapper supplies
raw conditioned connector values and a host bridge supplies an explicit
open-bus policy. **Confidence: VERIFIED_PRIMARY for connector-to-lane order
and non-inversion; VERIFIED_SIMULATION for the masked FPGA convention;
UNKNOWN for `OQ-032` connector semantics and idle state.**

## FPGA boundary for `/READSTAT`

`rtl/wrappers/hard_drivin_sound_read_status.sv` is a storage-free mapper. It
accepts raw `MAINFLAG`, `SOUNDFLAG`, `SOUND.TEST`, and `/TIRDY` values with one
validity bit per source. It exports:

- the four raw-polarity sources in host `D15:D12`;
- fixed driven mask `16'hf000`;
- a per-lane valid mask in `D15:D12`; and
- deterministic zero carriers for invalid sources and `D11:D0`.

The low twelve zeros are outside the driven mask and are not a board open-bus
claim. Likewise, an invalid high-nibble source is zero only in the carrier;
its cleared valid-mask bit prevents that value from becoming hardware
evidence. The future 68000/MiSTer bridge must combine this result with an
explicit platform open-bus policy. `SOUND.TEST` and `/TIRDY` remain raw inputs
so the mapper neither hardcodes MAME's constants nor models an unqualified
speech-device protocol. **Confidence: VERIFIED_PRIMARY for the bit/lane
mapping; VERIFIED_SIMULATION for the masked FPGA convention.**

## FPGA boundary for `/320PORT`

`rtl/wrappers/hard_drivin_sound_320_port_latch.sv` accepts a same-clock
physical I/O completion and captures only `io_write_data_i[7:0]` when port 3
is written. It exports:

- the raw eight-bit latch value and an explicit validity bit;
- a one-clock exact-commit pulse;
- `{latch, 8'h00}` as an interface data carrier;
- constant driven-lane mask `16'hff00`; and
- valid-lane mask `16'hff00` only after a real port-3 capture.

The low-byte zeros are filler outside the driven mask; this is not a physical open-bus claim.
`initialize_i` supplies deterministic FPGA storage with validity false;
processor and board reset do not clear the latch because no such connection
is drawn.

`hard_drivin_sound_mister` instantiates this path and treats port-3 output as
an internal no-wait target. It still exposes the physical I/O request and
commit for trace checking. The top does not yet decode a 68000 `/320PORT`
transaction or combine the masked value with a platform open-bus policy.

## FPGA low-host-read composition

`rtl/wrappers/hard_drivin_sound_host_read_mux.sv` composes the four already
qualified masked sources in Atari LS138 `30N` order:

| `read_quadrant_i` | `target_select_o` | selected source |
|---:|---:|---|
| `00` | `0001` | `/SOUNDRD` complete mailbox word |
| `01` | `0010` | `/320PORT` partial byte |
| `10` | `0100` | `/SWITCHES` raw nibble |
| `11` | `1000` | `/READSTAT` raw nibble |

`read_select_valid_i` means only that an external bridge has qualified one of
these source selections. When it is false, the output data and masks are all
zero and no target is claimed. When true, the mux forwards the selected
source's driven and valid masks without widening any physical lane, and
clamps data outside that valid mask to the deterministic zero carrier. This
keeps arbitrary pre-qualification storage contents out of the composed
carrier without changing the raw source output or assigning physical bus data.
It does not generate `/RVF` or `/RVAS`, sample 68000 strobes, produce DTACK, choose an
open-bus value, or cause any side effect. In particular, selecting
`/SOUNDRD` does not clear `MAINFLAG`; only the separate completed-read callback
does so. **Confidence: VERIFIED_PRIMARY for target order and lane maps;
VERIFIED_SIMULATION for storage-free masked composition.**

`hard_drivin_sound_mister` instantiates the raw switch mapper and this selector
alongside the existing mailbox, port latch, status mapper, and qualified
same-clock host-timing adapter. With `use_host_timing_i=0`, the original
explicit read-select callback remains selected. With it high, the adapter's
S4-through-S7 read-select and captured quadrant drive the mux, while the same
S7 `/SOUNDRD` completion clears `MAINFLAG`. All four selected sources still
export exact data, driven masks, and valid masks; the top does not synthesize
a complete word for partial targets. This is logical same-clock bus-cycle
composition, not raw-pin CDC or `OQ-030` open-bus resolution.

## Verification and synthesis

`tb_hard_drivin_sound_320_port_latch` exhausts all 65,536 TMS words, every
other port, direction and commit isolation, persistence, reinitialization,
and lane/valid masks. Five retained checks cover mask containment, validity,
commit qualification, and state validity.

The integrated board test forces external callback readiness low for port 3.
The smoke OUT captures `0xa5` and exposes masked host carrier `0xa500`; a
later low-address TBLW captures `0x30` from word `0xf230` and exposes
`0x3000`, exactly once, without modifying program RAM. This verifies the
same-clock FPGA boundary, not LS374 propagation delay or 68000 bus timing.
Standalone Yosys reports 19 abstract cells and five retained checks; the
integrated board hierarchy reports 2,966 cells, 257 checks, three memories,
and zero structural problems. Neither result is a Cyclone V fit.

`tb_hard_drivin_sound_read_status` exhausts all sixteen raw source nibbles
against all sixteen source-validity masks. It checks exact raw polarity,
per-lane validity, constant driven mask, invalid-source clamping, and the
separation between deterministic filler and physically driven lanes.
Standalone Yosys reports 23 abstract cells, eight retained checks, no storage
or latch, and zero structural problems. The board top now connects its flag
inputs directly to the qualified mailboxes and retains raw external
`SOUND.TEST`/`/TIRDY` inputs with their validity bits. The integrated test
checks exact status words and masks through nominal flag changes, both
mailbox conflicts, external-source invalidity, requalification, and board
reset. Its timing-enabled cases qualify the same-clock logical cycle but do
not choose an open-bus value or establish a raw-pin boundary.

`tb_hard_drivin_sound_switches` likewise exhausts all sixteen raw connector
nibbles against all sixteen connector-validity masks. It checks the exact
`J3-11/J3-9/J3-8/J3-7` lane order, non-inverting values, constant driven mask,
per-lane validity, invalid-source clamping, and low-lane filler separation.
Standalone Yosys reports 10 abstract cells, six retained checks, no storage or
latch, and zero structural problems. The board top now connects it to the
masked selector but proves neither connector semantics nor a 68000 read cycle.

`tb_hard_drivin_sound_host_read_mux` checks invalid-selection suppression,
exact Atari quadrant/one-hot order, distinct source masks, arbitrary nonzero
bits outside every source-valid mask, and every physically driven lane of all
four targets. Standalone Yosys reports 72 abstract cells,
13 retained checks, no storage or latch, and zero structural problems. The
integrated board regression separately proves the same order with live source
state, including MAME's swapped quadrant names, source validity propagation,
selection without mailbox flag clear, and both observed `/320PORT` latch
updates. The integrated timing cases additionally exercise all four read
quadrants from S4 through S7, confirm that the external selector is ignored
only while opted in, preserve each source mask, and clear `MAINFLAG` only at
the completed `/SOUNDRD` boundary.
