"""Independent, partial architectural model of the original TMS32010.

This partial slice supports ADD, ADDS, AND, APAC, B, BANZ, BGEZ, BGZ, BIOZ,
BLEZ, BLZ, BNZ, BV, BZ, CALL, DINT, DMOV, EINT, IN, LAC, LACK, LAR, LARK,
LARP, LDP, LDPK, LST, LT, LTA, LTD, MAR, MPY, MPYK, NOP, OR, OUT, PAC,
RET, ROVM, SACH, SACL, SAR, SOVM, SPAC, SUB, SUBC, SUBS, TBLR, TBLW, XOR,
ZAC, ZALH, and ZALS. Logical program, internal-data, and I/O transactions and
instruction totals are modeled; pin subphases are not integrated with this
model. RET's primary-defined state transition and cycle total are modeled,
but its unresolved second external cycle is deliberately absent from the
logical transaction trace under OQ-007.
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
ACCUMULATOR_BRANCHES = frozenset({"BGEZ", "BGZ", "BLEZ", "BLZ", "BNZ", "BZ"})
TWO_WORD_CONTROL_FLOW = ACCUMULATOR_BRANCHES | {
    "B",
    "BANZ",
    "BIOZ",
    "BV",
    "CALL",
}


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


class UnsupportedProgramOperand(RuntimeError):
    """Raised when a multiword instruction has an unqualified operand word."""

    def __init__(self, pc: int, opcode: int, address: int, word: int) -> None:
        super().__init__(
            f"unsupported program operand 0x{word:04x} at 0x{address:03x} "
            f"for opcode 0x{opcode:04x} at PC 0x{pc:03x}"
        )
        self.pc = pc
        self.opcode = opcode
        self.address = address
        self.word = word


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
        self.bio_input_high = True
        self.interrupt_input_high = True
        self._interrupt_delay_one = False
        self._interrupt_entry_pending = False
        self.cycle_count = 0

    def reset_at_instruction_boundary(self) -> None:
        """Apply only documented reset effects at a model step boundary.

        Physical assertion duration, cycle completion, and first-fetch phase
        are deliberately outside this method's current qualification.
        """
        self.state.pc = 0
        self.state.status.intm = True
        self.state.interrupt_pending = False
        self._interrupt_delay_one = False
        self._interrupt_entry_pending = False

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
            "interrupt_delay_one": self._interrupt_delay_one,
            "interrupt_entry_pending": self._interrupt_entry_pending,
            "cycle_count": self.cycle_count,
        }

    def step(self) -> StepTrace:
        """Execute one supported opcode or one interrupt-entry dummy cycle."""
        pc = self.state.pc & PC_MASK
        opcode = self.program[pc] & WORD_MASK
        if self._interrupt_entry_pending:
            transactions = (
                Transaction(
                    cycle=self.cycle_count,
                    space="program",
                    operation="interrupt_dummy_fetch",
                    address=pc,
                    data=opcode,
                ),
            )
            self.state.stack = [
                pc,
                self.state.stack[0],
                self.state.stack[1],
                self.state.stack[2],
            ]
            self.state.pc = 0x002
            self.state.status.intm = True
            self.state.interrupt_pending = False
            self._interrupt_delay_one = False
            self._interrupt_entry_pending = False
            self.cycle_count += 1
            return StepTrace(
                pc=pc,
                opcode=opcode,
                mnemonic="INTERRUPT",
                operands={"return_address": pc, "vector": 0x002},
                cycles=1,
                transactions=transactions,
                state_after=self.architectural_state(),
            )

        if not self.interrupt_input_high:
            self.state.interrupt_pending = True
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
        if mnemonic == "RET":
            return_address = self.state.stack[0] & PC_MASK
            old_bottom = self.state.stack[3] & PC_MASK
            self.state.stack = [
                self.state.stack[1] & PC_MASK,
                self.state.stack[2] & PC_MASK,
                old_bottom,
                old_bottom,
            ]
            self.state.pc = return_address
            cycles = 2
            self.cycle_count += cycles
            self._advance_interrupt_pipeline(mnemonic)
            return StepTrace(
                pc=pc,
                opcode=opcode,
                mnemonic=mnemonic,
                operands=operands,
                cycles=cycles,
                transactions=tuple(transactions),
                state_after=self.architectural_state(),
            )
        if mnemonic in TWO_WORD_CONTROL_FLOW:
            operand_address = (pc + 1) & PC_MASK
            operand_word = self.program[operand_address] & WORD_MASK
            if operand_word & 0xF000:
                raise UnsupportedProgramOperand(
                    pc,
                    opcode,
                    operand_address,
                    operand_word,
                )
            target = operand_word & PC_MASK
            operands["program_address"] = target
            transactions.append(
                Transaction(
                    cycle=self.cycle_count + 1,
                    space="program",
                    operation="following_word_fetch",
                    address=operand_address,
                    data=operand_word,
                )
            )
            if mnemonic == "BANZ":
                selected_arp = self.state.status.arp
                branch_taken = bool(self.state.ar[selected_arp] & 0x01FF)
                operands.update(
                    {
                        "auxiliary_register": selected_arp,
                        "branch_taken": int(branch_taken),
                    }
                )
                self.state.ar[selected_arp] = self._modify_counter(
                    self.state.ar[selected_arp],
                    -1,
                )
                self.state.pc = (
                    target if branch_taken else (pc + 2) & PC_MASK
                )
            elif mnemonic == "B":
                self.state.pc = target
            elif mnemonic == "BV":
                branch_taken = self.state.status.ov
                operands["branch_taken"] = int(branch_taken)
                self.state.pc = (
                    target if branch_taken else (pc + 2) & PC_MASK
                )
                if branch_taken:
                    self.state.status.ov = False
            elif mnemonic == "BIOZ":
                branch_taken = not self.bio_input_high
                operands["branch_taken"] = int(branch_taken)
                self.state.pc = (
                    target if branch_taken else (pc + 2) & PC_MASK
                )
            elif mnemonic == "CALL":
                return_address = (pc + 2) & PC_MASK
                self.state.stack = [
                    return_address,
                    self.state.stack[0],
                    self.state.stack[1],
                    self.state.stack[2],
                ]
                self.state.pc = target
            else:
                branch_taken = self._accumulator_branch_taken(
                    mnemonic,
                    self.state.acc,
                )
                operands["branch_taken"] = int(branch_taken)
                self.state.pc = (
                    target if branch_taken else (pc + 2) & PC_MASK
                )
            cycles = 2
            self.cycle_count += cycles
            self._advance_interrupt_pipeline(mnemonic)
            return StepTrace(
                pc=pc,
                opcode=opcode,
                mnemonic=mnemonic,
                operands=operands,
                cycles=cycles,
                transactions=tuple(transactions),
                state_after=self.architectural_state(),
            )

        selected_arp: int | None = None
        if mnemonic == "MAR" and operands["indirect"]:
            selected_arp = self.state.status.arp
        if mnemonic in {
            "ADD",
            "ADDS",
            "AND",
            "DMOV",
            "IN",
            "LAC",
            "LAR",
            "LDP",
            "LST",
            "LT",
            "LTA",
            "LTD",
            "MPY",
            "OR",
            "OUT",
            "SACL",
            "SACH",
            "SAR",
            "SUB",
            "SUBC",
            "SUBS",
            "TBLR",
            "TBLW",
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
            if mnemonic in {"DMOV", "LTD"} and data_address + 1 >= DATA_WORDS:
                raise UnsupportedDataAddress(
                    pc,
                    opcode,
                    data_address + 1,
                )
            operands["effective_address"] = data_address
            if mnemonic in {"DMOV", "LTD"}:
                operands["move_address"] = data_address + 1
            if mnemonic in {"TBLR", "TBLW"}:
                operands["program_address"] = self.state.acc & PC_MASK
            if mnemonic == "IN":
                transaction_data = self.io_input[operands["port"]] & WORD_MASK
            elif mnemonic == "TBLR":
                transaction_data = self.program[operands["program_address"]]
            elif mnemonic in {
                "ADD",
                "ADDS",
                "AND",
                "DMOV",
                "LAC",
                "LAR",
                "LDP",
                "LST",
                "LT",
                "LTA",
                "LTD",
                "MPY",
                "OR",
                "OUT",
                "SUB",
                "SUBC",
                "SUBS",
                "TBLW",
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
            if mnemonic == "IN":
                transactions.extend(
                    (
                        Transaction(
                            cycle=self.cycle_count + 1,
                            space="io",
                            operation="read",
                            address=operands["port"],
                            data=transaction_data,
                        ),
                        Transaction(
                            cycle=self.cycle_count + 1,
                            space="data",
                            operation="write",
                            address=data_address,
                            data=transaction_data,
                        ),
                    )
                )
            elif mnemonic == "OUT":
                transactions.extend(
                    (
                        Transaction(
                            cycle=self.cycle_count + 1,
                            space="data",
                            operation="read",
                            address=data_address,
                            data=transaction_data,
                        ),
                        Transaction(
                            cycle=self.cycle_count + 1,
                            space="io",
                            operation="write",
                            address=operands["port"],
                            data=transaction_data,
                        ),
                    )
                )
            elif mnemonic in {"TBLR", "TBLW"}:
                following_address = (pc + 1) & PC_MASK
                transactions.append(
                    Transaction(
                        cycle=self.cycle_count + 1,
                        space="program",
                        operation="discarded_prefetch",
                        address=following_address,
                        data=self.program[following_address] & WORD_MASK,
                    )
                )
                if mnemonic == "TBLR":
                    transactions.extend(
                        (
                            Transaction(
                                cycle=self.cycle_count + 2,
                                space="program",
                                operation="table_read",
                                address=operands["program_address"],
                                data=transaction_data,
                            ),
                            Transaction(
                                cycle=self.cycle_count + 2,
                                space="data",
                                operation="write",
                                address=data_address,
                                data=transaction_data,
                            ),
                        )
                    )
                else:
                    transactions.extend(
                        (
                            Transaction(
                                cycle=self.cycle_count + 2,
                                space="data",
                                operation="read",
                                address=data_address,
                                data=transaction_data,
                            ),
                            Transaction(
                                cycle=self.cycle_count + 2,
                                space="program",
                                operation="table_write",
                                address=operands["program_address"],
                                data=transaction_data,
                            ),
                        )
                    )
            else:
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
                                "LST",
                                "LT",
                                "LTA",
                                "DMOV",
                                "LTD",
                                "MPY",
                                "OR",
                                "SUB",
                                "SUBC",
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
            if mnemonic in {"DMOV", "LTD"}:
                transactions.append(
                    Transaction(
                        cycle=self.cycle_count,
                        space="data",
                        operation="write",
                        address=data_address + 1,
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
        elif mnemonic == "LST":
            status_word = self.data[operands["effective_address"]]
            self.state.status.ov = bool(status_word & 0x8000)
            self.state.status.ovm = bool(status_word & 0x4000)
            self.state.status.arp = (status_word >> 8) & 1
            self.state.status.dp = status_word & 1
        elif mnemonic == "LT":
            self.state.t = self.data[operands["effective_address"]]
        elif mnemonic == "LTA":
            self.state.t = self.data[operands["effective_address"]]
            self._add_accumulator(self.state.p)
        elif mnemonic == "LTD":
            data_word = self.data[operands["effective_address"]]
            self.state.t = data_word
            self.data[operands["move_address"]] = data_word
            self._add_accumulator(self.state.p)
        elif mnemonic == "DMOV":
            data_word = self.data[operands["effective_address"]]
            self.data[operands["move_address"]] = data_word
        elif mnemonic == "IN":
            self.data[operands["effective_address"]] = (
                self.io_input[operands["port"]] & WORD_MASK
            )
        elif mnemonic == "OUT":
            self.io_output[operands["port"]] = (
                self.data[operands["effective_address"]] & WORD_MASK
            )
        elif mnemonic == "TBLR":
            self.data[operands["effective_address"]] = (
                self.program[operands["program_address"]] & WORD_MASK
            )
            self.state.stack[3] = self.state.stack[2]
        elif mnemonic == "TBLW":
            self.program[operands["program_address"]] = (
                self.data[operands["effective_address"]] & WORD_MASK
            )
            self.state.stack[3] = self.state.stack[2]
        elif mnemonic == "MPY":
            data_word = self.data[operands["effective_address"]]
            if self.state.t == 0x8000 and data_word == 0x8000:
                self.state.p = 0xC000_0000
            else:
                signed_t = (
                    self.state.t
                    if self.state.t < 0x8000
                    else self.state.t - 0x10000
                )
                signed_data = (
                    data_word if data_word < 0x8000 else data_word - 0x10000
                )
                self.state.p = (signed_t * signed_data) & ACC_MASK
        elif mnemonic == "MPYK":
            signed_t = (
                self.state.t
                if self.state.t < 0x8000
                else self.state.t - 0x10000
            )
            self.state.p = (signed_t * operands["constant"]) & ACC_MASK
        elif mnemonic == "PAC":
            self.state.acc = self.state.p
        elif mnemonic == "APAC":
            self._add_accumulator(self.state.p)
        elif mnemonic == "SPAC":
            self._subtract_accumulator(self.state.p)
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
        elif mnemonic == "SUBC":
            self._conditional_subtract(
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
        elif mnemonic == "DINT":
            self.state.status.intm = True
        elif mnemonic == "EINT":
            self.state.status.intm = False
        elif mnemonic != "NOP":
            raise AssertionError(f"decoder returned unhandled mnemonic {mnemonic}")

        if (
            mnemonic
            in {
                "ADD",
                "ADDS",
                "AND",
                "DMOV",
                "IN",
                "LAC",
                "LAR",
                "LDP",
                "LST",
                "LT",
                "LTA",
                "LTD",
                "MAR",
                "MPY",
                "OR",
                "OUT",
                "SACL",
                "SACH",
                "SAR",
                "SUB",
                "SUBC",
                "SUBS",
                "TBLR",
                "TBLW",
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
            if (control & 0x08) == 0 and mnemonic != "LST":
                self.state.status.arp = control & 1

        if mnemonic in {"TBLR", "TBLW"}:
            cycles = 3
        elif mnemonic in {"IN", "OUT"}:
            cycles = 2
        else:
            cycles = 1
        self.cycle_count += cycles
        self._advance_interrupt_pipeline(mnemonic)
        return StepTrace(
            pc=pc,
            opcode=opcode,
            mnemonic=mnemonic,
            operands=operands,
            cycles=cycles,
            transactions=tuple(transactions),
            state_after=self.architectural_state(),
        )

    def _advance_interrupt_pipeline(self, retired_mnemonic: str) -> None:
        """Advance the primary-defined instruction/entry deferral sequence."""
        if self._interrupt_delay_one:
            if self.state.status.intm:
                # DINT in the protected instruction slot cancels entry while
                # preserving the internally latched request.
                self._interrupt_delay_one = False
            elif retired_mnemonic in {"MPY", "MPYK"}:
                # TI protects the instruction following a multiply. EINT's
                # distinct protection applies only when it enables a
                # previously masked pending request, which is scheduled by
                # the non-delayed path below.
                self._interrupt_delay_one = True
            else:
                self._interrupt_delay_one = False
                self._interrupt_entry_pending = True
        elif (
            self.state.interrupt_pending
            and not self.state.status.intm
        ):
            # Figure 2-12 executes one already-pipelined instruction before
            # the dummy return-address fetch acknowledges the interrupt.
            self._interrupt_delay_one = True

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

    def _conditional_subtract(self, data_word: int) -> None:
        """Apply the documented divide step and provisional OV stage."""
        old_acc = self.state.acc & ACC_MASK
        operand = ((data_word & WORD_MASK) << 15) & ACC_MASK
        intermediate = (old_acc - operand) & ACC_MASK
        overflow = (
            ((old_acc ^ operand) & (old_acc ^ intermediate) & 0x8000_0000)
            != 0
        )
        if overflow:
            self.state.status.ov = True
        if intermediate & 0x8000_0000:
            self.state.acc = (old_acc << 1) & ACC_MASK
        else:
            self.state.acc = ((intermediate << 1) | 1) & ACC_MASK

    @staticmethod
    def _accumulator_branch_taken(mnemonic: str, accumulator: int) -> bool:
        """Test one primary-defined signed/zero accumulator branch."""
        value = accumulator & ACC_MASK
        negative = bool(value & 0x8000_0000)
        zero = value == 0
        if mnemonic == "BGEZ":
            return not negative
        if mnemonic == "BGZ":
            return not negative and not zero
        if mnemonic == "BLEZ":
            return negative or zero
        if mnemonic == "BLZ":
            return negative
        if mnemonic == "BNZ":
            return not zero
        if mnemonic == "BZ":
            return zero
        raise ValueError(f"not an accumulator branch: {mnemonic}")

    @staticmethod
    def _decode(opcode: int, pc: int) -> tuple[str, dict[str, int]]:
        """Independent hand-written decode for the qualified model slice."""
        accumulator_branches = {
            0xFA00: "BLZ",
            0xFB00: "BLEZ",
            0xFC00: "BGZ",
            0xFD00: "BGEZ",
            0xFE00: "BNZ",
            0xFF00: "BZ",
        }
        if opcode in accumulator_branches:
            return accumulator_branches[opcode], {}
        if opcode == 0xF900:
            return "B", {}
        if opcode == 0xF400:
            return "BANZ", {}
        if opcode == 0xF500:
            return "BV", {}
        if opcode == 0xF600:
            return "BIOZ", {}
        if opcode == 0xF800:
            return "CALL", {}
        if (opcode & 0xF800) in {0x4000, 0x4800}:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return ("IN" if (opcode & 0xF800) == 0x4000 else "OUT"), {
                "port": (opcode >> 8) & 0x7,
                "indirect": indirect,
                "addressing_field": control,
            }
        if (opcode & 0xFF00) in {0x6700, 0x7D00}:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return ("TBLR" if (opcode & 0xFF00) == 0x6700 else "TBLW"), {
                "indirect": indirect,
                "addressing_field": control,
            }
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
        if opcode & 0xFF00 == 0x6400:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "SUBC", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if (opcode & 0xFF00) in {0x7800, 0x7900, 0x7A00, 0x7B00}:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            mnemonic = {
                0x7800: "XOR",
                0x7900: "AND",
                0x7A00: "OR",
                0x7B00: "LST",
            }[opcode & 0xFF00]
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
        if opcode & 0xFF00 == 0x6A00:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LT", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6900:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "DMOV", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6C00:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LTA", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6B00:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "LTD", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xFF00 == 0x6D00:
            indirect = (opcode >> 7) & 1
            control = opcode & 0x7F
            if indirect and (
                (control & 0x46) != 0 or (control & 0x30) == 0x30
            ):
                raise UnsupportedOpcode(pc, opcode)
            return "MPY", {
                "indirect": indirect,
                "addressing_field": control,
            }
        if opcode & 0xE000 == 0x8000:
            constant = opcode & 0x1FFF
            if constant & 0x1000:
                constant -= 0x2000
            return "MPYK", {"constant": constant}
        if opcode & 0xFFFE == 0x6E00:
            return "LDPK", {"constant": opcode & 1}
        fixed = {
            0x7F80: "NOP",
            0x7F81: "DINT",
            0x7F82: "EINT",
            0x7F89: "ZAC",
            0x7F8A: "ROVM",
            0x7F8B: "SOVM",
            0x7F8D: "RET",
            0x7F8E: "PAC",
            0x7F8F: "APAC",
            0x7F90: "SPAC",
        }
        mnemonic = fixed.get(opcode)
        if mnemonic is None:
            raise UnsupportedOpcode(pc, opcode)
        return mnemonic, {}
