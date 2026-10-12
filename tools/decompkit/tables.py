"""Strict readers for the small TSV inventories used by decomp projects."""

from __future__ import annotations

import csv
from pathlib import Path


def read_tsv(path: str | Path) -> list[dict[str, str]]:
    path = Path(path)
    lines = [line for line in path.read_text().splitlines() if line.strip()]
    if not lines:
        raise ValueError(f"{path}: empty table")
    header = [field.lstrip("# ") for field in lines[0].split("\t")]
    rows = []
    for number, line in enumerate(lines[1:], 2):
        if line.startswith("#"):
            continue
        values = next(csv.reader([line], delimiter="\t"))
        if len(values) != len(header):
            raise ValueError(
                f"{path}:{number}: expected {len(header)} fields, got {len(values)}"
            )
        rows.append(dict(zip(header, values)))
    return rows


def parse_owned_ranges(paths: list[str | Path]) -> list[dict]:
    ranges = []
    for raw_path in paths:
        path = Path(raw_path)
        section = ".rodata" if "rodata" in path.name else ".data"
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if not line or line.startswith("#"):
                continue
            try:
                unit, address_text, size_text = line.split("\t")
                address, size = int(address_text, 0), int(size_text, 0)
            except (ValueError, TypeError) as error:
                raise ValueError(f"{path}:{number}: invalid ownership row") from error
            if size <= 0:
                raise ValueError(f"{path}:{number}: size must be positive")
            ranges.append(
                dict(unit=unit, address=address, end=address + size, size=size,
                     section=section, source=path)
            )
    ranges.sort(key=lambda item: item["address"])
    for left, right in zip(ranges, ranges[1:]):
        if right["address"] < left["end"]:
            raise ValueError(
                f"owned ranges overlap: {left['unit']} and {right['unit']}"
            )
    return ranges
