# Hard Drivin' main-board primary and peripheral address decode

This note covers the SP-327 sheet-4 LS138 `160K`, both halves of LS139
`180E`, and the AS32 gate that produces `/RHSBUS`. It deliberately does not
claim to cover the separate ROM-bank LS138 `200M`, low-speed device decoders,
peripheral-internal register selection, or main-bus timing. Those are distinct
logic cones.

## Primary one-of-eight decode

LS138 `160K` has its active-high `G1` enable pulled high through `PR6`, its
active-low `G2A` enable connected to main `/AS`, and `G2B` grounded. Select
inputs `C:B:A` are `A23:A22:A21`. TI's LS138 function table makes all outputs
high while an enable is inactive and exactly one output low while enabled
[atari-hard-drivin-schematic-package-sp327, sheet 4, PDF p. 5;
ti-sn74ls138-datasheet, description and function table, printed pp. 1-2].

| `A23:A21` | output | physical byte-address region while `/AS=0` |
|---:|---|---|
| `000` | `/ROMEN` (Y0) | `0x000000..0x1fffff` |
| `001` | unconnected Y1 | `0x200000..0x3fffff` |
| `010` | unconnected Y2 | `0x400000..0x5fffff` |
| `011` | `/NBUS` (Y3) | `0x600000..0x7fffff` |
| `100` | `/EXTBUS` (Y4) | `0x800000..0x9fffff` |
| `101` | `/LSBUS` (Y5) | `0xa00000..0xbfffff` |
| `110` | `/HSBUS` (Y6) | `0xc00000..0xdfffff` |
| `111` | `/RAMEN` (Y7) | `0xe00000..0xffffff` |

`A20:A1` do not enter this decoder. The table describes raw primary selects,
not the final size or behavior of a memory or peripheral behind each select.
**Confidence: VERIFIED_PRIMARY for enable polarity, select order, signal
names, and logical regions.**

## RAM-region LS139

The first half of dual LS139 `180E` takes `/RAMEN` on its active-low enable.
Its `B:A` select inputs are `A15:A14`. TI defines the enabled mapping
`00 -> Y0`, `01 -> Y1`, `10 -> Y2`, and `11 -> Y3`, with the selected output
low and all others high [atari-hard-drivin-schematic-package-sp327, sheet 4,
PDF p. 5; ti-sn74ls139a-datasheet, function table and D/J/N/W pinout, printed
p. 1].

| `A15:A14` | output | raw selection within every selected 64 KiB block |
|---:|---|---|
| `00` | `/DUART` (Y0) | offset `0x0000..0x3fff` |
| `01` | `/ZRAM` (Y1) | offset `0x4000..0x7fff` |
| `10` | `/RAM0` (Y2) | offset `0x8000..0xbfff` |
| `11` | `/RAM1` (Y3) | offset `0xc000..0xffff` |

Thus this TTL selection ignores `A20:A16` and `A13:A1` (and, because the
physical MC68000 address bus begins at A1, has no A0 input). For example,
`0xff0000` is a canonical DUART base, but every address with
`A23:A21=111` and `A15:A14=00` asserts raw `/DUART`. The MC68681 separately
uses main `A4:A1` as `RS4:RS1` and `D15:D8` as its byte-wide data bus; this
decoder must not replace that peripheral-internal interpretation
[atari-hard-drivin-schematic-package-sp327, sheet 6, PDF p. 7].

Pinned MAME commit `030fefcbd14e47c01ec9d67655be90f64a1dc8ab`
maps only canonical software-facing ranges: DUART `0xff0000..0xff001f`, ZRAM
`0xff4000..0xff4fff`, and RAM `0xff8000..0xffffff`
[mame-harddriv-driver-030fefc, `driver_68k_map`, lines 564-566]. Those narrower
ranges are a secondary integration abstraction, not contrary physical-decode
evidence. **Confidence: VERIFIED_PRIMARY for the raw chip selects and broad
aliases; CORROBORATED for the canonical software ranges; UNKNOWN here for
downstream memory-device aliasing outside each implemented capacity.**

## High-speed host LS139

AS32 `160H` forms:

```text
/RHSBUS = /HSBUS OR /RVAS0
```

The second half of `180E` uses `/RHSBUS` as its active-low enable and again
uses `B:A = A15:A14`. Y0 is `/GSP`, Y1 is `/MSP`, and Y2/Y3 are unconnected.
Raw `/HSBUS` therefore identifies the address region, but neither TMS34010
host chip select asserts until the early held `/RVAS0` strobe is active
[atari-hard-drivin-schematic-package-sp327, sheet 4, PDF p. 5;
ti-sn74als32-datasheet-sdas113b, printed pp. 1 and 4;
ti-sn74ls139a-datasheet, function table, printed p. 1].

| `A15:A14` | output | raw address class with `/RVAS0=0` |
|---:|---|---|
| `00` | `/GSP` (Y0) | `A23:A21=110`, offset `0x0000..0x3fff` |
| `01` | `/MSP` (Y1) | `A23:A21=110`, offset `0x4000..0x7fff` |
| `10` | unconnected Y2 | `A23:A21=110`, offset `0x8000..0xbfff` |
| `11` | unconnected Y3 | `A23:A21=110`, offset `0xc000..0xffff` |

Supplemental Atari sheets connect `/GSP` and `/MSP` to the corresponding
TMS34010 `HCS` inputs. Their internal host-function and byte-strobe pins
interpret additional lower address and lane information; the LS139 does not
[atari-hard-drivin-main-board-gsp-supplement, drawing A044425 Rev J, sheet
10, PDF p. 1; atari-hard-drivin-main-board-msp-supplement, drawing A044425
Rev J, sheet 15, PDF p. 1]. Pinned MAME exposes canonical windows
`0xc00000..0xc03fff` and `0xc04000..0xc07fff`
[mame-harddriv-driver-030fefc, `driver_68k_map`, lines 562-563]. The physical
TTL select also ignores `A20:A16` and therefore repeats those two 16 KiB
classes across the full `0xc00000..0xdfffff` HSBUS region.
**Confidence: VERIFIED_PRIMARY for the physical selection, `/RVAS0`
qualification, and aliases; CORROBORATED for the canonical software ranges.**

## RTL and verification boundary

`hard_drivin_main_address_decode` exposes all eight LS138 outputs, all four
outputs of each LS139 half, and named board nets. Retaining unconnected Y
outputs makes the full truth tables and one-hot-low behavior observable. Its
input is physical `A23:A1`; exhaustive simulation varies every consumed
`A23:A14` combination with `/AS` and `/RVAS0`, while directed checks vary the
ignored address fields and compare canonical and mirrored selections.

A one-step bounded proof checks each LS138 output equation, all named RAM and
HSBUS equations, three one-hot-low invariants, and six non-vacuous covers.
Yosys 0.67+111 synthesizes the storage-free block to 49 cells with 20 retained
checks, no memory, latch, generated clock, or structural warning. This is not
a peripheral model, a complete main-board memory map, a raw-pin CDC boundary,
or electrical propagation analysis.
