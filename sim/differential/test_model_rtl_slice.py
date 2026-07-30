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
        words = [0x7000, 0x7100, 0x6880, 0x6E00, 0x7F89, 0x7F8A]
        choices = [0x7F80, 0x7F89, 0x7F8A, 0x7F8B]
        for _ in range(506):
            family = randomizer.randrange(6)
            if family == 0:
                words.append(0x7E00 | randomizer.randrange(256))
            elif family == 1:
                words.append(
                    0x7000
                    | (randomizer.randrange(2) << 8)
                    | randomizer.randrange(256)
                )
            elif family == 2:
                words.append(0x6880 | randomizer.randrange(2))
            elif family == 3:
                words.append(0x6E00 | randomizer.randrange(2))
            else:
                words.append(randomizer.choice(choices))

        model = Tms32010Model()
        model.load_words(words)
        expected = [model.step() for _ in words]

        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "program.hex"
            image.write_text(
                "".join(f"{word:04x}\n" for word in words),
                encoding="ascii",
            )
            result = subprocess.run(
                [
                    str(self.build / "Vtb_model_rtl_slice"),
                    f"+IMAGE={image}",
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


if __name__ == "__main__":
    unittest.main()
