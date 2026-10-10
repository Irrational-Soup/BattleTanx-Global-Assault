#!/usr/bin/env python3
"""Run bounded candidate searches across a portfolio of decompilation targets.

Manifest format (tab-separated, comments and a header are optional):

    source  function  vram  unit_vram  mutations  focus

Only the first three fields are required.  ``mutations`` is a comma-separated
subset accepted by decomp_permuter.py.  Results and logs are written below
build/decomp_search/batches/<name>; no source file is modified.
"""
import argparse
import concurrent.futures
import csv
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PYTHON = sys.executable
PERMUTER = os.path.join(ROOT, "tools", "decomp_permuter.py")
BEAM = os.path.join(ROOT, "tools", "decomp_beam.py")


def read_manifest(path):
    rows = []
    with open(path, newline="") as fh:
        for raw in csv.reader(fh, delimiter="\t"):
            if not raw or not raw[0].strip() or raw[0].lstrip().startswith("#"):
                continue
            if raw[0].strip().lower() == "source":
                continue
            raw += [""] * (6 - len(raw))
            source, function, vram, unit_vram, mutations, focus = (x.strip() for x in raw[:6])
            if not os.path.isabs(source):
                source = os.path.join(ROOT, source)
            if not os.path.isfile(source):
                raise ValueError("candidate source does not exist: %s" % source)
            int(vram, 16)
            if unit_vram:
                int(unit_vram, 16)
            rows.append(dict(source=source, function=function, vram=vram,
                             unit_vram=unit_vram or vram,
                             mutations=mutations, focus=focus))
    if not rows:
        raise ValueError("manifest contains no targets")
    return rows


def run_target(job):
    row, args, outdir, workers = job
    name = "%s_%s" % (args.name, row["function"])
    tool = BEAM if args.engine == "beam" else PERMUTER
    cmd = [PYTHON, tool, row["source"], row["function"], row["vram"],
           "--unit-vram", row["unit_vram"], "--jobs", str(workers),
           "--seed", str(args.seed), "--name", name, "--pipeline", args.pipeline]
    if args.engine == "beam":
        cmd += ["--rounds", str(args.rounds), "--beam", str(args.beam),
                "--samples", str(args.samples),
                "--plateau-rounds", str(args.plateau_rounds)]
    else:
        cmd += ["--iters", str(args.iters), "--max-mut", str(args.max_mut)]
    if row["mutations"]:
        cmd += ["--only", row["mutations"]]
    if row["focus"]:
        cmd += ["--focus", row["focus"], "--focus-max", str(args.focus_max)]
    if args.stop_at_zero:
        cmd.append("--stop-at-zero")
    started = time.time()
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    log = os.path.join(outdir, row["function"] + ".log")
    with open(log, "w") as fh:
        fh.write("$ " + " ".join(cmd) + "\n")
        fh.write(proc.stdout)
        fh.write(proc.stderr)
    summary_path = os.path.join(ROOT, "build", "decomp_search", name, "summary.tsv")
    summary = ""
    if os.path.exists(summary_path):
        with open(summary_path) as fh:
            lines = [line.rstrip("\n") for line in fh if line.strip()]
        summary = lines[-1] if lines else ""
    return dict(function=row["function"], returncode=proc.returncode,
                seconds=round(time.time() - started, 3), summary=summary,
                log=os.path.relpath(log, ROOT))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("--name", required=True)
    ap.add_argument("--iters", type=int, default=400)
    ap.add_argument("--targets", type=int, default=4,
                    help="number of functions searched concurrently")
    ap.add_argument("--jobs", type=int, default=8,
                    help="total compiler workers shared across targets")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--max-mut", type=int, default=2)
    ap.add_argument("--engine", choices=("random", "beam"), default="random")
    ap.add_argument("--rounds", type=int, default=3,
                    help="beam generations per target")
    ap.add_argument("--beam", type=int, default=10,
                    help="distinct machine outputs retained per generation")
    ap.add_argument("--samples", type=int, default=24,
                    help="stable mutation positions per family and parent")
    ap.add_argument("--plateau-rounds", type=int, default=2,
                    help="stop a beam target after this many unimproved generations")
    ap.add_argument("--pipeline", choices=("production", "raw-kmc", "asn64"),
                    default="production")
    ap.add_argument("--focus-max", type=int, default=2500)
    ap.add_argument("--stop-at-zero", action="store_true")
    args = ap.parse_args()
    rows = read_manifest(args.manifest)
    target_workers = max(1, min(args.targets, len(rows), args.jobs))
    workers_each = max(1, args.jobs // target_workers)
    outdir = os.path.join(ROOT, "build", "decomp_search", "batches", args.name)
    os.makedirs(outdir, exist_ok=True)
    print("portfolio: %d targets, %d concurrent, %d compiler workers each" %
          (len(rows), target_workers, workers_each), flush=True)
    jobs = [(row, args, outdir, workers_each) for row in rows]
    results = []
    with concurrent.futures.ThreadPoolExecutor(target_workers) as pool:
        for result in pool.map(run_target, jobs):
            results.append(result)
            print("%-24s rc=%d %6.1fs %s" %
                  (result["function"], result["returncode"], result["seconds"],
                   result["summary"]), flush=True)
    with open(os.path.join(outdir, "results.json"), "w") as fh:
        json.dump(results, fh, indent=2)
    with open(os.path.join(outdir, "results.tsv"), "w") as fh:
        fh.write("function\treturncode\tseconds\tsummary\tlog\n")
        for result in results:
            fh.write("{function}\t{returncode}\t{seconds}\t{summary}\t{log}\n".format(**result))
    if any(result["returncode"] for result in results):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
