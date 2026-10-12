"""Exact whole-image comparison helpers for reconstruction projects."""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ImageComparison:
    reference_size: int
    rebuilt_size: int
    reference_sha256: str
    rebuilt_sha256: str
    first_difference: int | None

    @property
    def exact(self) -> bool:
        return (
            self.reference_size == self.rebuilt_size
            and self.reference_sha256 == self.rebuilt_sha256
            and self.first_difference is None
        )


def compare_bytes(reference: bytes, rebuilt: bytes) -> ImageComparison:
    common = min(len(reference), len(rebuilt))
    first = next(
        (index for index in range(common) if reference[index] != rebuilt[index]),
        None,
    )
    if first is None and len(reference) != len(rebuilt):
        first = common
    return ImageComparison(
        reference_size=len(reference),
        rebuilt_size=len(rebuilt),
        reference_sha256=hashlib.sha256(reference).hexdigest(),
        rebuilt_sha256=hashlib.sha256(rebuilt).hexdigest(),
        first_difference=first,
    )


def compare_files(reference: str | Path, rebuilt: str | Path) -> ImageComparison:
    return compare_bytes(Path(reference).read_bytes(), Path(rebuilt).read_bytes())
