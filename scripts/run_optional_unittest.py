#!/usr/bin/env python3
"""Run unittest discovery when a test directory contains Python tests."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: run_optional_unittest.py DIRECTORY", file=sys.stderr)
        return 2
    directory = Path(sys.argv[1])
    tests = sorted(directory.rglob("test_*.py"))
    if not tests:
        print(f"SKIP-EVIDENCE: no Python tests under {directory}")
        return 0
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "unittest",
            "discover",
            "-s",
            str(directory),
            "-p",
            "test_*.py",
            "-v",
        ],
        check=False,
    )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
