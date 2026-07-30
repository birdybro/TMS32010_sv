# TMS32010 executable reference model

The model is an independent, width-explicit architectural oracle. It is not
derived from MAME and is intentionally structured differently from the future
RTL.

Current supported boundary:

- `LACK`, `LARK`, `LARP`, `LDPK`, `NOP`, `ZAC`, `ROVM`, and `SOVM`;
- 12-bit PC wrap;
- deterministic program/data/I/O storage and raw word-image loading;
- step-boundary reset effects established by TI;
- logical program-fetch transactions, documented cycle totals, and stable
  JSON traces.

Everything else raises `UnsupportedOpcode`; no reserved or unimplemented word
is treated as a no-op. The model currently reports logical transactions, not
qualified TMS32010 pin phases. Constructor-zeroed storage and registers are a
test-harness convenience, not a physical power-up claim.

Run the slice with:

```sh
make unit
```

Primary behavior citations live in `docs/generated/tms32010_isa.yaml` and the
architecture documents. Hand opcode fixtures under `tests/expected/` are
independent of this implementation.
