#!/usr/bin/env python3
"""Remove generated children of the repository build directory safely."""

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
    print(f"CLEAN: removed {removed} generated build entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
