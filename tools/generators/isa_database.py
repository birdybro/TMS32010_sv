"""Load and validate the partial machine-readable TMS32010 ISA database."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATABASE = REPOSITORY_ROOT / "docs" / "generated" / "tms32010_isa.yaml"

REQUIRED_INSTRUCTION_FIELDS = {
    "mnemonic",
    "aliases",
    "opcode",
    "operands",
    "addressing_modes",
    "registers_read",
    "registers_written",
    "memory_accesses",
    "status_flags_affected",
    "arithmetic_width_bits",
    "sign_extension_behavior",
    "shift_behavior",
    "overflow_behavior",
    "result_behavior",
    "branch_behavior",
    "interrupt_interaction",
    "documented_cycle_count",
    "conditional_cycle_differences",
    "external_bus_cycles",
    "source_citations",
    "confidence_level",
    "unresolved_questions",
}
VALID_CONFIDENCE_LEVELS = {
    "VERIFIED_PRIMARY",
    "VERIFIED_HARDWARE",
    "CORROBORATED",
    "INFERRED",
    "PROVISIONAL",
    "UNKNOWN",
}


class IsaDatabaseError(ValueError):
    """Raised when the canonical ISA data fails structural validation."""


def parse_int(value: int | str) -> int:
    """Parse a database integer while retaining readable hexadecimal source."""
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        return int(value, 0)
    raise IsaDatabaseError(f"expected integer or string, got {type(value).__name__}")


def decode_entry(entry: dict[str, Any], word: int) -> dict[str, int] | None:
    """Return decoded variable fields when *word* matches one entry."""
    if not 0 <= word <= 0xFFFF:
        raise ValueError(f"instruction word out of range: {word}")
    opcode = entry["opcode"]
    match = parse_int(opcode["match"])
    mask = parse_int(opcode["mask"])
    if word & mask != match & mask:
        return None
    fields: dict[str, int] = {}
    for field in opcode["variable_fields"]:
        width = int(field["width"])
        raw = (word >> int(field["lsb"])) & ((1 << width) - 1)
        if field["signed"] and raw & (1 << (width - 1)):
            raw -= 1 << width
        fields[field["name"]] = raw
    return fields


def validate_database(database: dict[str, Any]) -> None:
    """Validate schema, coverage partition, encodings, and decode uniqueness."""
    if database.get("schema_version") != 1:
        raise IsaDatabaseError("unsupported ISA schema version")
    if database.get("device") != "TMS32010":
        raise IsaDatabaseError("database device is not the original TMS32010")

    coverage = database.get("coverage")
    instructions = database.get("instructions")
    if not isinstance(coverage, dict) or not isinstance(instructions, list):
        raise IsaDatabaseError("database must contain coverage and instructions")

    expected = coverage.get("documented_mnemonics")
    supported = coverage.get("supported_mnemonics")
    if not isinstance(expected, list) or not isinstance(supported, list):
        raise IsaDatabaseError("coverage mnemonic lists are missing")
    if len(expected) != coverage.get("expected_documented_instruction_count"):
        raise IsaDatabaseError("documented mnemonic count does not match expectation")
    if len(expected) != len(set(expected)):
        raise IsaDatabaseError("documented mnemonic list contains duplicates")
    if not set(supported) <= set(expected):
        raise IsaDatabaseError("supported mnemonics are outside documented scope")

    entry_names: list[str] = []
    source_ids = _manifest_source_ids()
    for entry in instructions:
        if not isinstance(entry, dict):
            raise IsaDatabaseError("instruction entry is not a mapping")
        missing = REQUIRED_INSTRUCTION_FIELDS - set(entry)
        if missing:
            raise IsaDatabaseError(
                f"{entry.get('mnemonic', '<unknown>')} missing fields: "
                f"{', '.join(sorted(missing))}"
            )
        mnemonic = entry["mnemonic"]
        entry_names.append(mnemonic)
        if entry["confidence_level"] not in VALID_CONFIDENCE_LEVELS:
            raise IsaDatabaseError(f"{mnemonic} has invalid confidence level")
        opcode = entry["opcode"]
        match = parse_int(opcode["match"])
        mask = parse_int(opcode["mask"])
        if not 0 <= match <= 0xFFFF or not 0 <= mask <= 0xFFFF:
            raise IsaDatabaseError(f"{mnemonic} opcode is not 16 bits")
        if match & ~mask:
            raise IsaDatabaseError(f"{mnemonic} match sets an unmasked bit")
        variable_mask = 0
        for field in opcode["variable_fields"]:
            lsb = int(field["lsb"])
            width = int(field["width"])
            if lsb < 0 or width < 1 or lsb + width > 16:
                raise IsaDatabaseError(f"{mnemonic} has invalid variable field")
            field_mask = ((1 << width) - 1) << lsb
            if variable_mask & field_mask:
                raise IsaDatabaseError(f"{mnemonic} has overlapping variable fields")
            if mask & field_mask:
                raise IsaDatabaseError(
                    f"{mnemonic} variable field overlaps fixed opcode bits"
                )
            variable_mask |= field_mask
        if variable_mask != (~mask & 0xFFFF):
            raise IsaDatabaseError(
                f"{mnemonic} does not describe every variable opcode bit"
            )
        if entry["documented_cycle_count"] < 1:
            raise IsaDatabaseError(f"{mnemonic} has invalid cycle count")
        for citation in entry["source_citations"]:
            if citation.get("source_id") not in source_ids:
                raise IsaDatabaseError(f"{mnemonic} has unresolved source citation")

    if entry_names != supported:
        raise IsaDatabaseError("entry order/content differs from supported mnemonics")
    if len(entry_names) != len(set(entry_names)):
        raise IsaDatabaseError("duplicate instruction entries")

    for word in range(0x10000):
        matches = [
            entry["mnemonic"]
            for entry in instructions
            if decode_entry(entry, word) is not None
        ]
        if len(matches) > 1:
            raise IsaDatabaseError(
                f"decode collision at 0x{word:04x}: {', '.join(matches)}"
            )


def _manifest_source_ids() -> set[str]:
    manifest_path = REPOSITORY_ROOT / "docs" / "references" / "manifest.yaml"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    return {source["id"] for source in manifest["sources"]}


def load_database(path: Path = DEFAULT_DATABASE) -> dict[str, Any]:
    """Load JSON-compatible YAML and reject malformed or inconsistent data."""
    try:
        database = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise IsaDatabaseError(f"cannot load ISA database {path}: {error}") from error
    validate_database(database)
    return database


def decode_word(
    database: dict[str, Any],
    word: int,
) -> tuple[dict[str, Any], dict[str, int]] | None:
    """Decode one supported word, returning its entry and operand fields."""
    matches = []
    for entry in database["instructions"]:
        operands = decode_entry(entry, word)
        if operands is not None:
            matches.append((entry, operands))
    if not matches:
        return None
    if len(matches) != 1:
        raise IsaDatabaseError(f"ambiguous decode at 0x{word:04x}")
    return matches[0]
