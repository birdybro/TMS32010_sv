# Hard Drivin' Driver Sound local 68000 memory decode

## Scope and evidence boundary

This document traces the local MC68000 ROM, high-bank, DSP-program-path, and
local-RAM controls on Atari Driver Sound drawing A044427 Rev A. It describes
the physical Boolean decode and populated memory address projections needed by
TM-327's synthetic local program-ROM/program-RAM diagnostics. It does not
provide a 68000 core, copyrighted ROM, memory storage, DTACK generator,
electrical timing closure, or open-bus value.

Atari's schematic is the wiring authority. TI component data sheets establish
the LS138 active-low one-of-eight decode and ALS32 positive-OR functions. The
pinned MAME map is kept as a secondary software-oriented comparison
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3-5 of 10,
PDF pp. 5-10; ti-sn74ls138-datasheet, printed pp. 1-2;
ti-sn74als32-datasheet-sdas113b, printed p. 1;
mame-harddriv-audio-030fefc, `driversnd_68k_map` and the associated
`hdsnd68k_320*` handlers].

## Low-half ROM gate and populated address

ALS32 `30R` drives both EPROM `/CE` pins with:

```text
/ROMCE = A23 OR /AS
```

The two drawn `27256D20` devices at `70N` and `45N` supply `D15:D8` and
`D7:D0`. They share `/CE` and `/OE`, so a selected read drives a complete
sixteen-bit word; `/UDS` and `/LDS` do not gate either EPROM output. CPU
`A1:A15` reach the devices' fifteen address inputs. CPU `A16` reaches only the
`E1/E2` option at pin 1, which the populated 27256 symbol identifies as VPP.

Consequences for the drawn 27256 population are:

- every asserted `/AS` cycle with `A23=0` selects the ROM pair;
- `A22:A16` are absent from the populated word address;
- the physical 64 KiB image repeats throughout `0x000000-0x7fffff`; and
- the storage word address is `A15:A1`.

The exact installed `E1/E2` strap and any later larger-EPROM board population
remain `OQ-034`. The RTL therefore exports only the verified populated-27256
address and explicitly does not implement a larger-EPROM mode. **Confidence:
VERIFIED_PRIMARY for the Rev-A drawing and populated-device projection;
UNKNOWN for production strap/variant coverage.**

## High-bank LS138

LS138 `30P` is enabled by `A23=1`, asserted `/AS`, and its grounded second
active-low enable. Its select inputs are `A16:A14`. For the conventional
`0xffxxxx` page, the reachable outputs are:

| `A16:A14` | active-low output | canonical range | downstream role |
|---:|---|---|---|
| `100` | Y4 `/RVF` | `0xff0000-0xff3fff` | low mailbox/control/read bank |
| `101` | Y5 | `0xff4000-0xff7fff` | qualified DSP program/direct-I/O path |
| `110` | Y6 | `0xff8000-0xffbfff` | qualified communication RAM |
| `111` | Y7 `/RAM` | `0xffc000-0xffffff` | local 68000 SRAM |

`A22:A17` do not reach `30P`, so each row has 64 physical high-half aliases.
Y5 and Y6 pass through ALS32 `95L` with `/RVAS`, producing `/320RAM` and
`/320COM`. Y7 drives the local SRAM `/CS1` pins directly; their `/CS2` pins
receive pulled-high `PR3`. This is an address-selection distinction, not an
arbitrary wait mechanism. **Confidence: VERIFIED_PRIMARY.**

## Y5 program/direct-I/O subdecode

The 16 KiB Y5 bank is not one undifferentiated program-RAM alias. Sheet 5
generates four buffered controls, and sheet 4 passes them through LS244 `80L`
only while `/320RAM` is selected:

```text
/NRCE  = NOT(RVAS AND NOT A13)
/NPWE  = NOT(RVA AND /RWNB AND A13)
/NPDEN = NOT(RVAS AND RWNB AND A13)
```

Here `/RWNB=NOT RWN`, `RWNB=RWN`, and `RVAS` is the active-high complement of
`/RVAS`. Therefore:

- `0xff4000-0xff5fff` (`A13=0`) selects the 4K-by-16 DSP program RAM, using
  host `A12:A1` as its word address;
- `0xff6000-0xff7fff` (`A13=1`) sends a write pulse as `/PWE` or a held read
  enable as `/PDEN` into the TMS-side physical address/I/O decode; and
- neither upper/lower host data strobe enters these whole-word program/direct-
  I/O controls.

The final direct-I/O target still depends on the TMS-side `RA` decode. In
particular, this section does not claim that every upper-half address is a
verified eight-way I/O alias merely because MAME masks its handler offset with
seven. **Confidence: VERIFIED_PRIMARY for the raw controls and canonical
split; direct-I/O alias behavior outside canonical low offsets is not yet
qualified.**

