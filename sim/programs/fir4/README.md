# Synthetic four-tap FIR program

This directory contains a project-authored, redistribution-safe Q15 FIR
kernel for exercising a realistic original-TMS32010 multiply/accumulate data
path. It is not copied or adapted from a TI listing. TI's contemporary
application report establishes the architectural idiom: a direct-form FIR is
a finite weighted sum, and an `LTD`/`MPY` pair accumulates the preceding
product while advancing sample history and starting the next product
[ti-fir-iir-application-spra003, SPRA003A, printed pp. 8–12 (PDF pp. 8–12)].
**Confidence: VERIFIED_PRIMARY for the programming idiom. The source, numeric
vector, and expected trace are project fixtures rather than architectural
claims.**

The harness seeds these Q15 values:

| Address | Meaning | Hex | Value |
| --- | --- | --- | ---: |
| `0x10` | `h[0]` | `0x2000` | 0.25 |
| `0x11` | `h[1]` | `0x4000` | 0.5 |
| `0x12` | `h[2]` | `0x2000` | 0.25 |
| `0x13` | `h[3]` | `0x1000` | 0.125 |
| `0x20` | `x[n]` | `0x4000` | 0.5 |
| `0x21` | `x[n-1]` | `0x2000` | 0.25 |
| `0x22` | `x[n-2]` | `0xe000` | -0.25 |
| `0x23` | `x[n-3]` | `0x1000` | 0.125 |

The independently calculated output is

```text
0.25*0.5 + 0.5*0.25 + 0.25*(-0.25) + 0.125*0.125
= 0.203125
= Q15 0x1a00
```

The four signed products sum to the Q30 accumulator value `0x0d000000`.
`SACH 0x30,1` converts that value to Q15 by shifting once before storing the
high word. Three `LTD` operations also move `x[n]` through `x[n-2]` one word
toward the older-history addresses. The program has twelve one-cycle
instructions, so the instruction-boundary model reports twelve cycles. This
count is the sum of documented instruction cycles; it is not a claim about
unmodeled analog pin delays or power-on pipeline priming.

`expected.json` fixes the opcodes, initial data, final state, and every logical
data transaction. The regression also requires one
program fetch per instruction and an assembler/disassembler binary round trip:

```sh
python3 -m unittest tests.regressions.test_fir4_program -v
```
