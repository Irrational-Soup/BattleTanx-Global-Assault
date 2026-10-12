import importlib.util
import os
import subprocess
import sys
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
    def test_beam_exposes_bounded_generation_budget(self):
        proc = subprocess.run(
            [sys.executable, os.path.join(ROOT, "tools", "decomp_beam.py"), "--help"],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
        self.assertIn("--max-evals", proc.stdout)

    def test_context_diagnosis_categories(self):
        context = load("decomp_context")
        base = {
            "words": 3, "built_size": 16, "rom_size": 16,
            "classes": {"regname": 3}, "blocks": {"built": 1, "rom": 1},
            "pure_regname": True, "opcode_identical": True, "structural": 0,
        }
        self.assertEqual(context.diagnosis(base), "register_allocation")
        structural = dict(base, built_size=12, pure_regname=False)
        self.assertEqual(context.diagnosis(structural), "size_or_cfg_difference")

    def test_extra_instruction_does_not_establish_source_cause(self):
        context = load("decomp_context")
        extra_nop = {
            "words": 1, "built_size": 20, "rom_size": 16,
            "classes": {"insert": 1}, "blocks": {"built": 1, "rom": 1},
            "pure_regname": False, "opcode_identical": False, "structural": 1,
        }
        self.assertEqual(context.diagnosis(extra_nop), "size_or_cfg_difference")
        evidence = context.diagnostic_evidence(extra_nop)
        self.assertIsNone(evidence["established_producer"])
        self.assertEqual(evidence["size_delta"], 4)
        self.assertEqual(evidence["block_count_delta"], 0)
        self.assertIn("compiler_allocation_or_reload", evidence["possible_producers"])
        self.assertIn("assembler_or_linker", evidence["possible_producers"])

    def test_sibling_similarity_prefers_identical_features(self):
        siblings = load("decomp_siblings")
        a = (siblings.collections.Counter({("lw", "addiu", "sw"): 2}), 12)
        b = (siblings.collections.Counter({("lw", "addiu", "sw"): 2}), 12)
        c = (siblings.collections.Counter({("lwc1", "mul.s", "swc1"): 2}), 12)
        self.assertEqual(siblings.similarity(a, b), 1.0)
        self.assertEqual(siblings.similarity(a, c), 0.0)

    def test_worklist_has_actions_for_every_diagnosis(self):
        worklist = load("decomp_worklist")
        expected = {"source_structure", "size_or_cfg_difference", "instruction_selection_or_types",
                    "stack_layout_or_lifetime", "control_flow_or_calls",
                    "linking_rodata_or_ownership", "register_allocation",
                    "instruction_scheduling", "mixed_codegen",
                    "infrastructure", "exact"}
        self.assertEqual(set(worklist.NEXT), expected)

    def test_m2c_refresh_prefers_narrowest_span(self):
        refresh = load("decomp_m2c_refresh")
        spans = refresh.asm_candidates("func_800B6CC4")
        self.assertTrue(spans)
        self.assertLessEqual(os.path.getsize(spans[0]), os.path.getsize(spans[-1]))

    def test_catalogue_covers_distant_gameplay_ranges(self):
        compile_tool = load("decomp_compile")
        catalogue = compile_tool.catalogue()
        self.assertEqual(catalogue["func_800854C4"][0], 0x800854C4)
        self.assertEqual(catalogue["func_800A4468"][0], 0x800A4468)
        self.assertEqual(catalogue["func_800D6508"][0], 0x800D6508)

    def test_span_parser_accepts_size_and_canonical_range(self):
        compile_tool = load("decomp_compile")
        self.assertEqual(compile_tool.parse_span("0x40"), 0x40)
        self.assertEqual(compile_tool.parse_span("0x80001000..0x80001040"), 0x40)
        self.assertIsNone(compile_tool.parse_span(None))
        with self.assertRaisesRegex(ValueError, "precedes"):
            compile_tool.parse_span("0x20..0x10")

    def test_pipeline_modes_do_not_hide_asn64_match(self):
        compile_tool = load("decomp_compile")
        source = os.path.join(ROOT, "src", "code", "unknown/8008A1A4.c")
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
        source = os.path.join(ROOT, "src", "code", "unknown/8008A1A4.c")
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
        source = os.path.join(ROOT, "src", "code", "unknown/800D6508.c")
        built = compile_tool.build(source, 0x800D6508,
                                   focus="func_800D6508", pipeline="production")
        result = score_tool.classify(built, "func_800D6508")
        self.assertEqual(result["words"], 0)
        self.assertEqual(result["built_size"], result["rom_size"])

    def test_ai_leader_assisted_unit_is_exact(self):
        compile_tool = load("decomp_compile")
        score_tool = load("decomp_score")
        source = os.path.join(ROOT, "src", "code", "unknown/800854C4.c")
        built = compile_tool.build(source, 0x800854C4,
                                   focus="func_800854C4", pipeline="production")
        result = score_tool.classify(built, "func_800854C4")
        self.assertEqual(result["words"], 0)
        self.assertEqual(result["built_size"], result["rom_size"])

    def test_batch_manifest_defaults_unit_address(self):
        batch = load("decomp_batch")
        source = os.path.join(ROOT, "src", "code", "unknown/8009025C.c")
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

    def test_gcc_inline_spelling_is_normalized_for_parser(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("static __inline__ int helper(int x) { return x; }\n")
            fh.flush()
            text = permuter.preprocess(fh.name)
            permuter.parse(text)
        self.assertIn("static inline int helper", text)
        self.assertNotIn("__inline__", text)

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

    def test_gcc_typeof_candidate_round_trips_through_parser(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int target(int x) { __typeof__(x) y = x; return y; }\n")
            fh.flush()
            ast = permuter.parse(permuter.preprocess(fh.name))
        rendered = permuter.restore_typeof(
            permuter.c_generator.CGenerator().visit(ast))
        self.assertIn("__typeof__(x) y", rendered)
        self.assertNotIn("decomp_typeof_", rendered)

    def test_permuter_aligned_metric_prioritizes_structure_then_alignment(self):
        permuter = load("decomp_permuter")
        result = {
            "ok": True, "words": 99, "aligned": 7, "structural": 2,
            "size": 0x104, "rom": 0x100,
        }
        permuter.SCORE_METRIC[0] = "aligned"
        try:
            self.assertEqual(permuter.score(result), (3, 7, 4))
        finally:
            permuter.SCORE_METRIC[0] = "positional"

    def test_permuter_positional_metric_remains_backward_compatible(self):
        permuter = load("decomp_permuter")
        result = {
            "ok": True, "words": 9, "aligned": 1, "structural": 0,
            "size": 0x108, "rom": 0x100,
        }
        self.assertEqual(permuter.score(result), (17, 8))

    def test_permuter_exposes_aligned_metric_and_helper_mutation(self):
        proc = subprocess.run(
            [sys.executable, os.path.join(ROOT, "tools", "decomp_permuter.py"),
             "--help"],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
        self.assertIn("--metric", proc.stdout)
        self.assertIn("--mutate-func", proc.stdout)

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

    def test_beam_caps_generation_before_ast_expansion(self):
        beam = load("decomp_beam")
        self.assertEqual(beam.bounded_samples(28, 500, 12, 8), 6)
        self.assertEqual(beam.bounded_samples(28, 0, 12, 8), 28)
        self.assertEqual(beam.bounded_samples(28, 500, 0, 8), 28)

    def test_permuter_preserves_complete_build_diagnostic(self):
        permuter = load("decomp_permuter")
        original = permuter.kmclib.build
        diagnostic = "command prefix: " + ("x" * 300) + "\nactual cause"
        try:
            def fail(*args, **kwargs):
                raise RuntimeError(diagnostic)
            permuter.kmclib.build = fail
            result = permuter.evaluate(("unused.c", "int x;", 0, "f", "production"))
        finally:
            permuter.kmclib.build = original
        self.assertFalse(result["ok"])
        self.assertEqual(result["err"], diagnostic)

    def test_beam_aggregates_mutation_family_evidence(self):
        beam = load("decomp_beam")
        stats = {}
        beam.update_family_stat(stats, "swap_decls", (10, 0), {
            "ok": True, "words": 8, "size": 16, "rom": 16, "hash": "a",
        })
        beam.update_family_stat(stats, "swap_decls", (10, 0), {
            "ok": True, "words": 8, "size": 16, "rom": 16, "hash": "a",
        })
        beam.update_family_stat(stats, "swap_decls", (10, 0), {
            "ok": False, "err": "bad source",
        })
        self.assertEqual(stats["swap_decls"]["generated"], 3)
        self.assertEqual(stats["swap_decls"]["compiled"], 2)
        self.assertEqual(stats["swap_decls"]["build_errors"], 1)
        self.assertEqual(stats["swap_decls"]["distinct_outputs"], {"a"})
        self.assertEqual(stats["swap_decls"]["best"], (8, 0))
        self.assertEqual(stats["swap_decls"]["improvements"], 2)

    def test_integer_type_mutations_cover_locals_and_parameters(self):
        permuter = load("decomp_permuter")
        with tempfile.NamedTemporaryFile("w", suffix=".c") as fh:
            fh.write("int target(unsigned short p) { unsigned char i; i = p; return i; }\n")
            fh.flush()
            ast = permuter.parse(permuter.preprocess(fh.name))
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_int_type(fn, __import__("random").Random(1)))
        self.assertTrue(permuter.m_param_type(fn, __import__("random").Random(2)))

    def test_statement_swap_rejects_dependencies_and_calls(self):
        permuter = load("decomp_permuter")
        independent = permuter.parse(
            "int target(void) { int a; int b; a = 1; b = 2; return a + b; }")
        dependent = permuter.parse(
            "int target(void) { int a; int b; a = 1; b = a; return a + b; }")
        called = permuter.parse(
            "int call(void); int target(void) { int a; int b; a = call(); b = 2; return a + b; }")
        rng = __import__("random").Random(1)
        self.assertTrue(permuter.m_swap_stmts(permuter.find_func(independent, "target"), rng))
        self.assertFalse(permuter.m_swap_stmts(permuter.find_func(dependent, "target"), rng))
        self.assertFalse(permuter.m_swap_stmts(permuter.find_func(called, "target"), rng))

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

    def test_alias_mutation_rejects_uninitialized_or_reassigned_values(self):
        permuter = load("decomp_permuter")
        uninitialized = permuter.parse(
            "int target(int p) { int x; int y; x = p; y = x; return x + y; }")
        reassigned = permuter.parse(
            "int target(int p) { int x = p; int y; x = p + 1; y = x; return x + y; }")
        rng = __import__("random").Random(3)
        self.assertFalse(permuter.m_alias_uses(
            permuter.find_func(uninitialized, "target"), rng))
        self.assertFalse(permuter.m_alias_uses(
            permuter.find_func(reassigned, "target"), rng))

    def test_address_temp_keeps_call_argument_as_memory_dereference(self):
        permuter = load("decomp_permuter")
        ast = permuter.parse(
            "struct V { float z; }; void use(float); "
            "void target(struct V *v) { use(v->z); }")
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_address_temp(
            fn, __import__("random").Random(1)))
        rendered = permuter.restore_typeof(
            permuter.c_generator.CGenerator().visit(ast))
        self.assertIn("__typeof__(&v->z)", rendered)
        self.assertRegex(rendered, r"use\(\*pa\d+\)")

    def test_inline_address_alias_replaces_stable_pointer(self):
        permuter = load("decomp_permuter")
        ast = permuter.parse(
            "void use(int *); void target(void) { int x; int *p; "
            "p = &x; use(p); use(p); }")
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_inline_address_alias(
            fn, __import__("random").Random(1)))
        rendered = permuter.c_generator.CGenerator().visit(ast)
        self.assertNotIn("*p", rendered)
        self.assertNotIn("p =", rendered)
        self.assertEqual(rendered.count("use(&x)"), 2)

    def test_sink_address_assignment_moves_to_first_use(self):
        permuter = load("decomp_permuter")
        ast = permuter.parse(
            "void use(int *); void target(void) { int x; int y; int *p; "
            "p = &x; y = 2; use(p); use(p); }")
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_sink_address_assignment(
            fn, __import__("random").Random(1)))
        rendered = permuter.c_generator.CGenerator().visit(ast)
        self.assertLess(rendered.index("y = 2"), rendered.index("p = &x"))
        self.assertLess(rendered.index("p = &x"), rendered.index("use(p)"))

    def test_repeat_address_assignment_targets_later_use(self):
        permuter = load("decomp_permuter")
        ast = permuter.parse(
            "void use(int *); void target(void) { int x; int *p; "
            "p = &x; use(p); use(p); }")
        fn = permuter.find_func(ast, "target")
        self.assertTrue(permuter.m_repeat_address_assignment(
            fn, __import__("random").Random(1)))
        rendered = permuter.c_generator.CGenerator().visit(ast)
        self.assertEqual(rendered.count("p = &x"), 2)

    def test_m2c_refresh_supplies_fallthrough_and_delay_slot_labels(self):
        refresh = load("decomp_m2c_refresh")
        with tempfile.TemporaryDirectory() as td:
            asm = os.path.join(td, "input.s")
            table = os.path.join(td, "jump_tables.s")
            with open(asm, "w") as fh:
                fh.write("    /* 10 80000010 00000000 */ nop\n")
                fh.write("  .L80000014:\n")
                fh.write("    /* 14 80000014 00000000 */ nop\n")
            with open(table, "w") as fh:
                fh.write(".word .L80000010\n.word .L80000014\n")
            with open(os.path.join(td, "delay_slot_nop_before.txt"), "w") as fh:
                fh.write(".L80000014\n")
            generated = refresh.add_missing_jump_labels(asm, [table], td)
            with open(generated) as fh:
                text = fh.read()
        self.assertIn(".L80000010:\n", text)
        self.assertIn("nop  /* analysis-only delay-slot workaround */\n  .L80000014:", text)

    def test_campaign_parser_requires_complete_exact_evidence(self):
        runner = load("run_decomp_campaign")
        exact = (
            ".text 80001000..80001100: 0 mismatched words\n"
            "RESULT x.c: UNIT MATCH\n"
        )
        self.assertEqual(runner.parse_result(exact, 0), ("MATCH", 0))
        self.assertEqual(runner.parse_result(exact, 1)[0], "INVALID")
        self.assertEqual(
            runner.parse_result(exact + "Traceback (most recent call last):\n", 1)[0],
            "INVALID",
        )
        self.assertEqual(
            runner.parse_result("RESULT x.c: UNIT MATCH\n", 0)[0], "INVALID"
        )
        self.assertEqual(
            runner.parse_result("note: expected 'UNIT MATCH'\n", 2)[0], "ERROR"
        )
        assisted_empty = (
            ".text 80001000..80001000: 0 mismatched words\n"
            "RESULT x.c: NORMALIZER_ASSISTED\n"
        )
        self.assertEqual(runner.parse_result(assisted_empty, 0)[0], "INVALID")

    def test_campaign_cache_tracks_transitive_inputs(self):
        runner = load("run_decomp_campaign")
        from pathlib import Path

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            lane = root / "lane"
            tools = lane / "tools"
            candidates = lane / "candidates"
            tools.mkdir(parents=True)
            candidates.mkdir()
            comparator = tools / "kmc_cmp.py"
            helper = tools / "lanecfg.py"
            header = candidates / "candidate.h"
            candidate = candidates / "candidate.c"
            comparator.write_text("# comparator\n")
            helper.write_text("MODE = 1\n")
            header.write_text("#define VALUE 1\n")
            candidate.write_text('#include "candidate.h"\n')
            job = {
                "candidate": candidate,
                "comparator": comparator,
                "target": "80001000",
            }
            first = runner.digest_job(job, Path(ROOT))
            header.write_text("#define VALUE 2\n")
            second = runner.digest_job(job, Path(ROOT))
            helper.write_text("MODE = 2\n")
            third = runner.digest_job(job, Path(ROOT))
        self.assertNotEqual(first, second)
        self.assertNotEqual(second, third)


if __name__ == "__main__":
    unittest.main()
