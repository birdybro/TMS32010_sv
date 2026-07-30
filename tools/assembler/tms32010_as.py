"""Deterministic two-pass assembler for the currently qualified ISA slice."""

from __future__ import annotations

import argparse
import ast
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from tools.generators.isa_database import load_database, parse_int

PROGRAM_WORDS = 4096
LABEL_PATTERN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
TI_HEX_PATTERN = re.compile(r"(?<![A-Za-z0-9_])>([0-9A-Fa-f]+)")


class AssemblyError(ValueError):
    """Source-located deterministic assembler diagnostic."""


@dataclass(frozen=True)
class SourceLine:
    path: str
    number: int
    text: str

    def error(self, message: str) -> AssemblyError:
        return AssemblyError(f"{self.path}:{self.number}: {message}")


@dataclass(frozen=True)
class ListingRow:
    address: int
    word: int
    source: SourceLine


@dataclass
class AssemblyResult:
    words: dict[int, int]
    listing: list[ListingRow]
    symbols: dict[str, int]

    def address_range(self) -> range:
        if not self.words:
            return range(0)
        return range(0, max(self.words) + 1)

    def raw_bytes(self, *, byteorder: str = "big", fill: int = 0) -> bytes:
        if byteorder not in {"big", "little"}:
            raise ValueError("byteorder must be 'big' or 'little'")
        if not 0 <= fill <= 0xFFFF:
            raise ValueError("fill must be a 16-bit word")
        return b"".join(
            self.words.get(address, fill).to_bytes(2, byteorder)
            for address in self.address_range()
        )

    def hex_text(self, *, fill: int = 0) -> str:
        return "".join(
            f"{self.words.get(address, fill):04x}\n"
            for address in self.address_range()
        )

    def listing_text(self) -> str:
        return "".join(
            f"{row.address:03x} {row.word:04x} "
            f"{row.source.path}:{row.source.number} {row.source.text.rstrip()}\n"
            for row in self.listing
        )


