"""Database-driven, lossless disassembler for the qualified ISA slice."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable

from tools.generators.isa_database import decode_word, load_database


class Disassembler:
    def __init__(self) -> None:
        self.database = load_database()

    def disassemble_word(self, word: int) -> str:
        if not 0 <= word <= 0xFFFF:
            raise ValueError(f"instruction word out of range: {word}")
        decoded = decode_word(self.database, word)
        if decoded is None:
            return f".word 0x{word:04x}"
        entry, operands = decoded
        mnemonic = entry["mnemonic"]
        if mnemonic == "LACK":
            return f"LACK {operands['constant']}"
        if mnemonic == "LAC":
            shift = operands["shift"]
            if not operands["indirect"]:
                suffix = f",{shift}" if shift else ""
                return f"LAC {operands['addressing_field']}{suffix}"
            control = operands["addressing_field"]
            modifier = {0x00: "*", 0x20: "*+", 0x10: "*-"}[control & 0x30]
            if control & 0x08:
                if control & 1:
                    return f".word 0x{word:04x}"
                suffix = f",{shift}" if shift else ""
                return f"LAC {modifier}{suffix}"
            return f"LAC {modifier},{shift},{control & 1}"
        if mnemonic == "LARK":
            return (
                f"LARK AR{operands['auxiliary_register']},"
                f"{operands['constant']}"
            )
        if mnemonic in {"LARP", "LDPK"}:
            return f"{mnemonic} {operands['constant']}"
        return mnemonic

    def disassemble_source(self, words: Iterable[int]) -> str:
        return "".join(f"{self.disassemble_word(word)}\n" for word in words)

    def disassemble_listing(self, words: Iterable[int], origin: int = 0) -> str:
        if not 0 <= origin <= 0xFFF:
            raise ValueError(f"origin out of range: {origin}")
        rows = []
        for offset, word in enumerate(words):
            address = origin + offset
            if address > 0xFFF:
                raise ValueError("image exceeds 4096-word program space")
            rows.append(
                f"{address:03x} {word:04x}  {self.disassemble_word(word)}\n"
            )
        return "".join(rows)


def _load_binary(path: Path, byteorder: str) -> list[int]:
    content = path.read_bytes()
    if len(content) % 2:
        raise ValueError("raw program image has an odd byte count")
    return [
        int.from_bytes(content[index : index + 2], byteorder)
        for index in range(0, len(content), 2)
    ]


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("--byteorder", choices=("big", "little"), default="big")
    parser.add_argument("--origin", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--source", action="store_true")
    arguments = parser.parse_args(argv)
    try:
        words = _load_binary(arguments.binary, arguments.byteorder)
        disassembler = Disassembler()
        if arguments.source:
            print(disassembler.disassemble_source(words), end="")
        else:
            print(
                disassembler.disassemble_listing(words, arguments.origin),
                end="",
            )
    except (OSError, ValueError) as error:
        parser.exit(1, f"error: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
