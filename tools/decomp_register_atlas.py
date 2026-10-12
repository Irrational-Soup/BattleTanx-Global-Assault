#!/usr/bin/env python3
"""Exhaustively rank bounded register mappings between aligned instructions."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from decompkit.registers import exhaustive_register_maps, parse_instruction_rows


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
    parser.add_argument("--group", action="append", type=group, required=True)
    parser.add_argument("--limit", type=int, default=100_000)
    parser.add_argument("--keep", type=int, default=20)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    built = parse_instruction_rows(json.loads(args.built.read_text()))
    reference = parse_instruction_rows(json.loads(args.reference.read_text()))
    rows = exhaustive_register_maps(
        built, reference, args.group, limit=args.limit, keep=args.keep
    )
    payload = {
        "format": "decompkit-register-atlas-v1",
        "search_space": __import__("math").prod(
            __import__("math").factorial(len(sources)) for sources, _ in args.group
        ),
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