class Assembler:
    """Assembler front end driven by qualified canonical encodings."""

    def __init__(self) -> None:
        database = load_database()
        self.documented = set(database["coverage"]["documented_mnemonics"])
        self.entries = {
            entry["mnemonic"]: entry for entry in database["instructions"]
        }

    def assemble_text(
        self,
        text: str,
        *,
        source_name: str = "<memory>",
        include_root: Path | None = None,
    ) -> AssemblyResult:
        root = (include_root or Path.cwd()).resolve()
        lines = self._expand_text(text, source_name, root, ())
        return self._assemble(lines)

    def assemble_file(self, path: str | Path) -> AssemblyResult:
        source = Path(path).resolve()
        lines = self._expand_file(source, ())
        return self._assemble(lines)

    def _expand_file(
        self,
        path: Path,
        stack: tuple[Path, ...],
    ) -> list[SourceLine]:
        if path in stack:
            chain = " -> ".join(str(item) for item in (*stack, path))
            raise AssemblyError(f"recursive include: {chain}")
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as error:
            raise AssemblyError(f"cannot read {path}: {error}") from error
        return self._expand_text(text, str(path), path.parent, (*stack, path))

    def _expand_text(
        self,
        text: str,
        source_name: str,
        include_root: Path,
        stack: tuple[Path, ...],
    ) -> list[SourceLine]:
        expanded: list[SourceLine] = []
        for number, text_line in enumerate(text.splitlines(), 1):
            line = SourceLine(source_name, number, text_line)
            statement = self._statement(text_line)
            include = re.fullmatch(
                r'\.include\s+"([^"]+)"',
                statement,
                flags=re.IGNORECASE,
            )
            if include:
                expanded.extend(
                    self._expand_file(
                        (include_root / include.group(1)).resolve(),
                        stack,
                    )
                )
            else:
                expanded.append(line)
        return expanded

    def _assemble(self, lines: list[SourceLine]) -> AssemblyResult:
        symbols: dict[str, int] = {}
        location = 0
        for line in lines:
            statement, label = self._split_label(line)
            if label is not None:
                if label in symbols:
                    raise line.error(f"duplicate label {label}")
                symbols[label] = location
            if not statement:
                continue
            operation, operand_text = self._split_operation(statement)
            if operation == ".ORG":
                location = self._checked_address(
                    self._evaluate(operand_text, symbols, location, line),
                    line,
                )
            elif operation == ".WORD":
                location = self._checked_location(
                    location + len(self._operand_list(operand_text, line)),
                    line,
                )
            else:
                self._validate_instruction_shape(operation, operand_text, line)
                location = self._checked_location(location + 1, line)

        words: dict[int, int] = {}
        listing: list[ListingRow] = []
        location = 0
        for line in lines:
            statement, _ = self._split_label(line)
            if not statement:
                continue
            operation, operand_text = self._split_operation(statement)
            if operation == ".ORG":
                location = self._checked_address(
                    self._evaluate(operand_text, symbols, location, line),
                    line,
                )
                continue
            if operation == ".WORD":
                values = [
                    self._evaluate(expression, symbols, location + offset, line)
                    for offset, expression in enumerate(
                        self._operand_list(operand_text, line)
                    )
                ]
                for value in values:
                    if not 0 <= value <= 0xFFFF:
                        raise line.error(f".word value out of range: {value}")
                    self._emit(words, listing, location, value, line)
                    location += 1
                continue

            word = self._encode(operation, operand_text, symbols, location, line)
            self._emit(words, listing, location, word, line)
            location += 1
        return AssemblyResult(words=words, listing=listing, symbols=symbols)

    def _validate_instruction_shape(
        self,
        operation: str,
        operand_text: str,
        line: SourceLine,
    ) -> None:
        entry = self.entries.get(operation)
        if entry is None:
            if operation in self.documented:
                raise line.error(
                    f"documented instruction {operation} is not implemented"
                )
            if operation.startswith("."):
                raise line.error(f"unknown directive {operation}")
            raise line.error(f"unknown instruction {operation}")
        expects_operand = bool(entry["operands"])
        if expects_operand != bool(operand_text):
            expectation = "one operand" if expects_operand else "no operands"
            raise line.error(f"{operation} expects {expectation}")
        if operand_text and len(self._operand_list(operand_text, line)) != 1:
            raise line.error(f"{operation} expects one operand")

    def _encode(
        self,
        operation: str,
        operand_text: str,
        symbols: dict[str, int],
        location: int,
        line: SourceLine,
    ) -> int:
        self._validate_instruction_shape(operation, operand_text, line)
        entry = self.entries[operation]
        word = parse_int(entry["opcode"]["match"])
        if operation == "LACK":
            value = self._evaluate(operand_text, symbols, location, line)
            if not 0 <= value <= 0xFF:
                raise line.error(f"LACK constant out of range 0..255: {value}")
            word |= value
        return word

    @staticmethod
    def _statement(text: str) -> str:
        return text.split(";", 1)[0].strip()

    def _split_label(self, line: SourceLine) -> tuple[str, str | None]:
        statement = self._statement(line.text)
        match = LABEL_PATTERN.match(statement)
        if not match:
            return statement, None
        label = match.group(1).upper()
        return statement[match.end() :].strip(), label

    @staticmethod
    def _split_operation(statement: str) -> tuple[str, str]:
        fields = statement.split(None, 1)
        operation = fields[0].upper()
        operands = fields[1].strip() if len(fields) == 2 else ""
        return operation, operands

    @staticmethod
    def _operand_list(text: str, line: SourceLine) -> list[str]:
        operands = [item.strip() for item in text.split(",")]
        if not text or any(not item for item in operands):
            raise line.error("missing operand")
        return operands

    @staticmethod
    def _checked_address(value: int, line: SourceLine) -> int:
        if not 0 <= value < PROGRAM_WORDS:
            raise line.error(f"program address out of range: {value}")
        return value

    @staticmethod
    def _checked_location(value: int, line: SourceLine) -> int:
        if not 0 <= value <= PROGRAM_WORDS:
            raise line.error("program exceeds 4096-word address space")
        return value

    @staticmethod
    def _emit(
        words: dict[int, int],
        listing: list[ListingRow],
        address: int,
        word: int,
        line: SourceLine,
    ) -> None:
        if not 0 <= address < PROGRAM_WORDS:
            raise line.error(f"program address out of range: {address}")
        if address in words:
            raise line.error(f"address 0x{address:03x} already contains a word")
        words[address] = word
        listing.append(ListingRow(address, word, line))

    @staticmethod
    def _evaluate(
        expression: str,
        symbols: dict[str, int],
        location: int,
        line: SourceLine,
    ) -> int:
        normalized = TI_HEX_PATTERN.sub(r"0x\1", expression)
        normalized = normalized.replace("$", "__CURRENT")
        names = {name.upper(): value for name, value in symbols.items()}
        names["__CURRENT"] = location
        try:
            tree = ast.parse(normalized, mode="eval")
            return _ExpressionEvaluator(names).visit(tree)
        except (SyntaxError, ValueError, ZeroDivisionError) as error:
            raise line.error(f"invalid expression {expression!r}: {error}") from error


