from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from tools.decompkit.resources import extract_regions, rebuild_image
from tools.reproduce import command_plan


class ResourceImageTests(unittest.TestCase):
    def test_extract_and_rebuild_with_prefix_overlap(self) -> None:
        image = bytes(range(32))
        regions = [
            {"kind": "crossing", "name": "crossing", "start": 6, "end": 14},
            {"kind": "tail", "name": "tail", "start": 14, "end": 32},
        ]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(image, regions, root, include_after=8)
            rebuilt = rebuild_image(
                image[:8], manifest, root, require_pristine_resources=True
            )
            self.assertEqual(rebuilt, image)
            self.assertEqual(manifest["source_image_sha256"], hashlib.sha256(image).hexdigest())
            self.assertEqual(json.loads((root / "manifest.json").read_text()), manifest)

    def test_uncovered_tail_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(b"abcdefgh", [], root, include_after=4)
            with self.assertRaisesRegex(ValueError, "uncovered byte"):
                rebuild_image(b"abcd", manifest, root)

    def test_changed_overlap_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(
                b"abcdefgh", [{"start": 2, "end": 8, "name": "x"}], root, include_after=4
            )
            filename = manifest["regions"][0]["file"]
            (root / filename).write_bytes(b"ZZefgh")
            with self.assertRaisesRegex(ValueError, "disagrees with rebuilt prefix"):
                rebuild_image(b"abcd", manifest, root)

    def test_changed_resource_hash_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(
                b"abcdefgh", [{"start": 4, "end": 8, "name": "x"}], root, include_after=4
            )
            filename = manifest["regions"][0]["file"]
            (root / filename).write_bytes(b"WXYZ")
            with self.assertRaisesRegex(ValueError, "resource hash mismatch"):
                rebuild_image(b"abcd", manifest, root, require_pristine_resources=True)

    def test_wrong_prefix_size_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(
                b"abcdefgh", [{"start": 4, "end": 8, "name": "x"}], root, include_after=4
            )
            with self.assertRaisesRegex(ValueError, "prefix size"):
                rebuild_image(b"abc", manifest, root)

    def test_resource_path_escape_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = extract_regions(
                b"abcdefgh", [{"start": 4, "end": 8, "name": "x"}], root, include_after=4
            )
            manifest["regions"][0]["file"] = "../outside.bin"
            with self.assertRaisesRegex(ValueError, "escapes its root"):
                rebuild_image(b"abcd", manifest, root)

    def test_conflicting_resource_overlap_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            first = root / "first.bin"
            second = root / "second.bin"
            first.write_bytes(b"efgh")
            second.write_bytes(b"ZZij")
            manifest = {
                "image_size": 10,
                "rebuilt_prefix_size": 4,
                "regions": [
                    {"start": 4, "end": 8, "file": first.name, "sha256": ""},
                    {"start": 6, "end": 10, "file": second.name, "sha256": ""},
                ],
            }
            with self.assertRaisesRegex(ValueError, "overlapping resources disagree"):
                rebuild_image(b"abcd", manifest, root)


class ReproductionPlanTests(unittest.TestCase):
    def test_default_plan_covers_source_assets_full_rom_and_tests(self) -> None:
        plan = command_plan(Path("/repo"), Path("/tmp/game.z64"), toolchain=True, tests=True, raw_only=False)
        flattened = [" ".join(command) for command in plan]
        self.assertEqual(flattened[0], "python3 tools/check_repository.py")
        self.assertIn("make toolchain", flattened)
        self.assertIn("make verify-code", flattened)
        self.assertTrue(any("extract_resources.py" in command for command in flattened))
        self.assertTrue(any("build_rom.py --require-original" in command for command in flattened))
        self.assertIn("make verify-assets", flattened)
        self.assertIn("make check", flattened)

    def test_raw_only_and_optional_steps(self) -> None:
        plan = command_plan(Path("/repo"), Path("/tmp/game.z64"), toolchain=False, tests=False, raw_only=True)
        flattened = [" ".join(command) for command in plan]
        self.assertFalse(any("toolchain" in command for command in flattened))
        self.assertFalse(any(command == "make check" for command in flattened))
        self.assertTrue(any(command.endswith("--raw-only") for command in flattened))


if __name__ == "__main__":
    unittest.main()
