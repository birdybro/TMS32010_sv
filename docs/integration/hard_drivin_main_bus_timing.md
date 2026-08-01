# Hard Drivin' main-board `/DTACK`, `/RVAS0`, and `/RVAS` timing

This note covers only the SP-327 main-board logic that converts an asserted
main-processor `/AS` into early `/RVAS0`, `RVA`, and held expansion-bus
`/RVAS` strobes until the main-board `/DTACK` path has completed. It is
distinct from the A044427 local sound-68000 timing in
`hard_drivin_host_timing.md`. The complete combinational
`/DTACK` cone is now transcribed separately from the sequential hold state.
Supplemental Atari sheets identify the two graphics-processor wait sources,
and TI defines their common host-ready protocol. SP-327 plus Motorola's exact
MC68681 publication likewise qualify the DUART acknowledge boundary.
Device-internal response latency, raw clock-domain relationships, and
nanosecond timing margin remain outside the implemented blocks.

## Primary logic trace

SP-327 sheet 4 implements the following chain:

1. `/AS` passes through F04 `160M`; its rising output clocks D=1 into F74
   `135C`. This records an address-strobe assertion and drives `/S4` low.
2. The next rising `8MHZ` edge clocks that request into F74 `135H`. Its Q is
   `RVA`, its complementary output is `/RVA`, and `/RVA` clears the request
   latch. The next rising `8MHZ` edge therefore returns `RVA` low unless a new
   request was captured.
3. Active `/RVA` drives the asynchronous active-low preset of F74 `120H`.
   The flip-flop's complementary output is `/RVAS`, so the preset immediately
   asserts `/RVAS` low.
4. A separate F74 `135C` samples `/DTACK` on rising `/8MHZ`, equivalently the
   falling edge of `8MHZ`. Its Q drives the clock input of F74 `120H`.
5. F74 `120H` has D tied low. A sampled `/DTACK` low-to-high transition clocks
   Q low and therefore releases `/RVAS` high.

The request latch, `RVA` latch, sampled-`/DTACK` latch, and `/RVAS` latch all
show their asynchronous preset/clear inputs tied inactive through `PR7`; the
drawing does not connect them to board `/RESET`
[atari-hard-drivin-schematic-package-sp327, sheet 4, PDF p. 5]. TI specifies
the populated F74 as a positive-edge-triggered D flip-flop with asynchronous
active-low preset and clear [ti-sn74f74-datasheet-sdfs046a, description,
pinout, and function table, printed p. 1]. **Confidence: VERIFIED_PRIMARY for
this logical signal chain and polarity.**

The neighboring F74 `135H` output `/RVAS0` is a distinct early held-valid
strobe. Its D and ground pin are tied low, `/CLR` is pulled high, and AS32
`135K` drives `/PRE` from `8MHZ OR /S4`. The sampled-`/DTACK` Q clocks its
D=0 release. Active `/S4` therefore presets `/RVAS0` immediately during an
8 MHz low phase and at the next falling edge after a high-phase assertion.
The active-low preset dominates a coincident release clock, per the F74
function table. `/RVAS0` qualifies the `/HSBUS` acknowledgement path; it is
not the J7 expansion-bus `/RVAS` output
[atari-hard-drivin-schematic-package-sp327, sheet 4, PDF p. 5;
ti-sn74als32-datasheet-sdas113b, printed pp. 1 and 4;
ti-sn74f74-datasheet-sdfs046a, printed p. 1]. **Confidence:
VERIFIED_PRIMARY for connectivity, polarity, phase equation, and priority.**

## Normal MC68000 phase contract

The main MC68000 asserts `/AS` after the rising edge entering S2. The next
falling edge enters S3; `8MHZ` then goes low, making the `/RVAS0` preset
active before the next rising edge enters S4. S4 transfers the captured
request into `RVA` and presets `/RVAS`. For a selected no-wait HSBUS cycle,
the early `/RVAS0` term has already asserted `/DTACK` before the processor's
S4 completion sample at the following falling edge. That falling edge also
records `/DTACK=0` in F74 `135C` [motorola-m68000-users-manual-ninth,
§4.1.1 and MC68000 timing table on printed pp. 10-24 through 10-26;
atari-hard-drivin-schematic-package-sp327, sheet 4, PDF p. 5].
**Confidence: VERIFIED_PRIMARY for the individual edges and gates;
INFERRED from their composition for the named no-wait HSBUS intent.**

