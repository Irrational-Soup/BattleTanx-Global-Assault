#!/usr/bin/env python3
"""Enforce address-prefixed descriptive names without forcing a mass rename."""

from __future__ import annotations

import argparse
from pathlib import Path

from decompkit.source_names import audit_source_names, load_naming_policy, render_legacy


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path("config/source_naming.toml"))
    parser.add_argument("--write-baseline", action="store_true")
    args = parser.parse_args()
    policy = load_naming_policy(args.config)
    if args.write_baseline:
        policy.legacy.write_text(render_legacy(policy))
    audit = audit_source_names(policy)
    if not audit.clean:
        for label, rows in (
            ("new nonconforming source", audit.violations),
            ("stale legacy row", audit.stale_legacy),
            ("address mismatch", audit.address_mismatches),
        ):
            for row in rows:
                print(f"{label}: {row}")
        raise SystemExit(1)
    print(
        f"Source naming policy passed: {len(audit.preferred)} preferred/exempt, "
        f"{len(audit.legacy)} frozen legacy"
    )


if __name__ == "__main__":
    main()
