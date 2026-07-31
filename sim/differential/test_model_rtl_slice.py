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
            0x6303,
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
        ):
            append_and_step(word)

        choices = [0x7F80, 0x7F89, 0x7F8A, 0x7F8B]
        for _ in range(455):
            family = randomizer.randrange(27)
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
            else:
                word = randomizer.choice(choices)
            append_and_step(word)

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
                bool(int(fields[20], 16)),
                model_trace.state_after["status"]["ov"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[21], 16),
                model_trace.state_after["t"],
                (SEED, index),
            )
            self.assertEqual(
                int(fields[22], 16),
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
            expected_read = bool(
                data_transactions and data_transactions[0].operation == "read"
            )
            expected_write = bool(
                data_transactions and data_transactions[0].operation == "write"
            )
            self.assertEqual(bool(int(fields[15], 16)), expected_read, (SEED, index))
            self.assertEqual(bool(int(fields[16], 16)), expected_write, (SEED, index))
            self.assertEqual(
                bool(int(fields[17], 16)),
                bool(data_transactions),
                (SEED, index),
            )
            if data_transactions:
                self.assertEqual(
                    int(fields[14], 16),
                    data_transactions[0].address,
                    (SEED, index),
                )
                self.assertEqual(
                    int(fields[18 if expected_read else 19], 16),
                    data_transactions[0].data,
                    (SEED, index),
                )

        for index, line in enumerate(ram_lines):
            fields = line.split()
            self.assertEqual(int(fields[1], 16), index)
            self.assertEqual(int(fields[2], 16), model.data[index], (SEED, index))


if __name__ == "__main__":
    unittest.main()
