"""Toolchain-neutral narrow verification of reconstructed units."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from .config import ProjectConfig
from .tables import parse_owned_ranges, read_tsv


def load_unit_catalogue(config: ProjectConfig) -> dict[str, dict[str, str]]:
    result = {}
    for path, pipeline in config.unit_manifests:
        for source_row in read_tsv(path):
            row = dict(source_row, pipeline=pipeline, manifest=str(path))
            unit = row["unit"]
            if unit in result:
                raise ValueError(f"unit {unit!r} occurs in multiple pipeline manifests")
            result[unit] = row
    return result


def load_owned_ranges(path: str | Path) -> dict[str, tuple[int, int]]:
    return {
        item["unit"]: (item["address"], item["size"])
        for item in parse_owned_ranges([path])
    }


@dataclass
class UnitVerifier:
    """Verify units using project-supplied compiler and reference-byte hooks."""

    config: ProjectConfig
    build: Callable
    reference_bytes: Callable[[int, int], bytes]

    def verify(self, unit: str, entry: dict, rodata: dict[str, tuple[int, int]]) -> tuple[int, int]:
        source = self.config.source_dir / f"{unit}.c"
        if not source.is_file():
            raise RuntimeError(f"missing production source: {source}")
        vram = int(entry["vram"], 0)
        text_size = int(entry["text_size"], 0)
        built = self.build(str(source), vram, pipeline=entry["pipeline"])
        errors = []
        if built["tsz"] != text_size:
            errors.append(
                f"text size built=0x{built['tsz']:X} expected=0x{text_size:X}"
            )
        actual = built["text"][:text_size]
        expected = self.reference_bytes(vram, text_size)
        if actual != expected:
            words = sum(
                actual[index:index + 4] != expected[index:index + 4]
                for index in range(0, min(len(actual), len(expected)), 4)
            )
            errors.append(f"text differs ({words} positional words)")

        if unit in rodata:
            address, size = rodata[unit]
            emitted = built.get("rodata") or b""
            if len(emitted) < size:
                errors.append(f"rodata short built=0x{len(emitted):X} expected=0x{size:X}")
            elif emitted[:size] != self.reference_bytes(address, size):
                errors.append(f"rodata differs at 0x{address:08X}+0x{size:X}")
            if any(emitted[size:]):
                errors.append(f"nonzero unowned rodata tail (0x{len(emitted) - size:X} bytes)")
            if built.get("rodata_vram") != address:
                errors.append(
                    f"RODATA_VRAM marker is {built.get('rodata_vram')!r}, expected 0x{address:08X}"
                )
        elif built.get("rodata"):
            errors.append("emits rodata but has no ownership row")
        if errors:
            raise RuntimeError("; ".join(errors))
        return text_size, rodata.get(unit, (0, 0))[1]
