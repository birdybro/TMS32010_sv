# TMS32010 executable reference model

The model is an independent, width-explicit architectural oracle. It is not
derived from MAME and is intentionally structured differently from the future
RTL.

Current supported boundary:

- `ABS`, `ADD`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `DMOV`, `EINT`, `IN`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`,
  `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `OUT`, `PAC`, `ROVM`, `SACL`,
  `POP`, `PUSH`, `RET`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBC`, `SUBH`, `SUBS`, `TBLR`, `TBLW`,
  `XOR`, `ZAC`, `ZALH`, and `ZALS`;
- `ADDS` unsigned-source arithmetic, sticky overflow, wrapped `OVM=0` results,
  and positive saturation with `OVM=1`;
- `ADD` sign extension, shifts 0 through 15, sticky overflow, wrapped results,
  and positive/negative OVM saturation;
- `SUB` sign extension, shifts 0 through 15, sticky overflow, wrapped results,
  and positive/negative OVM saturation;
- `SUBH` high-half-aligned subtraction, low-half preservation on ordinary
  and wrapped results, sticky signed overflow, and full-accumulator positive/
  negative endpoint saturation under OVM;
- `SUBS` unsigned-source subtraction, sticky overflow, wrapped results, and
  negative OVM saturation;
- `SUBC` unsigned-divisor conditional subtraction, both result paths, the TI
  65-divided-by-7 example, common address updates, and a provisional sticky-OV
  stage; tests obey the required ACC-free following instruction
  (`OQ-017`/`OQ-018`);
- `BANZ` two-word program sequencing, old-counter branch selection,
  low-nine-bit modulo decrement with upper-bit preservation, target versus
  `PC+2` selection, two logical program transactions, and a two-cycle total;
  noncanonical following words trap before architectural effects;
- `B` exact two-word program sequencing, unconditional target selection,
  preserved non-PC architectural state, two logical program transactions,
  and a two-cycle total; noncanonical following words trap before effects;
- `BGEZ`/`BGZ`/`BLEZ`/`BLZ`/`BNZ`/`BZ` signed/zero 32-bit ACC predicates,
  taken/untaken target selection, two mandatory program transactions, and
  unchanged non-PC state;
- `BV` sticky-OV predicate, taken-path clear, untaken clear preservation, two
  mandatory program transactions, and unchanged unrelated state;
- `BIOZ` active-low external input predicate, target/fallthrough selection,
  two mandatory program transactions, and unchanged architectural state;
- `CALL` canonical target fetch, opcode-PC+2 return-address push, four-level
  stack shift with old-bottom discard, and a two-cycle total;
- `CALA` exact implied decode, opcode-PC+1 stack push, `ACC[11:0]` target
  selection, old-bottom discard, PC wrap, nested calls, and a two-cycle total;
  its unresolved second external cycle is deliberately absent from the
  logical transaction trace (`OQ-007`);
- `RET` exact implied decode, old-top PC load, four-level pop with old-bottom
  duplication, a two-cycle total, and completion after EINT before pending
  interrupt reentry; its unresolved second external cycle is deliberately not
  invented in the logical transaction trace (`OQ-007`);
- `PUSH`/`POP` exact implied decode, low-12-bit push or zero-extending pop,
  four-level shifting, old-bottom discard or duplication, repeated
  overflow/underflow behavior, PC wrap, and two-cycle totals; their unresolved
  second external cycles are deliberately absent from the logical transaction
  trace (`OQ-016`);
- `IN`/`OUT` direct/indirect internal-data selection, old-address ordering,
  eight-port I/O addressing, unchanged 16-bit transfers, common AR/ARP
  post-updates, one program plus one I/O transaction, and a two-cycle total;
- `TBLR`/`TBLW` direct/indirect internal-data selection, captured
  accumulator-derived program address, opcode and discarded-prefetch reads,
  third-cycle program read or write, common AR/ARP post-updates, documented
  stack-bottom duplication, and a three-cycle total;
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
- `ABS` signed magnitude conversion, the OVM-selected most-negative result,
  preserved incoming OV, one-cycle total, and no logical data transaction;
- `DINT`/`EINT` exact fixed decode and one-cycle `INTM` set/clear behavior,
  active-low request sampling, masked request persistence, EINT and MPY/MPYK
  deferral, a non-instruction return-PC dummy-fetch step, stack entry,
  internal acknowledge effects, and vector-2 selection;
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
`bio_input_high` defaults to the inactive high level and may be assigned by a
test environment before stepping BIOZ; it is external input state, not part
of the architectural-state snapshot.
`interrupt_input_high` likewise defaults inactive. A low level sampled by
`step()` latches `interrupt_pending`; `interrupt_delay_one` and
`interrupt_entry_pending` are included in deterministic snapshots so replay
does not hide the entry microstate. The model is instruction-boundary based
and does not claim the complete Figure 2-12 fetch/execute overlap.
Stack snapshots use `[top, level_1, level_2, bottom]` ordering.

Run the slice with:

```sh
make unit
```

Primary behavior citations live in `docs/generated/tms32010_isa.yaml` and the
architecture documents. Hand opcode fixtures under `tests/expected/` are
independent of this implementation.
