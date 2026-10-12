"""Fail-closed primitives for auditable assembly normalizers."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Mapping, Sequence


@dataclass(frozen=True)
class RewriteResult:
    text: str
    fires: int


def replace_exact(text: str, before: str, after: str, *, expected: int = 1) -> RewriteResult:
    fires = text.count(before)
    if fires != expected:
        raise RuntimeError(f"rewrite fired {fires} times (expected {expected})")
    return RewriteResult(text.replace(before, after), fires)


def function_body(text: str, name: str) -> tuple[int, int, str]:
    pattern = re.compile(
        rf"(?m)^({re.escape(name)}:\n.*?^\s*\.end\s+{re.escape(name)}\s*$)", re.S
    )
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        raise RuntimeError(f"function {name} occurred {len(matches)} times (expected 1)")
    match = matches[0]
    return match.start(1), match.end(1), match.group(1)


def rename_tokens(text: str, mapping: Mapping[str, str]) -> str:
    """Apply a simultaneous token rename, rejecting non-bijective maps."""
    if len(set(mapping.values())) != len(mapping):
        raise ValueError("token mapping must be injective")
    if not mapping:
        return text
    pattern = re.compile(
        r"(?<![A-Za-z0-9_])(" + "|".join(
            sorted((re.escape(key) for key in mapping), key=len, reverse=True)
        ) + r")(?![A-Za-z0-9_])"
    )
    return pattern.sub(lambda match: mapping[match.group(1)], text)


def permute_lines(block: str, order: Sequence[int]) -> str:
    lines = block.splitlines(keepends=True)
    if sorted(order) != list(range(len(lines))):
        raise ValueError("line order must be a complete permutation")
    return "".join(lines[index] for index in order)
