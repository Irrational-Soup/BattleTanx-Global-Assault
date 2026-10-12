import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from decompkit.config import load_config  # noqa: E402
from decompkit.image import compare_bytes  # noqa: E402
from decompkit.report import build_report  # noqa: E402
from decompkit.units import UnitVerifier, load_unit_catalogue  # noqa: E402


class DecompkitPortabilityTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "cfg").mkdir()
        (self.root / "source").mkdir()
        (self.root / "out").mkdir()
        (self.root / "cfg/functions.toml").write_text(textwrap.dedent("""
            [[section]]
            name = "text"
            [[section.functions]]
            name = "matched"
            vram = 0x1000
            size = 4
            [[section.functions]]
            name = "unmatched"
            vram = 0x1004
            size = 4
        """))
        (self.root / "cfg/splat.yaml").write_text(
            "subsegments:\n  - [0x0, c, matched_unit]\n"
            "  - [0x4, asm, unmatched_unit]\n"
        )
        (self.root / "cfg/rodata.tsv").write_text(
            "# unit\trodata_vram\trodata_size\nunit_a\t0x1008\t0x4\n"
        )
        (self.root / "cfg/data.tsv").write_text("# unit\tdata_vram\tdata_size\n")
        (self.root / "cfg/exclusions.tsv").write_text("# name\taddress\tsize\n")
        (self.root / "cfg/units.tsv").write_text(
            "unit\tvram\ttext_size\nunit_a\t0x1000\t0x4\n"
        )
        (self.root / "source/unit_a.c").write_text("void unit_a(void) {}\n")
        (self.root / "decompkit.toml").write_text(textwrap.dedent("""
            [project]
            root = "."
            functions = "cfg/functions.toml"
            splat = "cfg/splat.yaml"
            source_dir = "source"
            report_source_root = "source"
            rodata = "cfg/rodata.tsv"
            data = "cfg/data.tsv"
            exclusions = "cfg/exclusions.tsv"
            report_output = "out/report.json"
            [report]
            vram_delta = 0x1000
            code_end = 0x8
            image_start = 0x0
            image_end = 0x10
            source_kinds = ["c"]
            [units]
            manifests = [{ path = "cfg/units.tsv", pipeline = "toy" }]
        """))

    def tearDown(self):
        self.temporary.cleanup()

    def test_report_policy_comes_entirely_from_config(self):
        config = load_config(self.root / "decompkit.toml")
        report = build_report(
            config.functions, config.splat, [config.rodata, config.data],
            vram_delta=config.vram_delta, code_end=config.code_end,
            image_start=config.image_start, image_end=config.image_end,
            source_kinds=config.source_kinds,
            exclusions_path=config.exclusions, source_dir=config.source_dir,
            source_root=config.report_source_root,
        )
        self.assertEqual(report["measures"]["matched_functions"], 1)
        self.assertEqual(report["measures"]["total_functions"], 2)
        self.assertEqual(report["measures"]["matched_data"], "4")
        self.assertEqual(report["measures"]["total_data"], "8")

    def test_unit_verifier_accepts_injected_toolchain_and_reference(self):
        config = load_config(self.root / "decompkit.toml")
        catalogue = load_unit_catalogue(config)
        reference = {0x1000: b"TEXT", 0x1008: b"DATA"}

        def build(source, vram, pipeline):
            self.assertEqual(Path(source), self.root / "source/unit_a.c")
            self.assertEqual((vram, pipeline), (0x1000, "toy"))
            return {"text": b"TEXT", "tsz": 4, "rodata": b"DATA",
                    "rodata_vram": 0x1008}

        verifier = UnitVerifier(
            config, build, lambda address, size: reference[address][:size]
        )
        self.assertEqual(
            verifier.verify("unit_a", catalogue["unit_a"], {"unit_a": (0x1008, 4)}),
            (4, 4),
        )

    def test_duplicate_unit_manifest_rows_fail_closed(self):
        config_path = self.root / "decompkit.toml"
        config_path.write_text(config_path.read_text().replace(
            'manifests = [{ path = "cfg/units.tsv", pipeline = "toy" }]',
            'manifests = [{ path = "cfg/units.tsv", pipeline = "toy" }, '
            '{ path = "cfg/units.tsv", pipeline = "other" }]',
        ))
        with self.assertRaisesRegex(ValueError, "multiple pipeline manifests"):
            load_unit_catalogue(load_config(config_path))

    def test_whole_image_comparison_reports_hash_size_and_first_difference(self):
        exact = compare_bytes(b"ABCD", b"ABCD")
        self.assertTrue(exact.exact)
        self.assertEqual(exact.reference_sha256, exact.rebuilt_sha256)
        changed = compare_bytes(b"ABCD", b"ABxD")
        self.assertFalse(changed.exact)
        self.assertEqual(changed.first_difference, 2)
        short = compare_bytes(b"ABCD", b"ABC")
        self.assertEqual(short.first_difference, 3)


if __name__ == "__main__":
    unittest.main()
