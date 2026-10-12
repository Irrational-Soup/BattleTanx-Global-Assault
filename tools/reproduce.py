#!/usr/bin/env python3
"""One-command source, resource, and byte-identical ROM reproduction."""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
from pathlib import Path


def command_plan(
    root: Path,
    rom: Path,
    *,
    toolchain: bool,
    tests: bool,
    raw_only: bool,
) -> list[list[str]]:
    vpy = str(root / ".venv/bin/python")
    commands = [
        ["python3", "tools/check_repository.py"],
        ["make", ".venv/.installed"],
        [
            vpy,
            "tools/prepare_rom.py",
            "--input",
            str(rom),
            "--output",
            "baseroms/us/baserom.z64",
        ],
    ]
    if toolchain:
        commands.append(["make", "toolchain"])
    commands.extend(
        [
            ["make", "verify-code"],
            [vpy, "tools/extract_resources.py", "baseroms/us/baserom.z64"],
            [vpy, "tools/build_rom.py", "--require-original"],
            ["make", "verify-assets"],
        ]
    )
    if raw_only:
        extraction = next(
            command for command in commands if "tools/extract_resources.py" in command
        )
        extraction.append("--raw-only")
    if tests:
        commands.append(["make", "check"])
    return commands


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rom", type=Path, help="local USA Rev 0 big-endian .z64 dump")
    parser.add_argument(
        "--skip-toolchain", action="store_true", help="use already installed toolchains"
    )
    parser.add_argument("--skip-tests", action="store_true", help="omit the repository test suite")
    parser.add_argument(
        "--raw-only", action="store_true", help="omit editable/preview resource exports"
    )
    parser.add_argument(
        "--show-plan", action="store_true", help="print commands without executing them"
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    rom = args.rom.resolve()
    if rom.suffix.lower() != ".z64" or not rom.is_file():
        raise SystemExit("ROM input must be an existing local .z64 file")
    commands = command_plan(
        root, rom,
        toolchain=not args.skip_toolchain,
        tests=not args.skip_tests,
        raw_only=args.raw_only,
    )
    for command in commands:
        print("+", shlex.join(command), flush=True)
        if not args.show_plan:
            subprocess.run(command, cwd=root, env=os.environ.copy(), check=True)
    if not args.show_plan:
        print("Reproduction complete:")
        print("  compiled code: build/us/battletanx_ga.code.bin")
        print("  local resources: assets/extracted/us/")
        print("  complete ROM: build/us/battletanx_ga.z64")


if __name__ == "__main__":
    main()
