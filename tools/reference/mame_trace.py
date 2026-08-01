"""Parse and compare MAME TMS320C1x instruction-boundary traces.

The adapter consumes a deliberately strict marker emitted by MAME's debugger
``trace`` action.  It does not launch MAME, obtain ROMs, or interpret MAME's
cycle accounting as physical TMS32010 timing evidence.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence, TextIO

MARKER = "TMS32010_STATE"
DEFAULT_DEVICE_TAG = ":mainpcb:harddriv_sound:sounddsp"

_MAME_STATE_PATTERN = re.compile(
    rf"{MARKER} "
    r"PC=([0-9A-Fa-f]{4}) "
    r"ACC=([0-9A-Fa-f]{8}) "
    r"P=([0-9A-Fa-f]{8}) "
    r"T=([0-9A-Fa-f]{4}) "
    r"AR0=([0-9A-Fa-f]{4}) "
    r"AR1=([0-9A-Fa-f]{4}) "
    r"STR=([0-9A-Fa-f]{4}) "
    r"STK0=([0-9A-Fa-f]{4}) "
    r"STK1=([0-9A-Fa-f]{4}) "
    r"STK2=([0-9A-Fa-f]{4}) "
    r"STK3=([0-9A-Fa-f]{4})(?=\s|$)"
)
_SAFE_TRACE_FILE = re.compile(r"[A-Za-z0-9_./+-]+")
_SAFE_DEVICE_TAG = re.compile(r":[A-Za-z0-9_.:-]+")


class TraceFormatError(ValueError):
    """Raised when an oracle or model trace violates the adapter contract."""


@dataclass(frozen=True)
class MameState:
    """One pre-instruction state marker normalized to project conventions."""

    line_number: int
    pc: int
    acc: int
    p: int
    t: int
    ar: tuple[int, int]
    stack: tuple[int, int, int, int]
    ov: bool
    ovm: bool
    intm: bool
    arp: int
    dp: int
    raw_str: int


@dataclass(frozen=True)
class ModelStep:
    """The comparison-relevant portion of one model StepTrace JSON record."""

    line_number: int
    pc: int
    opcode: int
    mnemonic: str
    state_after: dict[str, object]


@dataclass(frozen=True)
class ComparisonResult:
    """Deterministic comparison summary."""

    compared_steps: int
    mame_rows: int
    mismatches: tuple[str, ...]


def _parse_hex_fields(match: re.Match[str]) -> list[int]:
    return [int(value, 16) for value in match.groups()]


def parse_mame_lines(lines: Iterable[str]) -> list[MameState]:
    """Parse every strict state marker and ignore ordinary MAME trace text."""
    states: list[MameState] = []
    for line_number, line in enumerate(lines, start=1):
        if MARKER not in line:
            continue
        match = _MAME_STATE_PATTERN.search(line)
        if match is None:
            raise TraceFormatError(
                f"MAME trace line {line_number}: malformed {MARKER} marker"
            )
        (
            pc,
            acc,
            p,
            t,
            ar0,
            ar1,
            status,
            stk0,
            stk1,
            stk2,
            stk3,
        ) = _parse_hex_fields(match)
        if pc > 0x0FFF:
            raise TraceFormatError(
                f"MAME trace line {line_number}: PC 0x{pc:04x} exceeds "
                "the original TMS32010 12-bit program space"
            )
        for name, value in (
            ("STK0", stk0),
            ("STK1", stk1),
            ("STK2", stk2),
            ("STK3", stk3),
        ):
            if value > 0x0FFF:
                raise TraceFormatError(
                    f"MAME trace line {line_number}: {name} 0x{value:04x} "
                    "exceeds the original TMS32010 12-bit stack width"
                )
        states.append(
            MameState(
                line_number=line_number,
                pc=pc,
                acc=acc,
                p=p,
                t=t,
                ar=(ar0, ar1),
                # MAME exposes its backing array from bottom to top.  The
                # project model exposes [top, level_1, level_2, bottom].
                stack=(stk3, stk2, stk1, stk0),
                ov=bool(status & 0x8000),
                ovm=bool(status & 0x4000),
                intm=bool(status & 0x2000),
                arp=(status >> 8) & 1,
                dp=status & 1,
                raw_str=status,
            )
        )
    if not states:
        raise TraceFormatError(f"MAME trace contains no {MARKER} markers")
    return states


def parse_mame_trace(path: str | Path) -> list[MameState]:
    """Load a UTF-8 MAME debugger trace."""
    try:
        with Path(path).open(encoding="utf-8") as stream:
            return parse_mame_lines(stream)
    except UnicodeDecodeError as error:
        raise TraceFormatError(f"MAME trace is not UTF-8 text: {path}") from error


def _require_int(record: dict[str, object], key: str, line_number: int) -> int:
    value = record.get(key)
    if not isinstance(value, int) or isinstance(value, bool):
        raise TraceFormatError(
            f"model trace line {line_number}: {key!r} must be an integer"
        )
    return value


def parse_model_lines(lines: Iterable[str]) -> list[ModelStep]:
    """Parse model StepTrace JSONL without importing the model implementation."""
    steps: list[ModelStep] = []
    for line_number, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as error:
            raise TraceFormatError(
                f"model trace line {line_number}: invalid JSON: {error.msg}"
            ) from error
        if not isinstance(record, dict):
            raise TraceFormatError(
                f"model trace line {line_number}: JSON record must be an object"
            )
        mnemonic = record.get("mnemonic")
        state_after = record.get("state_after")
        if not isinstance(mnemonic, str) or not mnemonic:
            raise TraceFormatError(
                f"model trace line {line_number}: 'mnemonic' must be a string"
            )
        if mnemonic == "INTERRUPT":
            raise TraceFormatError(
                f"model trace line {line_number}: MAME services interrupt entry "
                "before its instruction hook and cannot align the model's "
                "separate INTERRUPT pseudo-step; hold interrupt inactive"
            )
        if not isinstance(state_after, dict):
            raise TraceFormatError(
                f"model trace line {line_number}: 'state_after' must be an object"
            )
        pc = _require_int(record, "pc", line_number)
        opcode = _require_int(record, "opcode", line_number)
        if not 0 <= pc <= 0x0FFF:
            raise TraceFormatError(
                f"model trace line {line_number}: PC 0x{pc:x} is out of range"
            )
        if not 0 <= opcode <= 0xFFFF:
            raise TraceFormatError(
                f"model trace line {line_number}: opcode 0x{opcode:x} is out of range"
            )
        steps.append(
            ModelStep(
                line_number=line_number,
                pc=pc,
                opcode=opcode,
                mnemonic=mnemonic,
                state_after=state_after,
            )
        )
    if not steps:
        raise TraceFormatError("model trace contains no StepTrace JSON records")
    return steps


def parse_model_trace(path: str | Path) -> list[ModelStep]:
    """Load a UTF-8 model StepTrace JSONL file."""
    try:
        with Path(path).open(encoding="utf-8") as stream:
            return parse_model_lines(stream)
    except UnicodeDecodeError as error:
        raise TraceFormatError(f"model trace is not UTF-8 text: {path}") from error


def _model_state_view(step: ModelStep) -> dict[str, int | bool]:
    state = step.state_after
    try:
        ar = state["ar"]
        stack = state["stack"]
        status = state["status"]
        if not isinstance(ar, list) or len(ar) != 2:
            raise TypeError("ar must contain two values")
        if not isinstance(stack, list) or len(stack) != 4:
            raise TypeError("stack must contain four values")
        if not isinstance(status, dict):
            raise TypeError("status must be an object")
        view: dict[str, int | bool] = {
            "pc": state["pc"],
            "acc": state["acc"],
            "p": state["p"],
            "t": state["t"],
            "ar[0]": ar[0],
            "ar[1]": ar[1],
            "stack[0]": stack[0],
            "stack[1]": stack[1],
            "stack[2]": stack[2],
            "stack[3]": stack[3],
            "status.ov": status["ov"],
            "status.ovm": status["ovm"],
            "status.intm": status["intm"],
            "status.arp": status["arp"],
            "status.dp": status["dp"],
        }
    except (KeyError, TypeError, IndexError) as error:
        raise TraceFormatError(
            f"model trace line {step.line_number}: malformed state_after: {error}"
        ) from error
    for name in ("status.ov", "status.ovm", "status.intm"):
        if not isinstance(view[name], bool):
            raise TraceFormatError(
                f"model trace line {step.line_number}: {name} must be boolean"
            )
    limits = {
        "pc": 0x0FFF,
        "acc": 0xFFFF_FFFF,
        "p": 0xFFFF_FFFF,
        "t": 0xFFFF,
        "ar[0]": 0xFFFF,
        "ar[1]": 0xFFFF,
        "stack[0]": 0x0FFF,
        "stack[1]": 0x0FFF,
        "stack[2]": 0x0FFF,
        "stack[3]": 0x0FFF,
        "status.arp": 1,
        "status.dp": 1,
    }
    for name, limit in limits.items():
        value = view[name]
        if not isinstance(value, int) or isinstance(value, bool):
            raise TraceFormatError(
                f"model trace line {step.line_number}: {name} must be an integer"
            )
        if not 0 <= value <= limit:
            raise TraceFormatError(
                f"model trace line {step.line_number}: {name} "
                f"0x{value:x} exceeds range 0x0..0x{limit:x}"
            )
    return view


def _mame_state_view(state: MameState) -> dict[str, int | bool]:
    return {
        "pc": state.pc,
        "acc": state.acc,
        "p": state.p,
        "t": state.t,
        "ar[0]": state.ar[0],
        "ar[1]": state.ar[1],
        "stack[0]": state.stack[0],
        "stack[1]": state.stack[1],
        "stack[2]": state.stack[2],
        "stack[3]": state.stack[3],
        "status.ov": state.ov,
        "status.ovm": state.ovm,
        "status.intm": state.intm,
        "status.arp": state.arp,
        "status.dp": state.dp,
    }


def _display(value: int | bool) -> str:
    if isinstance(value, bool):
        return str(value).lower()
    return f"0x{value:x}"


def compare_steps(
    model_steps: Sequence[ModelStep],
    mame_states: Sequence[MameState],
    *,
    allow_trailing: bool = False,
) -> ComparisonResult:
    """Align model post-state N with MAME pre-state N+1 and compare it."""
    if len(mame_states) < len(model_steps) + 1:
        raise TraceFormatError(
            f"MAME trace has {len(mame_states)} state rows for "
            f"{len(model_steps)} model steps; one following sentinel row is "
            "required because MAME actions run before instruction execution"
        )
    expected_rows = len(model_steps) + 1
    if not allow_trailing and len(mame_states) > expected_rows:
        raise TraceFormatError(
            f"MAME trace has {len(mame_states)} state rows but exactly "
            f"{expected_rows} are required; trim the trace or explicitly use "
            "--allow-trailing"
        )
    mismatches: list[str] = []
    for index, step in enumerate(model_steps):
        before = mame_states[index]
        after = mame_states[index + 1]
        context = (
            f"step {index} {step.mnemonic} opcode=0x{step.opcode:04x} "
            f"model-line={step.line_number}"
        )
        if step.pc != before.pc:
            mismatches.append(
                f"{context}: pre.pc model=0x{step.pc:03x} "
                f"mame=0x{before.pc:03x} mame-line={before.line_number}"
            )
        model_view = _model_state_view(step)
        mame_view = _mame_state_view(after)
        for name in model_view:
            if model_view[name] != mame_view[name]:
                mismatches.append(
                    f"{context}: post.{name} "
                    f"model={_display(model_view[name])} "
                    f"mame={_display(mame_view[name])} "
                    f"mame-line={after.line_number}"
                )
    return ComparisonResult(
        compared_steps=len(model_steps),
        mame_rows=len(mame_states),
        mismatches=tuple(mismatches),
    )


def debugger_trace_command(trace_file: str, device_tag: str) -> str:
    """Return a safe MAME debugger command for the strict marker format."""
    if _SAFE_TRACE_FILE.fullmatch(trace_file) is None:
        raise ValueError(
            "trace filename may contain only letters, digits, '_./+-'"
        )
    if _SAFE_DEVICE_TAG.fullmatch(device_tag) is None:
        raise ValueError("device tag is not a safe absolute MAME tag")
    fields = (
        "PC=%04X ACC=%08X P=%08X T=%04X AR0=%04X AR1=%04X "
        "STR=%04X STK0=%04X STK1=%04X STK2=%04X STK3=%04X "
    )
    registers = "PC,ACC,P,T,AR0,AR1,STR,STK0,STK1,STK2,STK3"
    return (
        f'trace {trace_file},{device_tag},noloop,'
        f'{{tracelog "{MARKER} {fields}",{registers}}}'
    )


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate or compare strict MAME TMS320C1x state traces"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    command = subparsers.add_parser(
        "command", help="print the MAME debugger trace command"
    )
    command.add_argument("--trace-file", required=True)
    command.add_argument("--device-tag", default=DEFAULT_DEVICE_TAG)
    compare = subparsers.add_parser(
        "compare", help="compare model StepTrace JSONL with MAME trace text"
    )
    compare.add_argument("--model", required=True)
    compare.add_argument("--mame", required=True)
    compare.add_argument(
        "--allow-trailing",
        action="store_true",
        help="ignore MAME rows after the required following boundary",
    )
    return parser


def main(
    argv: Sequence[str] | None = None,
    *,
    stdout: TextIO = sys.stdout,
    stderr: TextIO = sys.stderr,
) -> int:
    """CLI entry point with deterministic diagnostics and exit status."""
    parser = _build_parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "command":
            print(
                debugger_trace_command(args.trace_file, args.device_tag),
                file=stdout,
            )
            return 0
        model_steps = parse_model_trace(args.model)
        mame_states = parse_mame_trace(args.mame)
        result = compare_steps(
            model_steps, mame_states, allow_trailing=args.allow_trailing
        )
    except (OSError, TraceFormatError, ValueError) as error:
        print(f"ERROR: {error}", file=stderr)
        return 2
    if result.mismatches:
        for mismatch in result.mismatches:
            print(f"MISMATCH: {mismatch}", file=stderr)
        print(
            f"FAIL: {len(result.mismatches)} mismatches across "
            f"{result.compared_steps} steps",
            file=stderr,
        )
        return 1
    trailing = result.mame_rows - result.compared_steps - 1
    print(
        f"PASS: {result.compared_steps} model steps match MAME "
        f"instruction-boundary state ({trailing} trailing rows ignored)",
        file=stdout,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
