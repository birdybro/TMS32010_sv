# Project-local TMS32010 disassembler

The disassembler is driven by `docs/generated/tms32010_isa.yaml` and currently
recognizes the thirty-eight-instruction model/tool slice. BANZ consumes and
renders its canonical following target word; a lone opcode or noncanonical
target remains lossless `.word` data. Unknown words are
rendered as lossless `.word 0xNNNN` directives, so disassembly remains reassemblable
without claiming that an encoding is reserved or inert. A legal but
noncanonical indirect `ADD`, `ADDS`, `AND`, `DMOV`, `LAC`, `LAR`, `LDP`, `LT`, `LTA`, `LTD`, `MPY`, `OR`, `SACL`,
`SACH`, `SAR`, `SUB`, `SUBC`, `SUBS`, `XOR`, `ZALH`, `ZALS`, or `LST` whose
ignored bit 0 is one while ARP is preserved also uses `.word`, retaining its
exact binary representation.
The same lossless policy applies to MAR; the two `MAR *,0/1` aliases
disassemble canonically as `LARP 0/1`.

```sh
python3 -m tools.disassembler.tms32010_dis build/program.bin
```

Raw word byte order is explicit and defaults to big endian.
