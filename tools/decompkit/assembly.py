"""Inventory generated and hand-authored assembly subsegments.

The parser intentionally understands only Splat's compact subsegment rows.  It
does not import a project configuration or assume a console architecture, so
other projects can use it to turn an opaque "assembly count" into actionable
code/data/padding/microcode categories.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterable


ROW = re.compile(
    r"^\s*-\s*\[\s*(0x[0-9A-Fa-f]+)\s*,\s*(asm|hasm)\s*,\s*([^,\]\s]+)"
)
ANY_ROW = re.compile(r"^\s*-\s*\[\s*(0x[0-9A-Fa-f]+)\s*,")
WORD = re.compile(r"^\s*(?:/\*.*?\*/\s*)?\.word\s+(.+?)\s*(?:/\*.*)?$")
INSTRUCTION = re.compile(r"^\s*(?:/\*.*?\*/\s*)?([A-Za-z][\w.]*)(?:\s+(.*?))?\s*$")


@dataclass(frozen=True)
class AssemblySegment:
    start: int
    end: int | None
    kind: str
    name: str
    path: Path
    category: str
    glabels: int
    dlabels: int
    instructions: int
    words: int
    zero_words: int

    @property
    def size(self) -> int | None:
        return None if self.end is None else self.end - self.start


def _stats(text: str) -> tuple[int, int, int, int, int]:
    glabels = sum(line.lstrip().startswith("glabel ") for line in text.splitlines())
    dlabels = sum(line.lstrip().startswith("dlabel ") for line in text.splitlines())
    instructions = words = zero_words = 0
    directives = {
        "include", "set", "section", "nonmatching", "glabel", "endlabel",
        "dlabel", "enddlabel", "align", "balign", "size", "type", "globl",
    }
    for line in text.splitlines():
        match = WORD.match(line)
        if match:
            words += 1
            zero_words += match.group(1).strip().split()[0].rstrip(",") in {
                "0", "0x0", "0x00000000",
            }
            continue
        match = INSTRUCTION.match(line)
        if match and match.group(1) not in directives and not line.lstrip().startswith("."):
            instructions += 1
    return glabels, dlabels, instructions, words, zero_words


def classify_assembly(kind: str, name: str, text: str) -> tuple[str, tuple[int, int, int, int, int]]:
    stats = _stats(text)
    glabels, dlabels, instructions, words, zero_words = stats
    lowered = (name + "\n" + text[:4096]).lower()
    if kind == "hasm":
        category = "authentic-source-assembly"
    elif "rspboot" in lowered or "microcode" in lowered or "f3dex" in lowered:
        category = "microcode-or-coprocessor-data"
    elif not glabels and (words or dlabels):
        category = "padding" if words and zero_words == words else "embedded-data"
    elif glabels and (dlabels or words):
        category = "mixed-code-data"
    elif glabels or instructions:
        category = "generated-code"
    else:
        category = "unclassified"
    return category, stats


def inventory_assembly(splat: Path, asm_root: Path) -> list[AssemblySegment]:
    """Parse assembly rows and derive sizes from the next Splat subsegment."""
    rows: list[tuple[int, str | None, str | None]] = []
    for line in splat.read_text().splitlines():
        any_match = ANY_ROW.match(line)
        if not any_match:
            continue
        match = ROW.match(line)
        rows.append(
            (
                int(any_match.group(1), 16),
                match.group(2) if match else None,
                match.group(3) if match else None,
            )
        )
    result: list[AssemblySegment] = []
    for index, (start, kind, name) in enumerate(rows):
        if kind is None or name is None:
            continue
        end = rows[index + 1][0] if index + 1 < len(rows) else None
        path = asm_root / (name + ".s")
        text = path.read_text() if path.exists() else ""
        category, stats = classify_assembly(kind, name, text)
        result.append(AssemblySegment(start, end, kind, name, path, category, *stats))
    return result


def category_totals(segments: Iterable[AssemblySegment]) -> dict[str, tuple[int, int]]:
    """Return category -> (row count, known byte count)."""
    totals: dict[str, tuple[int, int]] = {}
    for segment in segments:
        rows, size = totals.get(segment.category, (0, 0))
        totals[segment.category] = (rows + 1, size + (segment.size or 0))
    return totals
