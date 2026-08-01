"""Create noncopyrighted placeholder ROM files from MAME's listxml metadata.

The files intentionally have wrong checksums.  They exist only to let MAME
construct a machine whose relevant writable memory is populated through the
debugger.  This tool runs MAME metadata commands, never emulation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ElementTree
from pathlib import Path
from typing import Sequence, TextIO

_SAFE_SYSTEM = re.compile(r"[a-z0-9_]+")
MAX_FILE_BYTES = 64 * 1024 * 1024
MAX_TOTAL_BYTES = 512 * 1024 * 1024


class SyntheticRomError(RuntimeError):
    """Raised when metadata or existing output violates the safe contract."""


def _run_metadata(mame: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            [str(mame), *arguments],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except OSError as error:
        raise SyntheticRomError(
            f"cannot execute MAME metadata command: {error}"
        ) from error


def read_machine_roms(mame: Path, system: str) -> tuple[str, list[tuple[str, int]]]:
    """Return reported version and unique required ROM names/sizes."""
    if _SAFE_SYSTEM.fullmatch(system) is None:
        raise SyntheticRomError(
            "system name may contain only lower-case letters, digits, '_'"
        )
    version_result = _run_metadata(mame, "-version")
    if version_result.returncode:
        raise SyntheticRomError(
            f"MAME -version failed with status {version_result.returncode}: "
            f"{version_result.stderr.strip()}"
        )
    xml_result = _run_metadata(mame, system, "-listxml")
    if xml_result.returncode:
        raise SyntheticRomError(
            f"MAME {system} -listxml failed with status {xml_result.returncode}: "
            f"{xml_result.stderr.strip()}"
        )
    try:
        root = ElementTree.fromstring(xml_result.stdout)
    except ElementTree.ParseError as error:
        raise SyntheticRomError(f"MAME listxml is malformed: {error}") from error
    machine = next(
        (node for node in root.findall("machine") if node.get("name") == system),
        None,
    )
    if machine is None:
        raise SyntheticRomError(f"MAME listxml contains no exact {system!r} machine")
    files: dict[str, int] = {}
    for rom in machine.findall("rom"):
        name = rom.get("name")
        size_text = rom.get("size")
        if name is None or size_text is None:
            raise SyntheticRomError("MAME listxml ROM entry lacks name or size")
        path = Path(name)
        if path.name != name or name in {".", ".."}:
            raise SyntheticRomError(f"unsafe MAME ROM filename: {name!r}")
        try:
            size = int(size_text, 10)
        except ValueError as error:
            raise SyntheticRomError(
                f"invalid MAME ROM size {size_text!r} for {name}"
            ) from error
        if size <= 0:
            raise SyntheticRomError(f"non-positive MAME ROM size for {name}: {size}")
        if size > MAX_FILE_BYTES:
            raise SyntheticRomError(
                f"MAME ROM size exceeds {MAX_FILE_BYTES} byte safety limit for {name}"
            )
        if name in files and files[name] != size:
            raise SyntheticRomError(
                f"MAME lists conflicting sizes for {name}: {files[name]} and {size}"
            )
        files[name] = size
    if not files:
        raise SyntheticRomError(f"MAME lists no ROM files for {system}")
    total_bytes = sum(files.values())
    if total_bytes > MAX_TOTAL_BYTES:
        raise SyntheticRomError(
            f"MAME ROM total exceeds {MAX_TOTAL_BYTES} byte safety limit: {total_bytes}"
        )
    version = version_result.stdout.strip()
    if not version:
        raise SyntheticRomError("MAME -version returned an empty version")
    return version, sorted(files.items())


def create_placeholders(
    destination: Path,
    system: str,
    files: Sequence[tuple[str, int]],
    *,
    fill_byte: int,
    mame_path: Path,
    mame_version: str,
) -> dict[str, object]:
    """Idempotently create exact-sized, single-byte-filled synthetic ROMs."""
    if not 0 <= fill_byte <= 0xFF:
        raise SyntheticRomError("fill byte must be in range 0..255")
    system_directory = destination / system
    system_directory.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, object]] = []
    total_bytes = 0
    for name, size in files:
        content = bytes([fill_byte]) * size
        path = system_directory / name
        if path.exists():
            if not path.is_file():
                raise SyntheticRomError(f"placeholder target is not a file: {path}")
            if path.read_bytes() != content:
                raise SyntheticRomError(
                    f"refusing to overwrite non-matching existing file: {path}"
                )
        else:
            path.write_bytes(content)
        checksum = hashlib.sha256(content).hexdigest()
        records.append({"name": name, "size": size, "sha256": checksum})
        total_bytes += size
    manifest: dict[str, object] = {
        "format": 1,
        "purpose": "noncopyrighted wrong-checksum MAME machine-construction placeholders",
        "system": system,
        "fill_byte": fill_byte,
        "mame_path": str(mame_path),
        "mame_version": mame_version,
        "total_bytes": total_bytes,
        "files": records,
    }
    manifest_path = system_directory / "synthetic_manifest.json"
    serialized = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    if (
        manifest_path.exists()
        and manifest_path.read_text(encoding="utf-8") != serialized
    ):
        raise SyntheticRomError(
            f"refusing to overwrite non-matching existing manifest: {manifest_path}"
        )
    manifest_path.write_text(serialized, encoding="utf-8")
    return manifest


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="create deterministic wrong-checksum MAME ROM placeholders"
    )
    parser.add_argument("--mame", type=Path, required=True)
    parser.add_argument("--system", default="harddriv")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--fill-byte", type=lambda value: int(value, 0), default=0)
    return parser


def main(
    argv: Sequence[str] | None = None,
    *,
    stdout: TextIO = sys.stdout,
    stderr: TextIO = sys.stderr,
) -> int:
    args = _build_parser().parse_args(argv)
    try:
        version, files = read_machine_roms(args.mame, args.system)
        manifest = create_placeholders(
            args.output,
            args.system,
            files,
            fill_byte=args.fill_byte,
            mame_path=args.mame,
            mame_version=version,
        )
    except (OSError, SyntheticRomError, UnicodeError) as error:
        print(f"ERROR: {error}", file=stderr)
        return 2
    print(
        f"PASS: created/verified {len(files)} synthetic {args.system} ROM files "
        f"({manifest['total_bytes']} bytes) under {args.output}",
        file=stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
