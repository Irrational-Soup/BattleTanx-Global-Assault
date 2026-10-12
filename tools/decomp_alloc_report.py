#!/usr/bin/env python3
"""Report GCC 2.7.2 local/global register-allocation evidence.

This is deliberately an evidence extractor, not a cause classifier.  GCC 2.7.2's
``.greg`` dump is printed after reload, so assignments shown there must not be
described as a pre-reload snapshot.

Usage:
    tools/decomp_alloc_report.py SOURCE VRAM FUNCTION [--all] [--json]
"""

import argparse
import json

from decomp_compile import build
from decompkit.gcc_alloc import (
    allocation_rows, first_set, function_section, hard_name, parse_pre_reload,
)


def collect(source, vram, function, pre_reload_path=None):
    compiled = build(source, vram, focus=function, dumps=True)
    lreg = function_section(compiled["dumps"]["lreg"], function)
    greg = function_section(compiled["dumps"]["greg"], function)
    pre_reload = parse_pre_reload(pre_reload_path, function)
    parsed = allocation_rows(lreg, greg, pre_reload)
    rows = parsed["global"]
    local = parsed["local"]
    global_set = {row["pseudo"] for row in rows}
    return {
        "function": function,
        "source": source,
        "vram": f"0x{vram:08X}",
        "warning": ".greg is after reload in GCC 2.7.2",
        "global": rows,
        "local": [
            {
                "pseudo": pseudo,
                "hard": hard,
                "hard_name": hard_name(hard),
                "pre_reload_hard": (
                    pre_reload[pseudo]["hard"] if pseudo in pre_reload else None
                ),
                "pre_reload_hard_name": (
                    hard_name(pre_reload[pseudo]["hard"])
                    if pseudo in pre_reload and pre_reload[pseudo]["hard"] >= 0
                    else "MEM" if pseudo in pre_reload else None
                ),
                "first_set": first_set(lreg, pseudo),
            }
            for pseudo, hard in sorted(local.items())
        ],
        "pre_reload_other": [
            {
                "pseudo": pseudo,
                **item,
                "hard_name": hard_name(item["hard"]) if item["hard"] >= 0 else "MEM",
                "allocation_kind": (
                    "local" if pseudo in local else
                    "unallocated" if item["hard"] < 0 else "other"
                ),
                "first_set": first_set(lreg, pseudo),
            }
            for pseudo, item in sorted(pre_reload.items())
            if pseudo not in global_set
        ],
    }


def render(report, show_all):
    lines = [
        f"global_alloc order for {report['function']} ({len(report['global'])} allocnos)",
        "NOTE: .greg is after reload; this is not a pre-reload checkpoint.",
        f"{'rank':>4} {'reg':>5} {'refs':>5} {'live':>5} {'calls':>5} "
        f"{'priority':>10}  {'pre':<5} {'post':<5} {'reload':<6} first set",
    ]
    for row in report["global"]:
        lines.append(
            f"{row['rank']:4d} {row['pseudo']:5d} {row['refs']:5d} "
            f"{row['live']:5d} {row['calls']:5d} {row['priority']:10d}  "
            f"{(row['pre_reload_hard_name'] or '-'):5} {row['hard_name']:<5} "
            f"{('yes' if row['reload_changed_assignment'] else 'no'):<6} "
            f"{row['first_set']}"
        )
    if show_all:
        lines.append(
            "local-alloc placed: "
            + " ".join(f"{r['pseudo']}->{r['hard_name']}" for r in report["local"])
        )
        lines.append("pre-reload pseudos outside global_alloc order:")
        lines.append(
            f"{'reg':>5} {'kind':<11} {'hard':<5} {'refs':>5} {'live':>5} "
            f"{'calls':>5} first set"
        )
        for row in report["pre_reload_other"]:
            lines.append(
                f"{row['pseudo']:5d} {row['allocation_kind']:<11} "
                f"{row['hard_name']:<5} {row['refs']:5d} {row['live']:5d} "
                f"{row['calls']:5d} {row['first_set']}"
            )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("vram", type=lambda value: int(value, 0))
    parser.add_argument("function")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--pre-reload-log")
    args = parser.parse_args()
    report = collect(args.source, args.vram, args.function, args.pre_reload_log)
    print(json.dumps(report, indent=2) if args.json else render(report, args.all))


if __name__ == "__main__":
    main()
