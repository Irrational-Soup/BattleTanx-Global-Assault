"""Configurable source-portability inventory.

The scanner is intentionally project-neutral.  A repository supplies source
roots, path rules, and regular-expression detectors in TOML.  The resulting
inventory distinguishes source that can be compiled for another target from
source that needs a platform adapter, translation, or replacement.
"""

from __future__ import annotations

import fnmatch
import json
import re
import subprocess
import tomllib
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class SourceRoot:
    path: str
    role: str
    extensions: tuple[str, ...]


@dataclass(frozen=True)
class PathRule:
    glob: str
    category: str
    action: str
    reason: str


@dataclass(frozen=True)
class Detector:
    name: str
    category: str
    action: str
    pattern: str
    reason: str


@dataclass(frozen=True)
class PortabilityConfig:
    root: Path
    tracked_only: bool
    source_roots: tuple[SourceRoot, ...]
    rules: tuple[PathRule, ...]
    detectors: tuple[Detector, ...]


@dataclass(frozen=True)
class Finding:
    path: str
    role: str
    language: str
    categories: tuple[str, ...]
    actions: tuple[str, ...]
    evidence: tuple[str, ...]


def load_portability_config(path: str | Path) -> PortabilityConfig:
    config_path = Path(path).resolve()
    with config_path.open("rb") as stream:
        document = tomllib.load(stream)
    project = document.get("project", {})
    root = (config_path.parent / project.get("root", ".")).resolve()

    roots = tuple(
        SourceRoot(
            path=item["path"],
            role=item["role"],
            extensions=tuple(item.get("extensions", (".c", ".s", ".S"))),
        )
        for item in document.get("source_root", ())
    )
    if not roots:
        raise ValueError("portability config needs at least one [[source_root]]")

    rules = tuple(
        PathRule(
            glob=item["glob"],
            category=item["category"],
            action=item["action"],
            reason=item["reason"],
        )
        for item in document.get("rule", ())
    )
    detectors = tuple(
        Detector(
            name=item["name"],
            category=item["category"],
            action=item["action"],
            pattern=item["pattern"],
            reason=item["reason"],
        )
        for item in document.get("detector", ())
    )
    for detector in detectors:
        re.compile(detector.pattern)
    return PortabilityConfig(root, bool(project.get("tracked_only", False)), roots, rules, detectors)


def _language(path: Path) -> str:
    if path.suffix == ".c":
        return "c"
    if path.suffix in (".s", ".S"):
        return "assembly"
    return path.suffix.lstrip(".") or "unknown"


def scan_portability(config: PortabilityConfig) -> list[Finding]:
    findings: list[Finding] = []
    visited: set[Path] = set()
    compiled = [(item, re.compile(item.pattern)) for item in config.detectors]
    tracked: set[str] | None = None
    if config.tracked_only:
        result = subprocess.run(
            ("git", "-C", str(config.root), "ls-files", "-z"),
            check=True,
            capture_output=True,
        )
        tracked = {item.decode() for item in result.stdout.split(b"\0") if item}

    for source_root in config.source_roots:
        base = (config.root / source_root.path).resolve()
        if not base.is_dir():
            raise FileNotFoundError(f"source root does not exist: {base}")
        for path in sorted(p for p in base.rglob("*") if p.is_file()):
            if path.suffix not in source_root.extensions or path in visited:
                continue
            visited.add(path)
            relative = path.relative_to(config.root).as_posix()
            if tracked is not None and relative not in tracked:
                continue
            categories: list[str] = []
            actions: list[str] = []
            evidence: list[str] = []

            def add(category: str, action: str, reason: str) -> None:
                if category not in categories:
                    categories.append(category)
                if action not in actions:
                    actions.append(action)
                if reason not in evidence:
                    evidence.append(reason)

            for rule in config.rules:
                if fnmatch.fnmatch(relative, rule.glob):
                    add(rule.category, rule.action, rule.reason)

            text = path.read_text(errors="replace")
            for detector, expression in compiled:
                if expression.search(text):
                    add(detector.category, detector.action, detector.reason)

            if categories:
                findings.append(
                    Finding(
                        path=relative,
                        role=source_root.role,
                        language=_language(path),
                        categories=tuple(categories),
                        actions=tuple(actions),
                        evidence=tuple(evidence),
                    )
                )
    return findings


def inventory_document(config: PortabilityConfig, findings: list[Finding]) -> dict[str, object]:
    category_counts = Counter(category for item in findings for category in item.categories)
    action_counts = Counter(action for item in findings for action in item.actions)
    return {
        "schema": 1,
        "tracked_only": config.tracked_only,
        "source_roots": [
            {"path": item.path, "role": item.role, "extensions": list(item.extensions)}
            for item in config.source_roots
        ],
        "summary": {
            "files_with_findings": len(findings),
            "categories": dict(sorted(category_counts.items())),
            "actions": dict(sorted(action_counts.items())),
        },
        "findings": [
            {
                "path": item.path,
                "role": item.role,
                "language": item.language,
                "categories": list(item.categories),
                "actions": list(item.actions),
                "evidence": list(item.evidence),
            }
            for item in findings
        ],
    }


def render_json(config: PortabilityConfig, findings: list[Finding]) -> str:
    return json.dumps(inventory_document(config, findings), indent=2, sort_keys=True) + "\n"


def render_markdown(config: PortabilityConfig, findings: list[Finding]) -> str:
    document = inventory_document(config, findings)
    summary = document["summary"]
    lines = [
        "# Native-port blocker inventory",
        "",
        "This file is generated from `config/portability.toml` by",
        "`tools/portability_report.py`. Do not edit it by hand.",
        "",
        "Normalizer-assisted C is deliberately absent unless it also contains a",
        "detected target-specific construct. Normalizer rules belong only to the",
        "N64 byte-matching pipeline and are not runtime dependencies.",
        "",
        f"Files requiring review or target work: **{summary['files_with_findings']}**.",
        "",
        "## Categories",
        "",
        "| Category | Files |",
        "|---|---:|",
    ]
    for category, count in summary["categories"].items():
        lines.append(f"| `{category}` | {count} |")
    lines.extend(("", "## Required actions", "", "| Action | Files |", "|---|---:|"))
    for action, count in summary["actions"].items():
        lines.append(f"| `{action}` | {count} |")
    lines.extend(("", "## Findings", "", "| Source | Role | Categories | Actions |", "|---|---|---|---|"))
    for item in findings:
        categories = ", ".join(f"`{value}`" for value in item.categories)
        actions = ", ".join(f"`{value}`" for value in item.actions)
        lines.append(f"| `{item.path}` | {item.role} | {categories} | {actions} |")
    lines.extend(("", "## Interpretation", ""))
    lines.extend(
        (
            "- `portable-review` means the C can enter a host build after width, endian,",
            "  layout, and dependency review; it does not promise correctness on a host.",
            "- `platform-adapter` means the behavior belongs behind a host/Vita service",
            "  interface rather than being compiled as N64 hardware access.",
            "- `rewrite-portable` means target-specific C or inline assembly needs a",
            "  behaviorally tested portable implementation.",
            "- `replace-or-emulate` applies to native MIPS/RSP source that cannot execute",
            "  in a Windows or Vita process.",
            "",
        )
    )
    return "\n".join(lines)
