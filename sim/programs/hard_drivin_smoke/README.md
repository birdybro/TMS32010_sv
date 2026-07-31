# Hard Drivin' Driver Sound Board synthetic smoke program

This project-authored program exercises the known Driver Sound Board TMS32010
I/O roles without using or reconstructing any Atari ROM. It is an integration
fixture, not game code and not evidence that the real firmware performs this
exact sequence.

The working port map comes from Atari A044427 Rev-A wiring plus the pinned
MAME integration adapter. MAME maps program space to 4K shared words and maps
ports as sound-ROM read/DAC write (0), communication-RAM read (1), compare
read (2), an unresolved decoded `/CPORT` probe (3), mute (4), 68000 interrupt
request (5), and sound-ROM bank/address writes (6/7)
[atari-driver-sound-board-schematic, drawing A044427 Rev A, sheets 3–7 of 10,
PDF pp. 5–14; mame-harddriv-audio-030fefc,
`driversnd_dsp_program_map`, `driversnd_dsp_io_map`, and the corresponding
handlers]. **Confidence: VERIFIED_PRIMARY for the cited board wiring;
CORROBORATED for the software-visible port roles.**

Port 2 remains `PROVISIONAL`: the pinned MAME handler only logs the access and
returns zero. The smoke test deliberately expects that oracle value without
claiming physical compare-circuit behavior. MAME also configures a TMS320C10
device despite the A044427 TMS32010 label, so this fixture uses MAME only for
board adapter semantics, never as proof of processor behavior.

The harness supplies the following synthetic values:

- raw DAC word `0xf230` at internal RAM `0x10`;
- host communication word `0x55aa` from port 1;
- unresolved port-3 probe value `0x00a5`, mute value 1, and one 68000 IRQ
  request;
- populated Hard Drivin' sound-ROM block `0x03` and address `0x3456` through
  ports 6 and 7;
- synthetic physical sound-ROM response `0xea80` from raw byte `0xd5` at port 0;
- provisional compare response zero from port 2; and
- asserted active-low BIO, causing `BIOZ` to skip a sentinel `LACK 0xee`.

The program writes port 7 before its first input read. This qualifies the
physically uncleared shared LS191 address chain before port 1 uses `SA8:SA0`;
the following port-1, port-0, and port-2 reads then each advance the full
counter once. Reordering that project-authored sequence corrects the earlier
abstract-callback fixture without changing its instruction count, documented
cycle total, or final architectural results.

The port-0 word also follows the newly transcribed Rev-A sign extension:
byte `0xd5` maps to `0xea80` because its MSB drives both TDI15 and TDI14.
Pinned MAME's unsigned shift would instead produce `0x6a80`; that distinct
secondary-oracle result is `SC-026`, not the physical fixture value.
Block 3 corresponds to the populated `30A` position in the pinned Hard Drivin'
declaration. The earlier synthetic block-11 choice was invalid for this board
population because A044427 marks its C-row position not loaded.

The expected raw DAC write is preserved as `0xf230`. A044427 Rev A and the
Am6012 manufacturer data establish the physical DAC input code as
`0xf230 >> 4 = 0xf23`: `TD15:TD4` reach `B1:B12`, while `TD3:TD0` are absent
from the path. The pinned MAME adapter instead produces
`(0xf230 >> 4) XOR 0x800 = 0x723`; that distinct value remains a
secondary-oracle expectation under `SC-019`/`OQ-020`, not a physical-wiring
claim. See `docs/integration/hard_drivin_requirements.md` for the source
boundary.

`expected.json` fixes opcodes, logical program/I/O transactions, cycle count,
RAM results, raw outputs, and the derived oracle fields. Run it with:

```sh
python3 -m unittest tests.regressions.test_hard_drivin_smoke_program -v
```

The same fixed words also execute through the board-specific RTL wrapper after
a synthetic host load and safe `/320RES` handoff. That test additionally
checks physical I/O commits and the low-address TBLW alias:

```sh
python3 -m unittest sim.bus.test_hard_drivin_sound_mister -v
```
