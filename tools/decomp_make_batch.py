#!/usr/bin/env python3
"""Build a ranked decomp_batch manifest from prior TSV experiment inventories.

This turns accumulated lane evidence into reusable input instead of manually
choosing the same functions again. It keeps only functions still unmatched in
the current production report and chooses the lowest recorded mismatch for
each function.
"""
import argparse
import csv
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def first(row, names):
    for name in names:
        value = row.get(name, "").strip()
        if value:
            return value
    return ""


def current_unmatched():
    os.makedirs(os.path.join(ROOT, "build", "decomp_search"), exist_ok=True)
    fd, path = tempfile.mkstemp(
        dir=os.path.join(ROOT, "build", "decomp_search"), suffix=".json"
    )
    os.close(fd)
    try:
        subprocess.run(
            [sys.executable, os.path.join(ROOT, "tools", "generate_decomp_report.py"),
             "--output", path], cwd=ROOT, check=True, capture_output=True, text=True
        )
        with open(path) as fh:
            report = json.load(fh)
    finally:
        os.unlink(path)
    return {
        function["name"]
        for unit in report["units"]
        for function in unit.get("functions", [])
        if function["fuzzy_match_percent"] < 100.0
    }


def candidate_path(table, value):
    # Explanatory text often follows a path in parentheses or after whitespace.
    value = value.split(";", 1)[0].strip()
    match = re.search(r"([A-Za-z0-9_./-]+\.c)\b", value)
    if not match:
        return None
    path = match.group(1)
    if not os.path.isabs(path):
        base = os.path.dirname(table)
        choices = [os.path.join(base, path)]
        while base not in (ROOT, os.path.dirname(base)):
            base = os.path.dirname(base)
            choices.append(os.path.join(base, path))
        path = next((choice for choice in choices if os.path.isfile(choice)), choices[0])
    return os.path.normpath(path) if os.path.isfile(path) else None


def infer_unit_vram(source, fallback, catalogue):
    """Use the earliest catalogue function defined by a multi-function candidate."""
    with open(source, errors="ignore") as fh:
        text = fh.read()
    definitions = set(re.findall(
        r"(?m)^\s*[A-Za-z_][\w \t*]*?\s+([A-Za-z_]\w*)\s*"
        r"\([^;{}]*\)\s*\{", text
    ))
    addresses = [catalogue[name][0] for name in definitions if name in catalogue]
    return "%08X" % min(addresses) if addresses else fallback


def read_tables(patterns, unmatched):
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import decomp_compile
    catalogue = decomp_compile.catalogue()
    best = {}
    tables = []
    for pattern in patterns:
        hits = glob.glob(pattern, recursive=True)
        tables.extend(hits or ([pattern] if os.path.isfile(pattern) else []))
    for table in sorted(set(tables)):
        if os.path.basename(table) == "summary.tsv":
            with open(table, newline="") as fh:
                for row in csv.reader(fh, delimiter="\t"):
                    if not row or row[0].startswith("#") or len(row) < 6:
                        continue
                    function, source = row[0].strip(), row[1].strip()
                    if function not in unmatched or not os.path.isfile(source):
                        continue
                    match = re.search(r"\d+", row[4])
                    words = int(match.group()) if match else 10**9
                    address = re.search(r"([0-9A-Fa-f]{8})", function)
                    if not address:
                        continue
                    vram = address.group(1)
                    unit = infer_unit_vram(source, vram, catalogue)
                    record = (words, source, function, vram, unit, table)
                    if function not in best or record[:2] < best[function][:2]:
                        best[function] = record
            continue
        with open(table, newline="") as fh:
            reader = csv.DictReader(fh, delimiter="\t")
            if not reader.fieldnames:
                continue
            for row in reader:
                function = first(row, ("function", "func"))
                if function not in unmatched:
                    continue
                source = candidate_path(
                    table, first(row, ("best_candidate", "best_source",
                                       "candidate_or_evidence", "candidate",
                                       "prior_best_draft"))
                )
                if not source:
                    continue
                words_text = first(row, ("mismatch_words", "words", "word_diff"))
                match = re.search(r"\d+", words_text)
                words = int(match.group()) if match else 10**9
                vram = first(row, ("vram", "address")).removeprefix("0x")
                if not vram:
                    match = re.search(r"([0-9A-Fa-f]{8})", function)
                    if not match:
                        continue
                    vram = match.group(1)
                unit = first(row, ("unit", "unit_group", "unit_vram"))
                unit = unit.removeprefix("0x") if re.fullmatch(
                    r"(?:0x)?[0-9A-Fa-f]{6,8}", unit
                ) else vram
                unit = infer_unit_vram(source, unit, catalogue)
                record = (words, source, function, vram, unit, table)
                if function not in best or record[:2] < best[function][:2]:
                    best[function] = record
    return sorted(best.values(), key=lambda row: (row[0], int(row[3], 16)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tables", nargs="+", help="TSV paths or recursive glob patterns")
    ap.add_argument("--output", required=True)
    ap.add_argument("--limit", type=int, default=20)
    ap.add_argument("--mutations", default="commute,swap_decls,decl_init,split_assign,copy_temp,move_decl,move_decl_out")
    args = ap.parse_args()
    rows = read_tables(args.tables, current_unmatched())[:args.limit]
    with open(args.output, "w") as fh:
        fh.write("source\tfunction\tvram\tunit_vram\tmutations\tfocus\n")
        for words, source, function, vram, unit, _ in rows:
            fh.write("%s\t%s\t%s\t%s\t%s\t\n" %
                     (os.path.relpath(source, ROOT), function, vram, unit,
                      args.mutations))
    print("wrote %d ranked targets to %s" % (len(rows), args.output))
    for words, _, function, _, _, table in rows:
        print("%4s  %-24s %s" %
              ("?" if words == 10**9 else words, function,
               os.path.relpath(table, ROOT)))


if __name__ == "__main__":
    main()
