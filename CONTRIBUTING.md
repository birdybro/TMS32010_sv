# Contributing

Read [AGENTS.md](AGENTS.md), [TASKS.md](TASKS.md), [CHANGELOG.md](CHANGELOG.md),
and every relevant ADR before changing architectural behavior or RTL.

## Workflow

1. Select or add a stable task ID in `TASKS.md`.
2. Gather and record authoritative evidence before encoding behavior.
3. Add tests before or with the smallest coherent implementation.
4. Run focused tests, the relevant broader regression, lint, and synthesis
   smoke checks.
5. Update architecture/research documentation, `TASKS.md`, `CHANGELOG.md`, and
   `artifacts/progress.md`.
6. Inspect the complete diff and staged files before committing.

Use commit prefixes such as `research:`, `model:`, `rtl:`, `test:`, or `fix:`.
Keep every commit buildable.

## Evidence and test changes

An architectural expectation must cite the original TI document by revision
and page/section. Emulator behavior may corroborate but cannot silently replace
primary evidence. If evidence conflicts, record both hypotheses before
implementation.

Never change a test solely to make a failure disappear. Any expectation change
must explain the new evidence and update the affected research record.

## Copyright and clean-room contributions

Contributors must have the right to submit their changes under MIT. Do not paste
MAME, another emulator, an FPGA core, manuals, ROM images, legacy binary tools,
or other third-party material into this repository. Record third-party
references in `docs/references/manifest.yaml`; place uncommittable downloads in
the ignored `reference-cache/`.

By submitting a contribution, you certify that it is your original work or
that you have clearly documented compatible permission.

## Style and checks

Use two-space indentation, explicit widths and signedness, one architectural
clock, synchronous enables, and no gated clocks. Run:

```sh
make test
make lint
make synth-yosys
```

Additional focused targets are listed by `make help`.

GitHub Actions repeats the documentation, unit, Verilator regression/lint, and
Yosys smoke-synthesis checks from a clean Ubuntu 24.04 checkout. It deliberately
does not acquire manuals, ROMs, or legacy binary tools. Quartus remains a local
licensed-tool qualification step.
