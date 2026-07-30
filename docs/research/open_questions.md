# Open architecture questions

Open questions are not implementation permissions. Provisional choices require
a targeted test and must retain their confidence label.

| ID | Question | Status / competing hypotheses | Evidence needed | Hard Drivin' impact |
|---|---|---|---|---|
| OQ-001 | Can external cycles be lengthened on a part with no READY pin? | UNKNOWN: clock-input pause may be legal, or memories must always meet fixed AC limits | TI clock-generator and AC sections; hardware measurement if silent | program RAM and wrapper clock-enable design |
| OQ-002 | What is observed for original-TMS32010 data addresses `0x90`–`0xff`? | UNKNOWN: alias, open/internal value, or undocumented decode | original data-sheet decode detail or physical chip | likely low unless software accesses it |
| OQ-003 | What values does `SST` produce in every reserved bit? | RESEARCHING: Figure 2-9 transcription incomplete | high-resolution figure and instruction page | possible context-save code |
| OQ-004 | What is the exact interrupt-recognition and vector-fetch cycle trace? | RESEARCHING: architectural effects known; subphases untranscribed | Figure 2-11 plus AC timing; minimal physical trace if ambiguous | low if board INT is tied inactive |
| OQ-005 | Is Hard Drivin' TMS32010 `INT` tied inactive, and what net is `PR1`? | RESEARCHING: schematic appears to tie pin to a rail; MAME models no DSP interrupt source | full net-name/title-block review and board BOM/netlist | determines interrupt integration |
| OQ-006 | Which edge completes reset and starts the first address-0 fetch? | RESEARCHING | Figure 2-12 and AC table transcription | reset/halt release trace |
| OQ-007 | What are exact taken/untaken branch prefetch and address traces? | RESEARCHING; both are listed as two cycles | individual instruction diagrams and hardware trace if needed | program trace alignment |
| OQ-008 | Does any mask revision materially differ? | UNKNOWN | TI errata/mask notices or measured devices | release qualification |
| OQ-009 | Is a lawful, automatable modern TMS32010 assembler available? | RESEARCHING; no qualified candidate yet | license/source/encoding audit | local test-program workflow |
