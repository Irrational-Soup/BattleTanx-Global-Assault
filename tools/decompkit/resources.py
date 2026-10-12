"""Portable extraction and image-reassembly primitives.

Projects provide an ordered region map.  This module writes each region to an
ignored local tree and can later combine those files with a rebuilt prefix.
It deliberately knows nothing about ROM formats or game-specific tables.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Iterable, Mapping, Sequence, cast


def _safe_name(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("._")
    return value or "region"


def extract_regions(
    image: bytes,
    regions: Iterable[Mapping[str, object]],
    output: Path,
    *,
    include_after: int = 0,
    image_sha256: str | None = None,
) -> dict:
    """Extract mapped regions intersecting ``[include_after, len(image))``.

    Regions may overlap an independently rebuilt prefix.  Reassembly verifies
    that overlapping bytes agree, which is useful when a logical asset crosses
    the source/resource boundary.
    """

    output.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    for index, source in enumerate(regions):
        start = int(source["start"])
        end = int(source["end"])
        if start < 0 or end <= start or end > len(image):
            raise ValueError(f"invalid region {start:#x}-{end:#x}")
        if end <= include_after:
            continue
        name = str(source.get("name", f"region_{index:03d}"))
        kind = str(source.get("kind", "region"))
        filename = f"{start:08x}-{end:08x}_{_safe_name(name)}.bin"
        payload = image[start:end]
        (output / filename).write_bytes(payload)
        records.append(
            {
                "name": name,
                "kind": kind,
                "start": start,
                "end": end,
                "size": len(payload),
                "file": filename,
                "sha256": hashlib.sha256(payload).hexdigest(),
            }
        )

    manifest = {
        "format": "decompkit region resources v1",
        "image_size": len(image),
        "source_image_sha256": image_sha256 or hashlib.sha256(image).hexdigest(),
        "rebuilt_prefix_size": include_after,
        "region_count": len(records),
        "regions": records,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def rebuild_image(
    prefix: bytes,
    manifest: Mapping[str, object],
    resource_root: Path,
    *,
    require_pristine_resources: bool = False,
) -> bytes:
    """Combine a rebuilt prefix and extracted regions into one image."""

    image_size = int(manifest["image_size"])
    expected_prefix = int(manifest.get("rebuilt_prefix_size", len(prefix)))
    if len(prefix) != expected_prefix:
        raise ValueError(
            f"rebuilt prefix size is {len(prefix):#x}; expected {expected_prefix:#x}"
        )
    if len(prefix) > image_size:
        raise ValueError("rebuilt prefix is larger than the target image")
    output = bytearray(image_size)
    covered = bytearray(image_size)
    output[: len(prefix)] = prefix
    covered[: len(prefix)] = b"\x01" * len(prefix)

    records = cast(Sequence[Mapping[str, object]], manifest["regions"])
    resource_root = resource_root.resolve()
    for record in records:
        start = int(record["start"])
        end = int(record["end"])
        if start < 0 or end <= start or end > image_size:
            raise ValueError(f"invalid manifest region {start:#x}-{end:#x}")
        path = (resource_root / str(record["file"])).resolve()
        try:
            path.relative_to(resource_root)
        except ValueError:
            raise ValueError(f"resource path escapes its root: {record['file']}")
        payload = path.read_bytes()
        if len(payload) != end - start:
            raise ValueError(f"resource size mismatch: {record['file']}")
        if require_pristine_resources:
            digest = hashlib.sha256(payload).hexdigest()
            if digest != record["sha256"]:
                raise ValueError(f"resource hash mismatch: {record['file']}")
        overlap_end = min(end, len(prefix))
        if (
            start < overlap_end
            and payload[: overlap_end - start] != prefix[start:overlap_end]
        ):
            raise ValueError(f"resource disagrees with rebuilt prefix: {record['file']}")
        for offset in range(max(start, len(prefix)), end):
            if covered[offset] and output[offset] != payload[offset - start]:
                raise ValueError(f"overlapping resources disagree at {offset:#x}")
        output[start:end] = payload
        covered[start:end] = b"\x01" * (end - start)

    try:
        first_gap = covered.index(0)
    except ValueError:
        first_gap = -1
    if first_gap >= 0:
        raise ValueError(f"output image has an uncovered byte at {first_gap:#x}")
    return bytes(output)
