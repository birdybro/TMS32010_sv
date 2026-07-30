# Memory model

## Separate architectural spaces

The TMS32010 uses a modified Harvard architecture: program and data spaces are
architecturally separate, while special table instructions move values
between them. The physical pins multiplex some of these transactions, which
does not make the spaces interchangeable in the model or native RTL interface
[ti-tms32010-users-guide-spru001b, §§2.1.1, 2.3, printed pp. 2-1–2-3,
2-15–2-18 (PDF pp. 25–27, 39–42)]. **Confidence: VERIFIED_PRIMARY.**

| Space | Architectural range | Original TMS32010 storage |
|---|---:|---|
| program | `0x000`–`0xfff`, 16-bit words | external, ROMless |
| data page 0 | `0x00`–`0x7f`, 16-bit words | internal RAM |
| data page 1 | `0x80`–`0x8f`, 16-bit words | internal RAM |
| I/O input | ports 0–7, 16-bit | external |
| I/O output | ports 0–7, 16-bit | external |

Sources: [ti-tms32010-users-guide-spru001b, §§2.1.1, 2.3, printed
pp. 2-3, 2-15–2-18 (PDF pp. 27, 39–42)]. **Confidence:
VERIFIED_PRIMARY.**

The behavior of data addresses `0x90`–`0xff` is not assigned (`OQ-002`).
Expanded RAM in the TMS320C15 is outside the default device scope.

## Program/data bridges

`TBLR` reads a program word addressed by the low 12 bits of `ACC` into a data
RAM location. `TBLW` transfers a data RAM word to program space at that
address. Each is listed as three cycles. The intervening prefetched instruction
is discarded and fetched again
[ti-tms32010-users-guide-spru001b, §2.3 and Table 3-2, printed pp. 2-17,
3-7 (PDF pp. 41, 57)]. **Confidence: VERIFIED_PRIMARY.**

Self-modifying program RAM is consequently architecturally meaningful and
must remain observable. Program images are word-addressed; byte order belongs
to file/wrapper formats, not to the CPU architecture.
