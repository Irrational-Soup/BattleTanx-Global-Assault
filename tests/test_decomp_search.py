import importlib.util
import os
import tempfile
import unittest


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name):
    path = os.path.join(ROOT, "tools", name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DecompSearchTests(unittest.TestCase):
    def test_catalogue_covers_distant_gameplay_ranges(self):
        compile_tool = load("decomp_compile")
        catalogue = compile_tool.catalogue()
        self.assertEqual(catalogue["func_800854C4"][0], 0x800854C4)
        self.assertEqual(catalogue["func_800A4468"][0], 0x800A4468)
        self.assertEqual(catalogue["func_800D6508"][0], 0x800D6508)

    def test_pipeline_modes_do_not_hide_asn64_match(self):
        compile_tool = load("decomp_compile")
        source = os.path.join(ROOT, "src", "code", "func_8008A1A4.c")
        results = {}
        for pipeline in ("production", "raw-kmc", "asn64"):
            built = compile_tool.build(
                source, 0x8008A1A4, focus="func_8008A1A4", pipeline=pipeline
            )
            generated, retail, _, _, _ = compile_tool.func_words(
                built, "func_8008A1A4"
            )
            results[pipeline] = generated == retail
        self.assertFalse(results["production"])
        self.assertFalse(results["raw-kmc"])
        self.assertTrue(results["asn64"])

    def test_score_cli_accepts_explicit_pipeline(self):
        score = os.path.join(ROOT, "tools", "decomp_score.py")
        source = os.path.join(ROOT, "src", "code", "func_8008A1A4.c")
        import subprocess
        result = subprocess.run(
            [os.path.join(ROOT, ".venv", "bin", "python"), score, source,
             "8008A1A4", "func_8008A1A4", "--pipeline", "asn64"],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("words 0", result.stdout)

    def test_effect_burst_assisted_unit_is_exact(self):
        compile_tool = load("decomp_compile")
        score_tool = load("decomp_score")
        source = os.path.join(ROOT, "src", "code", "func_800D6508.c")
        built = compile_tool.build(source, 0x800D6508,
                                   focus="func_800D6508", pipeline="production")
        result = score_tool.classify(built, "func_800D6508")
        self.assertEqual(result["words"], 0)
        self.assertEqual(result["built_size"], result["rom_size"])

    def test_ai_leader_assisted_unit_is_exact(self):
        compile_tool = load("decomp_compile")
        score_tool = load("decomp_score")
        source = os.path.join(ROOT, "src", "code", "func_800854C4.c")
        built = compile_tool.build(source, 0x800854C4,
                                   focus="func_800854C4", pipeline="production")
        result = score_tool.classify(built, "func_800854C4")
        self.assertEqual(result["words"], 0)
        self.assertEqual(result["built_size"], result["rom_size"])

    def test_batch_manifest_defaults_unit_address(self):
        batch = load("decomp_batch")
        source = os.path.join(ROOT, "src", "code", "func_8009025C.c")
        with tempfile.NamedTemporaryFile("w", suffix=".tsv") as fh:
            fh.write("source\tfunction\tvram\n")
            fh.write("%s\tfunc_8009025C\t8009025C\n" % source)
            fh.flush()
            rows = batch.read_manifest(fh.name)
        self.assertEqual(rows[0]["unit_vram"], "8009025C")

    def test_batch_rejects_missing_candidate(self):
        batch = load("decomp_batch")
        with tempfile.NamedTemporaryFile("w", suffix=".tsv") as fh:
            fh.write("does/not/exist.c\tfunc_80000000\t80000000\n")
            fh.flush()
            with self.assertRaisesRegex(ValueError, "does not exist"):
                batch.read_manifest(fh.name)

    def test_batch_exposes_beam_engine(self):
        batch = load("decomp_batch")
        self.assertTrue(batch.BEAM.endswith("tools/decomp_beam.py"))
        self.assertTrue(os.path.isfile(batch.BEAM))

    def test_portfolio_generator_infers_multi_function_unit_start(self):
        generator = load("decomp_make_batch")
        catalogue = {
            "func_80001000": (0x80001000, 4),
            "func_80001100": (0x80001100, 4),
        }
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("extern int func_80000000(void);\n")
            fh.write("void func_80001000(void) {}\n")
            fh.write("void func_80001100(void) { func_80000000(); }\n")
            fh.flush()
            unit = generator.infer_unit_vram(fh.name, "80001100", catalogue)
        self.assertEqual(unit, "80001000")

    def test_portfolio_generator_reads_search_summary(self):
        generator = load("decomp_make_batch")
        with tempfile.TemporaryDirectory() as td:
            source = os.path.join(td, "best.c")
            table = os.path.join(td, "summary.tsv")
            with open(source, "w") as fh:
                fh.write("void func_800854C4(void) {}\n")
            with open(table, "w") as fh:
                fh.write("func_800854C4\t%s\tproduction\t-\t12\tDIFF\t-\ttest\n" % source)
            rows = generator.read_tables([table], {"func_800854C4"})
        self.assertEqual(rows[0][0], 12)
        self.assertEqual(rows[0][2], "func_800854C4")

    def test_m2c_helpers_are_expanded_before_ast_parsing(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("s32 test(void *p) { return M2C_FIELD(p, s32 *, 4); }\n")
            fh.flush()
            text = permuter.preprocess(fh.name)
            permuter.parse(text)
        self.assertIn("typedef signed int s32;", text)
        self.assertNotIn("M2C_FIELD", text)

    def test_m2c_unknown_width_and_null_are_lowered(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("M2C_UNK32 test(void) { void *p = NULL; return p != NULL; }\n")
            fh.flush()
            text = permuter.preprocess(fh.name)
            permuter.parse(text)
        self.assertIn("typedef unsigned int M2C_UNK32;", text)
        self.assertNotIn("NULL", text)

    def test_raw_m2c_question_mark_type_is_lowered(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("? test(? *p) { return *p; }\n")
            fh.flush()
            text = permuter.preprocess(fh.name)
            permuter.parse(text)
        self.assertNotIn("?", text)
        self.assertIn("M2C_UNK", text)

    def test_ternary_operator_is_not_lowered_as_unknown_type(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int test(int x) { return x ? 1 : 2; }\n")
            fh.flush()
            text = permuter.preprocess(fh.name)
            permuter.parse(text)
        self.assertIn("?", text)
        self.assertNotIn("M2C_UNK", text)

    def test_m2c_prototypes_can_be_relaxed_for_search_fallback(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("s32 func_80000000(s32, s32); /* extern */\n")
            fh.write("s32 target(void) { return func_80000000(1, 2, 3); }\n")
            fh.flush()
            strict = permuter.preprocess(fh.name)
            relaxed = permuter.preprocess(fh.name, relax_prototypes=True)
        self.assertIn("func_80000000(s32, s32)", strict)
        self.assertIn("func_80000000()", relaxed)

    def test_campaign_summary_score(self):
        campaign = load("decomp_campaign")
        summary = "func_80000000\tbest.c\tasn64\t-\t7\tDIFF\t-\tnote"
        self.assertEqual(campaign.summary_score(summary), (7, "DIFF"))
        self.assertEqual(campaign.summary_score(""), (10**9, "ERROR"))

    def test_campaign_writes_round_trip_manifest(self):
        campaign = load("decomp_campaign")
        rows = [{"source": "x.c", "function": "func_80000000",
                 "vram": "80000000", "unit_vram": "80000000",
                 "mutations": "commute", "focus": ""}]
        with tempfile.NamedTemporaryFile("w+", suffix=".tsv") as fh:
            campaign.write_manifest(fh.name, rows)
            self.assertEqual(campaign.read_manifest(fh.name), rows)

    def test_beam_expansion_is_stable_and_distinct(self):
        beam = load("decomp_beam")
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int target(int a, int b) { int x; int y; x = a; y = b; return x + y; }\n")
            fh.flush()
            ast = permuter.parse(permuter.preprocess(fh.name))
        generator = permuter.c_generator.CGenerator()
        first = beam.expand(ast, "target", ["swap_decls", "commute"], 8,
                            123, "", generator)
        second = beam.expand(ast, "target", ["swap_decls", "commute"], 8,
                             123, "", generator)
        self.assertEqual([x[4] for x in first], [x[4] for x in second])
        self.assertEqual(len({x[4] for x in first}), len(first))
        self.assertGreaterEqual(len(first), 2)

    def test_integer_type_mutations_cover_locals_and_parameters(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int target(unsigned short p) { unsigned char i; i = p; return i; }\n")
            fh.flush()
            ast = permuter.parse(permuter.preprocess(fh.name))
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_int_type(fn, __import__("random").Random(1)))
        self.assertTrue(permuter.m_param_type(fn, __import__("random").Random(2)))

    def test_alias_mutation_partitions_uses(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int target(int p) { int x = p; int y; int z; y = x; z = x; return x + y + z; }\n")
            fh.flush()
            ast = permuter.parse(permuter.preprocess(fh.name))
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_alias_uses(fn, __import__("random").Random(3)))
        rendered = permuter.c_generator.CGenerator().visit(ast)
        self.assertRegex(rendered, r"au\d+")


if __name__ == "__main__":
    unittest.main()