After the S7 falling edge, the MC68000 begins negating `/AS`. That releases
the raw `/HSBUS` address decode and hence `/DTACK`; the following falling
8 MHz edge samples the resulting high level and releases `/RVAS0` and
`/RVAS`. An asserted `/GSPWAIT` or `/MSPWAIT` holds `/DTACK` high after
`/RVAS0` assertion until both inputs return high.

Atari's supplemental Driver Main drawing connects `/GSP` to the GSP
TMS34010 `HCS` input and `/GSPWAIT` directly to its `HRDY` output. The
separate MSP sheet makes the corresponding `/MSP`-to-`HCS` and
`/MSPWAIT`-to-`HRDY` connections
[atari-hard-drivin-main-board-gsp-supplement, drawing A044425 Rev J, sheet
10, PDF pp. 1-2; atari-hard-drivin-main-board-msp-supplement, drawing
A044425 Rev J, sheet 15, PDF pp. 1-2]. TI defines `HCS` as active-low and
`HRDY` as high when a host access may complete. `HRDY` is driven low when the
host must wait, is always high while `HCS` is high, and returns high before
the host ends a stalled access [ti-tms34010-users-guide-spvu001-1988, Table
2-2, printed pp. 2-5-2-6; §10.3.2 and Figures 10-8-10-9, printed pp.
10-8-10-10]. Thus the inactive or unselected graphics processor contributes
a high level, while either selected processor may independently extend the
shared `/HSBUS` cycle by driving its own wait net low. **Confidence:
VERIFIED_PRIMARY for device ownership, direct connection, polarity, and the
general host-ready protocol; UNKNOWN for the workload-dependent duration,
cross-clock propagation, and electrical margin of a particular access.**

## MC68681 acknowledge ownership

SP-327 sheet 6 connects `/RDUART` directly to MC68681 `CS` pin 35, connects
`DTACK` pin 9 to `/DUDTACK`, and pulls that net to +5 V through R49=4.7 kΩ.
The DUART uses a dedicated 3.6864 MHz crystal at `X1/CLK` and `X2`; it does
not share the main processor's 8 MHz phase. Motorola defines active-low `CS`
as initiating a read or write cycle and the three-state, active-low,
open-drain `DTACK` output as confirming a completed read, write, or interrupt
acknowledge [atari-hard-drivin-schematic-package-sp327, sheet 6, PDF p. 7;
motorola-mc68681-advance-information-1985, §§1.1-1.2, printed p. 1-3 and
§§2.5-2.7, printed p. 2-3].

The exact-device AC table requires `CS` setup at least 90 ns before a rising
`X1/CLK` edge for the illustrated recognition point and allows `DTACK` up to
125 ns after that edge. If setup is missed, acknowledgement may move one
DUART clock later. After `CS` is negated, `DTACK` negates within 100 ns and
becomes high impedance within 125 ns [motorola-mc68681-advance-information-1985,
§§5.5, 5.7-5.8 and Figures 5-2-5-3, printed pp. 5-2-5-4]. The later
MC68HC681 manual corroborates that clocked interface and explicitly warns
where successor write-latching differs; no successor-only behavior is
assigned to Atari's MC68681 [nxp-mc68hc681-users-manual-mc68681um-1996,
§5.5.3, printed pp. 5-4-5-6].

Consequently, the main-board gate logic cannot replace `/DUDTACK` with a
fixed number of 8 MHz phases. It must accept a peripheral-owned completion
level. When the raw `/DUART` selection ends, `/RDUART` goes high and the
board's OR gate suppresses any still-low open-drain pin during its specified
release interval. **Confidence: VERIFIED_PRIMARY for part identity, clock,
wiring, pull-up, selection, polarity, and the generic read/write acknowledge
protocol; UNKNOWN for the exact cross-clock phase and loaded propagation
margin of any individual board cycle.**

## Complete combinational `/DTACK` cone

