#!/usr/bin/env python3
"""Create immutable build contexts and structured diagnoses for decomp candidates.

This is the measurement layer used before any mutation search.  A context ID
covers the candidate, transitive includes, toolchain executables, linker
symbols, normalizer, pipeline configuration, and exact reference span.  The
result is emitted as JSON; stdout tokens are never treated as evidence.
"""
import argparse
import csv
import hashlib
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import decomp_compile as compilelib  # noqa: E402
import decomp_score as scorelib  # noqa: E402


SCHEMA = "battletanx-ga-decomp-context-v1"


def sha256_bytes(value):
    return hashlib.sha256(value).hexdigest()


def file_record(path):
    path = os.path.realpath(path)
    with open(path, "rb") as fh:
        data = fh.read()
    return {"path": os.path.relpath(path, ROOT), "size": len(data),
            "sha256": sha256_bytes(data)}


def dependencies(source, cflags):
    """Ask the historical compiler for the candidate's transitive includes."""
    source = os.path.realpath(source)
    cmd = [compilelib.KMC + "gcc", "-B" + compilelib.KMC, "-M"] + list(cflags) + [
        "-I" + os.path.join(ROOT, "include"), "-I" + os.path.dirname(source), source]
    proc = subprocess.run(cmd, cwd=ROOT, env=compilelib.ENV,
                          capture_output=True, text=True)
    if proc.returncode:
        raise compilelib.BuildError("dependency scan failed:\n" + proc.stdout + proc.stderr)
    joined = proc.stdout.replace("\\\n", " ")
    body = joined.split(":", 1)[1] if ":" in joined else joined
    paths = []
    for token in body.split():
        path = token.replace("\\ ", " ")
        if not os.path.isabs(path):
            path = os.path.join(ROOT, path)
        if os.path.isfile(path):
            paths.append(os.path.realpath(path))
    paths.append(source)
    return sorted(set(paths))


def tool_inputs(pipeline):
    paths = [
        compilelib.KMC + "gcc", compilelib.KMC + "cc1", compilelib.KMC + "as",
        compilelib.B + "ld", compilelib.B + "objcopy", compilelib.B + "objdump",
        os.path.join(ROOT, "tools", "normalize_kmc_gcc_asm.py"),
        os.path.join(ROOT, "tools", "trim_elf32_section.py"),
        os.path.join(ROOT, "build", "us", "symbols.ld"),
        os.path.join(ROOT, "config", "us", "recomp_function_boundaries.toml"),
    ]
    if pipeline == "asn64":
        paths.append(os.path.join(ROOT, "tools", "modern_asn64.py"))
    return [path for path in paths if os.path.isfile(path)]


def diagnosis(result):
    """Return a triage hint, never an established compiler-pass diagnosis."""
    if result["words"] == 0 and result["built_size"] == result["rom_size"]:
        return "exact"
    classes = result["classes"]
    if result["built_size"] != result["rom_size"] or result["blocks"]["built"] != result["blocks"]["rom"]:
        return "size_or_cfg_difference"
    if classes.get("branch_inv", 0) or classes.get("call", 0):
        return "control_flow_or_calls"
    if result["pure_regname"] or (classes.get("regname", 0) and result["opcode_identical"]):
        return "register_allocation"
    if classes.get("stack", 0) and not result["structural"]:
        return "stack_layout_or_lifetime"
    if classes.get("schedule", 0) > sum(classes.values()) // 2:
        return "instruction_scheduling"
    if classes.get("literal", 0) or classes.get("call_disp", 0):
        return "linking_rodata_or_ownership"
    if any(classes.get(k, 0) for k in ("insert", "delete", "replace")):
        return "instruction_selection_or_types"
    return "mixed_codegen"


def diagnostic_evidence(result):
    """Keep output observations separate from unproved causal hypotheses.

    Retail has no available RTL or allocation tables. Final instruction diffs
    alone cannot establish which compiler/assembler phase produced a change.
    In GCC 2.7.2 the .greg dump is after reload, not a pre-reload checkpoint.
    """
    return {
        "basis": "final_output_only",
        "established_producer": None,
        "size_delta": result["built_size"] - result["rom_size"],
        "block_count_delta": result["blocks"]["built"] - result["blocks"]["rom"],
        "instruction_difference_classes": dict(result["classes"]),
        "possible_producers": (["source_or_types", "compiler_allocation_or_reload",
                                 "compiler_scheduling", "assembler_or_linker"]
                                if diagnosis(result) != "exact" else []),
    }


