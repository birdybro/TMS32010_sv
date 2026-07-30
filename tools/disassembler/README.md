# Project-local TMS32010 disassembler

The disassembler is driven by `docs/generated/tms32010_isa.yaml` and currently
recognizes only the five-instruction qualified slice. Unknown words are
rendered as lossless `.word 0xNNNN` directives, so disassembly remains
reassemblable without claiming that an encoding is reserved or inert.

```sh
python3 -m tools.disassembler.tms32010_dis build/program.bin
```

Raw word byte order is explicit and defaults to big endian.