SP-327 sheet 4 uses three active-low acknowledgement terms. Written as direct
Boolean equations, with every slash retained from the drawing:

```text
AS_ASSERTED     = NOT /AS
/VPA            = NAND(AS_ASSERTED, FC2, FC1, FC0)
DEFAULT_TERM_N  = NAND(/VPA, RVA, /HSBUS, /DUART)

/RHSBUS         = /HSBUS OR /RVAS0
WAIT_NAND       = NAND(/GSPWAIT, /MSPWAIT)
HSBUS_TERM_N    = /RHSBUS OR WAIT_NAND

/RDUART         = /DUART OR /RVAS
DUART_TERM_N    = /RDUART OR /DUDTACK

/DTACK          = DEFAULT_TERM_N AND HSBUS_TERM_N AND DUART_TERM_N
```

LS20 `150K` creates `/VPA` for an asserted function-code-7 CPU-space cycle and
the ordinary `RVA` acknowledgement. ALS32 `160H` creates `/RHSBUS` and
`/RDUART`. AS00 `190E` combines the two processor-wait inputs, two AS32 gates
make the specialized acknowledgement terms, and F11 `140K` ANDs the three
active-low results. The F11 `2A/2B/2C/2Y` pins are 3/4/5/6, exactly matching
TI's three-input positive-AND pinout; it is not an inferred OR despite the
scan's compact gate outline [atari-hard-drivin-schematic-package-sp327,
sheet 4, PDF p. 5; ti-sn74ls20-datasheet-sdls079, printed pp. 1 and 3;
ti-sn74as00-datasheet-sdas187a, printed pp. 1 and 4;
ti-sn74als32-datasheet-sdas113b, printed pp. 1 and 4;
ti-sn74f11-datasheet-sdfs040a, printed pp. 1 and 4]. SP-327 sheet 6 and
Motorola's exact-device publication qualify `/DUDTACK` as the clocked,
active-low open-drain MC68681 acknowledgement described above. Its timing is
deliberately not recreated inside this gate block
[atari-hard-drivin-schematic-package-sp327, sheet 6, PDF p. 7;
motorola-mc68681-advance-information-1985, §§2.5-2.7 and 5.7-5.8, printed
pp. 2-3 and 5-3-5-4]. **Confidence: VERIFIED_PRIMARY for the full Boolean
cone and both peripheral contracts; UNKNOWN for peripheral-internal latency
and electrical propagation margin.**

For the sound-reset expansion write, the LS138 decode selects `/EXTBUS`, not
`/HSBUS` or `/DUART`. A non-CPU-space cycle therefore uses the ordinary term:
`RVA=1` asserts `/DTACK`, and the next `RVA=0` releases `/DTACK`. The
specialized terms remain inactive-high. A synthetic composed test fixes a
representative non-CPU function code and proves that sequence through
`/RVAS` and `/SRES`; it does not claim the main processor's software mode or
raw pin delays.

## Logical event sequence

For a transaction whose main-board acknowledgement logic first asserts and
then releases `/DTACK`, the event-level sequence is:

| event | `RVA` | `/RVAS0` | sampled `/DTACK` | `/RVAS` | effect |
|---|---:|---:|---:|---:|---|
| FPGA initialization convention | 0 | 1 | 1 | 1 | deterministic idle only |
| S2 high-phase `/AS` assertion | 0 | 1 | unchanged | 1 | request pending |
| S3 falling 8 MHz | 0 | 0 | previous level | 1 | early HSBUS valid |
| S4 rising 8 MHz | 1 | 0 | unchanged | 0 | ordinary/expansion access begins |
| S5 falling with `/DTACK=0` | 1 | 0 | 0 | 0 | completion transition armed |
| S6 rising 8 MHz | 0 | 0 | 0 | 0 | `RVA` ends; held strobes remain |
| later falling with `/DTACK=1` | 0 | 1 | 1 | 1 | sampled low-to-high edge releases both holds |