## Local SRAM and byte lanes

The two `6264D15` devices at `85N` and `60N` supply the upper and lower bytes.
They share CPU `A1:A13`, `/RAM`, and `/RWNB`, forming 8K sixteen-bit words at
the canonical `0xffc000-0xffffff` range. ALS32 `30R` produces:

```text
/RWS = RWN OR /RVAS
/WEU = /UDS OR /RWS
/WEL = /LDS OR /RWS
```

`/RWNB=NOT RWN` drives both `/OE` pins. A selected read consequently drives
all `D15:D0`, independent of `/UDS` and `/LDS`; a write can update the upper
and lower 6264 slices independently. CPU `A22:A14` do not reach the SRAM word
address, although Y7 must still be selected. **Confidence: VERIFIED_PRIMARY
for Boolean controls, address projection, and lane wiring; no SRAM AC timing
claim is made.**

## MAME comparison

Pinned MAME declares canonical windows at `0x000000-0x01ffff`,
`0xff0000-0xff3fff`, `0xff4000-0xff5fff`, `0xff6000-0xff7fff`,
`0xff8000-0xffbfff`, and `0xffc000-0xffffff`. Its Hard Drivin' sets load one
`0x8000`-byte even EPROM and one `0x8000`-byte odd EPROM into a `0x20000`-byte
region. The 64 KiB populated payload corroborates the two drawn 27256 devices,
but the emulator's 128 KiB declared ROM window and omission of the broad
`A23=0`/high-bank aliases do not reproduce the physical gates. Its direct-I/O
handlers also use `offset & 7`, which is not by itself proof of every physical
upper-Y5 alias. These differences are recorded as `SC-034`; canonical
software behavior remains useful but cannot replace the schematic decode.

## RTL, verification, and synthesis

`rtl/wrappers/hard_drivin_sound_local_memory_decode.sv` is a storage-free
combinational transcription. It exposes all eight raw LS138 outputs, ROM and
local-RAM selects, `/320RAM` and `/320COM`, the Y5 program/direct-I/O
controls, local byte write enables, complete-word read masks, and exact
populated ROM/program/local-RAM word-address projections.

`tb_hard_drivin_sound_local_memory_decode` exhausts 131,072 combinations of
both `/AS` states, both `RVA` states, both `/RVAS` states, both `A23` values,
all 64 ignored `A22:A17` aliases, all eight `A16:A14` banks, both values of
subdecode `A13`, both transfer directions, and all four
`/UDS`/`/LDS` combinations. Directed projections
separately verify ignored ROM and SRAM address bits. The test assigns no
memory contents or open-bus value.

Yosys 0.67+111 reports 56 abstract combinational cells, 17 retained checks,
no memory or latch, and zero structural problems. This evidence qualifies the
Boolean decode only; it is not a raw-pin bridge, SRAM/EPROM model, Cyclone V
fit, or electrical timing result.

## Same-clock storage callback bridge

`rtl/wrappers/hard_drivin_sound_local_memory_bridge.sv` consumes the settled
same-clock state exported by `hard_drivin_sound_host_timing`: active-cycle
state, `RVA`, `/RVAS`, the pre-edge ordinary S7 completion event, and the
captured address, R/W direction, and byte strobes. The host write word is not
captured at `/AS`; the caller must retain it through its documented write-data
interval and the callback boundary, just as the current board-top timing path
does.

The bridge remains storage-free and exposes these callbacks:

| physical target | request/level | completion boundary |
|---|---|---|
| populated 27256 pair | complete-word read request with `A15:A1` | data must be valid by fixed S7; no READY exists |
| local 6264 pair | complete-word read request with `A13:A1` | upper/lower write commits independently at S7 |
| Y5 lower half | program-RAM read/write level with `A12:A1` | whole-word write commit at S7 |
| Y5 upper half | direct `/PDEN` or `/PWE` level with `A12:A1` | direct `/PWE` callback is sampled at the S6 rising boundary |
| Y6 | communication-RAM read/write level with `A9:A1` | whole-word write commit at S7 |

The S6 `/PWE` distinction is externally relevant. `/PWE` is generated from
`RVA`, so its rising edge occurs when `RVA` ends at S6. The SRAM write controls
instead remain active through `/RVAS` and end at S7. All callback event outputs
are pre-edge enables intended for same-clock `always_ff` consumers; they are
not asynchronous pulses or a new clock.

The bridge's ROM/local-RAM read carrier always reports a complete physical
driven mask for a selected read. Data validity is separate: an unavailable
ROM response or an unwritten synthetic SRAM word has a zero valid mask and
zeroed carrier data, while the driven mask remains `16'hffff`. A distinct
missing-response event is emitted at fixed S7. This is observability, not a
wait state and not an assigned open-bus value.

