#!/usr/bin/env python3
"""Classify Splat asm/hasm rows as code, data, padding, or microcode."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from decompkit.assembly import category_totals, inventory_assembly


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--splat", type=Path, required=True)
    parser.add_argument("--asm-root", type=Path, required=True)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()
    segments = inventory_assembly(args.splat, args.asm_root)
    payload = {
        "format": "decompkit-assembly-inventory-v1",
        "totals": {
            key: {"rows": value[0], "known_bytes": value[1]}
            for key, value in sorted(category_totals(segments).items())
        },
        "segments": [
            {
                "start": f"0x{row.start:X}",
                "end": None if row.end is None else f"0x{row.end:X}",
                "size": row.size,
                "type": row.kind,
                "name": row.name,
                "path": str(row.path),
                "category": row.category,
                "glabels": row.glabels,
                "dlabels": row.dlabels,
                "instructions": row.instructions,
                "words": row.words,
                "zero_words": row.zero_words,
            }
            for row in segments
        ],
    }
    rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.json:
        args.json.write_text(rendered)
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
