# MAME oracle environment

This file records local environmental evidence separately from the exact
source snapshots in `docs/references/manifest.yaml`. It does not qualify the
binary below as a reproducible build of the pinned source commit.

## Inspected source

- Commit: `030fefcbd14e47c01ec9d67655be90f64a1dc8ab`
- CPU source: `src/devices/cpu/tms320c1x/tms320c1x.cpp`
- CPU declaration: `src/devices/cpu/tms320c1x/tms320c1x.h`
- Disassembler: `src/devices/cpu/tms320c1x/tms320c1x_dasm.cpp`
- Hard Drivin' driver/audio: `src/mame/atari/harddriv.cpp`,
  `src/mame/atari/harddriv_a.cpp`, `src/mame/atari/harddriv.h`
- License: CPU and listed Atari source files have BSD-3-Clause file headers;
  MAME as a combined project is distributed under GPL-2.0-or-later. Exact
  per-file hashes and upstream URLs are in the reference manifest.
- Adapter modifications: none. The project does not patch or vendor MAME.

## Installed executable observed 2026-07-31

- Direct executable: `/usr/lib/mame/mame`
- Wrapper: `/usr/bin/mame`
- Reported version: `0.287 (mame0287-dirty)`
- Package: CachyOS `mame` `0.287-2.1`, repository `cachyos-extra-v3`,
  architecture `x86_64_v3`
- Package signature status: validated
- Packager: `CachyOS <admin@cachyos.org>`
- Package build date: 2026-04-11
- Package install date: 2026-04-19
- Binary bytes: `354698648`
- Binary SHA-256:
  `e8732a07ffc6995e31e5526fbf1f72e6ce55fb92cf2a1373b6a76e27cdc7dd91`
- Installed project license text:
  `/usr/share/doc/mame/source/license.rst`
  (SHA-256 `9a9bd33b049fbbc2b642576051c96be55b70dd43e127e5da3abb0544ad19a4d0`)
- Installed debugger documentation:
  `/usr/share/doc/mame/source/debugger/execution.rst` and
  `/usr/share/doc/mame/source/debugger/general.rst` (SHA-256
  `3f78d4eda6c9d275bcaf05cd5fc0ef722955da2977ee4d7fcfd0e79df825106d`
  and `0302cc8cbda6b71f63a1d085e06e0b2ca0f068469651c124ddabf05cad9d0427`)

The `-dirty` identifier does not expose an exact source commit or build
configuration. Therefore this binary is suitable for developing and checking
the text adapter, but it is not yet a reproducible qualified oracle binary.

`mame harddriv -listdevices` identifies the nested device as:

```text
:mainpcb:harddriv_sound:sounddsp  Texas Instruments TMS320C10 @ 20.00 MHz
```

This device-name mismatch from the board's TMS32010 label remains an explicit
scope limitation.

## Trace contract and qualification state

The project-generated debugger command uses MAME's `trace` action with
`noloop` and `tracelog` to prepend a strict `TMS32010_STATE` marker containing
PC, ACC, P, T, AR0, AR1, STR, and STK0-STK3. MAME documents that the action is
executed before its instruction trace message, so model post-state N is
compared with MAME marker N+1. The parser requires that following sentinel.
By default it also rejects further rows, preventing an unnoticed insertion or
deletion from being hidden by an overlong capture. MAME services pending
interrupts before the instruction hook, so this first adapter explicitly
requires inactive interrupts and rejects the model's separate interrupt-entry
pseudo-step.

The parser's seven synthetic text regressions and the placeholder/orchestration
tool's seven unit tests are ROM-free and passing. The runner rejects a
shell-script launcher before execution so `mame_sha256` cannot silently hash
only a wrapper instead of the emulator binary.

On 2026-07-31, this exact trusted local binary also passed:

```sh
make mame-synthetic MAME=/usr/lib/mame/mame
```

The runner obtained 20 required filenames/sizes from `harddriv -listxml`,
created 1,118,208 zero bytes across exact-sized files, verified MAME's explicit
wrong-checksum warnings, injected `tests/asm/mame_stack_control_smoke.asm`
into writable DSP program RAM, and released the emulated board's DSP halt
latch. No Atari ROM content was used. Ten model steps (`PUSH`, `NOP`, `LACK`,
`POP`, `LACK`, `CALA`, subroutine `LACK`, `RET`, return-path `LACK`, and
`NOP`) matched eleven live MAME instruction-boundary state rows. The path
pushes return PC `0x007`, enters PC `0x00c`, returns to PC `0x007`, and restores
the four-level stack before reaching sentinel PC `0x009`.
The model's OVM/INTM values are seeded to MAME's observed reset state for this
comparison. That setup does not promote MAME initialization into original-part
reset behavior.

- MAME trace SHA-256:
  `b522cdcfc22fb890dc9e91e488f4b55985c6c0a149bc529cbc3fdc8aa2ff7fce`
- Model trace SHA-256:
  `57ebf1260e87e4ce09c921216896b4d822edd693ba881cbe36fa0dc7080fa484`
- Generated debugger script SHA-256:
  `097117a1cd2693d59c3f090f956d5d677faa411346c17a2816850a87f97bf1fc`
- Placeholder manifest SHA-256:
  `06ec84c578b78c7bed57bde3d56b9a522d3713380d879ef71d26ac75947c81a7`
- Generated result: `PASS`, ten steps, eleven MAME rows, zero trailing rows

These generated files remain ignored below
`build/mame_synthetic_stack_control/`. The result is real execution of MAME's
TMS320C10 device in the Hard Drivin' machine configuration, but it is not Atari
firmware execution. It corroborates architectural PUSH/POP and CALA/RET state
only. MAME exposes no `/MEN`, external program-address cycle, or pin phase
through this trace, so `OQ-007` and `OQ-016` remain unresolved at the physical
bus level. A firmware-oriented comparison still requires user-supplied lawful
ROMs and must retain the exact executable hash and invocation.
