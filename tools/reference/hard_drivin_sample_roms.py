#!/usr/bin/env python3
"""Inventory authorized Driver Sound sample-ROM images by physical socket.

The tool hashes user-supplied images and maps the twelve A044427 sockets to
their physical /SR block numbers.  It never downloads, executes, disassembles,
or prints ROM contents, and supplied files do not prove board population.
"""

from __future__ import annotations

import argparse
from hashlib import sha256
import json
from pathlib import Path
import sys
from typing import Mapping, Sequence

SAMPLE_ROM_BYTES = 0x10000
BLOCK_TO_SOCKET = (
    "65A",
    "55A",
    "45A",
    "30A",
    "20A",
    "5A",
    "65C",
    "55C",
    "45C",
    "30C",
    "20C",
    "5C",
)
SOCKET_TO_BLOCK = {socket: block for block, socket in enumerate(BLOCK_TO_SOCKET)}


class SampleRomError(ValueError):
    """Raised when an image specification violates the physical socket map."""


def analyze_sample_roms(images: Mapping[str, bytes]) -> dict[str, object]:
    """Return a content-free block/presence report for explicit socket images."""

    normalized: dict[str, bytes] = {}
    for raw_socket, data in images.items():
        socket = raw_socket.upper()
        if socket not in SOCKET_TO_BLOCK:
            raise SampleRomError(f"unknown A044427 sample-ROM socket {raw_socket!r}")
        if socket in normalized:
            raise SampleRomError(f"duplicate sample-ROM socket {socket}")
        if len(data) != SAMPLE_ROM_BYTES:
            raise SampleRomError(
                f"{socket} must contain exactly 0x{SAMPLE_ROM_BYTES:x} bytes; "
                f"got 0x{len(data):x}"
            )
        normalized[socket] = data

    entries = []
    present_mask = 0
    for block, socket in enumerate(BLOCK_TO_SOCKET):
        if socket not in normalized:
            continue
        data = normalized[socket]
        present_mask |= 1 << block
        entries.append(
            {
                "block": block,
                "socket": socket,
                "bytes": len(data),
                "sha256": sha256(data).hexdigest(),
            }
        )

    present_blocks = [entry["block"] for entry in entries]
    return {
        "policy": "authorized_user_supplied_data_only_no_execution",
        "socket_map_authority": "A044427_Rev_A_sheet_6",
        "present_mask_12bit": present_mask,
        "present_mask_hex": f"0x{present_mask:03x}",
        "present_blocks": present_blocks,
        "absent_drawn_blocks": [
            block for block in range(len(BLOCK_TO_SOCKET)) if block not in present_blocks
        ],
        "undecoded_block_values": [12, 13, 14, 15],
        "physical_population_proven": False,
        "images": entries,
    }


def _parse_socket_specs(specs: Sequence[str]) -> dict[str, Path]:
    paths: dict[str, Path] = {}
    for spec in specs:
        if "=" not in spec:
            raise SampleRomError(
                f"socket specification {spec!r} must use SOCKET=PATH"
            )
        raw_socket, raw_path = spec.split("=", 1)
        socket = raw_socket.strip().upper()
        if socket not in SOCKET_TO_BLOCK:
            raise SampleRomError(f"unknown A044427 sample-ROM socket {raw_socket!r}")
        if socket in paths:
            raise SampleRomError(f"duplicate sample-ROM socket {socket}")
        if not raw_path:
            raise SampleRomError(f"sample-ROM socket {socket} has an empty path")
        paths[socket] = Path(raw_path)
    return paths


def analyze_files(specs: Sequence[str]) -> dict[str, object]:
    """Read explicit SOCKET=PATH arguments without modifying their files."""

    paths = _parse_socket_specs(specs)
    images: dict[str, bytes] = {}
    for socket, path in paths.items():
        try:
            images[socket] = path.read_bytes()
        except OSError as error:
            raise SampleRomError(f"cannot read {socket} image {path}: {error}") from error
    return analyze_sample_roms(images)


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--socket",
        action="append",
        required=True,
        metavar="SOCKET=PATH",
        help="authorized 64-KiB image at one A044427 socket; repeat as needed",
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
        report = analyze_files(args.socket)
    except SampleRomError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    indent = 2 if args.pretty else None
    separators = None if indent else (",", ":")
    print(json.dumps(report, indent=indent, sort_keys=True, separators=separators))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
