# Driver Sound upper-Y5 direct TMS I/O

This note qualifies the local MC68000 path that reaches the TMS32010 I/O
hardware through the upper half of high bank Y5. It does not assign an
open-bus value, prove that firmware uses every alias, or permit simultaneous
host and running-TMS ownership.

## Host transceivers and upper-Y5 controls

While `/320RAM` is asserted, LS244 pairs 70L/40L drive MC68000 `A12:A1` onto
`RA11:RA0`. LS245 pairs 40L/30L connect `D15:D0` to the TMS data nodes, with
direction selected by `/RWNB`. A13 divides Y5: its lower half controls the 4K
program RAM, while its upper half generates `/PWE` for writes or `/PDEN` for
reads [atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 4-5
of 10, PDF pp. 7-10]. **Confidence: VERIFIED_PRIMARY.**

`/PWE` follows the `RVA` interval and returns high at the modeled S6 rising
boundary. `/PDEN` remains active through `/RVAS` and returns high at S7. The
same `/PDEN` trailing edge clocks all four shared-address LS191 counters, so
every direct input read increments `SA15:SA0`, independent of which input
port was selected [atari-driver-sound-board-schematic, sheets 5-6 of 10, PDF
pp. 9-12; ti-sn74ls191-datasheet-sdls072, printed pp. 1-4]. **Confidence:
VERIFIED_PRIMARY for the logical edge relationship; electrical delays remain
outside the RTL.**

## Asymmetric downstream decode

The read and write paths do not have the same aliases.

For writes, three LS27 gates reduce `RA11:RA3`, and ALS11 95F forms `PORT`
only when all nine bits are zero. LS138 100K is enabled by `PORT` and `/PWE`,
then decodes `RA2:RA0`:

| port | LS138 output | drawn target |
|---:|---|---|
| 0 | Y0 | `/DACL` |
| 1 | Y1 | parenthesized optional `/DACR` |
| 2 | Y2 | no labeled connection |
| 3 | Y3 | `/CPORT` |
| 4 | Y4 | `/MCLK` |
| 5 | Y5 | `/68IRQ` |
| 6 | Y6 | `/SBLCK` |
| 7 | Y7 | `/SADR` |

Therefore only word addresses `0x000` through `0x007` select a write target.
At `0x008` through `0xfff`, `/PWE` still has its upper-Y5 timing but none of
the eight LS138 outputs is active. The FPGA boundary reports those events as
unselected and never aliases them onto a low port.

For reads, LS139 95K is enabled directly by `/PDEN` and sees only `RA1:RA0`:

| `RA1:RA0` | output | target |
|---:|---|---|
| 0 | Y0 | `/SROM` |
| 1 | Y1 | `/CRAM` |
| 2 | Y2 | `/CMPRD` |
| 3 | Y3 | no drawn data-source enable |

`RA11:RA2` do not enter this decoder. All upper-Y5 read addresses therefore
alias modulo four across the complete 4K-word window. Port 3 claims a decoder
output but no Rev-A source drives the TMS/host word. Its driven and valid masks are
zero; no deterministic filler is architectural board behavior. Sources:
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 5 of 10,
PDF pp. 9-10; ti-sn74ls138-datasheet, printed pp. 1-2]. **Confidence:
VERIFIED_PRIMARY.**

## Read carrier qualification

- Port 0 drives a complete word when the selected, present sample ROM returns
  a byte. The data mapping remains signed-byte-left-seven. The fixed host
  cycle has no READY input, so an FPGA ROM response must be valid by S7 or the
  valid mask remains zero.
- Port 1 can drive a complete word only when `CRAMEN=0` gives the communication
  RAM to the TMS side. With `CRAMEN=1`, its LS244 output is disabled; this is
  the unresolved firmware contract in `OQ-025`.
- Port 2 claims only `TD15` from the explicit external comparator callback.
  Lower lanes remain undriven and the loaded source remains unknown under
  `OQ-029`.
- Port 3 has neither driven nor valid bits. Platform open-bus completion stays
  outside the architectural board wrapper under `OQ-030`.

## MAME comparison

Pinned MAME maps one canonical `0xff6000-0xff7fff` host window and calls the
DSP I/O space with `offset & 7` for both reads and writes. Its DSP map defines
read handlers only at ports 0, 1, and 2 and write handlers at ports 0-7
[mame-harddriv-audio-030fefc, `driversnd_68k_map`,
`hdsnd68k_320ports_r`, `hdsnd68k_320ports_w`, and
`driversnd_dsp_io_map`]. This reproduces canonical software accesses but not
the physical asymmetry: it aliases noncanonical writes modulo eight and does
not alias physical reads modulo four. `SC-034` records the conflict.

## RTL and evidence

`hard_drivin_sound_direct_io` is storage-free. It exports independent one-hot
read, read-completion, write, and write-completion targets; a raw write-data
carrier; read driven/valid masks; and explicit read-alias/write-unselected
diagnostics. Its exhaustive test checks all 4,096 addresses in both directions
and proves that invalid or undriven response bits cannot leak into returned
data. Standalone Yosys synthesis is a structural check, not electrical timing
qualification.

`hard_drivin_sound_mister` connects the adapter to the existing sample-ROM,
communication-RAM, comparator callback, DAC, CPORT, MUTE/IRQ, ROM-block, and
sound-address state. Direct writes commit at S6; direct reads increment the
shared address at S7. A host/TMS I/O overlap drives neither modeled consumer
and raises `direct_io_ownership_conflict_o`; the wrapper assigns no priority
to an electrically invalid overlap under `OQ-021`.

The board-level regression performs canonical direct writes to ports 7, 6,
0, and 3, reads ports 0 and 2, checks an aliased undriven port-3 read, and
proves a noncanonical write has `/PWE` timing without a target. Synthetic ROM
and comparator values contain no copyrighted game data.
