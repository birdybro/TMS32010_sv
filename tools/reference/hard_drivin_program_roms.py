#!/usr/bin/env python3
"""Analyze authorized Driver Sound local-68000 program-ROM lane images.

The tool hashes and compares user-supplied bytes.  It never downloads,
executes, disassembles, or reproduces ROM contents.  File size and mirror
results constrain an E1/E2 hypothesis but cannot identify a physical board.
"""

from __future__ import annotations

import argparse
from hashlib import sha256
import json
from pathlib import Path
import sys
from typing import Sequence

EPROM_27256_BYTES = 0x8000
EPROM_27512_BYTES = 0x10000
SUPPORTED_LANE_BYTES = (EPROM_27256_BYTES, EPROM_27512_BYTES)


class ProgramRomError(ValueError):
    """Raised when supplied lane images cannot represent the documented pair."""


def _sha256_bytes(data: bytes) -> str:
    return sha256(data).hexdigest()


def _analyze_lane(data: bytes, socket: str, bus_lane: str) -> dict[str, object]:
    if len(data) not in SUPPORTED_LANE_BYTES:
        sizes = ", ".join(f"0x{size:x}" for size in SUPPORTED_LANE_BYTES)
        raise ProgramRomError(
            f"{socket} must contain one of the documented lane sizes "
            f"({sizes}) bytes; got 0x{len(data):x}"
        )

    halves_equal: bool | None = None
    lower_half_sha256: str | None = None
    upper_half_sha256: str | None = None
    if len(data) == EPROM_27512_BYTES:
        lower = data[:EPROM_27256_BYTES]
        upper = data[EPROM_27256_BYTES:]
        lower_half_sha256 = _sha256_bytes(lower)
        upper_half_sha256 = _sha256_bytes(upper)
        halves_equal = lower == upper

    return {
        "socket": socket,
        "bus_lane": bus_lane,
        "bytes": len(data),
        "sha256": _sha256_bytes(data),
        "lower_32k_sha256": lower_half_sha256,
        "upper_32k_sha256": upper_half_sha256,
        "upper_32k_equals_lower_32k": halves_equal,
    }


def interleave_program_lanes(upper_even: bytes, lower_odd: bytes) -> bytes:
    """Interleave 70N D15:D8/even bytes with 45N D7:D0/odd bytes."""

    if len(upper_even) != len(lower_odd):
        raise ProgramRomError(
            "70N upper/even and 45N lower/odd lane sizes must match; "
            f"got 0x{len(upper_even):x} and 0x{len(lower_odd):x}"
        )
    interleaved = bytearray(2 * len(upper_even))
    interleaved[0::2] = upper_even
    interleaved[1::2] = lower_odd
    return bytes(interleaved)


def analyze_program_roms(upper_even: bytes, lower_odd: bytes) -> dict[str, object]:
    """Return a content-free provenance and A16/mirror report for both lanes."""

    upper_report = _analyze_lane(upper_even, "70N", "D15:D8 / even byte")
    lower_report = _analyze_lane(lower_odd, "45N", "D7:D0 / odd byte")
    interleaved = interleave_program_lanes(upper_even, lower_odd)
    lane_bytes = len(upper_even)

    if lane_bytes == EPROM_27256_BYTES:
        size_class = "27256-sized"
        a16_information_bearing: bool | None = None
        strap_implication = "E1_if_each_file_is_a_complete_27256_image"
    else:
        size_class = "27512-sized"
        a16_information_bearing = not (
            bool(upper_report["upper_32k_equals_lower_32k"])
            and bool(lower_report["upper_32k_equals_lower_32k"])
        )
        if a16_information_bearing:
            strap_implication = "E2_required_to_execute_both_distinct_32k_halves"
        else:
            strap_implication = "ambiguous_mirrored_64k_dump"

    return {
        "policy": "authorized_user_supplied_data_only_no_execution",
        "size_class": size_class,
        "lane_bytes": lane_bytes,
        "interleaved_bytes": len(interleaved),
        "interleaved_sha256": _sha256_bytes(interleaved),
        "a16_information_bearing": a16_information_bearing,
        "strap_implication": strap_implication,
        "physical_strap_proven": False,
        "lanes": {
            "70n_upper_even": upper_report,
            "45n_lower_odd": lower_report,
        },
    }


def analyze_files(upper_even_path: Path, lower_odd_path: Path) -> dict[str, object]:
    """Read and analyze two explicit local paths without modifying them."""

    try:
        upper_even = upper_even_path.read_bytes()
    except OSError as error:
        raise ProgramRomError(
            f"cannot read 70N image {upper_even_path}: {error}"
        ) from error
    try:
        lower_odd = lower_odd_path.read_bytes()
    except OSError as error:
        raise ProgramRomError(
            f"cannot read 45N image {lower_odd_path}: {error}"
        ) from error
    return analyze_program_roms(upper_even, lower_odd)


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--upper-even",
        type=Path,
        required=True,
        help="authorized 70N D15:D8/even-address lane image",
    )
    parser.add_argument(
        "--lower-odd",
        type=Path,
        required=True,
        help="authorized 45N D7:D0/odd-address lane image",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="indent JSON output; compact sorted JSON is the default",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_argument_parser().parse_args(argv)
    try:
        report = analyze_files(args.upper_even, args.lower_odd)
    except ProgramRomError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    indent = 2 if args.pretty else None
    separators = None if indent else (",", ":")
    print(json.dumps(report, indent=indent, sort_keys=True, separators=separators))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
