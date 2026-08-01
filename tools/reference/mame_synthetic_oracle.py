"""Run a ROM-free MAME/model architectural-boundary smoke comparison.

This opt-in tool creates deterministic wrong-checksum placeholder files,
injects a project-authored PUSH/POP program into writable Hard Drivin' DSP
program RAM through the debugger, and compares MAME state with the independent
model.  It is not a cycle- or pin-timing oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence, TextIO

from sim.reference_models.tms32010_model import Tms32010Model
from tools.assembler.tms32010_as import Assembler
from tools.reference.mame_synthetic_roms import (
    SyntheticRomError,
    create_placeholders,
    read_machine_roms,
)
from tools.reference.mame_trace import (
    DEFAULT_DEVICE_TAG,
    TraceFormatError,
    compare_steps,
    debugger_trace_command,
    parse_mame_trace,
    parse_model_trace,
)

SYSTEM = "harddriv"
DEVICE_TAG = DEFAULT_DEVICE_TAG.removeprefix(":")
SOUND_CPU_TAG = "mainpcb:harddriv_sound:soundcpu"
FIXTURE = Path("tests/asm/push_pop_bus_probe.asm")
TRACE_START_PC = 1
STOP_PC = 6
MODEL_STEPS = STOP_PC - TRACE_START_PC
INSPECTED_SOURCE_COMMIT = "030fefcbd14e47c01ec9d67655be90f64a1dc8ab"


class SyntheticOracleError(RuntimeError):
    """Raised when MAME execution cannot satisfy the strict smoke contract."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def _resolve_mame(path: Path) -> Path:
    if len(path.parts) == 1:
        resolved = shutil.which(str(path))
        if resolved is None:
            raise SyntheticOracleError(f"MAME executable is not on PATH: {path}")
        return Path(resolved).resolve()
    return path.resolve()


def _program_words(repository: Path) -> dict[int, int]:
    result = Assembler().assemble_file(repository / FIXTURE)
    expected = {
        0x000: 0x7E55,
        0x001: 0x7F9C,
        0x002: 0x7F80,
        0x003: 0x7EAA,
        0x004: 0x7F9D,
        0x005: 0x7F80,
        0x006: 0xF900,
        0x007: 0x0006,
    }
    if result.words != expected or result.symbols.get("HOLD") != STOP_PC:
        raise SyntheticOracleError("PUSH/POP hand fixture changed unexpectedly")
    return result.words


def build_debug_script(words: dict[int, int], trace_path: Path) -> str:
    """Build the two-stage debugger script required to change CPU focus."""
    writes = " ; ".join(
        f"do {DEVICE_TAG}.pw@{address:x} = {word:04x}"
        for address, word in sorted(words.items())
    )
    first_line = (
        f"{writes} ; bp 0:{DEVICE_TAG} ; "
        f"do {SOUND_CPU_TAG}.pw!ff1018 = 0 ; focus {DEVICE_TAG}"
    )
    trace_command = debugger_trace_command(str(trace_path), DEFAULT_DEVICE_TAG)
    second_line = (
        f"bpclear 1 ; do pc = 0 ; {trace_command} ; "
        f"bp {STOP_PC:x},1,{{trace off,{DEFAULT_DEVICE_TAG} ; "
        "traceflush ; quit} ; go"
    )
    return first_line + "\n" + second_line + "\n"


def build_model_trace(words: dict[int, int], path: Path) -> None:
    """Create the independently executed trace aligned after the prime word."""
    model = Tms32010Model()
    model.state.status.ovm = True
    model.state.status.intm = True
    for address, word in words.items():
        model.program[address] = word
    prime = model.step()
    if prime.pc != 0 or prime.mnemonic != "LACK" or model.state.pc != TRACE_START_PC:
        raise SyntheticOracleError("unexpected synthetic trace priming instruction")
    records = [model.step() for _ in range(MODEL_STEPS)]
    if records[0].pc != TRACE_START_PC or model.state.pc != STOP_PC:
        raise SyntheticOracleError("synthetic model trace reached an unexpected PC")
    path.write_text(
        "".join(record.to_json() + "\n" for record in records),
        encoding="utf-8",
    )


