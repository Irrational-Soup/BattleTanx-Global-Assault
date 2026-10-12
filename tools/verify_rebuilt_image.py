#!/usr/bin/env python3
"""Compare a complete rebuilt binary image against its reference."""

import argparse
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from decompkit.image import compare_files  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("reference", type=Path)
    parser.add_argument("rebuilt", type=Path)
    args = parser.parse_args()
    result = compare_files(args.reference, args.rebuilt)
    print(f"reference size={result.reference_size} sha256={result.reference_sha256}")
    print(f"rebuilt   size={result.rebuilt_size} sha256={result.rebuilt_sha256}")
    if not result.exact:
        location = "end of shorter image" if result.first_difference is None else f"0x{result.first_difference:X}"
        raise SystemExit(f"images differ; first difference: {location}")
    print("Images are byte-identical")


if __name__ == "__main__":
    main()
