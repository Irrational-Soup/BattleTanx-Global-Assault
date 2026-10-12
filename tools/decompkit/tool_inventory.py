"""Validate and render a complete inventory of maintained repository tools."""

from __future__ import annotations

import ast
import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ToolGroup:
    name: str
    scope: str
    description: str
    evidence: str
    tools: tuple[str, ...]


def load_inventory(path: str | Path) -> tuple[ToolGroup, ...]:
    with Path(path).open("rb") as stream:
        document = tomllib.load(stream)
    groups = []
    for row in document.get("group", []):
        group = ToolGroup(
            name=row["name"], scope=row["scope"], description=row["description"],
            evidence=row["evidence"], tools=tuple(row["tools"]),
        )
        if group.scope not in {"portable", "adapter", "title-specific"}:
            raise ValueError(f"group {group.name!r} has invalid scope {group.scope!r}")
        if not group.description.strip() or not group.evidence.strip() or not group.tools:
            raise ValueError(f"group {group.name!r} is incomplete")
        groups.append(group)
    return tuple(groups)


def maintained_tools(directory: str | Path) -> set[str]:
    root = Path(directory)
    return {path.name for path in root.iterdir()
            if path.is_file() and path.suffix in {".py", ".sh"}}


def validate_inventory(groups: tuple[ToolGroup, ...], directory: str | Path) -> None:
    actual = maintained_tools(directory)
    owners: dict[str, list[str]] = {}
    for group in groups:
        for tool in group.tools:
            owners.setdefault(tool, []).append(group.name)
    duplicate = {tool: names for tool, names in owners.items() if len(names) != 1}
    missing = sorted(actual - owners.keys())
    stale = sorted(owners.keys() - actual)
    errors = []
    if missing:
        errors.append("unclassified tools: " + ", ".join(missing))
    if stale:
        errors.append("inventory entries without files: " + ", ".join(stale))
    if duplicate:
        errors.append("multiply classified tools: " + ", ".join(
            f"{tool} ({'/'.join(names)})" for tool, names in sorted(duplicate.items())
        ))
    if errors:
        raise ValueError("; ".join(errors))


def tool_summary(path: Path, fallback: str) -> str:
    text = path.read_text(errors="replace")
    if path.suffix == ".py":
        try:
            summary = ast.get_docstring(ast.parse(text), clean=True)
        except SyntaxError:
            summary = None
        if summary:
            return summary.split("\n\n", 1)[0].replace("\n", " ").strip()
    comment_lines = []
    for line in text.splitlines()[1:16]:
        stripped = line.strip()
        if stripped.startswith("#") and not stripped.startswith("#!"):
            candidate = stripped.lstrip("# ").strip()
            if any(character.isalnum() for character in candidate):
                comment_lines.append(candidate)
        elif comment_lines:
            break
    if comment_lines:
        return " ".join(comment_lines)
    return fallback


def render_markdown(groups: tuple[ToolGroup, ...], directory: str | Path) -> str:
    validate_inventory(groups, directory)
    root = Path(directory)
    lines = [
        "# Complete tool reference", "",
        "This file is generated from `config/tooling_inventory.toml`. Every maintained",
        "top-level Python and shell tool must occur exactly once. Scope describes whether",
        "the implementation is portable, a project/toolchain adapter, or title-specific.", "",
    ]
    for group in groups:
        lines += [f"## {group.name}", "", f"**Scope:** `{group.scope}`",
                  "", f"**Evidence:** {group.evidence}", "", group.description, "",
                  "| Tool | Purpose |", "|---|---|"]
        for tool in sorted(group.tools):
            lines.append(f"| `{tool}` | {tool_summary(root / tool, group.description)} |")
        lines.append("")
    return "\n".join(lines)
