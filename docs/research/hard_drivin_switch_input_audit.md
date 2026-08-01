# Driver Sound J3 switch-input audit

## Result

The published cabinet wiring does not assign cabinet functions to Driver
Sound inputs `J3-11`, `J3-9`, `J3-8`, or `J3-7`.

A044427 Rev A exposes the four inputs through a passive RC network and the
non-inverting LS244 read buffer. Hard Drivin' cockpit main wiring SP-327 and
Race Drivin' compact main wiring SP-360 show their Sound PCB power/audio
harness groups but no cable, switch, jumper block, or cabinet device at J3.
The two diagrams therefore refute the current premise that these are known
cabinet controls for those published configurations. They do not prove that
J3 was unpopulated, or that no service option, factory fixture, field rework,
or other cabinet revision ever used it.

The disconnected electrical value is also unspecified. A044427 has no DC
pull-up or pull-down on the four LS244 inputs, and the LS244 data sheet does
not define an open-input logic state. **Confidence: VERIFIED_PRIMARY that J3
is absent from the reviewed Hard Drivin' cockpit and Race Drivin' compact
cabinet wiring; VERIFIED_PRIMARY for the no-discrete-pull circuit; UNKNOWN for
the voltage/read value of a disconnected physical input and for other board
or cabinet revisions.**

## Sound-board circuit

A044427 sheet 3 maps the four signals in this order:

| external pin | series resistor | shunt capacitor | LS244 `10H` input | host bit |
|---|---:|---:|---:|---:|
| `J3-11` | `R23=1 kOhm` | `C17/C24=0.1 uF` path | pin 2 | `D15` |
| `J3-9` | `R22=1 kOhm` | `C18/C23=0.1 uF` path | pin 4 | `D14` |
| `J3-8` | `R24=1 kOhm` | `C19/C22=0.1 uF` path | pin 6 | `D13` |
| `J3-7` | `R21=1 kOhm` | `C20/C21=0.1 uF` path | pin 8 | `D12` |

The drawing ties `J3-1` and `J3-2` to ground and leaves `J3-3` through
`J3-6` with no shown circuit. It does not connect any of the four signal pins
to the grounded pins or name an external switch. Each signal has a 1 kOhm
series resistor and capacitive shunting on both sides of that resistor. A
capacitor is open at DC; none of these parts establishes an idle level
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheet 3 of 10,
PDF pp. 5-6].

LS244 `10H` is non-inverting. TI specifies valid driven input thresholds and
input currents, but supplies no parameter that guarantees the result of an
open input. The familiar tendency of an unconnected LS-TTL input to appear
high is therefore not a board contract and cannot justify an FPGA default
[ti-snx4ls24x-datasheet, recommended operating conditions and SNx4LS24x
electrical characteristics, printed pp. 4-5; SNx4LS244 function table,
printed pp. 11-13].

## Cabinet-wiring cross-check

SP-327 sheet 1 is the published Hard Drivin' cockpit main wiring diagram. Its
Sound PCB block is labeled `044427-XX`. The diagram connects the normal
nine-position power/audio group to `P12` and the six-position volume/audio
group, but it shows no J3 group and no drawn wire from the coin door, control
panel, component bracket, or main harness to J3
[atari-hard-drivin-schematic-package-sp327, sheet 1, PDF p. 2]. TM-327's
cabinet parts list identifies `A046491-01` as the Sound PCB Assembly and
`A046326-01` as the PCB Interconnect Harness Assembly; it does not assign J3
switch functions [atari-hard-drivin-manual-tm327-third, printed pp. 4-4 to
4-5, PDF pp. 78-79].

SP-360 sheet 1 repeats the check for Race Drivin' compact. Its complete main
wiring diagram again labels the Sound PCB `044427-XX`, connects the ordinary
power/audio groups, and has no J3 harness or cabinet switch assignment
[atari-race-drivin-compact-schematic-package-sp360, sheet 1, PDF p. 2]. The
Hard Drivin' compact TM-329 cabinet illustration independently identifies
`A046491-01` as its Sound PCB Assembly and `A046326-01` as its PCB
Interconnect Harness Assembly, but is not itself a connector pinout
[atari-hard-drivin-compact-manual-tm329-second, printed p. 4-3, PDF p. 67].

These are positive observations of what the published wiring diagrams draw,
not proof about every shipped assembly. Race Drivin' cockpit TM-351 names an
`A046491-02` Sound PCB Assembly, while the reviewed Hard Drivin' manuals name
`A046491-01`; no assembly drawing or BOM that establishes J3 population on the
`-02` revision has yet been qualified
[atari-race-drivin-cockpit-manual-tm351-second, printed p. 4-5, PDF p. 79].
The exact no-J3 claim is limited to the reviewed cabinet wiring diagrams and
their documented `044427-XX` Sound PCB blocks.

## MAME is not an idle-level oracle

Pinned MAME installs a handler for the relevant host address, logs access,
and returns a complete zero word. Its handler name is also assigned to the
opposite low-I/O quadrant from Atari LS138 `30N`; the paired handler returns
the same zero, hiding the swap. MAME therefore models neither the four J3
inputs nor the partially driven physical bus. Its zero cannot establish
grounded, active, inactive, or disconnected hardware
[mame-harddriv-audio-030fefc, `driversnd_68k_map`,
`hdsnd68k_switches_r`, and `hdsnd68k_320port_r`; `SC-033`].

## Remaining physical closure

To generalize beyond the published diagrams:

1. Photograph both sides of documented `A046491-01` and `A046491-02` boards,
   including J3 population, jumpers, rework, cables, assembly labels, and
   mating harnesses.
2. With power removed, record continuity from every J3 pin through the
   harness and any switch/fixture; do not infer a destination from wire color.
3. With current-limited power and appropriate ESD precautions, capture all
   four external-pin and LS244-input voltages with J3 disconnected, then with
   each actually populated contact in both states. Record instrument loading.
4. Capture the local 68000 `/SWITCHES` read strobe and `D15:D12` at the same
   time, preserving raw data and board identity.
5. Repeat on both cabinet families and at least two boards before claiming a
   production default.

Until then, `OQ-032` is `PARTIALLY RESOLVED_PRIMARY`: the reviewed cabinets
have no documented J3 functions, while physical disconnected values and
unreviewed variants remain unknown.

## Implementation policy

- Keep `hard_drivin_sound_switches.sv` as a raw, non-inverting, masked
  connector boundary.
- A platform reproducing the published cabinet wiring should leave the four
  source-valid bits clear unless it deliberately implements a documented
  service option or a measured physical-open policy.
- Do not rename the inputs as coin, test, service, or control-panel switches;
  those cabinet signals have separate documented routes to the main PCB.
- Do not drive zero or one and call it the physical disconnected state.
- No RTL or model behavior changes are justified by this research cycle.
