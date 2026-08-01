# Hard Drivin' main-board `/DTACK` and `/RVAS` timing

This note covers only the SP-327 main-board logic that converts an asserted
main-processor `/AS` into `RVA` and holds expansion-bus `/RVAS` until the
main-board `/DTACK` path has completed. It is distinct from the A044427 local
sound-68000 timing in `hard_drivin_host_timing.md`. The complete combinational
`/DTACK` cone is now transcribed separately from the sequential hold state;
raw source timing, clock-domain crossing, and nanosecond timing margin remain
outside the implemented blocks.

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
strobe. `8MHZ OR /S4` drives its asynchronous preset and the sampled-`/DTACK`
Q clocks its D=0 release. `/RVAS0` qualifies the `/HSBUS` acknowledgement
path; it is not the J7 expansion-bus `/RVAS` output and is not yet generated
by the standalone state adapter. **Confidence: VERIFIED_PRIMARY for the
connectivity; UNKNOWN for the phase/CDC contract needed by an FPGA model.**

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
ti-sn74f11-datasheet-sdfs040a, printed pp. 1 and 4]. SP-327 sheet 6 identifies
`/DUDTACK` as the MC68681 acknowledgement output; the UART's internal timing
is not modeled here [atari-hard-drivin-schematic-package-sp327, sheet 6,
PDF p. 7]. **Confidence: VERIFIED_PRIMARY for the full Boolean cone;
UNKNOWN for the external wait-source protocols and electrical propagation
margin.**

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

| event | `RVA` | sampled `/DTACK` | `/RVAS` | effect |
|---|---:|---:|---:|---|
| FPGA initialization convention | 0 | 1 | 1 | deterministic idle only |
| `/AS` assertion captured | 0 | unchanged | unchanged | request pending |
| next rising 8 MHz | 1 | unchanged | 0 | expansion access begins |
| falling 8 MHz with `/DTACK=0` | 1 | 0 | 0 | completion transition armed |
| next rising 8 MHz | 0 | 0 | 0 | `RVA` ends; `/RVAS` remains held |
| falling 8 MHz with `/DTACK=1` | 0 | 1 | 1 | sampled low-to-high edge releases hold |

`/RVAS` is therefore not a fixed-duration pulse and cannot be reconstructed
from elapsed clocks or an abstract transaction commit. If `/DTACK` never
samples low, the final F74 receives no later rising clock transition and
`/RVAS` remains asserted. The new RTL deliberately preserves that stuck-hold
case instead of adding a timeout. The equations that decide when the physical
main-board `/DTACK` signal goes low and high are now implemented, while the
specialized external wait inputs and their propagation remain unresolved
integration work. **Confidence: VERIFIED_PRIMARY for the state dependency;
VERIFIED_SIMULATION/FORMAL for the discrete event model; UNKNOWN for the
complete acknowledgement-path delay and fault behavior.**

## FPGA boundary

`hard_drivin_main_rvas_timing` uses one FPGA clock and caller-supplied,
mutually exclusive `main_8mhz_rise_i`, `main_8mhz_fall_i`, and
`address_strobe_assert_i` events. It samples the physical logical level
`dtack_n_i` only on falling-8-MHz events and exposes `RVA`, sampled `/DTACK`,
`/RVAS`, and one-clock assertion/release diagnostics. It creates no clock.

The caller must resolve raw `/AS`, `8MHZ`, and `/DTACK` into that event domain.
Coincident event pulses are rejected by assertions because the source
schematic's propagation ordering cannot be represented by simultaneous
same-clock enables. `initialize_i` chooses idle request, `RVA=0`, sampled
`/DTACK=1`, and `/RVAS=1`; this deterministic state is an FPGA convention,
not physical power-up behavior. The block remains standalone from
`hard_drivin_main_sound_reset_decode`; the directed test composition is not a
new wrapper. A platform still must define `/RVAS0`, external wait sources,
raw levels/events, and the CDC contract.

`hard_drivin_main_dtack_decode` is combinational and storage-free. It exposes
`/VPA`, `/RHSBUS`, `/RDUART`, all three acknowledgement terms, and final
`/DTACK` for traceability. It imposes no legal-cycle assumptions and therefore
preserves even contradictory raw input combinations for exhaustive checking.

## Verification evidence

The hold-state test covers the normal assertion/low-sample/RVA-end/release
sequence, continued hold across repeated edges when `/DTACK` never samples
low, a later low/high recovery sequence, and deterministic reinitialization.
A 12-step bounded
proof compares all state and event outputs against an independent transition
model under only mutually exclusive event assumptions. A 16-step cover
reaches the normal release chain, the missed-low stuck-hold state, and the
release pulse.

The decode test exhausts all 4,096 raw input combinations and separately
checks ordinary, CPU-space, high-speed-wait, and DUART paths. A one-step BMC
proves every output equation and a one-step cover reaches ordinary ACK,
CPU-space VPA, both high-speed wait states, and both DUART acknowledgement
states. A composed bus test connects the timing, `/DTACK`, and sound-reset
decode blocks and checks the complete synthetic `/AS` capture through `/SRES`
release sequence.

Yosys 0.67+111 reports 48 cells/twelve retained checks for the hold state and
21 cells/eight retained checks for the combinational decode, with no memory,
latch, generated clock, or structural problem. This is not a Cyclone V fit,
raw-pin CDC proof, electrical timing calculation, specialized-peripheral
model, or complete main-processor bus wrapper.
