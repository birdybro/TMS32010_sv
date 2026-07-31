# Project-local TMS32010 assembler

This clean-room assembler is currently a qualified workflow slice, not a
complete TMS32010 assembler. It supports:

- `ADD`, `ADDS`, `AND`, `APAC`, `B`, `BANZ`, `BGEZ`, `BGZ`, `BIOZ`, `BLEZ`, `BLZ`, `BNZ`, `BV`, `BZ`, `CALA`, `CALL`, `DINT`, `EINT`, `IN`, `LAC`, `LACK`, `LAR`, `LARK`, `LARP`, `LDP`,
  `DMOV`, `LDPK`, `LST`, `LT`, `LTA`, `LTD`, `MAR`, `MPY`, `MPYK`, `NOP`, `OR`, `PAC`, `ROVM`, `SACL`,
  `OUT`, `POP`, `PUSH`, `RET`, `SACH`, `SAR`, `SOVM`, `SPAC`, `SUB`, `SUBC`, `SUBH`, `SUBS`, `TBLR`,
  `TBLW`, `XOR`, `ZAC`, `ZALH`, and `ZALS`;
- two-pass labels;
- decimal, `0x` hexadecimal, and TI-style `>hex` constants;
- checked integer expressions;
- `.word`, `.org`, and nested `.include`;
- deterministic big- or little-endian raw binary, hex, and listing output.

Every other documented mnemonic produces an explicit not-implemented error.
Immediate ranges are diagnosed rather than silently truncated like the
historical TI assembler. `LARK` accepts `AR0`/`AR1` (or `0`/`1`) as its
register selector, and `LARP` accepts either the register name or a one-bit
constant.

`LAC` accepts TI direct and indirect forms such as `LAC 6,4`, `LAC *`,
`LAC *+,8,AR1`, and `LAC *-,0,0`. Direct addresses and shifts are checked;
an explicit next ARP is permitted only on an indirect form.

`LAR` accepts a designated AR followed by the common address form, such as
`LAR AR0,6`, `LAR AR1,*+`, or `LAR AR0,*-,AR1`.

`SAR` uses the same operand syntax, for example `SAR AR0,6`, `SAR AR1,*+`, or
`SAR AR0,*-,AR1`.

`MAR` accepts either its documented direct NOP form or an indirect update,
such as `MAR 127`, `MAR *`, or `MAR *+,AR1`. `MAR *,AR0/AR1` assembles the
documented exact aliases of `LARP 0/1`.

`DMOV`, `LDP`, `LST`, `LT`, `LTA`, `LTD`, and `MPY` accept the no-shift common
address forms, such as `DMOV 8`, `LDP 6`, `LT *`, `LTA 24`,
`LTD *-,AR1`, `LST *+,AR1`, or `MPY *+,AR1`. For LST, accepting a next-ARP
operand describes the primary encoding; execution precedence remains
provisional under `OQ-015`.

`MPYK` accepts a signed 13-bit immediate from `-4096` through `4095`, for
example `MPYK -9`. Values outside that primary-defined range are diagnosed.
`PAC`, `APAC`, `SPAC`, `CALA`, `DINT`, `EINT`, `POP`, and `PUSH` are
implied instructions with no operands.

`ADD` and `SUB` accept the same address and shift syntax as `LAC`, for example
`ADD 6,4`, `SUB 6,4`, or `SUB *+,8,AR1`.

`SACL` accepts forms such as `SACL 6`, `SACL *+`, and `SACL *-,0,AR1`.
There is no SACL shift; the explicit zero is the TI-defined placeholder needed
before a next-ARP operand. Any nonzero placeholder is diagnosed.

`SACH` accepts the same addressing forms and an optional shift of exactly
`0`, `1`, or `4`, for example `SACH 6,4` or `SACH *+,1,AR1`. Other shift
values are diagnosed rather than emitted as undocumented encodings.

`ZALH` and `ZALS` accept the common direct/indirect address forms without a
shift operand, for example `ZALH 6` or `ZALS *-,AR1`.

`ADDS` uses the same no-shift common address forms, for example `ADDS 6` or
`ADDS *+,AR1`.

`SUBS` uses the same no-shift common address forms, for example `SUBS 6` or
`SUBS *+,AR1`.

`SUBH` also uses the no-shift common address forms, for example `SUBH 6` or
`SUBH *+,AR1`; its architectural operation aligns the selected word to
accumulator bits 31:16.

`SUBC` also uses those no-shift common address forms, for example `SUBC 6` or
`SUBC *+,AR1`. Assembly support does not hide TI's requirement that the next
instruction not use ACC.

`BANZ` accepts a label or checked 12-bit program address. It emits exact
opcode `0xf400` followed by one canonical target word, and its two-word size
participates in label and `.org` location accounting.

`B` uses the same target syntax, range checking, canonical following word, and
two-word location accounting with exact opcode `0xf900`.

`BV` uses that target workflow with exact opcode `0xf500`.

`BIOZ` uses that target workflow with exact opcode `0xf600`.

`CALL` uses that target workflow with exact opcode `0xf800`.

`CALA` is the exact implied word `0x7f8c`; its program target comes from
`ACC[11:0]`, so it accepts no source-level operand.

`RET` is the exact implied word `0x7f8d`; it accepts no operands.
`PUSH` and `POP` are the exact implied words `0x7f9c` and `0x7f9d`;
they accept no operands.

`IN` and `OUT` take a common data operand followed by a checked port, for
example `IN 6,PA0`, `IN *+,7,AR1`, `OUT 24,3`, or `OUT *-,PA5`.
Ports may be written as numeric 0–7 or `PA0`–`PA7`; the optional next ARP is
valid only with an indirect data operand.

`TBLR` and `TBLW` take one common data operand without a shift, for example
`TBLR 6`, `TBLR *+,AR1`, or `TBLW *-`.

`BGEZ`, `BGZ`, `BLEZ`, `BLZ`, `BNZ`, and `BZ` use that identical target
workflow with exact opcodes `0xfd00`, `0xfc00`, `0xfb00`, `0xfa00`,
`0xfe00`, and `0xff00`, respectively.

`AND`, `OR`, and `XOR` use the same forms, for example `AND 6`,
`OR *+,AR1`, or `XOR *-`.

Example:

```sh
python3 -m tools.assembler.tms32010_as program.asm \
  --binary build/program.bin --hex build/program.hex \
  --listing build/program.lst
```

The assembler consumes the canonical partial ISA database. Its independent
validation anchor is `tests/expected/opcode_fixtures.yaml`, which is never
generated by this tool.
