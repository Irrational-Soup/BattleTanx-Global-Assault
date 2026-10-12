#!/usr/bin/env python3
"""Verify and identify the supported BattleTanx GA ROM without modifying it."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

EXPECTED_SHA1 = "805248fb0a0ee694cad8d7dc927b631d860dd8cf"
EXPECTED_SHA256 = "88268ce770ff39f2ca839848b842c87866df6c5ddaf775f180b2522c18ff6221"
EXPECTED_SIZE = 8 * 1024 * 1024
Z64_MAGIC = bytes.fromhex("80371240")


def verify(path: Path) -> None:
    data = path.read_bytes()
    errors: list[str] = []
    if len(data) != EXPECTED_SIZE:
        errors.append(f"size is {len(data)} bytes; expected {EXPECTED_SIZE}")
    if data[:4] != Z64_MAGIC:
        errors.append(
            f"byte order/magic is {data[:4].hex()}; expected big-endian z64 {Z64_MAGIC.hex()}"
        )
    sha1 = hashlib.sha1(data).hexdigest()
    sha256 = hashlib.sha256(data).hexdigest()
    if sha1 != EXPECTED_SHA1:
        errors.append(f"SHA-1 is {sha1}; expected {EXPECTED_SHA1}")
    if sha256 != EXPECTED_SHA256:
        errors.append(f"SHA-256 is {sha256}; expected {EXPECTED_SHA256}")
    if errors:
        raise SystemExit("Unsupported ROM:\n- " + "\n- ".join(errors))
    print(
        "Verified BattleTanx: Global Assault (USA Rev 0): "
        f"SHA-1 {sha1}, SHA-256 {sha256}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    args = parser.parse_args()
    verify(args.rom)


if __name__ == "__main__":
    main()
