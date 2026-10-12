"""Parse GCC 2.x local/global allocation evidence without invoking a compiler.

The ``.greg`` dump is after reload.  Optional ``PRE_RELOAD_REG`` records must
come from an explicitly instrumented compiler and are kept distinct.
"""

from __future__ import annotations

import math
import re
from pathlib import Path


DEFAULT_HARD_NAMES = (
    "zero at v0 v1 a0 a1 a2 a3 t0 t1 t2 t3 t4 t5 t6 t7 "
    "s0 s1 s2 s3 s4 s5 s6 s7 t8 t9 k0 k1 gp sp s8 ra"
).split() + [f"f{i}" for i in range(32)]


def hard_name(number: int, names: list[str] | tuple[str, ...] = DEFAULT_HARD_NAMES) -> str:
    return names[number] if 0 <= number < len(names) else f"hr{number}"


def function_section(text: str, function: str) -> str:
    parts = re.split(r"(?m)^;; Function (\S+)\s*$", text)
    for index in range(1, len(parts), 2):
        if parts[index] == function:
            return parts[index + 1]
    raise ValueError(f"function {function!r} is absent from compiler dump")


def register_stats(text: str) -> dict[int, dict[str, object]]:
    result: dict[int, dict[str, object]] = {}
    pattern = r"(?m)^Register (\d+) used (\d+) times across (\d+) insns(.*)$"
    for match in re.finditer(pattern, text):
        tail = match.group(4)
        calls = re.search(r"crosses (\d+) call", tail)
        width = re.search(r"(\d+) bytes", tail)
        result[int(match.group(1))] = {
            "refs": int(match.group(2)),
            "live": int(match.group(3)),
            "calls": int(calls.group(1)) if calls else 0,
            "size_words": max(1, (int(width.group(1)) + 3) // 4) if width else 1,
            "local": "in block" in tail,
            "description": tail.strip("; ."),
        }
    return result


def first_set(text: str, pseudo: int) -> str:
    match = re.search(rf"\(set \(reg(?:/\w+)*:\w+ {pseudo}\)\s*\n?\s*(.{{0,120}})", text)
    return re.sub(r"\s+", " ", match.group(1)).strip() if match else ""


def parse_pre_reload_text(text: str, function: str) -> dict[int, dict[str, int]]:
    result: dict[int, dict[str, int]] = {}
    pattern = re.compile(
        r"^PRE_RELOAD_REG function=(\S+) pseudo=(\d+) hard=(-?\d+) "
        r"allocno=(-?\d+) refs=(-?\d+) live=(-?\d+) calls=(-?\d+)$"
    )
    for line in text.splitlines():
        match = pattern.match(line)
        if not match or match.group(1) != function:
            continue
        result[int(match.group(2))] = dict(
            hard=int(match.group(3)), allocno=int(match.group(4)),
            refs=int(match.group(5)), live=int(match.group(6)), calls=int(match.group(7)),
        )
    return result


def parse_pre_reload(path: str | Path | None, function: str) -> dict[int, dict[str, int]]:
    return parse_pre_reload_text(Path(path).read_text(), function) if path else {}


def allocation_priority(refs: int, live: int, size_words: int = 1) -> int:
    """Reproduce the priority value reported by this GCC 2.7.2 investigation."""
    if refs <= 0:
        return 0
    if live <= 0 or size_words <= 0:
        raise ValueError("live range and size must be positive")
    return round(math.floor(math.log2(refs)) * refs / live * 10000 * size_words)


def allocation_rows(
    lreg: str,
    greg: str,
    pre_reload: dict[int, dict[str, int]] | None = None,
    hard_names: list[str] | tuple[str, ...] = DEFAULT_HARD_NAMES,
) -> dict[str, object]:
    """Join local/global dumps and optional pre-reload evidence."""
    pre_reload = pre_reload or {}
    stats = register_stats(lreg)
    order_match = re.search(r";; (\d+) regs to allocate:([ \d]*)", greg)
    order = [int(value) for value in order_match.group(2).split()] if order_match else []
    dispositions: dict[int, int] = {}
    marker = ";; Register dispositions:"
    if marker in greg:
        body = greg.split(marker, 1)[1].split(";; Hard regs used", 1)[0]
        dispositions = {int(p): int(h) for p, h in re.findall(r"(\d+) in (\d+)", body)}
    local = {int(p): int(h) for p, h in re.findall(r";; Register (\d+) in (\d+)\.", lreg)}
    rows = []
    for rank, pseudo in enumerate(order):
        item = stats.get(pseudo, dict(refs=0, live=1, calls=0, size_words=1,
                                      local=False, description=""))
        pre = pre_reload.get(pseudo)
        post_hard = dispositions.get(pseudo, -1)
        rows.append(dict(
            rank=rank, pseudo=pseudo, **item,
            priority=allocation_priority(item["refs"], item["live"], item["size_words"]),
            hard=None if post_hard < 0 else post_hard,
            hard_name="MEM" if post_hard < 0 else hard_name(post_hard, hard_names),
            pre_reload_hard=pre["hard"] if pre else None,
            pre_reload_hard_name=(hard_name(pre["hard"], hard_names)
                                  if pre and pre["hard"] >= 0 else "MEM" if pre else None),
            reload_changed_assignment=(pre is not None and pre["hard"] != post_hard),
            first_set=first_set(lreg, pseudo),
        ))
    return {"global": rows, "local": local, "pre_reload": pre_reload}
