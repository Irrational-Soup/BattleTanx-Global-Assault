#!/usr/bin/env python3
"""Exhaustively rank bounded register mappings between aligned instructions."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from decompkit.registers import (
    exhaustive_register_maps,
    parse_instruction_rows,
    single_register_swaps,
)


def group(value: str) -> tuple[list[str], list[str]]:
    try:
        left, right = value.split("=", 1)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("group must be SRC,...=DST,...") from exc
    sources = [item for item in left.split(",") if item]
    targets = [item for item in right.split(",") if item]
    if not sources or len(sources) != len(targets):
        raise argparse.ArgumentTypeError("group sides must be non-empty and equally sized")
    return sources, targets


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("built", type=Path)
    parser.add_argument("reference", type=Path)
    parser.add_argument("--group", action="append", type=group)
    parser.add_argument(
        "--single-swaps",
        action="store_true",
        help="score identity and every one-pair swap in each --group",
    )
    parser.add_argument(
        "--improving-only",
        action="store_true",
        help="with --single-swaps, omit swaps that do not beat identity",
    )
    parser.add_argument("--limit", type=int, default=100_000)
    parser.add_argument("--keep", type=int, default=20)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    built = parse_instruction_rows(json.loads(args.built.read_text()))
    reference = parse_instruction_rows(json.loads(args.reference.read_text()))
    if not args.group:
        parser.error("at least one --group is required")
    if args.single_swaps:
        rows = single_register_swaps(
            built,
            reference,
            [sources for sources, _ in args.group],
            keep=args.keep,
            improving_only=args.improving_only,
        )
        search_space = 1 + sum(
            len(sources) * (len(sources) - 1) // 2 for sources, _ in args.group
        )
        mode = "single-swaps"
    else:
        rows = exhaustive_register_maps(
            built, reference, args.group, limit=args.limit, keep=args.keep
        )
        search_space = __import__("math").prod(
            __import__("math").factorial(len(sources)) for sources, _ in args.group
        )
        mode = "permutations"
    payload = {
        "format": "decompkit-register-atlas-v1",
        "mode": mode,
        "search_space": search_space,
        "results": [
            {"mismatches": row.mismatches, "mapping": row.mapping} for row in rows
        ],
    }
    rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(rendered)
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