`/RVAS` is therefore not a fixed-duration pulse and cannot be reconstructed
from elapsed clocks or an abstract transaction commit. If `/DTACK` never
samples low, the final F74 receives no later rising clock transition and
`/RVAS` remains asserted. The new RTL deliberately preserves that stuck-hold
case instead of adding a timeout. The equations that decide when the physical
main-board `/DTACK` signal goes low and high are now implemented. The
graphics-ready and DUART acknowledgement inputs remain externally owned;
their sources, polarity, and general selection/completion protocols are now
source-qualified.
**Confidence: VERIFIED_PRIMARY for the state dependency;
VERIFIED_SIMULATION/FORMAL for the discrete event model; UNKNOWN for the
complete acknowledgement-path delay and fault behavior.**

## FPGA boundary

`hard_drivin_main_rvas_timing` uses one FPGA clock and caller-supplied,
mutually exclusive `main_8mhz_rise_i`, `main_8mhz_fall_i`, and
`address_strobe_assert_i` events plus `main_8mhz_high_i`. It requires every
phase-level change to carry its corresponding edge event. It samples the
physical logical level `dtack_n_i` only on falling-8-MHz events and exposes
`RVA`, sampled `/DTACK`, `/RVAS0`, `/RVAS`, and one-clock assertion/release
diagnostics. It creates no clock.

The caller must resolve raw `/AS`, `8MHZ`, and `/DTACK` into that event domain.
Coincident event pulses and inconsistent level/edge pairs are rejected by
assertions because the source
schematic's propagation ordering cannot be represented by simultaneous
same-clock enables. `initialize_i` chooses idle request, `RVA=0`, sampled
`/DTACK=1`, `/RVAS0=1`, and `/RVAS=1`; this deterministic state is an FPGA
convention, not physical power-up behavior. The block remains standalone from
`hard_drivin_main_sound_reset_decode`; the directed test composition is not a
new wrapper. A platform still must provide the two TMS34010 `HRDY`-derived
levels, the DUART acknowledgement, raw levels/events, and a qualified CDC
contract; this project does not recreate either graphics processor inside the
main-board gate block.

`hard_drivin_main_dtack_decode` is combinational and storage-free. It exposes
`/VPA`, `/RHSBUS`, `/RDUART`, all three acknowledgement terms, and final
`/DTACK` for traceability. It imposes no legal-cycle assumptions and therefore
preserves even contradictory raw input combinations for exhaustive checking.

## Verification evidence

The hold-state test covers the normal S2 high-phase request, S3 `/RVAS0`
assertion, S4 `RVA`/`/RVAS`, low-sample/end/release sequence, low-phase
immediate `/RVAS0` assertion, asynchronous-preset priority, continued hold
across repeated edges when `/DTACK` never samples low, later recovery, and
deterministic reinitialization. A 12-step bounded proof compares all state and
event outputs against an independent transition model under event-exclusivity
and phase-level/edge-consistency assumptions. A 16-step cover
reaches seven classes: the normal release chain, missed-low stuck hold,
`/RVAS` release, early `/RVAS0`, low-phase assertion, preset priority, and
`/RVAS0` release.

The decode test exhausts all 4,096 raw input combinations and separately
checks ordinary, CPU-space, high-speed-wait, and DUART paths. A one-step BMC
proves every output equation and a one-step cover reaches ordinary ACK,
CPU-space VPA, both high-speed wait states, and both DUART acknowledgement
states. A composed bus test connects the timing, `/DTACK`, and sound-reset
decode blocks and checks the complete synthetic `/AS` capture through `/SRES`
release sequence. A separate HSBUS composition checks S3 early
acknowledgement, independent GSP and MSP wait extensions, S7 raw-select
release, and the following sampled release edge. A DUART composition checks
that `/RVAS`, not `/RVAS0`, selects the MC68681; arbitrary external wait is
retained; a late `/DUDTACK` completes the transfer; and raw select removal
suppresses a still-low open-drain pin before the sampled release edge.

Yosys 0.67+111 reports 93 cells/25 retained checks for the two-strobe hold
state and 21 cells/eight retained checks for the combinational decode, with no
memory, latch, generated clock, or structural problem. This is not a Cyclone V
fit, raw-pin CDC proof, electrical timing calculation, TMS34010 host-interface
or MC68681 model, or complete main-processor bus wrapper.
