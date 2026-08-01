# EVM breakpoint evidence for one-word multicycle instructions

## Observation

The 1985 TMS32010 Evaluation Module rejects a breakpoint placed at the program
word immediately after its printed `TBRD` (`0x67xx`), `TBWR` (`0x7dxx`),
`CALA`, `RET`, `PUSH`, `POP`, `IN`, or `OUT` entries. The monitor describes
that following location as illegal for breakpoint use
[ti-tms32010-evm-users-guide-spru005a, SB command note 7, printed p. 3-58
(PDF p. 99)]. The first two opcode patterns correspond to the production
guide's TBLR/TBLW entries; the EVM spellings are retained here rather than
silently normalized.

The hardware description explains why an address can trigger the monitor. A
4K-by-1 breakpoint RAM is indexed by the TMS32010 program address. A set bit
causes the breakpoint flip-flop to replace dual-port program RAM data with a
hardwired NOP and captures the processor address, BIO, and INT state for the
monitor
[ti-tms32010-evm-users-guide-spru005a, §9.3, printed pp. 9-2 through 9-3
(PDF pp. 179-180)]. The warning is therefore tied to externally visible
program-address activity, not merely an assembler's instruction-length table.
Appendix A drawing D96214 sheet 3 shows the TMS32010, program memory,
breakpoint RAM, and start/stop logic but contains no instruction-specific
timing annotation from which a PUSH/POP phase can be transcribed
[ti-tms32010-evm-users-guide-spru005a, Appendix A drawing D96214 sheet 3
(PDF p. 188)].

## What this establishes

At `VERIFIED_PRIMARY` confidence for the TI EVM behavior:

- the word after PUSH or POP is unsafe as a simple address-triggered EVM
  breakpoint;
- the EVM breakpoint logic observes the TMS32010 program-address bus directly;
  and
- TI groups PUSH/POP with the other one-word multicycle operations whose
  following-word address can be exposed before ordinary breakpoint semantics
  are safe.

This corroborates that `N+1` becomes externally visible during PUSH/POP's
multicycle control sequence. It is also consistent with overlapped prefetch
and the production guide's every-cycle `MEN` contract.

## What this does not establish

The breakpoint RAM is address-driven, and the manual gives no phase waveform
or `MEN` qualification for the match. The warning therefore does not reveal:

- whether `N+1` appears in the first or second PUSH/POP execution interval;
- whether `N+1` is read once or repeated;
- whether a later interval advances to `N+2`;
- which fetched word becomes executable; or
- how the breakpoint flip-flop is phased relative to the processor's falling
  sample boundary.

It cannot choose `OQ-016` H1, H2, or H3. In particular, every candidate can
expose `N+1` at some point, while H2 and H3 remain indistinguishable without
the next program address. The original-NMOS capture procedure remains the
smallest resolving evidence.

## Transcription caution

The main SB-command table prints the correct `CALA=0x7f8c` and `RET=0x7f8d`
words. An appendix error-message summary prints both low nibbles as `B`; that
appendix typo is not opcode authority. This research uses neither occurrence
to alter the independently primary-verified ISA fixtures.

**Result:** primary development-system corroboration that PUSH/POP expose the
following-word address in a breakpoint-sensitive multicycle context, but no
new native bus sequence and no reduction of the three measured hypotheses.
