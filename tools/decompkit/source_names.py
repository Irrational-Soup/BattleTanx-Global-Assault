"""Evidence-preserving source filename policy for decompilation projects."""

from __future__ import annotations

import fnmatch
import re
import subprocess
import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class NamingPolicy:
    root: Path
    source_root: Path
    layout: Path
    legacy: Path
    vram_delta: int
    preferred: str
    exempt_globs: tuple[str, ...]
    tracked_only: bool


@dataclass(frozen=True)
class NamingAudit:
    preferred: tuple[str, ...]
    legacy: tuple[str, ...]
    violations: tuple[str, ...]
    stale_legacy: tuple[str, ...]
    address_mismatches: tuple[str, ...]

    @property
    def clean(self) -> bool:
        return not (self.violations or self.stale_legacy or self.address_mismatches)


_SPLAT_C_ROW = re.compile(r"\[\s*(0x[0-9A-Fa-f]+)\s*,\s*c\s*,\s*([^\],]+)")


def load_naming_policy(path: str | Path) -> NamingPolicy:
    config_path = Path(path).resolve()
    with config_path.open("rb") as stream:
        document = tomllib.load(stream)
    project = document.get("project", {})
    naming = document.get("naming", {})
    root = (config_path.parent / project.get("root", ".")).resolve()

    def resolved(value: str) -> Path:
        return (root / value).resolve()

    return NamingPolicy(
        root=root,
        source_root=resolved(naming.get("source_root", "src")),
        layout=resolved(naming["layout"]),
        legacy=resolved(naming["legacy"]),
        vram_delta=int(naming["vram_delta"]),
        preferred=naming.get("preferred", r"^[0-9A-F]{8}_[a-z0-9][a-z0-9_]*\.c$"),
        exempt_globs=tuple(naming.get("exempt_globs", ())),
        tracked_only=bool(project.get("tracked_only", False)),
    )


def layout_addresses(policy: NamingPolicy) -> dict[str, int]:
    addresses: dict[str, int] = {}
    for match in _SPLAT_C_ROW.finditer(policy.layout.read_text()):
        offset = int(match.group(1), 0)
        unit = match.group(2).strip()
        relative = f"src/{unit}.c"
        if relative in addresses:
            raise ValueError(f"duplicate C layout row for {relative}")
        addresses[relative] = offset + policy.vram_delta
    return addresses


def tracked_c_sources(policy: NamingPolicy) -> tuple[str, ...]:
    root_relative = policy.source_root.relative_to(policy.root).as_posix()
    if policy.tracked_only:
        result = subprocess.run(
            ("git", "-C", str(policy.root), "ls-files", "-z", f"{root_relative}/**/*.c", f"{root_relative}/*.c"),
            check=True,
            capture_output=True,
        )
        return tuple(sorted(item.decode() for item in result.stdout.split(b"\0") if item))
    return tuple(
        sorted(path.relative_to(policy.root).as_posix() for path in policy.source_root.rglob("*.c"))
    )


def legacy_entries(path: Path) -> tuple[str, ...]:
    if not path.is_file():
        return ()
    return tuple(
        line.strip() for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )


def nonpreferred_sources(policy: NamingPolicy) -> tuple[str, ...]:
    expression = re.compile(policy.preferred)
    return tuple(
        path for path in tracked_c_sources(policy)
        if not any(fnmatch.fnmatch(path, pattern) for pattern in policy.exempt_globs)
        and not expression.fullmatch(Path(path).name)
    )


def audit_source_names(policy: NamingPolicy) -> NamingAudit:
    expression = re.compile(policy.preferred)
    sources = tracked_c_sources(policy)
    source_set = set(sources)
    expected = layout_addresses(policy)
    baseline = set(legacy_entries(policy.legacy))
    preferred: list[str] = []
    current_legacy: list[str] = []
    violations: list[str] = []
    mismatches: list[str] = []

    for path in sources:
        if any(fnmatch.fnmatch(path, pattern) for pattern in policy.exempt_globs):
            preferred.append(path)
            continue
        name = Path(path).name
        if expression.fullmatch(name):
            address = int(name[:8], 16)
            if path not in expected:
                mismatches.append(f"{path}: preferred name has no C layout row")
            elif address != expected[path]:
                mismatches.append(
                    f"{path}: filename address 0x{address:08X} != layout 0x{expected[path]:08X}"
                )
            preferred.append(path)
        elif path in baseline:
            current_legacy.append(path)
        else:
            violations.append(path)

    stale = sorted(path for path in baseline if path not in source_set or path not in current_legacy)
    return NamingAudit(
        preferred=tuple(sorted(preferred)),
        legacy=tuple(sorted(current_legacy)),
        violations=tuple(sorted(violations)),
        stale_legacy=tuple(stale),
        address_mismatches=tuple(sorted(mismatches)),
    )


def render_legacy(policy: NamingPolicy) -> str:
    lines = [
        "# Existing filenames awaiting evidence-led migration.",
        "# New entries are forbidden; remove rows as units adopt ADDRESS_description.c.",
    ]
    lines.extend(nonpreferred_sources(policy))
    return "\n".join(lines) + "\n"