class _ExpressionEvaluator(ast.NodeVisitor):
    BINARY = {
        ast.Add: lambda left, right: left + right,
        ast.Sub: lambda left, right: left - right,
        ast.Mult: lambda left, right: left * right,
        ast.FloorDiv: lambda left, right: left // right,
        ast.Mod: lambda left, right: left % right,
        ast.LShift: lambda left, right: left << right,
        ast.RShift: lambda left, right: left >> right,
        ast.BitOr: lambda left, right: left | right,
        ast.BitAnd: lambda left, right: left & right,
        ast.BitXor: lambda left, right: left ^ right,
    }
    UNARY = {
        ast.UAdd: lambda value: value,
        ast.USub: lambda value: -value,
        ast.Invert: lambda value: ~value,
    }

    def __init__(self, names: dict[str, int]) -> None:
        self.names = names

    def visit_Expression(self, node: ast.Expression) -> int:
        return self.visit(node.body)

    def visit_Constant(self, node: ast.Constant) -> int:
        if type(node.value) is not int:
            raise ValueError("only integer constants are allowed")
        return node.value

    def visit_Name(self, node: ast.Name) -> int:
        try:
            return self.names[node.id.upper()]
        except KeyError as error:
            raise ValueError(f"undefined symbol {node.id}") from error

    def visit_BinOp(self, node: ast.BinOp) -> int:
        function = self.BINARY.get(type(node.op))
        if function is None:
            raise ValueError(f"operator {type(node.op).__name__} is not allowed")
        return function(self.visit(node.left), self.visit(node.right))

    def visit_UnaryOp(self, node: ast.UnaryOp) -> int:
        function = self.UNARY.get(type(node.op))
        if function is None:
            raise ValueError(f"operator {type(node.op).__name__} is not allowed")
        return function(self.visit(node.operand))

    def generic_visit(self, node: ast.AST) -> int:
        raise ValueError(f"expression element {type(node).__name__} is not allowed")


def _write_outputs(arguments: argparse.Namespace, result: AssemblyResult) -> None:
    if arguments.binary:
        arguments.binary.write_bytes(
            result.raw_bytes(byteorder=arguments.byteorder)
        )
    if arguments.hex:
        arguments.hex.write_text(result.hex_text(), encoding="ascii")
    if arguments.listing:
        arguments.listing.write_text(result.listing_text(), encoding="utf-8")


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--hex", type=Path)
    parser.add_argument("--listing", type=Path)
    parser.add_argument("--byteorder", choices=("big", "little"), default="big")
    arguments = parser.parse_args(argv)
    if not (arguments.binary or arguments.hex or arguments.listing):
        parser.error("at least one output option is required")
    try:
        result = Assembler().assemble_file(arguments.source)
        _write_outputs(arguments, result)
    except (AssemblyError, OSError) as error:
        parser.exit(1, f"error: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
