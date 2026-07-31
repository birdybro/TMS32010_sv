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
OPCODE_CLASSIFICATIONS = {
    "DOCUMENTED_LEGAL",
    "PRIMARY_RESERVED_INDIRECT_FIELD",
    "UNRESOLVED_SIMULTANEOUS_UPDATE",
    "DOCUMENTED_PATTERN_MISMATCH",
    "PRIMARY_UNLISTED_ENCODING",
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
    for constraint in opcode.get("constraints", []):
        when = constraint["when"]
        when_mask = parse_int(when["mask"])
        when_match = parse_int(when["match"])
        if word & when_mask != when_match:
            continue
        if "require" in constraint:
            requirement = constraint["require"]
            required_mask = parse_int(requirement["mask"])
            required_match = parse_int(requirement["match"])
            if word & required_mask != required_match:
                return None
        else:
            forbidden = constraint["forbid"]
            forbidden_mask = parse_int(forbidden["mask"])
            forbidden_match = parse_int(forbidden["match"])
            if word & forbidden_mask == forbidden_match:
                return None
    fields: dict[str, int] = {}
    for field in opcode["variable_fields"]:
        width = int(field["width"])
        raw = (word >> int(field["lsb"])) & ((1 << width) - 1)
        if field["signed"] and raw & (1 << (width - 1)):
            raw -= 1 << width
        if "legal_values" in field and raw not in field["legal_values"]:
            return None
        fields[field["name"]] = raw
    return fields


def classify_word(database: dict[str, Any], word: int) -> dict[str, Any]:
    """Classify one word without assigning behavior to unsupported encodings.

    Classification is deliberately narrower than decode. A word may lie in a
    primary-documented instruction pattern while violating a fixed, reserved,
    or unresolved field. That does not make the word a legal instruction or
    establish what original silicon does when it is executed.
    """
    if not 0 <= word <= 0xFFFF:
        raise ValueError(f"instruction word out of range: {word}")

    legal: list[tuple[dict[str, Any], dict[str, int]]] = []
    pattern_candidates: list[dict[str, Any]] = []
    base_candidates: list[dict[str, Any]] = []
    for entry in database["instructions"]:
        opcode = entry["opcode"]
        match = parse_int(opcode["match"])
        mask = parse_int(opcode["mask"])
        if word & mask == match & mask:
            base_candidates.append(entry)
        envelope = opcode.get("audit_envelope", opcode)
        envelope_match = parse_int(envelope["match"])
        envelope_mask = parse_int(envelope["mask"])
        if word & envelope_mask == envelope_match & envelope_mask:
            pattern_candidates.append(entry)
        operands = decode_entry(entry, word)
        if operands is not None:
            legal.append((entry, operands))

    if len(legal) > 1:
        names = ", ".join(item[0]["mnemonic"] for item in legal)
        raise IsaDatabaseError(f"ambiguous decode at 0x{word:04x}: {names}")
    if legal:
        entry, operands = legal[0]
        return {
            "classification": "DOCUMENTED_LEGAL",
            "mnemonics": [entry["mnemonic"]],
            "operands": operands,
        }

    reserved_candidates: list[str] = []
    simultaneous_candidates: list[str] = []
    for entry in base_candidates:
        fields = {
            field["name"]: field
            for field in entry["opcode"]["variable_fields"]
        }
        if "indirect" not in fields or "addressing_field" not in fields:
            continue
        indirect_field = fields["indirect"]
        address_field = fields["addressing_field"]
        indirect = (word >> int(indirect_field["lsb"])) & 1
        address = (
            word >> int(address_field["lsb"])
        ) & ((1 << int(address_field["width"])) - 1)
        if not indirect:
            continue
        if address & 0x46:
            reserved_candidates.append(entry["mnemonic"])
        elif (address & 0x30) == 0x30 and all(
            "legal_values" not in field
            or (
                (word >> int(field["lsb"]))
                & ((1 << int(field["width"])) - 1)
            )
            in field["legal_values"]
            for field in entry["opcode"]["variable_fields"]
        ):
            simultaneous_candidates.append(entry["mnemonic"])

    if reserved_candidates:
        return {
            "classification": "PRIMARY_RESERVED_INDIRECT_FIELD",
            "mnemonics": sorted(set(reserved_candidates)),
        }
    if simultaneous_candidates:
        return {
            "classification": "UNRESOLVED_SIMULTANEOUS_UPDATE",
            "mnemonics": sorted(set(simultaneous_candidates)),
            "unresolved_question": "OQ-010",
        }
    if pattern_candidates:
        return {
            "classification": "DOCUMENTED_PATTERN_MISMATCH",
            "mnemonics": sorted(
                {entry["mnemonic"] for entry in pattern_candidates}
            ),
        }
    return {"classification": "PRIMARY_UNLISTED_ENCODING", "mnemonics": []}


def audit_opcode_space(database: dict[str, Any]) -> dict[str, int]:
    """Return exhaustive classification counts for all 65,536 words."""
    counts = {name: 0 for name in sorted(OPCODE_CLASSIFICATIONS)}
    for word in range(0x10000):
        counts[classify_word(database, word)["classification"]] += 1
    return counts


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

    audit = database.get("opcode_space_audit")
    if not isinstance(audit, dict):
        raise IsaDatabaseError("database must contain opcode_space_audit")
    definitions = audit.get("classification_definitions")
    expected_counts = audit.get("expected_counts")
    if not isinstance(definitions, list) or not isinstance(expected_counts, dict):
        raise IsaDatabaseError("opcode-space audit definitions/counts are missing")
    definition_names = [definition.get("name") for definition in definitions]
    if set(definition_names) != OPCODE_CLASSIFICATIONS:
        raise IsaDatabaseError("opcode-space classification definitions differ")
    if len(definition_names) != len(set(definition_names)):
        raise IsaDatabaseError("duplicate opcode-space classification definition")
    if set(expected_counts) != OPCODE_CLASSIFICATIONS:
        raise IsaDatabaseError("opcode-space expected-count categories differ")
    if any(
        type(count) is not int or count < 0
        for count in expected_counts.values()
    ):
        raise IsaDatabaseError("opcode-space expected counts must be nonnegative integers")
    if sum(expected_counts.values()) != 0x10000:
        raise IsaDatabaseError("opcode-space expected counts do not cover 16 bits")

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
            if "legal_values" in field:
                legal_values = field["legal_values"]
                if (
                    not isinstance(legal_values, list)
                    or not legal_values
                    or len(legal_values) != len(set(legal_values))
                    or any(
                        type(value) is not int or not 0 <= value < (1 << width)
                        for value in legal_values
                    )
                ):
                    raise IsaDatabaseError(
                        f"{mnemonic} variable field has invalid legal values"
                    )
            variable_mask |= field_mask
        if variable_mask != (~mask & 0xFFFF):
            raise IsaDatabaseError(
                f"{mnemonic} does not describe every variable opcode bit"
            )
        for constraint in opcode.get("constraints", []):
            _validate_constraint(mnemonic, constraint)
        if "audit_envelope" in opcode:
            envelope = opcode["audit_envelope"]
            if not isinstance(envelope, dict) or set(envelope) != {"mask", "match"}:
                raise IsaDatabaseError(
                    f"{mnemonic} audit envelope is not a mask/match pattern"
                )
            envelope_mask = parse_int(envelope["mask"])
            envelope_match = parse_int(envelope["match"])
            if (
                not 0 <= envelope_mask <= 0xFFFF
                or not 0 <= envelope_match <= 0xFFFF
            ):
                raise IsaDatabaseError(f"{mnemonic} audit envelope is not 16 bits")
            if envelope_match & ~envelope_mask:
                raise IsaDatabaseError(
                    f"{mnemonic} audit envelope sets an unmasked bit"
                )
            if envelope_mask & ~mask:
                raise IsaDatabaseError(
                    f"{mnemonic} audit envelope is narrower than legal decode"
                )
            if match & envelope_mask != envelope_match:
                raise IsaDatabaseError(
                    f"{mnemonic} audit envelope excludes its legal match"
                )
        if entry["documented_cycle_count"] < 1:
            raise IsaDatabaseError(f"{mnemonic} has invalid cycle count")
        for citation in entry["source_citations"]:
            if citation.get("source_id") not in source_ids:
                raise IsaDatabaseError(f"{mnemonic} has unresolved source citation")

    for definition in definitions:
        if not isinstance(definition.get("meaning"), str):
            raise IsaDatabaseError("opcode-space classification meaning is missing")
        citations = definition.get("source_citations")
        if not isinstance(citations, list):
            raise IsaDatabaseError("opcode-space classification citations are missing")
        for citation in citations:
            if citation.get("source_id") not in source_ids:
                raise IsaDatabaseError(
                    f"{definition['name']} has unresolved source citation"
                )

    if entry_names != supported:
        raise IsaDatabaseError("entry order/content differs from supported mnemonics")
    if len(entry_names) != len(set(entry_names)):
        raise IsaDatabaseError("duplicate instruction entries")

    match_counts = {mnemonic: 0 for mnemonic in entry_names}
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
        for mnemonic in matches:
            match_counts[mnemonic] += 1
    for mnemonic, count in match_counts.items():
        if count == 0:
            raise IsaDatabaseError(f"{mnemonic} constraints reject every encoding")


def _validate_constraint(mnemonic: str, constraint: object) -> None:
    if not isinstance(constraint, dict):
        raise IsaDatabaseError(f"{mnemonic} opcode constraint is not a mapping")
    if set(constraint) not in ({"when", "require"}, {"when", "forbid"}):
        raise IsaDatabaseError(
            f"{mnemonic} constraint needs when and exactly one action"
        )
    for name in constraint:
        pattern = constraint[name]
        if not isinstance(pattern, dict) or set(pattern) != {"mask", "match"}:
            raise IsaDatabaseError(
                f"{mnemonic} constraint {name} is not a mask/match pattern"
            )
        mask = parse_int(pattern["mask"])
        match = parse_int(pattern["match"])
        if not 0 <= mask <= 0xFFFF or not 0 <= match <= 0xFFFF:
            raise IsaDatabaseError(f"{mnemonic} constraint is not 16 bits")
        if match & ~mask:
            raise IsaDatabaseError(
                f"{mnemonic} constraint {name} sets an unmasked bit"
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
