#!/usr/bin/env python3
"""Verify units using decompkit's portable subprocess adapter protocol."""

from __future__ import annotations

import argparse
import shlex
from pathlib import Path

from decompkit.adapters import CommandBuildAdapter, ImageReference
from decompkit.config import load_config
from decompkit.units import UnitVerifier, load_owned_ranges, load_unit_catalogue


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument(
        "--adapter-command", required=True,
        help="argv parsed with shlex; include literal {request} and {response} entries",
    )
    parser.add_argument("units", nargs="*")
    args = parser.parse_args()
    config = load_config(args.config)
    catalogue = load_unit_catalogue(config)
    selected = args.units or sorted(catalogue)
    unknown = sorted(set(selected) - set(catalogue))
    if unknown:
        parser.error("unknown units: " + ", ".join(unknown))
    build = CommandBuildAdapter(shlex.split(args.adapter_command), cwd=config.root)
    reference = ImageReference(args.reference, lambda address: address - config.vram_delta)
    verifier = UnitVerifier(config, build, reference)
    rodata = load_owned_ranges(config.rodata)
    total_text = total_rodata = 0
    for unit in selected:
        text, owned = verifier.verify(unit, catalogue[unit], rodata)
        total_text += text
        total_rodata += owned
        print(f"PASS {unit}: text=0x{text:X} rodata=0x{owned:X}")
    print(f"Verified {len(selected)} units: text=0x{total_text:X} rodata=0x{total_rodata:X}")


if __name__ == "__main__":
    main()
