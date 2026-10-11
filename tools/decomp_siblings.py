#!/usr/bin/env python3
"""Rank already reconstructed functions as structural references for targets.

Similarity is computed from ROM instruction mnemonic n-grams, so register names
and addresses do not dominate retrieval.  Exact bytes remain the only matching
gate; this tool only chooses examples for source/type/control-flow hypotheses.
"""
import argparse
import collections
import csv
import json
import math
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import decomp_compile as compilelib  # noqa: E402


def current_report():
    fd, path = tempfile.mkstemp(dir=os.path.join(ROOT, "build"), suffix=".json")
    os.close(fd)
    try:
        subprocess.run([sys.executable, os.path.join(HERE, "generate_decomp_report.py"),
                        "--output", path], cwd=ROOT, check=True,
                       capture_output=True, text=True)
        with open(path) as fh:
            return json.load(fh)
    finally:
        os.unlink(path)


def matched_names(report):
    return {f["name"] for unit in report["units"] for f in unit.get("functions", [])
            if f.get("fuzzy_match_percent") == 100.0}


def features(name, catalogue, cache, ngram=3):
    if name in cache:
        return cache[name]
    address, size = catalogue[name]
    ins = compilelib.disasm(compilelib.rom_bytes(address, size), address)
    mn = [row[2] for row in ins]
    grams = collections.Counter(tuple(mn[i:i + ngram])
                                for i in range(max(0, len(mn) - ngram + 1)))
    # Short routines may have no 3-grams; instruction counts remain useful.
    if not grams:
        grams = collections.Counter((op,) for op in mn)
    cache[name] = (grams, len(mn))
    return cache[name]


def similarity(a, b):
    af, an = a; bf, bn = b
    overlap = sum((af & bf).values())
    union = sum((af | bf).values()) or 1
    jaccard = overlap / union
    length = min(an, bn) / max(an, bn, 1)
    return jaccard * math.sqrt(length)


def rank(target, candidates, catalogue, cache, limit):
    tf = features(target, catalogue, cache)
    rows = []
    ta, ts = catalogue[target]
    for candidate in candidates:
        if candidate == target or candidate not in catalogue:
            continue
        score = similarity(tf, features(candidate, catalogue, cache))
        if score <= 0:
            continue
        ca, cs = catalogue[candidate]
        rows.append((score, candidate, ca, cs, abs(ca - ta)))
    return sorted(rows, key=lambda r: (-r[0], r[4], r[1]))[:limit]


def targets_from_manifest(path):
    with open(path, newline="") as fh:
        return [row["function"] for row in csv.DictReader(fh, delimiter="\t")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("--output", required=True)
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--ngram", type=int, default=3)
    args = ap.parse_args()
    catalogue = compilelib.catalogue()
    matched = matched_names(current_report())
    cache = {}
    rows = []
    for target in targets_from_manifest(args.manifest):
        if target not in catalogue:
            continue
        for index, (score, sibling, address, size, distance) in enumerate(
                rank(target, matched, catalogue, cache, args.limit), 1):
            rows.append((target, index, "%.6f" % score, sibling,
                         "0x%08X" % address, "0x%X" % size, "0x%X" % distance))
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w", newline="") as fh:
        writer = csv.writer(fh, delimiter="\t", lineterminator="\n")
        writer.writerow(("target", "rank", "score", "sibling", "vram", "size", "distance"))
        writer.writerows(rows)
    print("wrote %d sibling references for %d targets to %s" %
          (len(rows), len(set(r[0] for r in rows)), args.output))


if __name__ == "__main__":
    main()
