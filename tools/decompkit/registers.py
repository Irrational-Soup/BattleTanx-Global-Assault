"""Bounded, architecture-neutral register-mapping analysis."""

from __future__ import annotations

from dataclasses import dataclass
from itertools import permutations, product
from math import factorial
from typing import Iterable, Mapping, Sequence

Instruction = tuple[str, tuple[str, ...]]


@dataclass(frozen=True)
class MappingResult:
    mismatches: int
    mapping: dict[str, str]


def parse_instruction_rows(rows: Iterable[Mapping[str, object]]) -> list[Instruction]:
    """Validate the portable JSON instruction representation."""
    result: list[Instruction] = []
    for index, row in enumerate(rows):
        opcode = row.get("opcode")
        operands = row.get("operands", [])
        if not isinstance(opcode, str) or not opcode:
            raise ValueError(f"instruction {index} has no opcode")
        if not isinstance(operands, list) or not all(isinstance(x, str) for x in operands):
            raise ValueError(f"instruction {index} operands must be strings")
        result.append((opcode, tuple(operands)))
    return result


def mapping_cost(
    built: Sequence[Instruction], reference: Sequence[Instruction], mapping: Mapping[str, str]
) -> int:
    """Count opcode/operand slots that remain different after ``mapping``."""
    cost = abs(len(built) - len(reference))
    for left, right in zip(built, reference):
        if left[0] != right[0]:
            cost += 1
            continue
        width = max(len(left[1]), len(right[1]))
        for index in range(width):
            lhs = left[1][index] if index < len(left[1]) else None
            rhs = right[1][index] if index < len(right[1]) else None
            if lhs is not None:
                lhs = mapping.get(lhs, lhs)
            cost += lhs != rhs
    return cost


def search_space_size(groups: Sequence[tuple[Sequence[str], Sequence[str]]]) -> int:
    total = 1
    for sources, targets in groups:
        if len(sources) != len(targets):
            raise ValueError("register groups must have equal source and target sizes")
        if len(set(sources)) != len(sources) or len(set(targets)) != len(targets):
            raise ValueError("register groups must not contain duplicates")
        total *= factorial(len(sources))
    return total


def exhaustive_register_maps(
    built: Sequence[Instruction],
    reference: Sequence[Instruction],
    groups: Sequence[tuple[Sequence[str], Sequence[str]]],
    *,
    limit: int = 100_000,
    keep: int = 20,
) -> list[MappingResult]:
    """Rank every bijection in explicit groups, rejecting factorial explosions."""
    if keep < 1 or limit < 1:
        raise ValueError("keep and limit must be positive")
    space = search_space_size(groups)
    if space > limit:
        raise ValueError(f"register search space {space} exceeds limit {limit}")
    source_seen: set[str] = set()
    target_seen: set[str] = set()
    choices = []
    for sources, targets in groups:
        overlap = source_seen.intersection(sources)
        if overlap:
            raise ValueError(f"source registers occur in multiple groups: {sorted(overlap)}")
        overlap = target_seen.intersection(targets)
        if overlap:
            raise ValueError(f"target registers occur in multiple groups: {sorted(overlap)}")
        source_seen.update(sources)
        target_seen.update(targets)
        choices.append(tuple(permutations(targets)))
    ranked: list[MappingResult] = []
    for selected in product(*choices):
        mapping: dict[str, str] = {}
        for (sources, _), targets in zip(groups, selected):
            mapping.update(zip(sources, targets))
        ranked.append(MappingResult(mapping_cost(built, reference, mapping), mapping))
    ranked.sort(key=lambda item: (item.mismatches, sorted(item.mapping.items())))
    return ranked[:keep]
