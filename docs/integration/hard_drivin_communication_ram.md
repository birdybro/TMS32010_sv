# Hard Drivin' communication RAM and sound-address path

## Scope

This document transcribes the A044427 Rev-A digital path that joins the
Driver Sound 68000, the 512-word communication RAM, and TMS32010 input port 1.
It also records the shared 16-bit sound-address counter because that counter,
not the DSP I/O-port number, supplies the communication-RAM address. Analog
audio, host DTACK timing, and unauthorized game firmware are outside scope.

## Storage and address wiring

Two HM6116 devices form a 16-bit data word. Their `A10` and `A9` inputs are
grounded; `CRA8:CRA0` reach the remaining address pins. The populated circuit
therefore exposes 512 words even though each component has a larger native
array. The upper and lower devices share `/CRCS`, `/CROE`, and `/CRWE`, so a
physical write enables both bytes together
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF p. 10]. **Confidence: VERIFIED_PRIMARY.**

When `CRAMEN=1`, LS244 `60L` drives `CRA7:CRA0` from host `A8:A1`, and the
host-control half of LS244 `20K` drives `CRA8` from `A9`, `/CROE` from
`/RWNB`, `/CRCS` from `/320COM`, and `/CRWE` from `/RWS`. Two LS245 devices
join all sixteen host data bits to `CRD15:CRD0`
[atari-driver-sound-board-schematic, sheets 3 and 5 of 10, PDF pp. 5-6 and
9-10]. This is a 16-bit host path with a nine-bit word address. The drawing
does not route `/HEU` or `/HEL` to either RAM byte; byte-write behavior remains
`SC-025`/`OQ-024` rather than an inferred merge.

When `CRAMEN=0`, LS244 `25E` instead drives `CRA7:CRA0` from `SA7:SA0`; the
other half of `20K` drives `CRA8` from `SA8`, forces chip select and output
enable active, and enables the CRD-to-TDI buffers. `/CRWE` is then held
inactive-high by `R89`, making the DSP path read-only. The CRD-to-TDI buffers
are selected only when the input decoder also asserts `/CRAM` for port 1
[atari-driver-sound-board-schematic, sheet 5 of 10, PDF pp. 9-10].
**Confidence: VERIFIED_PRIMARY.**

## Ownership

`CRAMEN` is output 3 of host LS259 `80R`. Board `/RESET` clears that latch,
giving the DSP-side address/read path ownership by default. The LS259's
separate active-low clear behavior is also defined by its manufacturer
[atari-driver-sound-board-schematic, sheet 3 of 10, PDF p. 6;
ti-sn74ls259b-datasheet-sdls086, printed pp. 1-4].
**Confidence: VERIFIED_PRIMARY.**

The ownership table is:

| `CRAMEN` | Host `/320COM` access | DSP port-1 read | Physical result |
|---:|---|---|---|
| 0 | disabled | enabled, read-only | `SA8:SA0` select RAM |
| 1 | enabled, read/write | CRD-to-TDI buffer disabled | host `A9:A1` select RAM |

Unlike the program-RAM path, this circuit contains complementary buffer
enables and does not create two simultaneous RAM-address drivers. A DSP port-1
read while `CRAMEN=1` is nevertheless outside the useful protocol: the RAM
input buffer is disabled, so the drawing does not establish a returned TDI
word. A digital adapter must not return the RAM contents and call that physical
behavior. The current pinned MAME handler does exactly that unconditionally;
the discrepancy is `SC-023`/`OQ-025`.

## Sound-address counter

Four cascaded LS191 devices produce `SA15:SA0`. A port-7 write asserts
`/SADR` and asynchronously loads all sixteen TMS data bits. Their direction
inputs are tied low for up-counting, their clocks share `/PDEN`, and the ripple
outputs enable the higher nibbles. TI specifies that LS191 counting occurs on
the low-to-high clock transition when count enable is low and that active-low
load asynchronously presets the outputs
[atari-driver-sound-board-schematic, sheet 6 of 10, PDF pp. 11-12;
ti-sn74ls191-datasheet-sdls072, printed pp. 1-4].
**Confidence: VERIFIED_PRIMARY.**

