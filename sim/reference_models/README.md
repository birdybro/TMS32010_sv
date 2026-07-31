# TMS32010 executable reference model

The model is an independent, width-explicit architectural oracle. It is not
derived from MAME and is intentionally structured differently from the future
RTL.

Current supported boundary:

- `ADD`, `ADDS`, `AND`, `APAC`, `DINT`, `DMOV`, `EINT`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`,
  `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`, `ROVM`, `SACL`,
  `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBC`, `SUBS`, `XOR`, `ZAC`, `ZALH`, and
  `ZALS`;
- `ADDS` unsigned-source arithmetic, sticky overflow, wrapped `OVM=0` results,
  and positive saturation with `OVM=1`;
- `ADD` sign extension, shifts 0 through 15, sticky overflow, wrapped results,
  and positive/negative OVM saturation;
- `SUB` sign extension, shifts 0 through 15, sticky overflow, wrapped results,
  and positive/negative OVM saturation;
- `SUBS` unsigned-source subtraction, sticky overflow, wrapped results, and
  negative OVM saturation;
- `SUBC` unsigned-divisor conditional subtraction, both result paths, the TI
  65-divided-by-7 example, common address updates, and a provisional sticky-OV
  stage; tests obey the required ACC-free following instruction
  (`OQ-017`/`OQ-018`);
- `LAC` direct/indirect addressing, internal-data read traces, sign extension,
  shifts, nine-bit auxiliary-counter updates, and optional ARP replacement;
- `LAR` direct/indirect loads to either auxiliary register, including
  same-address-register update suppression and other-target post-modification;
- `SAR` direct/indirect stores from either auxiliary register, including
  post-modified same-source values written at the pre-modification address;
- `MAR` direct-form no-operations and indirect AR/ARP updates without any
  logical data-memory transaction, with `MAR *,0/1` decoded canonically as LARP;
- `LDP` direct/indirect reads, source-LSB-to-DP transfer, and old-address
  ordering before common indirect AR/ARP updates;
- `LT` direct/indirect full-word loads into T with the same old-address and
  post-access AR/ARP ordering;
- `LTA` concurrent full-word T loads and previous-P accumulation into ACC,
  including sticky OV, OVM-controlled results, and the same address ordering;
- `LTD` concurrent source-to-T load, previous-P accumulation, and unchanged
  source copy to the following internal-RAM address, with separate logical
  read/write transactions and trap-before-effects for unresolved endpoints;
- `DMOV` unchanged source copy to the following internal-RAM address without
  T/ACC/P/arithmetic-status effects, using the same separate logical
  source/write transactions and unresolved-endpoint policy;
- `MPY` direct/indirect signed 16-by-16 products into P, including the
  original `0x8000`-by-`0x8000` result and common post-access ordering;
- `MPYK` signed T times a sign-extended 13-bit immediate into P, including
  both immediate endpoints and no logical data-memory transaction;
- `PAC` full-width P-to-ACC transfer with P and status preservation and no
  logical data-memory transaction;
- `APAC` full-width P-plus-ACC arithmetic with sticky OV, OVM-controlled wrap
  or signed-endpoint saturation, unchanged P, and no logical data transaction;
- `SPAC` full-width ACC-minus-P arithmetic with the same sticky-OV and
  OVM-controlled result policy, unchanged P, and no logical data transaction;
- `DINT`/`EINT` exact fixed decode and one-cycle `INTM` set/clear behavior,
  preserving the model's pending-request latch and exposing only a program
  fetch; interrupt recognition, EINT deferral, and vector entry remain absent;
- `LST` direct/indirect reads, exhaustive `OV`/`OVM`/`ARP`/`DP` source-bit
  combinations, `INTM` preservation, old-address ordering, and indirect
  counter updates; memory-sourced ARP precedence is provisional under
  `OQ-015`;
- `SACL` direct/indirect writes of `ACC[15:0]`, logical write traces, and the
  same post-access auxiliary-register controls;
- `SACH` direct/indirect writes after complete-accumulator left shifts of
  exactly 0, 1, or 4, with the same post-access controls;
- `AND`, `OR`, and `XOR` direct/indirect low-half logic, including AND's
  upper-half clear, OR/XOR upper-half preservation, and unchanged OV/OVM;
- `ZALH` and `ZALS` direct/indirect reads into the accumulator high and low
  halves, respectively, with the same post-access controls;
- 12-bit PC wrap;
- deterministic program/data/I/O storage and raw word-image loading;
- step-boundary reset effects established by TI;
- logical program-fetch transactions, documented cycle totals, and stable
  JSON traces.

Everything else raises `UnsupportedOpcode`; an access beyond physical data
word 143 raises `UnsupportedDataAddress`. No reserved or unimplemented word is
treated as a no-op. The model currently reports logical transactions, not
qualified TMS32010 pin phases. Constructor-zeroed storage and registers are a
test-harness convenience, not a physical power-up claim.

Run the slice with:

```sh
make unit
```

Primary behavior citations live in `docs/generated/tms32010_isa.yaml` and the
architecture documents. Hand opcode fixtures under `tests/expected/` are
independent of this implementation.
