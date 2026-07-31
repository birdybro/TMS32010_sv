from __future__ import annotations

import random
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from sim.reference_models.tms32010_model import Tms32010Model

ROOT = Path(__file__).resolve().parents[2]
SEED = 0x32010


class ModelRtlSliceDifferentialTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        verilator = shutil.which("verilator")
        if verilator is None:
            raise RuntimeError("Verilator is required once architectural RTL exists")
        cls.build = ROOT / "build" / "verilator" / "tb_model_rtl_slice"
        cls.build.mkdir(parents=True, exist_ok=True)
        sources = [
            ROOT / "rtl" / "packages" / "tms32010_pkg.sv",
            ROOT / "rtl" / "core" / "tms32010_decode.sv",
            ROOT / "rtl" / "core" / "tms32010_internal_ram.sv",
            ROOT / "rtl" / "core" / "tms32010_multiplier.sv",
            ROOT / "rtl" / "core" / "tms32010_core.sv",
            ROOT / "sim" / "differential" / "tb_model_rtl_slice.sv",
        ]
        result = subprocess.run(
            [
                verilator,
                "--binary",
                "--timing",
                "--Wall",
                "--Wno-PINCONNECTEMPTY",
                "--top-module",
                "tb_model_rtl_slice",
                "--Mdir",
                str(cls.build),
                *map(str, sources),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode:
            raise RuntimeError(result.stdout + result.stderr)

    def test_seeded_mixed_stream_matches_model(self) -> None:
        randomizer = random.Random(SEED)
        data_words = [randomizer.randrange(0x10000) for _ in range(144)]
        data_words[0:5] = [0x0000, 0x0001, 0x7FFF, 0x8000, 0xFFFF]
        words: list[int] = []
        expected = []
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.data[:] = data_words

        def append_and_step(word: int) -> None:
            address = len(words)
            words.append(word)
            model.program[address] = word
            expected.append(model.step())

        for word in (
            0x7000,
            0x7100,
            0x6880,
            0x6E00,
            0x7F82,
            0x7F81,
            0x6E00,
            0x7B00,
            0x7000,
            0x6880,
            0x7BA1,
            0x7102,
            0x6881,
            0x7B90,
            0x6E00,
            0x6900,
            0x6901,
            0x697F,
            0x7F89,
            0x7F8A,
            0x7E5A,
            0x5005,
            0x2005,
            0x2F02,
            0x5C06,
            0x6504,
            0x6604,
            0x6502,
            0x6104,
            0x6101,
            0x7800,
            0x7901,
            0x7A04,
            0x0403,
            0x1403,
            0x6203,
            0x6303,
            0x6E00,
            0x6400,
            0x7F80,
            0x6401,
            0x7F80,
            0x6403,
            0x7F80,
            0x3800,
            0x7101,
            0x6881,
            0x39A8,
            0x7002,
            0x6880,
            0x39A8,
            0x3105,
            0x700A,
            0x6880,
            0x30A8,
            0x700A,
            0x7155,
            0x6880,
            0x3198,
            0x687F,
            0x68A1,
            0x6898,
            0x6F00,
            0x6F01,
            0x6F0F,
            0x6A00,
            0x6A01,
            0x6A0F,
            0x6D00,
            0x6D01,
            0x6D0F,
            0x6A03,
            0x6D03,
            0x8000,
            0x9FF7,
            0x9000,
            0x8FFF,
            0x7F8E,
            0x7F8F,
            0x7F90,
            0x6C00,
            0x6C01,
            0x6C0F,
            0x6B00,
            0x6B01,
            0x6B7F,
        ):
            append_and_step(word)

        for _ in range(16):
            if randomizer.randrange(2):
                address = (
                    randomizer.randrange(128)
                    if model.state.status.dp == 0
                    else randomizer.randrange(16)
                )
                word = 0x6400 | address
            else:
                selected = model.state.status.arp
                if (model.state.ar[selected] & 0xFF) < 144:
                    control = randomizer.choice(
                        [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                    )
                    word = 0x6400 | control
                else:
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6400 | address
            append_and_step(word)
            append_and_step(0x7F80)

        choices = [0x7F80, 0x7F81, 0x7F82, 0x7F89, 0x7F8A, 0x7F8B]
        for _ in range(394):
            family = randomizer.randrange(33)
            if family == 0:
                word = 0x7E00 | randomizer.randrange(256)
            elif family == 1:
                word = (
                    0x7000
                    | (randomizer.randrange(2) << 8)
                    | randomizer.randrange(144)
                )
            elif family == 2:
                word = 0x6880 | randomizer.randrange(2)
            elif family == 3:
                word = 0x6E00 | randomizer.randrange(2)
            elif family == 4:
                shift = randomizer.randrange(16)
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x2000 | (shift << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x2000 | (shift << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x2000 | (shift << 8) | address
            elif family == 5:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x5000 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x5000 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x5000 | address
            elif family == 6:
                shift = randomizer.choice((0, 1, 4))
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x5800 | (shift << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x5800 | (shift << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x5800 | (shift << 8) | address
            elif family in {7, 8}:
                base = 0x6500 if family == 7 else 0x6600
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = base | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = base | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = base | address
            elif family in {9, 10, 11, 12}:
                base = (0x6100, 0x7800, 0x7900, 0x7A00)[family - 9]
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = base | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = base | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = base | address
            elif family == 13:
                shift = randomizer.randrange(16)
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = (shift << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = (shift << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = (shift << 8) | address
            elif family == 14:
                shift = randomizer.randrange(16)
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x1000 | (shift << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x1000 | (shift << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x1000 | (shift << 8) | address
            elif family == 15:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6300 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6300 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6300 | address
            elif family == 16:
                target = randomizer.randrange(2)
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x3800 | (target << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x3800 | (target << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x3800 | (target << 8) | address
            elif family == 17:
                target = randomizer.randrange(2)
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x3000 | (target << 8) | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x3000 | (target << 8) | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x3000 | (target << 8) | address
            elif family == 18:
                if randomizer.randrange(2):
                    word = 0x6800 | randomizer.randrange(128)
                else:
                    word = 0x6800 | randomizer.choice(
                        [0x88, 0x98, 0xA8, 0x90, 0x91, 0xA0, 0xA1]
                    )
            elif family == 19:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6F00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6F00 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6F00 | address
            elif family == 20:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6A00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6A00 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6A00 | address
            elif family == 21:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6D00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6D00 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6D00 | address
            elif family == 22:
                word = 0x8000 | randomizer.randrange(0x2000)
            elif family == 23:
                word = 0x7F8E
            elif family == 24:
                word = 0x7F8F
            elif family == 25:
                word = 0x7F90
            elif family == 26:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6C00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6C00 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6C00 | address
            elif family == 27:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(127)
                        if model.state.status.dp == 0
                        else randomizer.randrange(15)
                    )
                    word = 0x6B00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 143:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6B00 | control
                    else:
                        address = (
                            randomizer.randrange(127)
                            if model.state.status.dp == 0
                            else randomizer.randrange(15)
                        )
                        word = 0x6B00 | address
            elif family == 28:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(127)
                        if model.state.status.dp == 0
                        else randomizer.randrange(15)
                    )
                    word = 0x6900 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 143:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6900 | control
                    else:
                        address = (
                            randomizer.randrange(127)
                            if model.state.status.dp == 0
                            else randomizer.randrange(15)
                        )
                        word = 0x6900 | address
            elif family == 29:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x6200 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x6200 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x6200 | address
            elif family == 30:
                if randomizer.randrange(2):
                    address = (
                        randomizer.randrange(128)
                        if model.state.status.dp == 0
                        else randomizer.randrange(16)
                    )
                    word = 0x7B00 | address
                else:
                    selected = model.state.status.arp
                    if (model.state.ar[selected] & 0xFF) < 144:
                        control = randomizer.choice(
                            [0x88, 0xA8, 0x98, 0x80, 0x81, 0xA0, 0xA1, 0x90, 0x91]
                        )
                        word = 0x7B00 | control
                    else:
                        address = (
                            randomizer.randrange(128)
                            if model.state.status.dp == 0
                            else randomizer.randrange(16)
                        )
                        word = 0x7B00 | address
            elif family == 31:
                word = randomizer.choice(choices)
            else:
                word = 0x7F88
            append_and_step(word)

        self.assertIn(0x7F88, words, "seed must retain randomized ABS coverage")

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    f"+COUNT={len(words)}",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [line for line in result.stdout.splitlines() if line.startswith("TRACE ")]
        self.assertEqual(len(lines), len(expected))
        ram_lines = [
            line for line in result.stdout.splitlines() if line.startswith("RAM ")
        ]
        self.assertEqual(len(ram_lines), 144)

        for index, (line, model_trace) in enumerate(zip(lines, expected)):
            fields = line.split()
            self.assertEqual(int(fields[1], 16), model_trace.pc, (SEED, index))
            self.assertEqual(int(fields[2], 16), model_trace.opcode, (SEED, index))
            self.assertEqual(
                int(fields[3], 16),
                model_trace.state_after["pc"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[4], 16),
                model_trace.state_after["acc"],
                (SEED, index),
            )
            self.assertEqual(
                bool(int(fields[5], 16)),
                model_trace.state_after["status"]["ovm"],
                (SEED, index),
            )
            self.assertEqual(
                bool(int(fields[22], 16)),
                model_trace.state_after["status"]["ov"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[23], 16),
                model_trace.state_after["t"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[24], 16),
                model_trace.state_after["p"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[6], 16),
                model_trace.state_after["ar"][0],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[7], 16),
                model_trace.state_after["ar"][1],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[8], 16),
                model_trace.state_after["status"]["arp"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[9], 16),
                model_trace.state_after["status"]["dp"],
                (SEED, index),
            )
            self.assertEqual(
                bool(int(fields[25], 16)),
                model_trace.state_after["status"]["intm"],
                (SEED, index),
            )
            self.assertEqual(
                [int(field, 16) for field in fields[26:30]],
                model_trace.state_after["stack"],
                (SEED, index),
            )
            self.assertEqual(int(fields[10], 16), 1, (SEED, index))
            self.assertEqual(int(fields[11], 16), 1, (SEED, index))
            self.assertEqual(int(fields[12], 16), 0, (SEED, index))
            self.assertEqual(
                int(fields[13], 16),
                model_trace.state_after["cycle_count"],
                (SEED, index),
            )
            data_transactions = [
                transaction
                for transaction in model_trace.transactions
                if transaction.space == "data"
            ]
            read_transaction = next(
                (
                    transaction
                    for transaction in data_transactions
                    if transaction.operation == "read"
                ),
                None,
            )
            write_transaction = next(
                (
                    transaction
                    for transaction in data_transactions
                    if transaction.operation == "write"
                ),
                None,
            )
            expected_read = read_transaction is not None
            expected_write = write_transaction is not None
            self.assertEqual(bool(int(fields[15], 16)), expected_read, (SEED, index))
            self.assertEqual(bool(int(fields[16], 16)), expected_write, (SEED, index))
            self.assertEqual(
                bool(int(fields[17], 16)),
                bool(data_transactions),
                (SEED, index),
            )
            self.assertEqual(
                bool(int(fields[19], 16)),
                expected_write,
                (SEED, index),
            )
            if read_transaction is not None:
                self.assertEqual(
                    int(fields[14], 16),
                    read_transaction.address,
                    (SEED, index),
                )
                self.assertEqual(
                    int(fields[20], 16),
                    read_transaction.data,
                    (SEED, index),
                )
            elif write_transaction is not None:
                self.assertEqual(
                    int(fields[14], 16),
                    write_transaction.address,
                    (SEED, index),
                )
            if write_transaction is not None:
                self.assertEqual(
                    int(fields[18], 16),
                    write_transaction.address,
                    (SEED, index),
                )
                self.assertEqual(
                    int(fields[21], 16),
                    write_transaction.data,
                    (SEED, index),
                )

        for index, line in enumerate(ram_lines):
            fields = line.split()
            self.assertEqual(int(fields[1], 16), index)
            self.assertEqual(int(fields[2], 16), model.data[index], (SEED, index))

    def test_io_cycles_state_ram_and_transactions_match_model(self) -> None:
        words = [
            0x7008,  # LARK AR0,8
            0x7128,  # LARK AR1,40
            0x6880,  # LARP AR0
            0x41A1,  # IN *+,PA1,AR1
            0x4D98,  # OUT *-,PA5, preserve ARP
            0x4307,  # IN 7,PA3
            0x4F07,  # OUT 7,PA7
            0x7F80,  # NOP
        ]
        data_words = [0] * 144
        data_words[40] = 0xCAFE
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        model.data[:] = data_words
        model.io_input[:] = [0x1000 + port for port in range(8)]
        expected = [model.step() for _ in words]
        machine_cycles = sum(trace.cycles for trace in expected)
        self.assertEqual(machine_cycles, 12)

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    f"+COUNT={machine_cycles}",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line.split()
            for line in result.stdout.splitlines()
            if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), machine_cycles)
        ram_lines = [
            line.split()
            for line in result.stdout.splitlines()
            if line.startswith("RAM ")
        ]
        self.assertEqual(len(ram_lines), 144)

        cycle_base = 0
        for model_trace in expected:
            retire_index = cycle_base + model_trace.cycles - 1
            rtl = lines[retire_index]
            self.assertEqual(int(rtl[3], 16), model_trace.state_after["pc"])
            self.assertEqual(int(rtl[6], 16), model_trace.state_after["ar"][0])
            self.assertEqual(int(rtl[7], 16), model_trace.state_after["ar"][1])
            self.assertEqual(
                int(rtl[8], 16),
                model_trace.state_after["status"]["arp"],
            )
            self.assertEqual(
                int(rtl[9], 16),
                model_trace.state_after["status"]["dp"],
            )
            self.assertEqual(int(rtl[11], 16), 1)
            self.assertEqual(
                int(rtl[13], 16),
                model_trace.state_after["cycle_count"],
            )
            if model_trace.cycles == 2:
                opcode_cycle = lines[cycle_base]
                self.assertEqual(
                    [int(opcode_cycle[index], 16) for index in (15, 16, 31, 32)],
                    [0, 0, 0, 0],
                )
                transaction_cycle = lines[retire_index]
                io_transaction = next(
                    transaction
                    for transaction in model_trace.transactions
                    if transaction.space == "io"
                )
                self.assertEqual(
                    int(transaction_cycle[30], 16),
                    io_transaction.address,
                )
                self.assertEqual(
                    int(transaction_cycle[31], 16),
                    int(io_transaction.operation == "read"),
                )
                self.assertEqual(
                    int(transaction_cycle[32], 16),
                    int(io_transaction.operation == "write"),
                )
                self.assertEqual(
                    int(transaction_cycle[33], 16),
                    io_transaction.data,
                )
                self.assertEqual(
                    [int(transaction_cycle[index], 16) for index in (15, 16)],
                    (
                        [0, 1]
                        if io_transaction.operation == "read"
                        else [1, 0]
                    ),
                )
            cycle_base += model_trace.cycles

        for index, line in enumerate(ram_lines):
            self.assertEqual(int(line[1], 16), index)
            self.assertEqual(int(line[2], 16), model.data[index])
        self.assertEqual(model.data[8], 0x1001)
        self.assertEqual(model.data[7], 0x1003)
        self.assertEqual(model.io_output[5], 0xCAFE)
        self.assertEqual(model.io_output[7], 0x1003)

    def test_table_transfer_cycles_buses_stack_and_memory_match_model(
        self,
    ) -> None:
        words = [
            0xF800,
            0x0002,
            0xF800,
            0x0004,
            0xF800,
            0x0006,
            0xF800,
            0x0008,
            0x7E20,
            0x6703,
            0x7E21,
            0x7D03,
            0x7F80,
        ]
        data_words = [0] * 144
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        model.program[0x20] = 0xBEEF
        model.program[0x21] = 0xAAAA
        model.data[:] = data_words
        expected = [model.step() for _ in range(9)]
        machine_cycles = sum(trace.cycles for trace in expected)

        self.assertEqual(
            [trace.mnemonic for trace in expected],
            [
                "CALL",
                "CALL",
                "CALL",
                "CALL",
                "LACK",
                "TBLR",
                "LACK",
                "TBLW",
                "NOP",
            ],
        )
        self.assertEqual(machine_cycles, 17)
        self.assertEqual(model.data[3], 0xBEEF)
        self.assertEqual(model.program[0x21], 0xBEEF)
        self.assertEqual(model.state.stack, [8, 6, 4, 4])

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image_words = words + [0x7F80] * (0x22 - len(words))
            image_words[0x20] = 0xBEEF
            image_words[0x21] = 0xAAAA
            image.write_text(
                "".join(f"{word:04x}\n" for word in image_words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    f"+COUNT={machine_cycles}",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line.split()
            for line in result.stdout.splitlines()
            if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), machine_cycles)
        self.assertEqual(
            [int(line[1], 16) for line in lines],
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0x20, 10, 11, 12, 0x21, 12],
        )
        self.assertEqual(
            [int(line[11], 16) for line in lines],
            [0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1],
            "table transfers retire only on their third cycles",
        )
        self.assertEqual(
            [(int(line[34], 16), int(line[35], 16)) for line in lines[9:12]],
            [(1, 0), (1, 0), (1, 0)],
            "TBLR uses MEN for opcode, discarded prefetch, and table read",
        )
        self.assertEqual(
            [(int(line[34], 16), int(line[35], 16)) for line in lines[13:16]],
            [(1, 0), (1, 0), (0, 1)],
            "TBLW changes from MEN prefetches to program-space write",
        )
        self.assertEqual(int(lines[15][36], 16), 0xBEEF)

        cumulative_cycles = 0
        for trace in expected:
            cumulative_cycles += trace.cycles
            rtl = lines[cumulative_cycles - 1]
            state = trace.state_after
            self.assertEqual(int(rtl[3], 16), state["pc"])
            self.assertEqual(int(rtl[4], 16), state["acc"])
            self.assertEqual(
                [int(field, 16) for field in rtl[26:30]],
                state["stack"],
            )
            self.assertEqual(int(rtl[13], 16), state["cycle_count"])

        ram_lines = [
            line.split()
            for line in result.stdout.splitlines()
            if line.startswith("RAM ")
        ]
        self.assertEqual(int(ram_lines[3][2], 16), model.data[3])
        program_lines = {
            int(line.split()[1], 16): int(line.split()[2], 16)
            for line in result.stdout.splitlines()
            if line.startswith("PROGRAM ")
        }
        self.assertEqual(program_lines[0x20], model.program[0x20])
        self.assertEqual(program_lines[0x21], model.program[0x21])

    def test_banz_two_cycle_taken_and_untaken_trace_matches_model(self) -> None:
        words = [
            0x7000,  # LARK AR0,0
            0xF400,  # untaken BANZ
            0x0003,  # fallthrough target
            0x7001,  # LARK AR0,1
            0xF400,  # taken BANZ
            0x0007,  # skips address 6
            0x7F89,  # skipped ZAC
            0x7F80,  # target NOP
        ]
        data_words = [0] * 144
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        expected = [model.step() for _ in range(5)]

        self.assertEqual(
            [trace.mnemonic for trace in expected],
            ["LARK", "BANZ", "LARK", "BANZ", "NOP"],
        )
        self.assertEqual([trace.cycles for trace in expected], [1, 2, 1, 2, 1])
        self.assertEqual(
            [
                transaction.address
                for trace in expected
                for transaction in trace.transactions
                if transaction.space == "program"
            ],
            [0, 1, 2, 3, 4, 5, 7],
        )

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    "+COUNT=7",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line for line in result.stdout.splitlines() if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), 7)
        fields = [line.split() for line in lines]
        self.assertEqual(
            [int(field[1], 16) for field in fields],
            [0, 1, 2, 3, 4, 5, 7],
        )
        self.assertEqual(
            [int(field[2], 16) for field in fields],
            [0x7000, 0xF400, 0x0003, 0x7001, 0xF400, 0x0007, 0x7F80],
        )
        self.assertEqual(
            [int(field[11], 16) for field in fields],
            [1, 0, 1, 1, 0, 1, 1],
            "BANZ retires only after its following-word fetch",
        )
        self.assertEqual(
            [int(field[13], 16) for field in fields],
            list(range(1, 8)),
            "each of the two BANZ program reads counts one machine cycle",
        )
        self.assertTrue(all(int(field[10], 16) for field in fields))
        self.assertTrue(all(not int(field[12], 16) for field in fields))

        for rtl_index, model_index in ((2, 1), (5, 3), (6, 4)):
            rtl = fields[rtl_index]
            model_state = expected[model_index].state_after
            self.assertEqual(int(rtl[3], 16), model_state["pc"])
            self.assertEqual(int(rtl[4], 16), model_state["acc"])
            self.assertEqual(int(rtl[6], 16), model_state["ar"][0])
            self.assertEqual(int(rtl[7], 16), model_state["ar"][1])
            self.assertEqual(int(rtl[13], 16), model_state["cycle_count"])

    def test_b_two_cycle_trace_matches_model(self) -> None:
        words = [
            0x7E5A,  # LACK 0x5a
            0xF900,  # B
            0x0004,  # skips address 3
            0x7F89,  # skipped ZAC
            0xF900,  # B
            0x0007,  # skips address 6
            0x7F89,  # skipped ZAC
            0x7F80,  # target NOP
        ]
        data_words = [0] * 144
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        expected = [model.step() for _ in range(4)]

        self.assertEqual(
            [trace.mnemonic for trace in expected],
            ["LACK", "B", "B", "NOP"],
        )
        self.assertEqual([trace.cycles for trace in expected], [1, 2, 2, 1])
        self.assertEqual(
            [
                transaction.address
                for trace in expected
                for transaction in trace.transactions
                if transaction.space == "program"
            ],
            [0, 1, 2, 4, 5, 7],
        )

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    "+COUNT=6",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line for line in result.stdout.splitlines() if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), 6)
        fields = [line.split() for line in lines]
        self.assertEqual(
            [int(field[1], 16) for field in fields],
            [0, 1, 2, 4, 5, 7],
        )
        self.assertEqual(
            [int(field[2], 16) for field in fields],
            [0x7E5A, 0xF900, 0x0004, 0xF900, 0x0007, 0x7F80],
        )
        self.assertEqual(
            [int(field[11], 16) for field in fields],
            [1, 0, 1, 0, 1, 1],
            "B retires only after its following-word fetch",
        )
        self.assertEqual(
            [int(field[13], 16) for field in fields],
            list(range(1, 7)),
            "each of the two B program reads counts one machine cycle",
        )
        self.assertTrue(all(int(field[10], 16) for field in fields))
        self.assertTrue(all(not int(field[12], 16) for field in fields))

        for rtl_index, model_index in ((2, 1), (4, 2), (5, 3)):
            rtl = fields[rtl_index]
            model_state = expected[model_index].state_after
            self.assertEqual(int(rtl[3], 16), model_state["pc"])
            self.assertEqual(int(rtl[4], 16), model_state["acc"])
            self.assertEqual(int(rtl[6], 16), model_state["ar"][0])
            self.assertEqual(int(rtl[7], 16), model_state["ar"][1])
            self.assertEqual(int(rtl[13], 16), model_state["cycle_count"])

    def test_bv_taken_clear_and_untaken_trace_matches_model(self) -> None:
        words = [
            0x7B00,  # LST 0 sets OV from data word 0.
            0xF500,  # BV taken.
            0x0004,
            0x7F89,  # Skipped ZAC.
            0xF500,  # BV untaken after the first BV clears OV.
            0x0008,
            0x7F80,  # Fallthrough NOP.
            0x7F89,
            0x7F80,
        ]
        data_words = [0] * 144
        data_words[0] = 0x8000
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        model.data[:] = data_words
        expected = [model.step() for _ in range(4)]

        self.assertEqual(
            [trace.mnemonic for trace in expected],
            ["LST", "BV", "BV", "NOP"],
        )
        self.assertEqual([trace.cycles for trace in expected], [1, 2, 2, 1])
        self.assertEqual(
            [trace.operands.get("branch_taken") for trace in expected],
            [None, 1, 0, None],
        )
        self.assertEqual(
            [trace.state_after["status"]["ov"] for trace in expected],
            [1, 0, 0, 0],
        )

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    "+COUNT=6",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line for line in result.stdout.splitlines() if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), 6)
        fields = [line.split() for line in lines]
        self.assertEqual(
            [int(field[1], 16) for field in fields],
            [0, 1, 2, 4, 5, 6],
        )
        self.assertEqual(
            [int(field[2], 16) for field in fields],
            [0x7B00, 0xF500, 0x0004, 0xF500, 0x0008, 0x7F80],
        )
        self.assertEqual(
            [int(field[11], 16) for field in fields],
            [1, 0, 1, 0, 1, 1],
        )
        self.assertEqual(
            [int(field[13], 16) for field in fields],
            list(range(1, 7)),
        )
        self.assertEqual(
            [int(field[22], 16) for field in fields],
            [1, 1, 0, 0, 0, 0],
            "BV clears OV only when its taken target word retires",
        )
        self.assertTrue(all(int(field[10], 16) for field in fields))
        self.assertTrue(all(not int(field[12], 16) for field in fields))

        for rtl_index, model_index in ((0, 0), (2, 1), (4, 2), (5, 3)):
            rtl = fields[rtl_index]
            model_state = expected[model_index].state_after
            self.assertEqual(int(rtl[3], 16), model_state["pc"])
            self.assertEqual(int(rtl[4], 16), model_state["acc"])
            self.assertEqual(
                int(rtl[22], 16),
                model_state["status"]["ov"],
            )
            self.assertEqual(int(rtl[13], 16), model_state["cycle_count"])

    def test_bioz_active_low_paths_match_model(self) -> None:
        words = [
            0xF600,  # BIOZ
            0x0004,
            0x7F80,  # Fallthrough.
            0x7F89,
            0x7F80,  # Target.
        ]
        data_words = [0] * 144

        for bio_high, expected_pc in ((False, 4), (True, 2)):
            with self.subTest(bio_high=bio_high):
                model = Tms32010Model()
                model.reset_at_instruction_boundary()
                model.load_words(words)
                model.bio_input_high = bio_high
                expected = model.step()

                self.assertEqual(expected.mnemonic, "BIOZ")
                self.assertEqual(expected.cycles, 2)
                self.assertEqual(
                    expected.operands["branch_taken"],
                    int(not bio_high),
                )
                self.assertEqual(expected.state_after["pc"], expected_pc)

                with tempfile.TemporaryDirectory() as directory:
                    image = Path(directory) / "program.hex"
                    data_image = Path(directory) / "data.hex"
                    image.write_text(
                        "".join(f"{word:04x}\n" for word in words),
                        encoding="ascii",
                    )
                    data_image.write_text(
                        "".join(f"{word:04x}\n" for word in data_words),
                        encoding="ascii",
                    )
                    result = subprocess.run(
                        [
                            str(self.build / "Vtb_model_rtl_slice"),
                            f"+IMAGE={image}",
                            f"+DATA={data_image}",
                            f"+BIO={int(bio_high)}",
                            "+COUNT=2",
                        ],
                        cwd=ROOT,
                        text=True,
                        capture_output=True,
                        check=False,
                    )

                self.assertEqual(
                    result.returncode,
                    0,
                    result.stdout + result.stderr,
                )
                lines = [
                    line
                    for line in result.stdout.splitlines()
                    if line.startswith("TRACE ")
                ]
                self.assertEqual(len(lines), 2)
                fields = [line.split() for line in lines]
                self.assertEqual(
                    [int(field[1], 16) for field in fields],
                    [0, 1],
                )
                self.assertEqual(
                    [int(field[2], 16) for field in fields],
                    [0xF600, 0x0004],
                )
                self.assertEqual(
                    [int(field[11], 16) for field in fields],
                    [0, 1],
                )
                self.assertEqual(
                    [int(field[13], 16) for field in fields],
                    [1, 2],
                )
                self.assertTrue(
                    all(int(field[10], 16) for field in fields)
                )
                self.assertTrue(
                    all(not int(field[12], 16) for field in fields)
                )
                self.assertEqual(
                    int(fields[-1][3], 16),
                    expected.state_after["pc"],
                )
                self.assertEqual(
                    int(fields[-1][4], 16),
                    expected.state_after["acc"],
                )
                self.assertEqual(
                    int(fields[-1][13], 16),
                    expected.state_after["cycle_count"],
                )

    def test_call_program_reads_pc_and_stack_match_model(self) -> None:
        words = [
            0xF800,  # CALL 4
            0x0004,
            0x7F89,  # Skipped.
            0x7F89,  # Skipped.
            0xF800,  # CALL 8
            0x0008,
            0x7F89,  # Skipped.
            0x7F89,  # Skipped.
            0x7F80,  # Final NOP.
        ]
        data_words = [0] * 144
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        expected = [model.step(), model.step(), model.step()]
        transactions = [
            transaction
            for trace in expected
            for transaction in trace.transactions
            if transaction.space == "program"
        ]
        machine_cycles = sum(trace.cycles for trace in expected)
        self.assertEqual(machine_cycles, 5)
        self.assertEqual(
            [trace.mnemonic for trace in expected],
            ["CALL", "CALL", "NOP"],
        )
        self.assertEqual(expected[0].state_after["stack"], [2, 0, 0, 0])
        self.assertEqual(expected[1].state_after["stack"], [6, 2, 0, 0])

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    f"+COUNT={machine_cycles}",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line for line in result.stdout.splitlines()
            if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), machine_cycles)
        fields = [line.split() for line in lines]
        self.assertEqual(
            [int(field[1], 16) for field in fields],
            [transaction.address for transaction in transactions],
        )
        self.assertEqual(
            [int(field[2], 16) for field in fields],
            [transaction.data for transaction in transactions],
        )
        self.assertEqual(
            [int(field[11], 16) for field in fields],
            [0, 1, 0, 1, 1],
        )
        self.assertEqual(
            [int(field[13], 16) for field in fields],
            [1, 2, 3, 4, 5],
        )
        self.assertTrue(all(int(field[10], 16) for field in fields))
        self.assertTrue(all(not int(field[12], 16) for field in fields))

        cumulative_cycles = 0
        for trace in expected:
            cumulative_cycles += trace.cycles
            rtl = fields[cumulative_cycles - 1]
            self.assertEqual(int(rtl[3], 16), trace.state_after["pc"])
            self.assertEqual(
                [int(field, 16) for field in rtl[26:30]],
                trace.state_after["stack"],
            )
            self.assertEqual(
                int(rtl[13], 16),
                trace.state_after["cycle_count"],
            )

    def test_accumulator_branch_family_trace_matches_model(self) -> None:
        cases = [
            ("BLZ", 0xFA00, 0x2000, True),
            ("BLZ", 0xFA00, 0x7F89, False),
            ("BLEZ", 0xFB00, 0x7F89, True),
            ("BLEZ", 0xFB00, 0x7E01, False),
            ("BGZ", 0xFC00, 0x7E01, True),
            ("BGZ", 0xFC00, 0x7F89, False),
            ("BGEZ", 0xFD00, 0x7F89, True),
            ("BGEZ", 0xFD00, 0x2000, False),
            ("BNZ", 0xFE00, 0x7E01, True),
            ("BNZ", 0xFE00, 0x7F89, False),
            ("BZ", 0xFF00, 0x7F89, True),
            ("BZ", 0xFF00, 0x7E01, False),
        ]
        words: list[int] = []
        for _, opcode, setup, expected_taken in cases:
            base = len(words)
            words.extend(
                [
                    setup,
                    opcode,
                    base + (4 if expected_taken else 5),
                    0x7F80,
                ]
            )
        words.append(0x7F80)

        data_words = [0] * 144
        data_words[0] = 0xFFFF
        model = Tms32010Model()
        model.reset_at_instruction_boundary()
        model.load_words(words)
        model.data[:] = data_words
        expected = []
        for mnemonic, _, _, expected_taken in cases:
            expected.append(model.step())
            branch = model.step()
            expected.append(branch)
            self.assertEqual(branch.mnemonic, mnemonic)
            self.assertEqual(
                branch.operands["branch_taken"],
                int(expected_taken),
            )
            if not expected_taken:
                expected.append(model.step())
        expected.append(model.step())

        transactions = [
            transaction
            for trace in expected
            for transaction in trace.transactions
            if transaction.space == "program"
        ]
        machine_cycles = sum(trace.cycles for trace in expected)
        self.assertEqual(machine_cycles, len(transactions))

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            data_image = Path(directory) / "data.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            data_image.write_text(
                "".join(f"{word:04x}\n" for word in data_words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
                    f"+DATA={data_image}",
                    f"+COUNT={machine_cycles}",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        lines = [
            line for line in result.stdout.splitlines() if line.startswith("TRACE ")
        ]
        self.assertEqual(len(lines), machine_cycles)
        fields = [line.split() for line in lines]
        self.assertEqual(
            [int(field[1], 16) for field in fields],
            [transaction.address for transaction in transactions],
        )
        self.assertEqual(
            [int(field[2], 16) for field in fields],
            [transaction.data for transaction in transactions],
        )
        self.assertEqual(
            [int(field[13], 16) for field in fields],
            list(range(1, machine_cycles + 1)),
        )
        self.assertTrue(all(int(field[10], 16) for field in fields))
        self.assertTrue(all(not int(field[12], 16) for field in fields))

        cumulative_cycles = 0
        for trace in expected:
            cumulative_cycles += trace.cycles
            rtl = fields[cumulative_cycles - 1]
            self.assertEqual(int(rtl[11], 16), 1)
            self.assertEqual(int(rtl[3], 16), trace.state_after["pc"])
            self.assertEqual(int(rtl[4], 16), trace.state_after["acc"])
            self.assertEqual(
                int(rtl[13], 16),
                trace.state_after["cycle_count"],
            )
            if trace.cycles == 2:
                self.assertEqual(int(fields[cumulative_cycles - 2][11], 16), 0)


if __name__ == "__main__":
    unittest.main()
