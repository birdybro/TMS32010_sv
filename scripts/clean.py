#!/usr/bin/env python3
"""Remove known generated build and local Quartus products safely."""

from __future__ import annotations

import shutil
from pathlib import Path

from reference_manifest import REPOSITORY_ROOT


def main() -> int:
    build = (REPOSITORY_ROOT / "build").resolve()
    expected = REPOSITORY_ROOT.resolve() / "build"
    if build != expected or build.parent != REPOSITORY_ROOT.resolve():
        raise RuntimeError(f"refusing unexpected build path: {build}")
    build.mkdir(exist_ok=True)
    removed = 0
    for child in build.iterdir():
        if child.name == ".gitkeep":
            continue
        if child.is_dir() and not child.is_symlink():
            shutil.rmtree(child)
        else:
            child.unlink()
        removed += 1
    quartus = (REPOSITORY_ROOT / "synthesis" / "quartus").resolve()
    expected_quartus = REPOSITORY_ROOT.resolve() / "synthesis" / "quartus"
    if quartus != expected_quartus or quartus.parent.parent != REPOSITORY_ROOT.resolve():
        raise RuntimeError(f"refusing unexpected Quartus path: {quartus}")
    for name in (
        "db",
        "incremental_db",
        "output_files",
        "c5_pin_model_dump.txt",
    ):
        target = quartus / name
        if not target.exists() and not target.is_symlink():
            continue
        if target.is_dir() and not target.is_symlink():
            shutil.rmtree(target)
        else:
            target.unlink()
        removed += 1
    print(f"CLEAN: removed {removed} generated build entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
