#!/usr/bin/env python3
"""Validate the complete tool inventory and optionally refresh its reference."""

from __future__ import annotations

import argparse
from pathlib import Path

from decompkit.tool_inventory import load_inventory, render_markdown


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, default=Path("config/tooling_inventory.toml"))
    parser.add_argument("--tools", type=Path, default=Path("tools"))
    parser.add_argument("--write", type=Path)
    parser.add_argument("--check", type=Path)
    args = parser.parse_args()
    rendered = render_markdown(load_inventory(args.inventory), args.tools)
    if args.write and args.check:
        parser.error("--write and --check are mutually exclusive")
    if args.write:
        args.write.write_text(rendered)
    elif args.check:
        if not args.check.is_file() or args.check.read_text() != rendered:
            raise SystemExit(f"tool reference is stale; run --write {args.check}")
        print(f"Tool inventory and {args.check} are current")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
