#!/usr/bin/env python3
"""Build a complete BattleTanx ROM from compiled code and local resources."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from decompkit.resources import rebuild_image
from verify_rom import EXPECTED_SHA256


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--code", type=Path, default=Path("build/us/battletanx_ga.code.bin")
    )
    parser.add_argument(
        "--resources", type=Path, default=Path("assets/extracted/us/raw")
    )
    parser.add_argument(
        "--output", type=Path, default=Path("build/us/battletanx_ga.z64")
    )
    parser.add_argument("--require-original", action="store_true")
    args = parser.parse_args()

    manifest = json.loads((args.resources / "manifest.json").read_text())
    image = rebuild_image(
        args.code.read_bytes(),
        manifest,
        args.resources,
        require_pristine_resources=args.require_original,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(image)
    digest = hashlib.sha256(image).hexdigest()
    if args.require_original and digest != EXPECTED_SHA256:
        raise SystemExit(
            f"rebuilt ROM SHA-256 mismatch: expected {EXPECTED_SHA256}, got {digest}"
        )
    print(f"Built {args.output} ({len(image)} bytes, SHA-256 {digest})")


if __name__ == "__main__":
    main()
