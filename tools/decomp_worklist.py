#!/usr/bin/env python3
"""Combine context diagnoses and sibling retrieval into an explicit work ledger."""
import argparse
import csv
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import decomp_compile  # noqa: E402


NEXT = {
    "source_structure": "reconstruct CFG/types using matched siblings; do not permute",
    "instruction_selection_or_types": "audit field widths, signedness, casts and packed layout",
    "stack_layout_or_lifetime": "capture RTL allocation stages; test scope/lifetime hypotheses",
    "control_flow_or_calls": "audit branch/call structure and observable call effects",
    "linking_rodata_or_ownership": "resolve TU ownership, constants, relocations and alignment",
    "register_allocation": "compare allocation RTL with matched corpus; then bounded lifetime search",
    "instruction_scheduling": "compare scheduler RTL and assembler output separately",
    "mixed_codegen": "capture RTL stages and isolate the first divergent compiler pass",
    "infrastructure": "repair or replace the non-building draft before scoring",
    "exact": "run whole-unit narrow gate and queue integration",
}


def load_siblings(path):
    result = {}
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            result.setdefault(row["target"], []).append(row)
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("contexts", help="directory written by decomp_context.py")
    ap.add_argument("siblings")
    ap.add_argument("--alternate-contexts",
                    help="optional second context directory (for example ASN64)")
    ap.add_argument("--output", required=True)
    args = ap.parse_args()
    siblings = load_siblings(args.siblings)
    alternate = {}
    if args.alternate_contexts:
        alt_summary = os.path.join(args.alternate_contexts, "summary.tsv")
        with open(alt_summary, newline="") as fh:
            alternate = {row["function"]: row for row in csv.DictReader(fh, delimiter="\t")}
    catalogue = decomp_compile.catalogue()
    summary_path = os.path.join(args.contexts, "summary.tsv")
    with open(summary_path, newline="") as fh:
        summary = list(csv.DictReader(fh, delimiter="\t"))
    rows = []
    for item in summary:
        path = item["result"]
        if not os.path.isabs(path):
            path = os.path.join(ROOT, path)
        with open(path) as fh:
            detail = json.load(fh)
        function = item["function"]
        address, size = catalogue[function]
        sib = siblings.get(function, [])
        context = detail.get("context", {})
        alt = alternate.get(function, {})
        words = int(item["words"]) if item["words"] else None
        alt_words = int(alt["words"]) if alt.get("words") else None
        if words is None or alt_words is None:
            pipeline_effect = "unknown"
        elif alt_words < words:
            pipeline_effect = "alternate_better:%d" % (words - alt_words)
        elif alt_words > words:
            pipeline_effect = "production_better:%d" % (alt_words - words)
        else:
            pipeline_effect = "same"
        rows.append({
            "function": function, "vram": "0x%08X" % address,
            "bytes": size, "status": item["status"], "words": item["words"],
            "diagnosis": item["diagnosis"],
            "alternate_words": "" if alt_words is None else alt_words,
            "pipeline_effect": pipeline_effect,
            "next_action": NEXT.get(item["diagnosis"], NEXT["mixed_codegen"]),
            "candidate": context.get("source", ""),
            "context_id": context.get("context_id", ""),
            "sibling_1": sib[0]["sibling"] if sib else "",
            "sibling_score_1": sib[0]["score"] if sib else "",
            "sibling_2": sib[1]["sibling"] if len(sib) > 1 else "",
            "sibling_score_2": sib[1]["score"] if len(sib) > 1 else "",
        })
    rows.sort(key=lambda r: (-r["bytes"], r["function"]))
    fields = tuple(rows[0])
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fields, delimiter="\t", lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)
    print("wrote %d targets / %d bytes to %s" %
          (len(rows), sum(r["bytes"] for r in rows), args.output))


if __name__ == "__main__":
    main()
