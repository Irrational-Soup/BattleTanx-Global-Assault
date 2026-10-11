#!/usr/bin/env python3
"""Regenerate and gate fresh m2c drafts for unscorable worklist targets.

Generated drafts stay below build/decomp_search.  This is a bootstrap tool,
not a matching claim: a draft enters the measured corpus only when KMC GCC can
compile it and decomp_score can compare its nonempty retail span.
"""
import argparse
import csv
import glob
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import decomp_compile  # noqa: E402
import decomp_score  # noqa: E402


def asm_candidates(function):
    needle = "glabel " + function
    hits = []
    for path in glob.glob(os.path.join(ROOT, "asm", "us", "*.s")):
        with open(path, errors="ignore") as fh:
            if needle in fh.read():
                hits.append(path)
    # Split files with the narrowest owned range are generally the current
    # production span and avoid feeding unrelated functions to m2c.
    return sorted(hits, key=lambda p: (os.path.getsize(p), p))


def error_targets(worklist):
    with open(worklist, newline="") as fh:
        return [row for row in csv.DictReader(fh, delimiter="\t")
                if row["status"] == "ERROR"]


def add_missing_jump_labels(asm, extra_asm, outdir):
    """Give m2c names for jump-table targets that are fall-through blocks.

    Splat's disassembly does not label every address named by a separately
    reconstructed rodata table.  m2c requires those labels in the text input.
    This creates a generated analysis-only copy; production assembly is never
    modified.
    """
    targets = set()
    for path in extra_asm:
        with open(path, errors="ignore") as fh:
            targets.update(re.findall(r"^\.word\s+(?:func_|\.L)([0-9A-Fa-f]{8})\s*$",
                                      fh.read(), re.MULTILINE))
    delay_workarounds = set()
    workaround_path = os.path.join(outdir, "delay_slot_nop_before.txt")
    if os.path.isfile(workaround_path):
        with open(workaround_path) as fh:
            delay_workarounds.update(line.strip() for line in fh
                                     if line.strip() and not line.startswith("#"))
    if not targets and not delay_workarounds:
        return asm
    with open(asm, errors="ignore") as fh:
        lines = fh.readlines()
    present = set(re.findall(r"^\s*(?:func_|\.L)([0-9A-Fa-f]{8}):", "".join(lines),
                             re.MULTILINE))
    missing = targets - present
    output = []
    found = set()
    for line in lines:
        label_match = re.match(r"^\s*([.$A-Za-z_][\w.$]*):", line)
        if label_match and label_match.group(1) in delay_workarounds:
            output.append("    nop  /* analysis-only delay-slot workaround */\n")
        match = re.search(r"/\*\s+[0-9A-Fa-f]+\s+([0-9A-Fa-f]{8})\s+", line)
        if match and match.group(1) in missing:
            output.append(".L%s:\n" % match.group(1).upper())
            found.add(match.group(1))
        output.append(line)
    unresolved = missing - found
    if unresolved:
        raise RuntimeError("jump targets absent from text: " + ", ".join(sorted(unresolved)))
    labels = set(re.findall(r"^\s*([.$A-Za-z_][\w.$]*):", "".join(lines),
                            re.MULTILINE))
    unresolved_workarounds = delay_workarounds - labels
    if unresolved_workarounds:
        raise RuntimeError("delay-slot labels absent from text: " +
                           ", ".join(sorted(unresolved_workarounds)))
    generated = os.path.join(outdir, "_m2c_input.s")
    with open(generated, "w") as fh:
        fh.writelines(output)
    return generated


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("worklist")
    ap.add_argument("--m2c", required=True, help="path to pinned m2c.py")
    ap.add_argument("--output", required=True)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    m2c = os.path.realpath(args.m2c)
    macros = os.path.join(os.path.dirname(m2c), "m2c_macros.h")
    if not os.path.isfile(m2c) or not os.path.isfile(macros):
        ap.error("m2c.py and m2c_macros.h must exist together")
    os.makedirs(args.output, exist_ok=True)
    rows = []
    for index, target in enumerate(error_targets(args.worklist)):
        if args.limit and index >= args.limit:
            break
        function = target["function"]
        spans = asm_candidates(function)
        outdir = os.path.join(args.output, function)
        os.makedirs(outdir, exist_ok=True)
        result = {"function": function, "status": "ERROR", "asm": ""}
        try:
            if not spans:
                raise RuntimeError("no assembly span contains " + function)
            asm = spans[0]
            result["asm"] = os.path.relpath(asm, ROOT)
            extra_asm = sorted(glob.glob(os.path.join(outdir, "jump*.s")))
            m2c_asm = add_missing_jump_labels(asm, extra_asm, outdir)
            proc = subprocess.run([
                sys.executable, m2c, "-t", "mips-gcc-c", "--valid-syntax",
                "--deterministic-vars", "--globals", "used", "-f", function,
                m2c_asm, *extra_asm,
            ], cwd=ROOT, capture_output=True, text=True)
            if proc.returncode:
                raise RuntimeError("m2c failed:\n" + proc.stdout + proc.stderr)
            candidate = os.path.join(outdir, "candidate.c")
            with open(candidate, "w") as fh:
                fh.write('#include "types.h"\n#include "m2c_macros.h"\n\n')
                fh.write(proc.stdout)
            shutil.copyfile(macros, os.path.join(outdir, "m2c_macros.h"))
            vram = int(target["vram"], 16)
            built = decomp_compile.build(candidate, vram, focus=function,
                                           pipeline="production")
            classified = decomp_score.classify(built, function)
            result.update(status="DIFF" if classified["words"] else "MATCH",
                          words=classified["words"], diagnosis="generated_baseline",
                          candidate=os.path.relpath(candidate, ROOT),
                          comparison=classified)
        except Exception as exc:
            result["error"] = "%s: %s" % (type(exc).__name__, exc)
        path = os.path.join(outdir, "result.json")
        with open(path, "w") as fh:
            json.dump(result, fh, indent=2, sort_keys=True)
        rows.append((function, result["status"], result.get("words", ""),
                     result["asm"], os.path.relpath(path, ROOT)))
        print("%-24s %-5s %-6s %s" % rows[-1][:-1], flush=True)
    with open(os.path.join(args.output, "summary.tsv"), "w") as fh:
        fh.write("function\tstatus\twords\tasm\tresult\n")
        for row in rows:
            fh.write("\t".join(map(str, row)) + "\n")


if __name__ == "__main__":
    main()