def evaluate(source, function, vram, unit_vram, pipeline, capture_dumps=False,
             artifact_dir=None):
    source = os.path.realpath(source)
    with open(source) as fh:
        source_text = fh.read()
    marks = compilelib.markers(source_text)
    cat = compilelib.catalogue()
    if function not in cat:
        raise ValueError("function is absent from catalogue: " + function)
    address, size = cat[function]
    if size <= 0:
        raise ValueError("reference span is empty: " + function)
    dep_records = [file_record(p) for p in dependencies(source, marks["cflags"])]
    tool_records = [file_record(p) for p in tool_inputs(pipeline)]
    reference = compilelib.rom_bytes(address, size)
    context = {
        "schema": SCHEMA, "function": function, "pipeline": pipeline,
        "source": os.path.relpath(source, ROOT), "vram": "0x%08X" % vram,
        "unit_vram": "0x%08X" % unit_vram,
        "reference": {"vram": "0x%08X" % address, "size": size,
                      "sha256": sha256_bytes(reference)},
        "markers": marks, "dependencies": dep_records, "tools": tool_records,
    }
    canonical = json.dumps(context, sort_keys=True, separators=(",", ":")).encode()
    context["context_id"] = sha256_bytes(canonical)
    built = compilelib.build(source, unit_vram, focus=function,
                             pipeline=pipeline, dumps=capture_dumps)
    classified = scorelib.classify(built, function)
    actual, expected, _, _, _ = compilelib.func_words(built, function)
    exact = len(expected) > 0 and len(actual) == len(expected) and actual == expected
    result = {
        "schema": SCHEMA, "context": context, "status": "MATCH" if exact else "DIFF",
        "exact": exact, "diagnosis": diagnosis(classified),
        "diagnostic_evidence": diagnostic_evidence(classified),
        "comparison": classified,
        "actual": {"size": len(actual), "sha256": sha256_bytes(actual)},
        "assembly": {"raw_sha256": sha256_bytes(built["raw_s"].encode()),
                     "pipeline_sha256": sha256_bytes(built["norm_s"].encode())},
        "relocations_sha256": sha256_bytes(built["relocs"].encode()),
    }
    if capture_dumps:
        result["rtl_dumps"] = {name: sha256_bytes(text.encode())
                               for name, text in built.get("dumps", {}).items()}
        if artifact_dir:
            os.makedirs(artifact_dir, exist_ok=True)
            artifacts = {}
            payloads = dict(built.get("dumps", {}))
            payloads.update(raw_assembly=built["raw_s"],
                            pipeline_assembly=built["norm_s"],
                            relocations=built["relocs"])
            for name, text in payloads.items():
                filename = re.sub(r"[^A-Za-z0-9_.-]", "_", name) + ".txt"
                output = os.path.join(artifact_dir, filename)
                with open(output, "w") as fh:
                    fh.write(text)
                artifacts[name] = {"path": os.path.relpath(output, ROOT),
                                   "sha256": sha256_bytes(text.encode())}
            result["artifacts"] = artifacts
    return result


def read_manifest(path):
    with open(path, newline="") as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    for row in rows:
        source = row["source"]
        if not os.path.isabs(source):
            source = os.path.join(ROOT, source)
        yield source, row["function"], int(row["vram"], 16), int(row.get("unit_vram") or row["vram"], 16)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("--output", required=True)
    ap.add_argument("--pipeline", choices=("production", "raw-kmc", "asn64"), default="production")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--rtl", action="store_true")
    args = ap.parse_args()
    os.makedirs(args.output, exist_ok=True)
    summary = []
    for index, (source, function, vram, unit) in enumerate(read_manifest(args.manifest)):
        if args.limit and index >= args.limit:
            break
        try:
            artifact_dir = os.path.join(args.output,
                                        "%s.%s.artifacts" % (function, args.pipeline))
            result = evaluate(source, function, vram, unit, args.pipeline, args.rtl,
                              artifact_dir if args.rtl else None)
        except Exception as exc:
            result = {"schema": SCHEMA, "function": function, "status": "ERROR",
                      "exact": False, "error": "%s: %s" % (type(exc).__name__, exc)}
        path = os.path.join(args.output, "%s.%s.json" % (function, args.pipeline))
        with open(path, "w") as fh:
            json.dump(result, fh, indent=2, sort_keys=True)
        comp = result.get("comparison", {})
        summary.append((function, result["status"], comp.get("words", ""),
                        result.get("diagnosis", "infrastructure"), os.path.relpath(path, ROOT)))
        print("%-24s %-5s %-6s %s" % summary[-1][:-1], flush=True)
    with open(os.path.join(args.output, "summary.tsv"), "w") as fh:
        fh.write("function\tstatus\twords\tdiagnosis\tresult\n")
        for row in summary:
            fh.write("\t".join(map(str, row)) + "\n")


if __name__ == "__main__":
    main()
