#!/usr/bin/env python3
"""Run a resumable, portfolio-wide matching-decomp search campaign.

The campaign deliberately separates cheap discovery from expensive mutation:

1. collect the best saved candidate for every currently unmatched function;
2. compile every candidate through each requested assembler pipeline;
3. rank candidates by their *current* mismatch count;
4. spend the mutation budget on the best candidates concurrently; and
5. write one leaderboard containing the best result seen in every stage.

All output is confined to build/decomp_search/campaigns/NAME and the normal
ignored per-target search directories.  Production sources are never edited.
"""
import argparse
import csv
import glob
import json
import os
import re
import subprocess
import sys


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PYTHON = sys.executable
MAKE_BATCH = os.path.join(ROOT, "tools", "decomp_make_batch.py")
BATCH = os.path.join(ROOT, "tools", "decomp_batch.py")
DEFAULT_TABLES = (
    "claude-work/output/**/NEAR_MISSES.tsv",
    "claude-work/output/**/INVENTORY.tsv",
    "build/decomp_search/**/summary.tsv",
)


def run(cmd, allow_failure=False):
    print("+ " + " ".join(cmd), flush=True)
    proc = subprocess.run(cmd, cwd=ROOT)
    if proc.returncode and not allow_failure:
        raise subprocess.CalledProcessError(proc.returncode, cmd)
    return proc.returncode


def read_manifest(path):
    with open(path, newline="") as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


def write_manifest(path, rows):
    fields = ("source", "function", "vram", "unit_vram", "mutations", "focus")
    with open(path, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def summary_score(text):
    # summary.tsv ends with: function, source, pipeline, unit, words, status, ...
    fields = text.split("\t")
    if len(fields) >= 6 and fields[4].isdigit():
        return int(fields[4]), fields[5]
    match = re.search(r"(?:^|\t)(\d+)(?:\t)(?:DIFF|MATCH|UNIT MATCH)", text)
    return (int(match.group(1)), "") if match else (10**9, "ERROR")


def read_results(path, stage, pipeline):
    if not os.path.isfile(path):
        return []
    with open(path) as fh:
        results = json.load(fh)
    out = []
    for result in results:
        words, status = summary_score(result.get("summary", ""))
        out.append({
            "function": result["function"], "pipeline": pipeline,
            "stage": stage, "words": words, "status": status,
            "seconds": result.get("seconds", 0), "log": result.get("log", ""),
        })
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True)
    ap.add_argument("--tables", nargs="*", default=list(DEFAULT_TABLES))
    ap.add_argument("--pipelines", default="production,asn64")
    ap.add_argument("--shortlist", type=int, default=24)
    ap.add_argument("--iters", type=int, default=500)
    ap.add_argument("--targets", type=int, default=8)
    ap.add_argument("--jobs", type=int, default=16)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--max-mut", type=int, default=2)
    ap.add_argument("--resume", action="store_true",
                    help="reuse completed stage result files")
    args = ap.parse_args()

    pipelines = [x.strip() for x in args.pipelines.split(",") if x.strip()]
    invalid = set(pipelines) - {"production", "raw-kmc", "asn64"}
    if invalid:
        ap.error("unknown pipeline(s): " + ", ".join(sorted(invalid)))

    outdir = os.path.join(ROOT, "build", "decomp_search", "campaigns", args.name)
    os.makedirs(outdir, exist_ok=True)
    manifest = os.path.join(outdir, "all.tsv")
    patterns = []
    for pattern in args.tables:
        absolute = pattern if os.path.isabs(pattern) else os.path.join(ROOT, pattern)
        patterns.extend(sorted(glob.glob(absolute, recursive=True)))
    if not patterns:
        ap.error("no evidence tables matched")
    run([PYTHON, MAKE_BATCH, *patterns, "--output", manifest, "--limit", "100000"])

    evidence = []
    for pipeline in pipelines:
        batch_name = "%s_baseline_%s" % (args.name, pipeline)
        results = os.path.join(ROOT, "build", "decomp_search", "batches",
                               batch_name, "results.json")
        if not (args.resume and os.path.isfile(results)):
            run([PYTHON, BATCH, manifest, "--name", batch_name, "--iters", "1",
                 "--targets", str(args.targets), "--jobs", str(args.jobs),
                 "--seed", str(args.seed), "--max-mut", "1", "--pipeline", pipeline],
                allow_failure=True)
        evidence.extend(read_results(results, "baseline", pipeline))

    best_baseline = {}
    for row in evidence:
        old = best_baseline.get(row["function"])
        if old is None or (row["words"], row["pipeline"]) < (old["words"], old["pipeline"]):
            best_baseline[row["function"]] = row
    wanted = [r["function"] for r in sorted(
        best_baseline.values(), key=lambda x: (x["words"], x["function"])
    ) if r["words"] > 0][:args.shortlist]
    all_rows = read_manifest(manifest)
    shortlist = os.path.join(outdir, "shortlist.tsv")
    write_manifest(shortlist, [row for row in all_rows if row["function"] in set(wanted)])

    for pipeline in pipelines:
        if not wanted:
            break
        batch_name = "%s_search_%s" % (args.name, pipeline)
        results = os.path.join(ROOT, "build", "decomp_search", "batches",
                               batch_name, "results.json")
        if not (args.resume and os.path.isfile(results)):
            run([PYTHON, BATCH, shortlist, "--name", batch_name,
                 "--iters", str(args.iters), "--targets", str(args.targets),
                 "--jobs", str(args.jobs), "--seed", str(args.seed),
                 "--max-mut", str(args.max_mut), "--pipeline", pipeline,
                 "--stop-at-zero"], allow_failure=True)
        evidence.extend(read_results(results, "search", pipeline))

    best = {}
    for row in evidence:
        old = best.get(row["function"])
        if old is None or (row["words"], row["stage"] != "search") < \
                (old["words"], old["stage"] != "search"):
            best[row["function"]] = row
    leaderboard = os.path.join(outdir, "leaderboard.tsv")
    fields = ("function", "words", "status", "pipeline", "stage", "seconds", "log")
    with open(leaderboard, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(sorted(best.values(), key=lambda x: (x["words"], x["function"])))
    exact = sum(row["words"] == 0 for row in best.values())
    print("campaign complete: %d candidates, %d exact; %s" %
          (len(best), exact, os.path.relpath(leaderboard, ROOT)))


if __name__ == "__main__":
    main()
