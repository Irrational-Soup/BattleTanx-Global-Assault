#!/usr/bin/env python3
"""Sweep evidence-backed KMC GCC flag sets across unresolved candidates.

This is a diagnostic/search tool.  It writes generated candidates and results
under ``build/decomp_search`` and never edits production sources.  Exact-byte
comparison still comes from :mod:`decomp_context`; a lower score is only a
lead, not a matching claim.
"""

import argparse
import concurrent.futures
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import decomp_context  # noqa: E402


FLAG_SETS = {
    "default": "-O2 -G0 -mips3 -mgp32 -mfp32",
    "r8000": "-O2 -G0 -mips3 -mgp32 -mfp32 -mcpu=r8000",
    "r4600": "-O2 -G0 -mips3 -mgp32 -mfp32 -mcpu=r4600",
    "r4650": "-O2 -G0 -mips3 -mgp32 -mfp32 -mcpu=r4650",
    "no_cse_skip": "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-cse-skip-blocks",
    "no_sched1": "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-schedule-insns",
    "no_sched2": "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-schedule-insns2",
    "no_sched_both": (
        "-O2 -G0 -mips3 -mgp32 -mfp32 "
        "-fno-schedule-insns -fno-schedule-insns2"
    ),
    "debug_g3": "-O2 -G0 -mips3 -mgp32 -mfp32 -g3",
    "no_force_addr": "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-force-addr",
    "no_force_mem": "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-force-mem",
    "no_strength_reduce": (
        "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-strength-reduce"
    ),
    "no_rerun_cse": (
        "-O2 -G0 -mips3 -mgp32 -mfp32 -fno-rerun-cse-after-loop"
    ),
}


def source_with_flags(source, flags):
    marker = "/* CFLAGS %s */" % flags
    pattern = re.compile(r"/\*\s*CFLAGS\s+.*?\*/")
    if pattern.search(source):
        return pattern.sub(marker, source, count=1)
    return marker + "\n" + source


def incomplete_functions(report_path):
    if not report_path or not os.path.isfile(report_path):
        return None
    with open(report_path) as fh:
        report = json.load(fh)
    names = set()
    for unit in report.get("units", []):
        metadata = unit.get("metadata", {})
        if metadata.get("complete") or "code" not in metadata.get("progress_categories", []):
            continue
        names.update(function["name"] for function in unit.get("functions", []))
    return names


def load_targets(path, selected, incomplete):
    rows = []
    with open(path, newline="") as fh:
        for fields in csv.reader(fh, delimiter="\t"):
            if not fields or fields[0].startswith("#") or fields[0] == "function":
                continue
            name = fields[0]
            if selected and name not in selected:
                continue
            if incomplete is not None and name not in incomplete:
                continue
            try:
                vram = int(fields[1], 16)
            except (IndexError, ValueError):
                continue
            candidates = [value for value in fields[2:] if value.endswith(".c")]
            source = next(
                (value for value in candidates
                 if os.path.isfile(value if os.path.isabs(value)
                                   else os.path.join(ROOT, value))),
                None,
            )
            if source:
                source = source if os.path.isabs(source) else os.path.join(ROOT, source)
                rows.append((name, vram, source))
    return rows


def evaluate(job):
    name, vram, source_path, flag_name, flags, pipeline, outdir = job
    target_dir = os.path.join(outdir, name)
    os.makedirs(target_dir, exist_ok=True)
    generated = os.path.join(target_dir, flag_name + ".c")
    with open(source_path) as fh:
        source = source_with_flags(fh.read(), flags)
    with open(generated, "w") as fh:
        fh.write(source)
    record = {
        "function": name,
        "vram": "0x%08X" % vram,
        "source": os.path.relpath(source_path, ROOT),
        "flags": flag_name,
        "pipeline": pipeline,
    }
    try:
        result = decomp_context.evaluate(
            generated, name, vram, vram, pipeline,
            artifact_dir=os.path.join(target_dir, flag_name + "." + pipeline),
        )
        record.update(
            status=result["status"],
            exact=result["exact"],
            aligned=result["comparison"]["aligned_diffs"],
            positional=result["comparison"]["words"],
            size=result["actual"]["size"],
            diagnosis=result["diagnosis"],
            text_sha256=result["actual"]["sha256"],
        )
    except Exception as exc:
        record.update(status="ERROR", exact=False, error=str(exc))
    return record


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--worklist", default="build/decomp_search/worklists/remaining71-current3.tsv")
    parser.add_argument("--function", action="append", default=[])
    parser.add_argument("--pipeline", choices=("production", "asn64"), default="production")
    parser.add_argument("--report", default="build/us/report.json",
                        help="only sweep functions incomplete in this report; empty disables")
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--output", default="build/decomp_search/flag_sweep")
    args = parser.parse_args()
    selected = set(args.function)
    report_path = os.path.join(ROOT, args.report) if args.report else None
    targets = load_targets(os.path.join(ROOT, args.worklist), selected,
                           incomplete_functions(report_path))
    os.makedirs(os.path.join(ROOT, args.output), exist_ok=True)
    jobs = [
        (name, vram, source, flag_name, flags, args.pipeline,
         os.path.join(ROOT, args.output))
        for name, vram, source in targets
        for flag_name, flags in FLAG_SETS.items()
    ]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        records = list(pool.map(evaluate, jobs))

    baselines = {
        row["function"]: row for row in records
        if row["flags"] == "default" and row.get("aligned") is not None
    }
    for row in records:
        base = baselines.get(row["function"])
        if base and row.get("aligned") is not None:
            row["aligned_delta"] = row["aligned"] - base["aligned"]
    records.sort(key=lambda row: (
        not row.get("exact", False),
        row.get("aligned_delta", 1 << 30),
        row.get("aligned", 1 << 30),
        row["function"], row["flags"],
    ))
    output = os.path.join(ROOT, args.output, "results.json")
    with open(output, "w") as fh:
        json.dump({"worklist": args.worklist, "report": args.report,
                   "records": records}, fh,
                  indent=2, sort_keys=True)
    print("targets=%d evaluations=%d" % (len(targets), len(records)))
    for row in records:
        if row.get("exact") or row.get("aligned_delta", 0) < 0:
            print("%-18s %-18s %-6s aligned=%-5s delta=%-5s size=%s" % (
                row["function"], row["flags"], row["status"],
                row.get("aligned", "-"), row.get("aligned_delta", "-"),
                row.get("size", "-"),
            ))
    if any(row.get("exact") for row in records):
        return


if __name__ == "__main__":
    main()
