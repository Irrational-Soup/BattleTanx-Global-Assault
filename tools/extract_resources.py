#!/usr/bin/env python3
"""Extract the complete local BattleTanx resource tree from a supported ROM."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from decompkit.resources import extract_regions
from inventory_rom_layout import inventory_layout
from inventory_stale_object import inventory_stale_object
from verify_rom import verify

CODE_PREFIX_SIZE = 0x101000


def run(command: list[str], root: Path) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=root, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rom", type=Path, help="local USA Rev 0 big-endian .z64 dump")
    parser.add_argument(
        "--output", type=Path, default=Path("assets/extracted/us"),
        help="ignored resource output tree",
    )
    parser.add_argument(
        "--raw-only", action="store_true",
        help="write only lossless build inputs, without editable/preview exports",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    rom_path = args.rom.resolve()
    if rom_path.suffix.lower() != ".z64" or not rom_path.is_file():
        raise SystemExit("ROM input must be an existing local .z64 file")
    output = (root / args.output).resolve() if not args.output.is_absolute() else args.output
    verify(rom_path)
    rom = rom_path.read_bytes()
    layout = inventory_layout(
        rom,
        root / "src/code/slot_asset_ranges.c",
        root / "src/code/campaign_mission_config.c",
    )
    raw = output / "raw"
    manifest = extract_regions(
        rom,
        layout["regions"],
        raw,
        include_after=CODE_PREFIX_SIZE,
        image_sha256=hashlib.sha256(rom).hexdigest(),
    )
    (output / "rom-layout.json").write_text(
        json.dumps({"rom_sha1": hashlib.sha1(rom).hexdigest(), **layout}, indent=2) + "\n"
    )

    if not args.raw_only:
        py = sys.executable
        reports = output / "reports"
        reports.mkdir(parents=True, exist_ok=True)
        (reports / "stale-object.json").write_text(
            json.dumps(inventory_stale_object(rom), indent=2) + "\n"
        )
        commands = [
            [
                py, "tools/inventory_lzari_assets.py", "--rom", str(rom_path),
                "--output", str(reports / "lzari.json"),
                "--extract-dir", str(output / "lzari"), "--split-bundles",
            ],
            [
                py, "tools/extract_lzari_images.py", "--rom", str(rom_path),
                str(output / "images"),
            ],
            [
                py, "tools/extract_lzari_worlds.py", "--rom", str(rom_path),
                str(output / "worlds"),
            ],
            [
                py, "tools/inventory_script_assets.py", "--rom", str(rom_path),
                "--output", str(reports / "scripts.json"),
                "--extract-dir", str(output / "scripts"),
            ],
            [
                py, "tools/inventory_libmus_assets.py", "--rom", str(rom_path),
                "--output", str(reports / "libmus.json"),
                "--extract-dir", str(output / "libmus"),
            ],
            [
                py, "tools/inventory_world_pools.py", "--rom", str(rom_path),
                "--output", str(reports / "world-pools.json"),
                "--extract-dir", str(output / "world-pools"),
            ],
            [
                py, "tools/inventory_world_display_lists.py", "--rom", str(rom_path),
                "--output", str(reports / "display-lists.json"),
            ],
            [
                py, "tools/inventory_world_textures.py", "--rom", str(rom_path),
                "--output", str(reports / "world-textures.json"),
                "--preview-dir", str(output / "world-textures"),
            ],
            [
                py, "tools/inventory_world_geometry.py", "--rom", str(rom_path),
                "--output", str(reports / "geometry.json"),
                "--obj", str(output / "world-geometry.obj"),
            ],
            [
                py, "tools/inventory_stale_debug.py", "--rom", str(rom_path),
                "--output", str(reports / "stale-debug.json"),
            ],
        ]
        for command in commands:
            run(command, root)

    print(
        f"Extracted {manifest['region_count']} lossless ROM regions and local resources to {output}"
    )


if __name__ == "__main__":
    main()
