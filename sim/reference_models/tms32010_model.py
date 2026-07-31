"""Independent, partial architectural model of the original TMS32010.

This partial slice supports ADD, ADDS, AND, LAC, LACK, LAR, LARK, LARP, LDP,
LDPK, MAR, NOP, OR, ROVM, SACH, SACL, SAR, SOVM, SUB, SUBS, XOR, ZAC, ZALH,
and ZALS.
Logical program and internal-data transactions and instruction totals are
modeled; pin subphases are not yet integrated with this model.
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
        if mnemonic == "MAR" and operands["indirect"]:
            selected_arp = self.state.status.arp
        if mnemonic in {
            "ADD",
            "ADDS",
            "AND",
            "LAC",
            "LAR",
            "LDP",
            "OR",
            "SACL",
            "SACH",
            "SAR",
            "SUB",
            "SUBS",
            "XOR",
            "ZALH",
            "ZALS",
        }:
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
            if mnemonic in {
                "ADD",
                "ADDS",
                "AND",
                "LAC",
                "LAR",
                "LDP",
                "OR",
                "SUB",
                "SUBS",
                "XOR",
                "ZALH",
                "ZALS",
            }:
                transaction_data = self.data[data_address]
            elif mnemonic == "SACL":
                transaction_data = self.state.acc & WORD_MASK
            elif mnemonic == "SAR":
                register = operands["auxiliary_register"]
                transaction_data = self.state.ar[register]
                if operands["indirect"] and register == selected_arp:
                    control = operands["addressing_field"]
                    if control & 0x20:
                        transaction_data = self._modify_counter(
                            transaction_data,
                            1,
                        )
                    elif control & 0x10:
                        transaction_data = self._modify_counter(
                            transaction_data,
                            -1,
                        )
            else:
                shifted = (self.state.acc << operands["shift"]) & ACC_MASK
                transaction_data = shifted >> 16
            transactions.append(
                Transaction(
                    cycle=self.cycle_count,
                    space="data",
                    operation=(
                        "read"
                        if mnemonic
                        in {
                            "ADD",
                            "ADDS",
                            "AND",
                            "LAC",
                            "LAR",
                            "LDP",
                            "OR",
                            "SUB",
                            "SUBS",
                            "XOR",
                            "ZALH",
                            "ZALS",
                        }
                        else "write"
                    ),
                    address=data_address,
                    data=transaction_data,
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
        elif mnemonic == "LAR":
            register = operands["auxiliary_register"]
            self.state.ar[register] = self.data[operands["effective_address"]]
        elif mnemonic == "LDP":
            self.state.status.dp = (
                self.data[operands["effective_address"]] & 1
            )
        elif mnemonic == "SACL":
            self.data[operands["effective_address"]] = (
                self.state.acc & WORD_MASK
            )
        elif mnemonic == "SAR":
            register = operands["auxiliary_register"]
            store_value = self.state.ar[register]
            if operands["indirect"] and register == selected_arp:
                control = operands["addressing_field"]
                if control & 0x20:
                    store_value = self._modify_counter(store_value, 1)
                elif control & 0x10:
                    store_value = self._modify_counter(store_value, -1)
            self.data[operands["effective_address"]] = store_value
        elif mnemonic == "SACH":
            shifted = (self.state.acc << operands["shift"]) & ACC_MASK
            self.data[operands["effective_address"]] = shifted >> 16
        elif mnemonic == "ZALH":
            data_word = self.data[operands["effective_address"]]
            self.state.acc = data_word << 16
        elif mnemonic == "ZALS":
            self.state.acc = self.data[operands["effective_address"]]
        elif mnemonic == "ADDS":
            self._add_accumulator(self.data[operands["effective_address"]])
        elif mnemonic == "ADD":
            data_word = self.data[operands["effective_address"]]
            signed_word = (
                data_word if data_word < 0x8000 else data_word - 0x10000
            )
            self._add_accumulator(
                (signed_word << operands["shift"]) & ACC_MASK
            )
        elif mnemonic == "SUB":
            data_word = self.data[operands["effective_address"]]
            signed_word = (
                data_word if data_word < 0x8000 else data_word - 0x10000
            )
            self._subtract_accumulator(
                (signed_word << operands["shift"]) & ACC_MASK
            )
        elif mnemonic == "SUBS":
            self._subtract_accumulator(
                self.data[operands["effective_address"]]
            )
        elif mnemonic == "XOR":
            self.state.acc = (
                (self.state.acc & 0xFFFF_0000)
                | (
                    (self.state.acc & WORD_MASK)
                    ^ self.data[operands["effective_address"]]
                )
            )
        elif mnemonic == "AND":
            self.state.acc = (
                (self.state.acc & WORD_MASK)
                & self.data[operands["effective_address"]]
            )
        elif mnemonic == "OR":
            self.state.acc |= self.data[operands["effective_address"]]
        elif mnemonic == "LARK":
            register = operands["auxiliary_register"]
            self.state.ar[register] = operands["constant"] & 0xFF
        elif mnemonic == "LARP":
            self.state.status.arp = operands["constant"]
        elif mnemonic == "MAR":
            pass
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

        if (
            mnemonic
            in {
                "ADD",
                "ADDS",
                "AND",
                "LAC",
                "LAR",
                "LDP",
                "MAR",
                "OR",
                "SACL",
                "SACH",
                "SAR",
                "SUB",
                "SUBS",
                "XOR",
                "ZALH",
                "ZALS",
            }
            and operands["indirect"]
        ):
            assert selected_arp is not None
            control = operands["addressing_field"]
            suppress_counter_update = (
                mnemonic == "LAR"
                and operands["auxiliary_register"] == selected_arp
            )
            if not suppress_counter_update:
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

    def _add_accumulator(self, addend: int) -> None:
        """Apply sticky signed-overflow and OVM rules to a 32-bit addition."""
        old_acc = self.state.acc & ACC_MASK
        addend &= ACC_MASK
        wrapped = (old_acc + addend) & ACC_MASK
        overflow = (
            (~(old_acc ^ addend) & (old_acc ^ wrapped) & 0x8000_0000) != 0
        )
        if overflow:
            self.state.status.ov = True
            if self.state.status.ovm:
                self.state.acc = (
                    0x8000_0000 if old_acc & 0x8000_0000 else 0x7FFF_FFFF
                )
                return
        self.state.acc = wrapped

    def _subtract_accumulator(self, subtrahend: int) -> None:
        """Apply sticky signed-overflow and OVM rules to a 32-bit subtraction."""
        old_acc = self.state.acc & ACC_MASK
        subtrahend &= ACC_MASK
        wrapped = (old_acc - subtrahend) & ACC_MASK
        overflow = (
            ((old_acc ^ subtrahend) & (old_acc ^ wrapped) & 0x8000_0000)
            != 0
        )
        if overflow:
            self.state.status.ov = True
            if self.state.status.ovm:
                self.state.acc = (
                    0x8000_0000 if old_acc & 0x8000_0000 else 0x7FFF_FFFF
                )
                return
        self.state.acc = wrapped

    @staticmethod
    def _decode(opcode: int, pc: int) -> tuple[str, dict[str, int]]:
        """Independent hand-written decode for the qualified model slice."""
        if opcode & 0xF000 == 0x0000:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "ADD", {
                "shift": (opcode >> 8) & 0xF,
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xF000 == 0x1000:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SUB", {
                "shift": (opcode >> 8) & 0xF,
                "indirect": indirect,
                "addressing_field": control,
            }
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
        if opcode & 0xFE00 == 0x3000:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SAR", {
                "auxiliary_register": (opcode >> 8) & 1,
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFE00 == 0x3800:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LAR", {
                "auxiliary_register": (opcode >> 8) & 1,
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
        if opcode & 0xF800 == 0x5800:
            shift = (opcode >> 8) & 0x7
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if shift not in {0, 1, 4} or (
                indirect
                and ((control & 0x46) != 0 or (control & 0x30) == 0x30)
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SACH", {
                "shift": shift,
                "indirect": indirect,
                "addressing_field": control,
            }
        if (opcode & 0xFF00) in {0x6500, 0x6600}:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return ("ZALH" if (opcode & 0xFF00) == 0x6500 else "ZALS"), {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6100:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "ADDS", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6300:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SUBS", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if (opcode & 0xFF00) in {0x7800, 0x7900, 0x7A00}:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            mnemonic = {0x7800: "XOR", 0x7900: "AND", 0x7A00: "OR"}[
                opcode & 0xFF00
            ]
            return mnemonic, {
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
        if opcode & 0xFF00 == 0x6800:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "MAR", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6F00:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LDP", {
                "indirect": indirect,
                "addressing_field": control,
            }
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
