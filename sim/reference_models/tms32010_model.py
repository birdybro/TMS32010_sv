"""Independent, partial architectural model of the original TMS32010.

This partial slice supports LAC, LACK, LARK, LARP, LDPK, NOP, ROVM, SACL,
SOVM, and ZAC. Logical program and internal-data transactions and instruction
totals are modeled; pin subphases are not yet integrated with this model.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

WORD_MASK = 0xFFFF
ACC_MASK = 0xFFFF_FFFF
PC_MASK = 0x0FFF
PROGRAM_WORDS = 4096
DATA_WORDS = 144
IO_PORTS = 8


class UnsupportedOpcode(RuntimeError):
    """Raised when execution reaches an opcode outside the qualified slice."""

    def __init__(self, pc: int, opcode: int) -> None:
        super().__init__(f"unsupported opcode 0x{opcode:04x} at PC 0x{pc:03x}")
        self.pc = pc
        self.opcode = opcode


class UnsupportedDataAddress(RuntimeError):
    """Raised for original-part data addresses whose behavior is unresolved."""

    def __init__(self, pc: int, opcode: int, address: int) -> None:
        super().__init__(
            f"unresolved data address 0x{address:02x} "
            f"for opcode 0x{opcode:04x} at PC 0x{pc:03x}"
        )
        self.pc = pc
        self.opcode = opcode
        self.address = address


@dataclass
class Status:
    """Architectural status bits; zero defaults are deterministic test values."""

    ov: bool = False
    ovm: bool = False
    intm: bool = False
    arp: int = 0
    dp: int = 0


@dataclass
class State:
    """Programmer-visible state plus the internal pending-interrupt latch."""

    pc: int = 0
    acc: int = 0
    p: int = 0
    t: int = 0
    ar: list[int] = field(default_factory=lambda: [0, 0])
    stack: list[int] = field(default_factory=lambda: [0, 0, 0, 0])
    status: Status = field(default_factory=Status)
    interrupt_pending: bool = False


@dataclass(frozen=True)
class Transaction:
    """One logical architectural-space transaction."""

    cycle: int
    space: str
    operation: str
    address: int
    data: int


@dataclass(frozen=True)
class StepTrace:
    """Deterministic instruction-boundary trace record."""

    pc: int
    opcode: int
    mnemonic: str
    operands: dict[str, int]
    cycles: int
    transactions: tuple[Transaction, ...]
    state_after: dict[str, object]

    def to_json(self) -> str:
        """Serialize with stable keys and no host-dependent values."""
        return json.dumps(asdict(self), sort_keys=True, separators=(",", ":"))


class Tms32010Model:
    """Partial instruction-boundary model with separate memory and I/O spaces."""

    def __init__(self) -> None:
        self.state = State()
        self.program = [0] * PROGRAM_WORDS
        self.data = [0] * DATA_WORDS
        self.io_input = [0] * IO_PORTS
        self.io_output = [0] * IO_PORTS
        self.cycle_count = 0

    def reset_at_instruction_boundary(self) -> None:
        """Apply only documented reset effects at a model step boundary.

        Physical assertion duration, cycle completion, and first-fetch phase
        are deliberately outside this method's current qualification.
        """
        self.state.pc = 0
        self.state.status.intm = True
        self.state.interrupt_pending = False

    def load_words(self, words: Iterable[int], origin: int = 0) -> None:
        """Load 16-bit program words without assuming a file byte order."""
        if not 0 <= origin < PROGRAM_WORDS:
            raise ValueError(f"origin out of range: {origin}")
        for offset, word in enumerate(words):
            address = origin + offset
            if address >= PROGRAM_WORDS:
                raise ValueError("program image exceeds 4096-word space")
            if not 0 <= word <= WORD_MASK:
                raise ValueError(f"program word out of range at {address}: {word}")
            self.program[address] = word

    def load_binary(
        self,
        path: str | Path,
        *,
        byteorder: str = "big",
        origin: int = 0,
    ) -> None:
        """Load an even-length raw binary with explicit word byte order."""
        if byteorder not in {"big", "little"}:
            raise ValueError("byteorder must be 'big' or 'little'")
        content = Path(path).read_bytes()
        if len(content) % 2:
            raise ValueError("raw program image has an odd byte count")
        words = (
            int.from_bytes(content[index : index + 2], byteorder)
            for index in range(0, len(content), 2)
        )
        self.load_words(words, origin)

    def architectural_state(self) -> dict[str, object]:
        """Return a detached, JSON-safe snapshot."""
        return {
            "pc": self.state.pc,
            "acc": self.state.acc,
            "p": self.state.p,
            "t": self.state.t,
            "ar": list(self.state.ar),
            "stack": list(self.state.stack),
            "status": asdict(self.state.status),
            "interrupt_pending": self.state.interrupt_pending,
            "cycle_count": self.cycle_count,
        }

    def step(self) -> StepTrace:
        """Execute one supported opcode and return an instruction trace."""
        pc = self.state.pc & PC_MASK
        opcode = self.program[pc] & WORD_MASK
        transactions = [
            Transaction(
                cycle=self.cycle_count,
                space="program",
                operation="instruction_fetch",
                address=pc,
                data=opcode,
            )
        ]

        mnemonic, operands = self._decode(opcode, pc)
        operands = dict(operands)
        selected_arp: int | None = None
        if mnemonic in {"LAC", "SACL"}:
            if operands["indirect"]:
                selected_arp = self.state.status.arp
                data_address = self.state.ar[selected_arp] & 0xFF
            else:
                data_address = (
                    (self.state.status.dp << 7) | operands["addressing_field"]
                )
            if data_address >= DATA_WORDS:
                raise UnsupportedDataAddress(pc, opcode, data_address)
            operands["effective_address"] = data_address
            transactions.append(
                Transaction(
                    cycle=self.cycle_count,
                    space="data",
                    operation="read" if mnemonic == "LAC" else "write",
                    address=data_address,
                    data=(
                        self.data[data_address]
                        if mnemonic == "LAC"
                        else self.state.acc & WORD_MASK
                    ),
                )
            )

        self.state.pc = (pc + 1) & PC_MASK

        if mnemonic == "LACK":
            self.state.acc = operands["constant"] & 0xFF
        elif mnemonic == "LAC":
            data_word = self.data[operands["effective_address"]]
            signed_word = (
                data_word if data_word < 0x8000 else data_word - 0x10000
            )
            self.state.acc = (signed_word << operands["shift"]) & ACC_MASK
        elif mnemonic == "SACL":
            self.data[operands["effective_address"]] = (
                self.state.acc & WORD_MASK
            )
        elif mnemonic == "LARK":
            register = operands["auxiliary_register"]
            self.state.ar[register] = operands["constant"] & 0xFF
        elif mnemonic == "LARP":
            self.state.status.arp = operands["constant"]
        elif mnemonic == "LDPK":
            self.state.status.dp = operands["constant"]
        elif mnemonic == "ZAC":
            self.state.acc = 0
        elif mnemonic == "ROVM":
            self.state.status.ovm = False
        elif mnemonic == "SOVM":
            self.state.status.ovm = True
        elif mnemonic != "NOP":
            raise AssertionError(f"decoder returned unhandled mnemonic {mnemonic}")

        if mnemonic in {"LAC", "SACL"} and operands["indirect"]:
            assert selected_arp is not None
            control = operands["addressing_field"]
            if control & 0x20:
                self.state.ar[selected_arp] = self._modify_counter(
                    self.state.ar[selected_arp],
                    1,
                )
            elif control & 0x10:
                self.state.ar[selected_arp] = self._modify_counter(
                    self.state.ar[selected_arp],
                    -1,
                )
            if (control & 0x08) == 0:
                self.state.status.arp = control & 1

        cycles = 1
        self.cycle_count += cycles
        return StepTrace(
            pc=pc,
            opcode=opcode,
            mnemonic=mnemonic,
            operands=operands,
            cycles=cycles,
            transactions=tuple(transactions),
            state_after=self.architectural_state(),
        )

    @staticmethod
    def _modify_counter(value: int, delta: int) -> int:
        """Modify only AR[8:0], the documented circular counter field."""
        return (value & 0xFE00) | ((value + delta) & 0x01FF)

    @staticmethod
    def _decode(opcode: int, pc: int) -> tuple[str, dict[str, int]]:
        """Independent hand-written decode for the qualified model slice."""
        if opcode & 0xF000 == 0x2000:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LAC", {
                "shift": (opcode >> 8) & 0xF,
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x7E00:
            return "LACK", {"constant": opcode & 0xFF}
        if opcode & 0xFF00 == 0x5000:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SACL", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFE00 == 0x7000:
            return "LARK", {
                "auxiliary_register": (opcode >> 8) & 1,
                "constant": opcode & 0xFF,
            }
        if opcode & 0xFFFE == 0x6880:
            return "LARP", {"constant": opcode & 1}
        if opcode & 0xFFFE == 0x6E00:
            return "LDPK", {"constant": opcode & 1}
        fixed = {
            0x7F80: "NOP",
            0x7F89: "ZAC",
            0x7F8A: "ROVM",
            0x7F8B: "SOVM",
        }
        mnemonic = fixed.get(opcode)
        if mnemonic is None:
            raise UnsupportedOpcode(pc, opcode)
        return mnemonic, {}
