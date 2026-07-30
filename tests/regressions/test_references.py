from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HELPER_PATH = ROOT / "scripts" / "reference_manifest.py"
SPEC = importlib.util.spec_from_file_location("reference_manifest", HELPER_PATH)
assert SPEC is not None and SPEC.loader is not None
REFERENCE_MANIFEST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REFERENCE_MANIFEST)


class ReferenceManifestTests(unittest.TestCase):
    def test_committed_manifest_is_valid(self) -> None:
        manifest = REFERENCE_MANIFEST.load_manifest()
        self.assertGreaterEqual(len(manifest["sources"]), 10)

    def test_manifest_is_yaml_compatible_json(self) -> None:
        path = ROOT / "docs" / "references" / "manifest.yaml"
        parsed = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(parsed["schema_version"], 1)

    def test_cache_paths_cannot_escape(self) -> None:
        manifest = REFERENCE_MANIFEST.load_manifest()
        source = dict(manifest["sources"][0])
        source["local_filename"] = "../outside.pdf"
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(REFERENCE_MANIFEST.ManifestError):
                REFERENCE_MANIFEST.cache_path(source, Path(directory))

    def test_duplicate_ids_are_rejected(self) -> None:
        original = REFERENCE_MANIFEST.load_manifest()
        malformed = dict(original)
        malformed["sources"] = list(original["sources"])
        malformed["sources"].append(dict(original["sources"][0]))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.yaml"
            path.write_text(json.dumps(malformed), encoding="utf-8")
            with self.assertRaises(REFERENCE_MANIFEST.ManifestError):
                REFERENCE_MANIFEST.load_manifest(path)


if __name__ == "__main__":
    unittest.main()
