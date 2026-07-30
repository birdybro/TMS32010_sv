#!/usr/bin/env python3
"""Verify cached references against acquired SHA-256 provenance records."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from reference_manifest import (
    DEFAULT_CACHE,
    DEFAULT_MANIFEST,
    ManifestError,
    cache_path,
    load_manifest,
    select_sources,
    sha256_file,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--id", action="append", default=[])
    parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="do not fail when an acquired source is absent from this clone",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        manifest = load_manifest(args.manifest)
        sources = select_sources(manifest, args.id)
    except ManifestError as error:
        print(f"MANIFEST ERROR: {error}", file=sys.stderr)
        return 2

    failures = 0
    checked = 0
    missing = 0
    unpinned = 0
    for source in sources:
        expected = source["sha256"]
        path = cache_path(source, args.cache)
        if expected is None:
            unpinned += 1
            print(f"UNPINNED {source['id']} status={source['status']}")
            continue
        if not path.is_file():
            missing += 1
            print(f"MISSING {source['id']} {path}", file=sys.stderr)
            if not args.allow_missing:
                failures += 1
            continue

        checked += 1
        actual = sha256_file(path)
        if actual != expected:
            failures += 1
            print(
                f"MISMATCH {source['id']} actual={actual} expected={expected}",
                file=sys.stderr,
            )
        else:
            print(f"OK {source['id']} {actual}")

    print(
        f"SUMMARY checked={checked} missing={missing} "
        f"unpinned={unpinned} failures={failures}"
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
