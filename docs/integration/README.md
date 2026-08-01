# Integration documentation

- `mister_wrapper.md`: platform-neutral MiSTer/FPGA callback wrapper, reset,
  ready/hold, clock-enable, debug, and clock-domain contract.
- `hard_drivin_requirements.md`: Atari Driver Sound Board research and the
  eventual board-specific adapter requirements.
- `hard_drivin_communication_ram.md`: primary-transcribed CRAMEN ownership,
  512-word communication RAM, shared sound-address counter, and source
  conflicts around ports 1–3.
- `hard_drivin_sound_rom.md`: primary-transcribed parallel sample-ROM block,
  address, population, port-0 word alignment, and MAME sign-bit conflict.
- `hard_drivin_sound_control.md`: primary-transcribed raw MUTE and 68000 IRQ
  latch behavior for ports 4 and 5.
- `hard_drivin_bio.md`: primary-transcribed divide-by-50 source and CLKOUT
  resampler, with explicit independent-clock uncertainty.
- `hard_drivin_compare.md`: primary port-2 `/CMPRD`/`CMPOUT` trace, explicit
  Rev-A nonpopulation, and MAME zero-stub boundary.
- `hard_drivin_host_control.md`: 68000 low-I/O decode, address-encoded LS259
  state, board-reset effects, and standalone FPGA callback boundary.
- `hard_drivin_host_reads.md`: complete and partial 68000 read targets,
  driven-lane validity, and the TMS port-3 host latch.
- `hard_drivin_host_mailboxes.md`: bidirectional main/sound word latches,
  LS74 pending flags, read-clear behavior, and explicit conflict validity.
- `hard_drivin_mister_wrapper.md`: partial same-clock processor/program-RAM
  top, reset/ownership protocol, physical I/O callback, and test boundary.

`rtl/wrappers/hard_drivin_sound_bus_decode.sv` is the first board-specific
piece: a storage-free transcription of the verified program-RAM ownership,
low-eight port decode, and TBLW/OUT alias. It deliberately reports invalid
host/DSP overlap rather than inventing arbitration.

`rtl/wrappers/hard_drivin_sound_program_ram.sv` adds an FPGA-oriented,
same-clock 4K-by-16 storage adapter around that decoder. It uses synchronous
reads and explicit commit inputs, does not clear program contents, and grants
neither side during invalid overlap. Its whole-word host callback is not a
68000 byte-lane or DTACK implementation.

`rtl/wrappers/hard_drivin_sound_mister.sv` connects those pieces to the
generic processor callback wrapper. It can execute a host-loaded synthetic
program and correctly routes low-address TBLW to physical I/O. It now selects
the qualified LS259 host-control state only behind an explicit opt-in while
retaining external reset/CRAMEN callbacks by default; the complete 68000 bridge
remains external.

`rtl/wrappers/hard_drivin_sound_communication_path.sv` combines a standalone
512-by-16 communication-RAM adapter with the primary-defined shared-address
and port-6 control state. It exhaustively verifies CRAMEN ownership and every
word. `hard_drivin_sound_mister` now routes processor port 1 to that adapter
and exposes its whole-word host callback, but still does not implement a 68000
bus/latch decode or physical HM6116 timing.
`hard_drivin_sound_rom.md` records the parallel selected-ROM mapping. The new
storage-free adapter routes processor port 0 to an explicit authorized-byte
callback, rejects absent/invalid selections instead of inventing a bus value,
and contains neither ROM images nor physical access-time behavior.
`rtl/wrappers/hard_drivin_sound_dac_latch.sv` captures the independently
qualified raw port-0 output code `TD15:TD4` and emits a one-clock commit pulse.
It implements no MAME bit-11 transform, signed-sample interpretation, DAC
analog model, or filter.
`hard_drivin_sound_control.md` qualifies the two LS74 halves behind ports 4
and 5: the raw complementary `MUTE` net and latched active-high `320IRQ`. The
corresponding RTL exposes those states without inventing a loaded mute consumer
or embedding a 68000 bus decoder.
`hard_drivin_bio.md` transcribes the independent-clock divide-by-50 source,
one-period `/320BIO` pulse, reset-uninitialized counter phase, and CLKOUT
resampler. Its standalone RTL uses explicit enables and validity instead of
creating clocks or pretending board reset initializes the divider.
`hard_drivin_compare.md` establishes that Rev-A port 2 drives only `TDI15`
from an unpopulated-source `CMPOUT`; it therefore remains on the board top's
external data/ready callback instead of receiving an invented zero-valued
peripheral.
`hard_drivin_host_control.md` qualifies the LS259 whose raw Q3/Q4 outputs are
`CRAMEN` and `/320RES`. Its standalone RTL uses an explicit decoded host
completion and per-bit validity. The board top can opt into Q3/Q4 and exports
selected-control validity; the full `/RVAS`/DTACK bridge remains future work.
`hard_drivin_host_mailboxes.md` qualifies the two complete-word LS374 paths
and LS74 `MAINFLAG`/`SOUNDFLAG` handshake. Its standalone RTL preserves
reset-independent data, read-cleared flags, and explicit invalidity for
unsourced coincident set/clear cases; board-top integration remains future
work.
`hard_drivin_host_reads.md` also defines the standalone storage-free
`/READSTAT` mapper. It exports only `D15:D12` as driven, preserves one validity
bit per raw status source, and leaves the complete-word open-bus policy to a
future host bridge.

The generic processor and MiSTer wrapper do not contain Atari memory maps,
ROM content, DAC transforms, or host-handshake behavior. Those belong in a
separate Hard Drivin'-specific integration layer after their evidence is
qualified.
