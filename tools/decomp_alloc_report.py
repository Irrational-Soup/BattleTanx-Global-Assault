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
import math
import re

from decomp_compile import build


HARD_NAMES = (
    "zero at v0 v1 a0 a1 a2 a3 t0 t1 t2 t3 t4 t5 t6 t7 "
    "s0 s1 s2 s3 s4 s5 s6 s7 t8 t9 k0 k1 gp sp s8 ra"
).split() + [f"f{i}" for i in range(32)]


def hard_name(number):
    return HARD_NAMES[number] if number < len(HARD_NAMES) else f"hr{number}"


def function_section(text, function):
    parts = re.split(r"(?m)^;; Function (\S+)\s*$", text)
    for index in range(1, len(parts), 2):
        if parts[index] == function:
            return parts[index + 1]
    raise ValueError(f"function {function!r} is absent from compiler dump")


def register_stats(text):
    result = {}
    pattern = r"(?m)^Register (\d+) used (\d+) times across (\d+) insns(.*)$"
    for match in re.finditer(pattern, text):
        tail = match.group(4)
        calls = re.search(r"crosses (\d+) call", tail)
        width = re.search(r"(\d+) bytes", tail)
        result[int(match.group(1))] = {
            "refs": int(match.group(2)),
            "live": int(match.group(3)),
            "calls": int(calls.group(1)) if calls else 0,
            "size_words": max(1, (int(width.group(1)) + 3) // 4) if width else 1,
            "local": "in block" in tail,
            "description": tail.strip("; ."),
        }
    return result


def first_set(text, pseudo):
    match = re.search(
        rf"\(set \(reg(?:/\w+)*:\w+ {pseudo}\)\s*\n?\s*(.{{0,120}})", text
    )
    return re.sub(r"\s+", " ", match.group(1)).strip() if match else ""


def parse_pre_reload(path, function):
    if not path:
        return {}
    result = {}
    pattern = re.compile(
        r"^PRE_RELOAD_REG function=(\S+) pseudo=(\d+) hard=(-?\d+) "
        r"allocno=(-?\d+) refs=(-?\d+) live=(-?\d+) calls=(-?\d+)$"
    )
    with open(path) as trace:
        for line in trace:
            match = pattern.match(line.rstrip())
            if not match or match.group(1) != function:
                continue
            pseudo = int(match.group(2))
            result[pseudo] = {
                "hard": int(match.group(3)),
                "allocno": int(match.group(4)),
                "refs": int(match.group(5)),
                "live": int(match.group(6)),
                "calls": int(match.group(7)),
            }
    return result


def collect(source, vram, function, pre_reload_path=None):
    compiled = build(source, vram, focus=function, dumps=True)
    lreg = function_section(compiled["dumps"]["lreg"], function)
    greg = function_section(compiled["dumps"]["greg"], function)
    stats = register_stats(lreg)

    order_match = re.search(r";; (\d+) regs to allocate:([ \d]*)", greg)
    order = [int(value) for value in order_match.group(2).split()] if order_match else []

    dispositions = {}
    marker = ";; Register dispositions:"
    if marker in greg:
        body = greg.split(marker, 1)[1].split(";; Hard regs used", 1)[0]
        dispositions = {int(p): int(h) for p, h in re.findall(r"(\d+) in (\d+)", body)}

    local = {
        int(p): int(h)
        for p, h in re.findall(r";; Register (\d+) in (\d+)\.", lreg)
    }

    pre_reload = parse_pre_reload(pre_reload_path, function)
    global_set = set(order)
    rows = []
    for rank, pseudo in enumerate(order):
        item = stats.get(
            pseudo,
            {"refs": 0, "live": 1, "calls": 0, "size_words": 1,
             "local": False, "description": ""},
        )
        refs = item["refs"]
        priority = (
            math.floor(math.log2(refs)) * refs / item["live"] * 10000
            * item["size_words"]
            if refs else 0
        )
        pre = pre_reload.get(pseudo)
        rows.append({
            "rank": rank,
            "pseudo": pseudo,
            **item,
            "priority": round(priority),
            "hard": dispositions.get(pseudo),
            "hard_name": hard_name(dispositions[pseudo]) if pseudo in dispositions else "MEM",
            "pre_reload_hard": pre["hard"] if pre else None,
            "pre_reload_hard_name": (
                hard_name(pre["hard"]) if pre and pre["hard"] >= 0 else
                "MEM" if pre else None
            ),
            "reload_changed_assignment": (
                pre is not None and pre["hard"] != dispositions.get(pseudo, -1)
            ),
            "first_set": first_set(lreg, pseudo),
        })
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
