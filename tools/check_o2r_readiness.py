#!/usr/bin/env python3
"""Validate and report the project's honest O2R migration readiness."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from decompkit.o2r import load_readiness, readiness_summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", nargs="?", type=Path,
                        default=Path("config/o2r_resources.toml"))
    parser.add_argument("--json", type=Path)
    args = parser.parse_args()
    resources = load_readiness(args.manifest)
    payload = {"format": "decompkit-o2r-readiness-v1",
               "summary": readiness_summary(resources),
               "resources": [resource.__dict__ for resource in resources]}
    rendered = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(rendered)
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
