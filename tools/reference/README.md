# MAME instruction-boundary oracle adapter

`mame_trace.py` generates a strict MAME debugger trace action and compares the
resulting state markers with JSONL records emitted by the independent Python
model. It does not launch MAME, download software, locate ROMs, or modify a
MAME build.

Generate the debugger command for the Driver Sound DSP hierarchy:

```sh
python3 -m tools.reference.mame_trace command \
  --trace-file tms32010.tr
```

Use the printed command in MAME's debugger, after supplying lawfully obtained
ROMs through MAME's normal configuration. MAME's action runs before each
instruction trace line, so a comparison needs one marker after the final model
step. Interrupt inputs must remain inactive: MAME services pending interrupt
entry before the debugger instruction hook, while the model represents entry
as a separate pseudo-step. Then compare the files:

```sh
python3 -m tools.reference.mame_trace compare \
  --model model.jsonl --mame tms32010.tr
```

The adapter checks pre-execution PC alignment and strictly validates and
compares the following post-instruction PC, ACC, P, T, AR0, AR1, four-level
stack, OV, OVM, INTM, ARP, and DP widths/types. MAME exposes `STK0` through
`STK3` in backing-array order; the adapter reverses them into this project's
`[top, level_1, level_2, bottom]` convention. Reserved status bits are
deliberately not compared. Exactly one more MAME row than model step is
required by default; `--allow-trailing` is an explicit escape for a longer
captured trace.

## ROM-free synthetic Hard Drivin' smoke

An opt-in workflow constructs the MAME Hard Drivin' machine without any game
content. It queries `-listxml`, creates exact-sized files containing only zero
bytes, requires MAME to report their deliberately wrong checksums, injects the
project-authored `tests/asm/push_pop_bus_probe.asm` words into writable DSP
program RAM, and releases the emulated board's DSP halt latch through the
debugger. The first LACK primes debugger focus; the next five instructions are
compared against six strict boundary markers:

```sh
make mame-synthetic MAME=/path/to/trusted/mame
```

Generated placeholder files, debugger commands, traces, logs, and result
metadata remain below `build/mame_synthetic/`. The generator is idempotent,
refuses to overwrite any non-matching file, rejects path traversal and large
metadata sizes, and places a non-passing result marker before execution so a
failed rerun cannot leave stale passing evidence. The runner has a finite
wall-clock timeout. Use only a trusted installed or independently built MAME
binary; the workflow does not download one.

The synthetic run exercises PUSH, NOP, LACK, POP, and NOP at instruction
boundaries. It does not execute Atari firmware and does not provide MAME cycle
counts, bus transactions, or pin signals. It therefore corroborates stack and
register state only and cannot resolve `OQ-016`. The comparison model is seeded
with MAME's observed OVM/INTM reset values after the trace-prime LACK; that is
oracle alignment, not a physical TMS32010 reset claim.

## Evidence limits and provenance

The project pins the inspected MAME source at commit
`030fefcbd14e47c01ec9d67655be90f64a1dc8ab`; its exact source paths, hashes,
and file licenses are recorded in `docs/references/manifest.yaml`. The local
executable inspected on 2026-07-31 is a separately packaged
`0.287 (mame0287-dirty)` binary, so it is not represented as a build of that
pinned commit. Exact environmental provenance is in
`artifacts/mame_oracle.md`.

Current MAME identifies the Hard Drivin' device at
`:mainpcb:harddriv_sound:sounddsp` as a 20 MHz TMS320C10. This is a valuable
independent functional oracle, but it is not primary proof of original NMOS
TMS32010 behavior. The debugger state trace contains neither physical pin
phases nor the information needed to qualify this core's cycle timing. Any
disagreement is a research item; it is not automatically resolved in favor of
MAME or this project.

No game ROMs, MAME binaries, trace files containing ROM-derived disassembly,
generated placeholder images, or cached MAME source belong in Git.
