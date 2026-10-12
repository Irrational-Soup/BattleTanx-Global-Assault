#!/usr/bin/env python3
"""Narrow integration gate for selected reconstructed C translation units.

This compiles each named production source through the pipeline declared by
its allowlist, links it at its retail address, and compares the complete text
and owned rodata ranges with the base ROM.  It is intentionally independent of
the full-ROM build so a batch can be checked without rebuilding unrelated
translation units.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import decomp_compile  # noqa: E402
from decompkit.config import load_config  # noqa: E402
from decompkit.units import (  # noqa: E402
    UnitVerifier,
    load_owned_ranges,
    load_unit_catalogue,
)


DEFAULT_CONFIG = os.path.join(ROOT, "config", "decompkit.toml")


def catalogue(config_path=DEFAULT_CONFIG):
    return load_unit_catalogue(load_config(config_path))


def owned_rodata(config_path=DEFAULT_CONFIG):
    config = load_config(config_path)
    return load_owned_ranges(config.rodata)


def verify(unit, entry, rodata, config_path=DEFAULT_CONFIG):
    config = load_config(config_path)
    verifier = UnitVerifier(config, decomp_compile.build, decomp_compile.rom_bytes)
    return verifier.verify(unit, entry, rodata)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default=DEFAULT_CONFIG)
    parser.add_argument("units", nargs="+")
    args = parser.parse_args()
    entries = catalogue(args.config)
    rodata = owned_rodata(args.config)
    failed = False
    for unit in args.units:
        try:
            if unit not in entries:
                raise RuntimeError("unit is absent from a pipeline manifest")
            text_size, rodata_size = verify(
                unit, entries[unit], rodata, args.config
            )
            print("MATCH %-32s %-10s text=0x%X rodata=0x%X" %
                  (unit, entries[unit]["pipeline"], text_size, rodata_size))
        except Exception as exc:
            failed = True
            print("FAIL  %-32s %s" % (unit, exc), file=sys.stderr)
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
