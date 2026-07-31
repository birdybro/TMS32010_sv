# Integration documentation

- `mister_wrapper.md`: platform-neutral MiSTer/FPGA callback wrapper, reset,
  ready/hold, clock-enable, debug, and clock-domain contract.
- `hard_drivin_requirements.md`: Atari Driver Sound Board research and the
  eventual board-specific adapter requirements.

`rtl/wrappers/hard_drivin_sound_bus_decode.sv` is the first board-specific
piece: a storage-free transcription of the verified program-RAM ownership,
low-eight port decode, and TBLW/OUT alias. It deliberately reports invalid
host/DSP overlap rather than inventing arbitration.

`rtl/wrappers/hard_drivin_sound_program_ram.sv` adds an FPGA-oriented,
same-clock 4K-by-16 storage adapter around that decoder. It uses synchronous
reads and explicit commit inputs, does not clear program contents, and grants
neither side during invalid overlap. Its whole-word host callback is not a
68000 byte-lane or DTACK implementation.

The generic processor and MiSTer wrapper do not contain Atari memory maps,
ROM content, DAC transforms, or host-handshake behavior. Those belong in a
separate Hard Drivin'-specific integration layer after their evidence is
qualified.
