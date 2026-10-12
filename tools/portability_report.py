#!/usr/bin/env python3
"""Inventory target-specific source that blocks or shapes a native port."""

from __future__ import annotations

import argparse
from pathlib import Path

from decompkit.portability import load_portability_config, render_json, render_markdown, scan_portability


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path("config/portability.toml"))
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--write", type=Path)
    parser.add_argument("--check", type=Path)
    args = parser.parse_args()
    if args.write and args.check:
        parser.error("--write and --check are mutually exclusive")
    config = load_portability_config(args.config)
    findings = scan_portability(config)
    rendered = render_markdown(config, findings) if args.format == "markdown" else render_json(config, findings)
    if args.write:
        args.write.write_text(rendered)
    elif args.check:
        if not args.check.is_file() or args.check.read_text() != rendered:
            raise SystemExit(f"portability report is stale; regenerate {args.check}")
        print(f"Portability inventory is current: {len(findings)} files with findings")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
