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


@dataclass(frozen=True)
class WindowMappingResult:
    mismatches: int
    improvement: int
    start: int
    end: int
    mapping: dict[str, str]


def register_tokens(instructions: Sequence[Instruction]) -> set[str]:
    """Return register-like operand tokens seen in an instruction stream.

    The representation deliberately remains architecture-neutral: callers decide
    which token families may be exchanged.  Memory operands are not decomposed;
    JSON producers should expose a base register as its own operand when they want
    it included in the search.
    """
    return {operand for _, operands in instructions for operand in operands}


def single_register_swaps(
    built: Sequence[Instruction],
    reference: Sequence[Instruction],
    groups: Sequence[Sequence[str]],
    *,
    keep: int = 100,
    improving_only: bool = False,
) -> list[MappingResult]:
    """Score identity plus every one-pair swap in each register family.

    This is the inexpensive exhaustive probe to run before a factorial mapping
    search.  It tests every pair exactly once, never exchanges tokens across
    caller-defined families (for example GPR and FPR), and reports deterministic
    results.  The mismatch count is the same operand-slot metric used by
    :func:`exhaustive_register_maps`.
    """
    if keep < 1:
        raise ValueError("keep must be positive")
    seen: set[str] = set()
    normalized: list[tuple[str, ...]] = []
    for group in groups:
        current = tuple(group)
        if len(set(current)) != len(current):
            raise ValueError("register groups must not contain duplicates")
        overlap = seen.intersection(current)
        if overlap:
            raise ValueError(f"registers occur in multiple groups: {sorted(overlap)}")
        seen.update(current)
        normalized.append(current)

    baseline = mapping_cost(built, reference, {})
    ranked = [MappingResult(baseline, {})]
    for current in normalized:
        for left_index, left in enumerate(current):
            for right in current[left_index + 1 :]:
                mapping = {left: right, right: left}
                cost = mapping_cost(built, reference, mapping)
                if not improving_only or cost < baseline:
                    ranked.append(MappingResult(cost, mapping))
    ranked.sort(key=lambda item: (item.mismatches, sorted(item.mapping.items())))
    return ranked[:keep]


def regional_register_swaps(
    built: Sequence[Instruction],
    reference: Sequence[Instruction],
    groups: Sequence[Sequence[str]],
    *,
    keep: int = 100,
) -> list[WindowMappingResult]:
    """Find the best contiguous instruction window for every one-pair swap.

    A compiler allocation often differs for one pseudo's lifetime rather than
    for an entire function.  For each pair this uses a minimum-subarray scan of
    per-instruction mismatch deltas, yielding the globally best half-open
    ``[start, end)`` window without enumerating every possible window.
    """
    if keep < 1:
        raise ValueError("keep must be positive")
    if len(built) != len(reference):
        raise ValueError("regional swap search requires equal instruction counts")
    seen: set[str] = set()
    baseline = mapping_cost(built, reference, {})
    ranked: list[WindowMappingResult] = []
    for group in groups:
        current = tuple(group)
        if len(set(current)) != len(current):
            raise ValueError("register groups must not contain duplicates")
        overlap = seen.intersection(current)
        if overlap:
            raise ValueError(f"registers occur in multiple groups: {sorted(overlap)}")
        seen.update(current)
        for left_index, left in enumerate(current):
            for right in current[left_index + 1 :]:
                mapping = {left: right, right: left}
                deltas = [
                    mapping_cost([lhs], [rhs], mapping)
                    - mapping_cost([lhs], [rhs], {})
                    for lhs, rhs in zip(built, reference)
                ]
                best_sum = current_sum = 0
                best_start = best_end = current_start = 0
                for index, delta in enumerate(deltas):
                    if current_sum + delta >= 0:
                        current_sum = 0
                        current_start = index + 1
                    else:
                        current_sum += delta
                        if current_sum < best_sum:
                            best_sum = current_sum
                            best_start, best_end = current_start, index + 1
                if best_sum < 0:
                    ranked.append(WindowMappingResult(
                        baseline + best_sum, -best_sum, best_start, best_end, mapping
                    ))
    ranked.sort(key=lambda item: (
        item.mismatches, item.end - item.start, item.start, sorted(item.mapping.items())
    ))
    return ranked[:keep]


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