def run_oracle(
    *,
    repository: Path,
    mame: Path,
    output: Path,
    debugger: str,
    timeout_seconds: float,
) -> dict[str, object]:
    """Generate inputs, run the installed MAME binary, and compare state."""
    repository = repository.resolve()
    mame = _resolve_mame(mame)
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    version, rom_files = read_machine_roms(mame, SYSTEM)
    placeholder_manifest = create_placeholders(
        output / "roms",
        SYSTEM,
        rom_files,
        fill_byte=0,
        mame_path=mame,
        mame_version=version,
    )
    words = _program_words(repository)
    trace_path = output / "mame.tr"
    model_path = output / "model.jsonl"
    script_path = output / "debugger.cmd"
    log_path = output / "mame_output.txt"
    result_path = output / "result.json"
    build_model_trace(words, model_path)
    script_path.write_text(build_debug_script(words, trace_path), encoding="utf-8")
    # A failed debugger script must never leave a prior passing trace/result
    # looking current in this explicit generated-output directory.
    trace_path.write_bytes(b"")
    result_path.write_text(
        json.dumps(
            {
                "format": 1,
                "status": "NOT_QUALIFIED",
                "reason": "synthetic MAME run has not completed successfully",
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    command = [
        str(mame),
        SYSTEM,
        "-rompath",
        str(output / "roms"),
        "-noplugins",
        "-debug",
        "-debugger",
        debugger,
        "-debugscript",
        str(script_path),
        "-video",
        "none",
        "-sound",
        "none",
        "-nothrottle",
        "-skip_gameinfo",
        "-seconds_to_run",
        "2",
    ]
    try:
        completed = subprocess.run(
            command,
            cwd=output,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=timeout_seconds,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise SyntheticOracleError(f"MAME synthetic run failed: {error}") from error
    combined_output = completed.stdout + completed.stderr
    log_path.write_text(combined_output, encoding="utf-8")
    if completed.returncode:
        raise SyntheticOracleError(
            f"MAME synthetic run returned status {completed.returncode}; see {log_path}"
        )
    if "WRONG CHECKSUMS" not in combined_output:
        raise SyntheticOracleError(
            "MAME did not report the intentionally wrong synthetic checksums"
        )
    if not trace_path.is_file() or not trace_path.stat().st_size:
        raise SyntheticOracleError(f"MAME produced no state trace: {trace_path}")
    model_steps = parse_model_trace(model_path)
    mame_states = parse_mame_trace(trace_path)
    comparison = compare_steps(model_steps, mame_states)
    if comparison.mismatches:
        raise SyntheticOracleError("; ".join(comparison.mismatches))
    result: dict[str, object] = {
        "format": 1,
        "claim": "MAME TMS320C10 architectural instruction-boundary smoke only",
        "excludes": [
            "original NMOS TMS32010 equivalence",
            "instruction cycle accounting",
            "external bus transactions",
            "pin timing",
        ],
        "mame_path": str(mame),
        "mame_version": version,
        "mame_sha256": _sha256(mame),
        "inspected_source_commit_not_binary_identity": INSPECTED_SOURCE_COMMIT,
        "system": SYSTEM,
        "device_tag": DEFAULT_DEVICE_TAG,
        "fixture": str(FIXTURE),
        "model_steps": comparison.compared_steps,
        "mame_rows": comparison.mame_rows,
        "debugger": debugger,
        "placeholder_total_bytes": placeholder_manifest["total_bytes"],
        "placeholder_manifest_sha256": _sha256(
            output / "roms" / SYSTEM / "synthetic_manifest.json"
        ),
        "debugger_script_sha256": _sha256(script_path),
        "model_trace_sha256": _sha256(model_path),
        "mame_trace_sha256": _sha256(trace_path),
        "mame_output_sha256": _sha256(log_path),
        "invocation": command,
        "status": "PASS",
    }
    result_path.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return result


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="run the ROM-free Hard Drivin' MAME/model smoke oracle"
    )
    parser.add_argument("--mame", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("build/mame_synthetic"))
    parser.add_argument("--repository", type=Path, default=Path.cwd())
    parser.add_argument("--debugger", choices=("qt", "imgui"), default="qt")
    parser.add_argument("--timeout-seconds", type=float, default=20.0)
    return parser


def main(
    argv: Sequence[str] | None = None,
    *,
    stdout: TextIO = sys.stdout,
    stderr: TextIO = sys.stderr,
) -> int:
    args = _build_parser().parse_args(argv)
    if args.timeout_seconds <= 0:
        print("ERROR: timeout must be positive", file=stderr)
        return 2
    try:
        result = run_oracle(
            repository=args.repository,
            mame=args.mame,
            output=args.output,
            debugger=args.debugger,
            timeout_seconds=args.timeout_seconds,
        )
    except (
        OSError,
        SyntheticOracleError,
        SyntheticRomError,
        TraceFormatError,
        UnicodeError,
        ValueError,
    ) as error:
        print(f"ERROR: {error}", file=stderr)
        return 2
    print(
        f"PASS: {result['model_steps']} model steps match the ROM-free "
        f"MAME {result['mame_version']} TMS320C10 boundary trace",
        file=stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
