# Project-local TMS32010 disassembler

The disassembler is driven by `docs/generated/tms32010_isa.yaml` and currently
recognizes the twenty-one-instruction model/tool slice. Unknown words are rendered
as lossless `.word 0xNNNN` directives, so disassembly remains reassemblable
without claiming that an encoding is reserved or inert. A legal but
noncanonical indirect `ADD`, `ADDS`, `AND`, `LAC`, `LAR`, `OR`, `SACL`, `SACH`, `SUB`, `SUBS`, `XOR`,
`ZALH`, or `ZALS` whose
ignored bit 0 is one while ARP is preserved also uses `.word`, retaining its
exact binary representation.

```sh
python3 -m tools.disassembler.tms32010_dis build/program.bin
```

Raw word byte order is explicit and defaults to big endian.
