import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from decompkit.config import load_config  # noqa: E402
from decompkit.adapters import AdapterError, CommandBuildAdapter, ImageReference  # noqa: E402
from decompkit.assembly import category_totals, classify_assembly, inventory_assembly  # noqa: E402
from decompkit.gcc_alloc import (  # noqa: E402
    allocation_priority, allocation_rows, function_section, parse_pre_reload_text,
)
from decompkit.image import compare_bytes  # noqa: E402
from decompkit.o2r import load_readiness, readiness_summary  # noqa: E402
from decompkit.registers import (  # noqa: E402
    exhaustive_register_maps, exhaustive_window_register_maps, mapping_cost,
    opcode_aligned_regions, regional_register_swaps,
    single_register_swaps,
)
from decompkit.report import build_report  # noqa: E402
from decompkit.rewrite import function_body, permute_lines, rename_tokens, replace_exact  # noqa: E402
from decompkit.tool_inventory import (  # noqa: E402
    ToolGroup, load_inventory, render_markdown, validate_inventory,
)
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

    def test_register_atlas_finds_independent_swaps(self):
        built = [("add", ("r1", "r2", "r3")), ("mul", ("f0", "f2", "f4"))]
        reference = [("add", ("r2", "r1", "r3")), ("mul", ("f2", "f0", "f4"))]
        rows = exhaustive_register_maps(
            built, reference,
            [(["r1", "r2"], ["r1", "r2"]), (["f0", "f2"], ["f0", "f2"])],
        )
        self.assertEqual(rows[0].mismatches, 0)
        self.assertEqual(
            rows[0].mapping,
            {"r1": "r2", "r2": "r1", "f0": "f2", "f2": "f0"},
        )

    def test_register_atlas_scores_every_single_swap(self):
        built = [
            ("add", ("r1", "r2", "r3")),
            ("mul", ("r1", "r4", "r2")),
            ("fadd", ("f0", "f2", "f4")),
        ]
        reference = [
            ("add", ("r2", "r1", "r3")),
            ("mul", ("r2", "r4", "r1")),
            ("fadd", ("f0", "f2", "f4")),
        ]
        rows = single_register_swaps(
            built, reference, [["r1", "r2", "r3", "r4"], ["f0", "f2", "f4"]]
        )
        self.assertEqual(rows[0].mismatches, 0)
        self.assertEqual(rows[0].mapping, {"r1": "r2", "r2": "r1"})
        self.assertEqual(len(rows), 10)  # identity + C(4,2) + C(3,2)

    def test_register_atlas_finds_best_regional_swap_window(self):
        built = [
            ("use", ("r1",)),
            ("use", ("r1", "r2")),
            ("use", ("r2", "r1")),
            ("use", ("r1",)),
        ]
        reference = [
            ("use", ("r1",)),
            ("use", ("r2", "r1")),
            ("use", ("r1", "r2")),
            ("use", ("r1",)),
        ]
        rows = regional_register_swaps(built, reference, [["r1", "r2"]])
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0].start, rows[0].end), (1, 3))
        self.assertEqual(rows[0].improvement, 4)
        self.assertEqual(rows[0].mismatches, 0)

    def test_register_atlas_aligns_around_inserted_opcode(self):
        built = [
            ("add", ("r1", "r2")),
            ("nop", ()),
            ("sub", ("r1", "r2")),
            ("mul", ("r1", "r2")),
        ]
        reference = [
            ("add", ("r1", "r2")),
            ("sub", ("r2", "r1")),
            ("mul", ("r2", "r1")),
        ]
        self.assertEqual(
            opcode_aligned_regions(built, reference), [(0, 0, 1), (2, 1, 2)]
        )
        rows = regional_register_swaps(
            built, reference, [["r1", "r2"]], align_opcodes=True
        )
        self.assertEqual((rows[0].start, rows[0].end), (2, 4))
        self.assertEqual(rows[0].improvement, 4)

    def test_register_atlas_exhausts_permutations_in_one_window(self):
        built = [("head", ("r1",)), ("body", ("r1", "r2")), ("tail", ("r1",))]
        reference = [("head", ("r1",)), ("body", ("r2", "r1")), ("tail", ("r1",))]
        rows = exhaustive_window_register_maps(
            built, reference, [(["r1", "r2"], ["r1", "r2"])], 1, 2
        )
        self.assertEqual(rows[0].mapping, {"r1": "r2", "r2": "r1"})
        self.assertEqual(rows[0].mismatches, 0)
        self.assertEqual(rows[0].improvement, 2)
        inserted = built[:1] + [("nop", ())] + built[1:]
        aligned = exhaustive_window_register_maps(
            inserted, reference, [(["r1", "r2"], ["r1", "r2"])], 2, 3,
            align_opcodes=True,
        )
        self.assertEqual(aligned[0].mapping, {"r1": "r2", "r2": "r1"})
        self.assertEqual(aligned[0].improvement, 2)

    def test_o2r_readiness_requires_real_runtime_contract(self):
        manifest = self.root / "o2r.toml"
        manifest.write_text(textwrap.dedent("""
            [[resource]]
            name = "texture"
            stage = "runtime-ready"
            extractor = "extract.py"
            serializer = "TextureV1"
            resource_type = "Texture"
            factory = "TextureFactory"

            [[resource]]
            name = "world"
            stage = "structured"
            extractor = "world.py"
            blocker = "No runtime factory yet."
        """))
        resources = load_readiness(manifest)
        self.assertEqual(readiness_summary(resources)["runtime-ready"], 1)
        manifest.write_text(manifest.read_text().replace(
            'factory = "TextureFactory"', 'blocker = "Not actually ready"'
        ))
        with self.assertRaisesRegex(ValueError, "runtime-ready requires factory"):
            load_readiness(manifest)

    def test_assembly_inventory_separates_code_data_padding_and_hasm(self):
        asm = self.root / "asm"
        asm.mkdir()
        (asm / "code.s").write_text("glabel f\n  addiu $sp, $sp, -8\n")
        (asm / "data.s").write_text("dlabel d\n  .word 0x12345678\n")
        (asm / "pad.s").write_text("dlabel p\n  .word 0x00000000\n")
        (asm / "hand.s").write_text("glabel h\n  jr $ra\n")
        splat = self.root / "splat.yaml"
        splat.write_text(textwrap.dedent("""
            subsegments:
              - [0x100, asm, code]
              - [0x108, asm, data]
              - [0x10C, asm, pad]
              - [0x110, hasm, hand]
              - [0x118, c, next]
        """))
        rows = inventory_assembly(splat, asm)
        self.assertEqual([row.category for row in rows], [
            "generated-code", "embedded-data", "padding", "authentic-source-assembly",
        ])
        self.assertEqual(rows[0].size, 8)
        self.assertEqual(category_totals(rows)["padding"], (1, 4))

    def test_assembly_inventory_recognizes_disassembled_ascii(self):
        text = """glabel bogus
/* D468 8007D468 6754696D */ daddiu $s4, $k0, 0x696D
/* D46C 8007D46C 65520000 */ daddiu $s2, $t2, 0
"""
        self.assertEqual(classify_assembly("asm", "bogus", text)[0], "embedded-data")

    def test_register_atlas_rejects_factorial_explosion(self):
        with self.assertRaisesRegex(ValueError, "exceeds limit"):
            exhaustive_register_maps(
                [], [], [(["a", "b", "c"], ["x", "y", "z"])], limit=5
            )
        self.assertEqual(
            mapping_cost([("a", ("r1",))], [("b", ("r2",))], {"r1": "r2"}), 1
        )

    def test_rewrite_primitives_are_fail_closed(self):
        self.assertEqual(replace_exact("a b", "a", "x").text, "x b")
        with self.assertRaisesRegex(RuntimeError, "fired 0 times"):
            replace_exact("a b", "z", "x")
        self.assertEqual(
            rename_tokens("$s1,$s10,$s2", {"$s1": "$s2", "$s2": "$s1"}),
            "$s2,$s10,$s1",
        )
        with self.assertRaisesRegex(ValueError, "injective"):
            rename_tokens("a", {"a": "x", "b": "x"})
        body = "f:\n\ta\n\tb\n\t.end f\n"
        self.assertEqual(function_body(body, "f")[2], body)
        self.assertEqual(permute_lines("a\nb\n", [1, 0]), "b\na\n")
        with self.assertRaisesRegex(ValueError, "complete permutation"):
            permute_lines("a\nb\n", [0, 0])

    def test_gcc_allocation_parser_keeps_pre_and_post_reload_distinct(self):
        dump = ";; Function f\nbody\n;; Function g\nother\n"
        self.assertEqual(function_section(dump, "f"), "\nbody\n")
        lreg = (
            "Register 101 used 4 times across 8 insns; crosses 1 call; 8 bytes.\n"
            ";; Register 102 in 18.\n"
            "(set (reg:SI 101)\n    (const_int 3))\n"
        )
        greg = (
            ";; 1 regs to allocate: 101\n"
            ";; Register dispositions:\n101 in 19\n;; Hard regs used\n"
        )
        pre = parse_pre_reload_text(
            "PRE_RELOAD_REG function=f pseudo=101 hard=18 allocno=4 refs=4 live=8 calls=1\n",
            "f",
        )
        parsed = allocation_rows(lreg, greg, pre)
        row = parsed["global"][0]
        self.assertEqual((row["pre_reload_hard_name"], row["hard_name"]), ("s2", "s3"))
        self.assertTrue(row["reload_changed_assignment"])
        self.assertEqual(parsed["local"], {102: 18})
        self.assertEqual(row["priority"], allocation_priority(4, 8, 2))

    def test_command_adapter_and_image_reference_are_project_neutral(self):
        adapter_script = self.root / "adapter.py"
        adapter_script.write_text(textwrap.dedent("""
            import json, pathlib, sys
            request = json.loads(pathlib.Path(sys.argv[1]).read_text())
            assert request["format"] == "decompkit-build-request-v1"
            response = {
                "format": "decompkit-build-response-v1",
                "text_hex": "54455854",
                "text_size": 4,
                "rodata_hex": "44415441",
                "rodata_vram": "0x1008",
                "observed_pipeline": request["pipeline"],
            }
            pathlib.Path(sys.argv[2]).write_text(json.dumps(response))
        """))
        adapter = CommandBuildAdapter(
            [sys.executable, str(adapter_script), "{request}", "{response}"], cwd=self.root
        )
        built = adapter(str(self.root / "source/unit_a.c"), 0x1000, pipeline="toy")
        self.assertEqual((built["text"], built["rodata"]), (b"TEXT", b"DATA"))
        self.assertEqual(built["adapter_response"]["observed_pipeline"], "toy")

        image = self.root / "reference.bin"
        image.write_bytes(b"TEXTxxxxDATA")
        reference = ImageReference(image, lambda address: address - 0x1000)
        self.assertEqual(reference(0x1008, 4), b"DATA")
        with self.assertRaisesRegex(ValueError, "short"):
            reference(0x100B, 4)

        broken = CommandBuildAdapter(
            [sys.executable, "-c", "import sys; sys.exit(3)", "{request}", "{response}"]
        )
        with self.assertRaisesRegex(AdapterError, "exited 3"):
            broken(str(self.root / "source/unit_a.c"), 0x1000, pipeline="toy")

    def test_tool_inventory_is_complete_unique_and_rendered(self):
        inventory = load_inventory(ROOT / "config/tooling_inventory.toml")
        rendered = render_markdown(inventory, ROOT / "tools")
        self.assertEqual(rendered, (ROOT / "docs/TOOL_REFERENCE.md").read_text())

        toy_tools = self.root / "toy_tools"
        toy_tools.mkdir()
        (toy_tools / "a.py").write_text('"""A tool."""\n')
        (toy_tools / "b.sh").write_text("#!/bin/sh\n")
        group = ToolGroup("toy", "portable", "Toy tools.", "Synthetic fixture.", ("a.py",))
        with self.assertRaisesRegex(ValueError, "unclassified tools: b.sh"):
            validate_inventory((group,), toy_tools)
        duplicate = ToolGroup("copy", "adapter", "Copy.", "Synthetic fixture.", ("a.py",))
        with self.assertRaisesRegex(ValueError, "multiply classified tools"):
            validate_inventory((group, duplicate, ToolGroup(
                "shell", "portable", "Shell.", "Synthetic fixture.", ("b.sh",)
            )), toy_tools)


if __name__ == "__main__":
    unittest.main()
