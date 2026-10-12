"""Portable readiness checks for migrating extracted assets into O2R resources."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

VALID_STAGES = {"raw", "structured", "runtime-ready"}


@dataclass(frozen=True)
class O2RResource:
    name: str
    stage: str
    extractor: str
    serializer: str | None = None
    resource_type: str | None = None
    factory: str | None = None
    blocker: str | None = None


def load_readiness(path: Path) -> list[O2RResource]:
    """Load and validate a TOML O2R readiness manifest."""
    import tomllib

    payload: dict[str, Any] = tomllib.loads(path.read_text())
    rows = payload.get("resource", [])
    if not isinstance(rows, list):
        raise ValueError("resource must be an array of tables")
    result: list[O2RResource] = []
    names: set[str] = set()
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"resource {index} must be a table")
        name, stage, extractor = row.get("name"), row.get("stage"), row.get("extractor")
        if not all(isinstance(value, str) and value for value in (name, stage, extractor)):
            raise ValueError(f"resource {index} requires name, stage, and extractor")
        if name in names:
            raise ValueError(f"duplicate resource name: {name}")
        if stage not in VALID_STAGES:
            raise ValueError(f"{name}: invalid stage {stage!r}")
        names.add(name)
        item = O2RResource(
            name=name, stage=stage, extractor=extractor,
            serializer=row.get("serializer"), resource_type=row.get("resource_type"),
            factory=row.get("factory"), blocker=row.get("blocker"),
        )
        for field in ("serializer", "resource_type", "factory", "blocker"):
            value = getattr(item, field)
            if value is not None and (not isinstance(value, str) or not value):
                raise ValueError(f"{name}: {field} must be a non-empty string")
        if stage == "runtime-ready":
            missing = [field for field in ("serializer", "resource_type", "factory")
                       if getattr(item, field) is None]
            if missing:
                raise ValueError(f"{name}: runtime-ready requires {', '.join(missing)}")
        elif not item.blocker:
            raise ValueError(f"{name}: non-runtime-ready entry requires a blocker")
        result.append(item)
    return result


def readiness_summary(resources: list[O2RResource]) -> dict[str, int]:
    summary = {stage: 0 for stage in sorted(VALID_STAGES)}
    for resource in resources:
        summary[resource.stage] += 1
    summary["total"] = len(resources)
    return summary
