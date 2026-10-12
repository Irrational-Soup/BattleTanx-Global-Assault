"""Configuration loading for decompkit consumers."""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProjectConfig:
    """Resolved project policy and paths.

    Paths in TOML are relative to ``root``.  When ``root`` is omitted it is
    resolved relative to the configuration file, making a copied toolkit work
    without retaining the source repository's absolute path.
    """

    root: Path
    functions: Path
    splat: Path
    source_dir: Path
    report_source_root: str
    rodata: Path
    data: Path
    exclusions: Path
    report_output: Path
    vram_delta: int
    code_end: int
    image_start: int
    image_end: int
    source_kinds: tuple[str, ...]
    unit_manifests: tuple[tuple[Path, str], ...]


def _integer(value: object, name: str) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        return int(value, 0)
    raise ValueError(f"{name} must be an integer or base-prefixed string")


def load_config(path: str | Path) -> ProjectConfig:
    path = Path(path).resolve()
    with path.open("rb") as stream:
        document = tomllib.load(stream)
    project = document.get("project", {})
    report = document.get("report", {})
    units = document.get("units", {})

    configured_root = Path(project.get("root", "."))
    root = (path.parent / configured_root).resolve()

    def resolved(key: str, default: str) -> Path:
        return (root / project.get(key, default)).resolve()

    manifests = []
    for item in units.get("manifests", []):
        try:
            manifest_path = (root / item["path"]).resolve()
            pipeline = item["pipeline"]
        except KeyError as error:
            raise ValueError("each units.manifests row needs path and pipeline") from error
        manifests.append((manifest_path, pipeline))

    return ProjectConfig(
        root=root,
        functions=resolved("functions", "config/recomp_function_boundaries.toml"),
        splat=resolved("splat", "config/splat.yaml"),
        source_dir=resolved("source_dir", "src"),
        report_source_root=project.get("report_source_root", "src"),
        rodata=resolved("rodata", "config/unit_rodata.tsv"),
        data=resolved("data", "config/unit_data.tsv"),
        exclusions=resolved("exclusions", "config/data_exclusions.tsv"),
        report_output=resolved("report_output", "build/report.json"),
        vram_delta=_integer(report["vram_delta"], "report.vram_delta"),
        code_end=_integer(report["code_end"], "report.code_end"),
        image_start=_integer(report["image_start"], "report.image_start"),
        image_end=_integer(report["image_end"], "report.image_end"),
        source_kinds=tuple(report.get("source_kinds", ("c", "hasm"))),
        unit_manifests=tuple(manifests),
    )
