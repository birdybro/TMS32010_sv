#!/usr/bin/env python3
"""Safely populate the ignored reference cache from the provenance manifest."""

from __future__ import annotations

import argparse
import os
import socket
import sys
import tempfile
import urllib.error
import urllib.request
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

USER_AGENT = "tms32010-sv-reference-fetcher/1 (+local research tool)"
CHUNK_SIZE = 1024 * 1024


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest", type=Path, default=DEFAULT_MANIFEST, help="manifest path"
    )
    parser.add_argument(
        "--cache", type=Path, default=DEFAULT_CACHE, help="ignored cache root"
    )
    parser.add_argument(
        "--id", action="append", default=[], help="fetch one source ID; repeatable"
    )
    parser.add_argument(
        "--list", action="store_true", help="list source IDs without downloading"
    )
    parser.add_argument(
        "--timeout", type=float, default=30.0, help="per-operation timeout in seconds"
    )
    return parser.parse_args()


def normalized_content_type(headers: object) -> str:
    if hasattr(headers, "get_content_type"):
        return str(headers.get_content_type()).lower()
    return ""


def download_one(source: dict[str, object], cache_root: Path, timeout: float) -> str:
    destination = cache_path(source, cache_root)
    expected_digest = source["sha256"]

    if destination.is_file():
        actual_digest = sha256_file(destination)
        if expected_digest is None or actual_digest == expected_digest:
            qualifier = "unpinned" if expected_digest is None else "verified"
            print(f"CACHED {source['id']} {actual_digest} ({qualifier})")
            return "ok"
        print(
            f"INTEGRITY {source['id']}: cached SHA-256 {actual_digest} "
            f"!= manifest {expected_digest}",
            file=sys.stderr,
        )
        return "integrity"
    if destination.exists():
        print(
            f"INTEGRITY {source['id']}: destination is not a regular file",
            file=sys.stderr,
        )
        return "integrity"

    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(
        str(source["source_url"]),
        headers={"User-Agent": USER_AGENT, "Accept": "*/*"},
        method="GET",
    )
    temporary_name: str | None = None
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            final_url = response.geturl()
            if not final_url.startswith("https://"):
                raise ValueError(f"redirected to non-HTTPS URL: {final_url}")
            content_type = normalized_content_type(response.headers)
            allowed = {
                str(item).lower()
                for item in source["download"]["expected_content_types"]
            }
            if content_type not in allowed:
                raise ValueError(
                    f"unexpected Content-Type {content_type!r}; "
                    f"allowed: {', '.join(sorted(allowed))}"
                )

            with tempfile.NamedTemporaryFile(
                mode="wb",
                prefix=f".{destination.name}.",
                suffix=".partial",
                dir=destination.parent,
                delete=False,
            ) as temporary:
                temporary_name = temporary.name
                while True:
                    chunk = response.read(CHUNK_SIZE)
                    if not chunk:
                        break
                    temporary.write(chunk)
                temporary.flush()
                os.fsync(temporary.fileno())

        temporary_path = Path(temporary_name)
        actual_digest = sha256_file(temporary_path)
        if expected_digest is not None and actual_digest != expected_digest:
            print(
                f"INTEGRITY {source['id']}: downloaded SHA-256 {actual_digest} "
                f"!= manifest {expected_digest}",
                file=sys.stderr,
            )
            return "integrity"
        os.replace(temporary_path, destination)
        temporary_name = None
        qualifier = "record this hash in manifest" if expected_digest is None else "verified"
        print(f"FETCHED {source['id']} {actual_digest} ({qualifier})")
        return "ok"
    except (
        OSError,
        ValueError,
        socket.timeout,
        urllib.error.HTTPError,
        urllib.error.URLError,
    ) as error:
        print(f"UNAVAILABLE {source['id']}: {error}", file=sys.stderr)
        return "unavailable"
    finally:
        if temporary_name is not None:
            Path(temporary_name).unlink(missing_ok=True)


def main() -> int:
    args = parse_args()
    try:
        manifest = load_manifest(args.manifest)
        sources = select_sources(manifest, args.id)
    except ManifestError as error:
        print(f"MANIFEST ERROR: {error}", file=sys.stderr)
        return 2

    if args.list:
        for source in sources:
            print(f"{source['id']}\t{source['status']}\t{source['title']}")
        return 0

    if args.timeout <= 0:
        print("ERROR: --timeout must be positive", file=sys.stderr)
        return 2

    results = [download_one(source, args.cache, args.timeout) for source in sources]
    counts = {result: results.count(result) for result in set(results)}
    print(
        "SUMMARY "
        + " ".join(
            f"{key}={counts.get(key, 0)}"
            for key in ("ok", "unavailable", "integrity")
        )
    )
    return 1 if counts.get("integrity", 0) else 0


if __name__ == "__main__":
    raise SystemExit(main())