`/PDEN` is the shared physical input-read strobe, so its trailing low-to-high
edge increments the counter after every completed input-port read. This
includes port 2, not only sound-ROM port 0 and communication-RAM port 1. A
separate port-6 latch stores `TD3:TD0` as sound-ROM block selects `SCD:SCA`;
those four bits are not part of the communication-RAM address. The current
pinned MAME adapter combines these fields into one software offset and only
increments it in the port-0 and port-1 handlers. That narrower increment is
the abstraction recorded in `SC-024`.

No clear or board-reset input is drawn on the four LS191 counters. The
physical address is therefore not qualified until software writes port 7.
MAME's zero initialization and any deterministic FPGA `initialize_i` value are
implementation conveniences, not power-up claims.

## Port 3 is unresolved

The output LS138 decodes port 3 as active-low `/CPORT`, but the audited Rev-A
sheets show no loaded consumer for that named net. Pinned MAME's port-3
handler logs the written word and changes no modeled state. Neither fact proves
that “communication control” is a working hardware function. `OQ-023` retains
the possibility of an unreviewed ECO, test connection, or board variant.

The ROM-free smoke deliberately retains a port-3 write as a decode probe. Its
`0x00a5` value is not a claimed control command.

## FPGA adaptation requirements

A portable same-clock adapter may use synchronous read responses and explicit
commit pulses, provided it labels those as FPGA conventions. It must:

1. retain 512 complete 16-bit words without clearing them on processor reset;
2. grant exactly one ownership side from `CRAMEN`;
3. reject or hold DSP port-1 reads while the host owns the RAM;
4. keep the DSP path read-only;
5. use `sound_address[8:0]` for DSP reads and `host_address[8:0]` for host
   accesses;
6. increment the full 16-bit sound address exactly once after each accepted
   physical input read;
7. load the full counter on an accepted port-7 write and latch only the low
   nibble on port 6; and
8. expose port 3 without inventing a state effect.

These requirements describe the digital relationship, not the HM6116 AC
timing, 68000 DTACK generation, or firmware handoff interval.

## Current FPGA implementation

Three standalone modules implement this qualified digital boundary:

- `hard_drivin_sound_address_control` models the four-counter relationship and
  separate port-6 nibble, while retaining explicit validity flags because the
  drawing shows no physical clear on either state element;
- `hard_drivin_sound_communication_ram` retains 512 complete words, gives the
  selected host side read/write access, gives the selected DSP side read-only
  access, and returns registered owner-tagged read responses; and
- `hard_drivin_sound_communication_path` restricts the internal DSP request to
  physical port 1 at `sound_address[8:0]` while forwarding every committed
  physical input read to the global address increment logic.

`initialize_i` clears response-valid and state-valid metadata, but it neither
clears the communication memory nor claims a deterministic physical counter
or latch power-up value. A port-1 request before a port-7 load is explicitly
reported as an invalid address and is not acknowledged. A request by the
non-owning side is reported as blocked rather than returning RAM contents.
Port 3 is visible to the commit stream but has no state effect.

`tb_hard_drivin_sound_communication_path` loads every one of the 512 words
through whole-word host writes and reads every word through the DSP port-1
path at the exact low-nine address. It also checks both CRAMEN ownership
states, blocked accesses, synchronous response ownership, exactly-once
increments including port 2, 16-bit wrap, port-7 load, port-6 low-nibble
latching, port-3 non-effect, invalid initial address state, and storage
retention across FPGA initialization. **Confidence: VERIFIED_SIMULATION for
the stated adapter contract.**

The pre-technology Yosys target retains one `$mem_v2` in an 82-cell hierarchy
with seven checks and zero structural problems. This is portable memory-shape
evidence only; it is not a Quartus block-RAM mapping, physical HM6116 timing
result, or completed board top. The communication path is not yet connected
to `hard_drivin_sound_mister`, and there is still no 68000 byte-lane/DTACK
adapter or serial sound-ROM data implementation.