`tb_hard_drivin_sound_local_memory_bridge` composes the actual timing adapter,
decoder, bridge, and a testbench-only synthetic byte-valid SRAM. It checks
ROM-valid, ROM-invalid, and mirrored ROM reads; an invalid unwritten SRAM
read; complete and upper-byte SRAM writes; a broad Y7 alias; Y5 program reads
and writes; Y5 direct reads and S6 writes; Y6 communication reads and writes;
and isolation of the separate Y4 low-I/O path. No copyrighted image is used.

Yosys 0.67+111 reports 305 abstract combinational hierarchy cells, 40
retained checks, no memory or latch, and zero structural problems.

## Board-top composition

When `hard_drivin_sound_mister.use_host_timing_i=1`, the board top now feeds
the complete captured host cycle into this bridge. Lower-Y5 select, direction,
`A12:A1`, raw write data, and the S7 commit drive the existing shared program-
RAM adapter. Y6 similarly drives the existing communication-RAM host port at
`A9:A1`; CRAMEN remains the independent ownership qualification. The explicit
program/communication callbacks remain selected unchanged when timing mode is
off, so the integration does not silently replace the older same-clock API.
The physical bridge still exposes the unqualified whole-bank write level, but
the FPGA storage mux accepts its commit only when both host byte strobes are
active. Partial lower-Y5/Y6 writes emit separate diagnostic pulses and leave
the FPGA memories unchanged under `OQ-022`/`OQ-024`; this is an explicit
protective boundary, not a claim that the physical board suppresses the write.

The board top forwards the complete ROM callback, local-RAM callback, byte-
specific local-RAM commits, read carrier masks, and missing-response event to
its caller. It also forwards the upper-Y5 `/PDEN` level and `/PWE` S6 commit,
but does not yet connect that direct path to a complete MC68000/TMS data-bus
multiplexer. ROM bytes remain external. The local-SRAM callback remains the
default, while `use_internal_local_ram_i` explicitly selects the optional
storage described below. No copyrighted image or open-bus value is embedded.

### Optional lane-valid FPGA SRAM

`hard_drivin_sound_local_ram` implements the drawn pair as separate 8K-by-8
upper and lower data memories with one shared two-bit lane-validity memory.
Reads are combinational, matching the same-clock fixed-cycle bridge contract;
S7 callbacks write either byte independently. A read returns zero on every
invalid lane and carries exactly one of `0x0000`, `0xff00`, `0x00ff`, or
`0xffff` as its validity mask. Physical driven-lane reporting remains in the
bridge and is therefore still independent of known FPGA contents.

Neither data memory is reset. On `initialize_i`, a small controller instead
starts a sequential 8,192-clock scrub of validity metadata. Storage reports
not-ready throughout that interval, all reads remain invalid, and attempted
writes raise `host_local_ram_storage_write_blocked_o` rather than being
accepted ahead of a later scrub location. This is a deterministic FPGA
qualification policy, not a claim that either physical 6264 clears, waits, or
blocks writes after board reset. An integration selecting internal storage
must finish the scrub before releasing the local processor; the fixed Atari
host path has no READY mechanism with which to stretch an early access.

When internal storage is selected, the external local-RAM request and write-
commit outputs remain inactive, while the raw word address and write data stay
observable. When it is not selected, the original external data/validity and
callback interface is unchanged. Authorized ROM supply is independent of this
choice.

`tb_hard_drivin_sound_local_ram` checks the exact 8,192-clock scrub, blocked
pre-ready writes, all 8,192 invalid words, independent upper/lower validity,
all 8,192 complete-word writes and reads, and reinitialization invalidation.
Standalone Yosys retains three abstract memories and reports 88 cells, nine
checks, no latch, and zero structural problems.

`tb_hard_drivin_sound_mister` verifies the composition with synthetic mirrored
ROM and external lane-valid local-SRAM responses, then opts into the internal
SRAM, proves an external all-valid sentinel is ignored, writes the two byte
lanes independently, and reads one fully valid combined word. It also checks
lower-Y5 program-RAM write/readback, upper-Y5 direct-I/O isolation and S6
commit, and Y6 communication-RAM write/readback under CRAMEN. Opposite explicit
callback sentinels prove timing-mode ownership, and later board tests prove the
explicit-callback fallback still operates with timing mode disabled.

The composed board hierarchy retains six memories and reports 3,424 abstract
cells with 362 checks and zero structural problems in Yosys
0.67+111. This remains pre-technology synthesis, not raw-pin CDC, a complete
MC68000 data-bus mux, a Cyclone V fit, or electrical timing closure.
