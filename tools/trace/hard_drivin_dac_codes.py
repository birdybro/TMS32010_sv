#!/usr/bin/env python3
"""Compare raw Driver Sound DAC codes with MAME's signed interpretation.

The voltage/current results are ideal nominal calculations from A044427 Rev A
sheet 7 and the AMD Am6012 transfer equation.  They are not measurements and
do not model resistor tolerance, converter error, op-amp limits, or filtering.
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass
from fractions import Fraction
from typing import Sequence, TextIO

WORD_MASK = 0xFFFF
DAC_MASK = 0x0FFF
DAC_SIGN_BIT = 0x0800
DAC_LEVELS = 0x1000

# A044427 Rev A sheet 7: +5 V through R12=1 kOhm and R13=4.7 kOhm to
# VREF(+), followed by the IOUT-to-voltage R15=2.2 kOhm stage.  AMD gives
# IOUT = 4 * IREF * code / 4096 for the straight-binary connection.
REFERENCE_VOLTS = Fraction(5, 1)
REFERENCE_OHMS = 1_000 + 4_700
FEEDBACK_OHMS = 2_200


@dataclass(frozen=True)
class DacCodeRow:
    """One DSP output word interpreted at the documented digital boundaries."""

    word: int
    raw_code: int
    mame_code: int
    signed_code: int
    ideal_iout_amps: Fraction
    ideal_dacout_volts: Fraction


def _require_range(value: int, maximum: int, name: str) -> int:
    if not 0 <= value <= maximum:
        raise ValueError(f"{name} must be in the range 0..0x{maximum:x}")
    return value


def raw_dac_code(word: int) -> int:
    """Return A044427's true-output LS374/Am6012 code, TD15 through TD4."""

    return _require_range(word, WORD_MASK, "word") >> 4


def mame_dac_code(word: int) -> int:
    """Return the 12-bit value written to pinned MAME's unsigned mapper."""

    return raw_dac_code(word) ^ DAC_SIGN_BIT


def signed_12bit(code: int) -> int:
    """Interpret a twelve-bit word as a two's-complement integer."""

    code = _require_range(code, DAC_MASK, "code")
    return code - DAC_LEVELS if code & DAC_SIGN_BIT else code


def ideal_board_iout_amps(code: int) -> Fraction:
    """Return ideal nominal Am6012 IOUT for Rev-A's positive reference."""

    code = _require_range(code, DAC_MASK, "code")
    reference_current = REFERENCE_VOLTS / REFERENCE_OHMS
    return 4 * reference_current * code / DAC_LEVELS


def ideal_board_dacout_volts(code: int) -> Fraction:
    """Return ideal nominal first-stage DACOUT voltage before AC coupling."""

    return -FEEDBACK_OHMS * ideal_board_iout_amps(code)


def interpret_word(word: int) -> DacCodeRow:
    """Calculate raw, emulator, signed, and ideal electrical interpretations."""

    raw_code = raw_dac_code(word)
    return DacCodeRow(
        word=word,
        raw_code=raw_code,
        mame_code=mame_dac_code(word),
        signed_code=signed_12bit(raw_code),
        ideal_iout_amps=ideal_board_iout_amps(raw_code),
        ideal_dacout_volts=ideal_board_dacout_volts(raw_code),
    )


def parse_word(text: str) -> int:
    """Parse a DSP output word as hexadecimal, with or without a 0x prefix."""

    token = text.strip().lower().replace("_", "")
    if token.startswith("0x"):
        token = token[2:]
    if not token:
        raise ValueError("empty word")
    try:
        value = int(token, 16)
    except ValueError as error:
        raise ValueError(f"invalid hexadecimal word: {text!r}") from error
    return _require_range(value, WORD_MASK, "word")


def write_csv(words: Sequence[int], output: TextIO) -> None:
    """Write deterministic comparison rows for captured DSP output words."""

    writer = csv.writer(output, lineterminator="\n")
    writer.writerow(
        (
            "tms_word",
            "raw_am6012_code",
            "mame_mapper_code",
            "signed_12bit",
            "ideal_iout_ma",
            "ideal_dacout_v",
        )
    )
    for word in words:
        row = interpret_word(word)
        writer.writerow(
            (
                f"0x{row.word:04x}",
                f"0x{row.raw_code:03x}",
                f"0x{row.mame_code:03x}",
                str(row.signed_code),
                f"{float(row.ideal_iout_amps * 1_000):.9f}",
                f"{float(row.ideal_dacout_volts):.9f}",
            )
        )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "word",
        nargs="*",
        help="16-bit hexadecimal DSP output word; defaults to boundary values",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    tokens = args.word or ("0000", "7ff0", "8000", "fff0", "ffff")
    try:
        words = [parse_word(token) for token in tokens]
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    write_csv(words, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
