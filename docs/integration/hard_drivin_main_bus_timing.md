# Hard Drivin' main-board `/RVAS` hold timing

This note covers only the SP-327 main-board logic that converts an asserted
main-processor `/AS` into `RVA` and holds expansion-bus `/RVAS` until the
main-board `/DTACK` path has completed. It is distinct from the A044427 local
sound-68000 timing in `hard_drivin_host_timing.md`. The complete main-board
`/DTACK` acknowledgement tree, raw-pin clock-domain crossing, and nanosecond
timing margin remain outside the implemented block.

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
the F74 as a positive-edge-triggered D flip-flop with asynchronous active-low
preset and clear [ti-sn74ls74a-datasheet-sdls119, description, pinout, and
function table, printed pp. 1-3]. **Confidence: VERIFIED_PRIMARY for this
logical signal chain and polarity.**

The neighboring F74 `135H` output `/RVAS0` belongs to a separate local
main-board strobe path. It is not the J7 expansion-bus `/RVAS` output and is
not represented by the standalone adapter.

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
main-board `/DTACK` signal goes low and high remain unresolved integration
work. **Confidence: VERIFIED_PRIMARY for the state dependency;
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
`hard_drivin_main_sound_reset_decode` until a complete main-bus composition
defines the acknowledgement tree and CDC contract.

## Verification evidence

The directed test covers the normal assertion/low-sample/RVA-end/release
sequence, indefinite hold when `/DTACK` never samples low, a later low/high
recovery sequence, and deterministic reinitialization. A 12-step bounded
proof compares all state and event outputs against an independent transition
model under only mutually exclusive event assumptions. A 16-step cover
reaches the normal release chain, the missed-low stuck-hold state, and the
release pulse.

Yosys 0.67+111 reports 48 cells and twelve retained checks, with no memory,
latch, generated clock, or structural problem. This is not a Cyclone V fit,
raw-pin CDC proof, electrical timing calculation, or complete main-board bus
model.
