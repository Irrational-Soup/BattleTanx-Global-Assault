#!/usr/bin/env python3
"""Narrow integration gate for selected reconstructed C translation units.

This compiles each named production source through the pipeline declared by
its allowlist, links it at its retail address, and compares the complete text
and owned rodata ranges with the base ROM.  It is intentionally independent of
the full-ROM build so a batch can be checked without rebuilding unrelated
translation units.
"""
import argparse
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import decomp_compile  # noqa: E402


MANIFESTS = (
    ("config/us/clean_normalized_units.tsv", "production"),
    ("config/us/asn64_units.tsv", "asn64"),
    ("config/us/normalizer_assisted_units.tsv", "production"),
)


def rows(path):
    with open(os.path.join(ROOT, path), newline="") as fh:
        lines = [line.rstrip("\n") for line in fh if line.strip()]
    header = [field.lstrip("# ") for field in lines[0].split("\t")]
    for line in lines[1:]:
        if line.startswith("#"):
            continue
        values = line.split("\t")
        yield dict(zip(header, values))


def catalogue():
    result = {}
    for path, pipeline in MANIFESTS:
        for row in rows(path):
            row = dict(row)
            row["pipeline"] = pipeline
            row["manifest"] = path
            result[row["unit"]] = row
    return result


def owned_rodata():
    result = {}
    for row in rows("config/us/unit_rodata.tsv"):
        result[row["unit"]] = (int(row["rodata_vram"], 16),
                               int(row["rodata_size"], 16))
    return result


def verify(unit, entry, rodata):
    source = os.path.join(ROOT, "src", "code", unit + ".c")
    if not os.path.isfile(source):
        raise RuntimeError("missing production source: " + source)
    vram = int(entry["vram"], 16)
    text_size = int(entry["text_size"], 16)
    built = decomp_compile.build(source, vram, pipeline=entry["pipeline"])
    actual = built["text"][:text_size]
    expected = decomp_compile.rom_bytes(vram, text_size)
    errors = []
    if built["tsz"] != text_size:
        errors.append("text size built=0x%X expected=0x%X" %
                      (built["tsz"], text_size))
    if actual != expected:
        words = sum(a != b for a, b in zip(
            [actual[i:i + 4] for i in range(0, len(actual), 4)],
            [expected[i:i + 4] for i in range(0, len(expected), 4)]))
        errors.append("text differs (%d positional words)" % words)
    if unit in rodata:
        address, size = rodata[unit]
        emitted = built.get("rodata") or b""
        if len(emitted) < size:
            errors.append("rodata short built=0x%X expected=0x%X" %
                          (len(emitted), size))
        elif emitted[:size] != decomp_compile.rom_bytes(address, size):
            errors.append("rodata differs at 0x%08X+0x%X" % (address, size))
        if any(emitted[size:]):
            errors.append("nonzero unowned rodata tail (0x%X bytes)" %
                          (len(emitted) - size))
        if built.get("rodata_vram") != address:
            errors.append("RODATA_VRAM marker is %r, expected 0x%08X" %
                          (built.get("rodata_vram"), address))
    elif built.get("rodata"):
        errors.append("emits rodata but has no unit_rodata.tsv row")
    if errors:
        raise RuntimeError("; ".join(errors))
    return text_size, rodata.get(unit, (0, 0))[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("units", nargs="+")
    args = parser.parse_args()
    entries = catalogue()
    rodata = owned_rodata()
    failed = False
    for unit in args.units:
        try:
            if unit not in entries:
                raise RuntimeError("unit is absent from a pipeline manifest")
            text_size, rodata_size = verify(unit, entries[unit], rodata)
            print("MATCH %-32s %-10s text=0x%X rodata=0x%X" %
                  (unit, entries[unit]["pipeline"], text_size, rodata_size))
        except Exception as exc:
            failed = True
            print("FAIL  %-32s %s" % (unit, exc), file=sys.stderr)
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
