#!/usr/bin/env python3
"""Fail when private/generated artifacts or host-specific paths are tracked."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

FORBIDDEN_SUFFIXES = {
    ".z64", ".n64", ".v64", ".elf", ".vpk", ".self", ".velf", ".psp2dmp"
}
FORBIDDEN_PATTERNS = (
    re.compile(rb"/home/[A-Za-z0-9._-]+/"),
    re.compile(rb"[A-Za-z]:\\Users\\[A-Za-z0-9._-]+\\"),
    re.compile(rb"gh[opsu]_[A-Za-z0-9_]+"),
)
def remote_failure(url: str) -> str | None:
    normalized = url.strip().rstrip("/")
    if normalized.lower().endswith(".git"):
        normalized = normalized[:-4]
    normalized = normalized.replace("git@github.com:", "https://github.com/")
    normalized = normalized.replace("ssh://git@github.com/", "https://github.com/")
    if normalized.lower() == "https://github.com/thegh0stship/vitatanxga":
        return (
            "forbidden origin for the N64 decompilation worktree: " + url.strip()
            + " (use TheGh0stShip/BattleTanx-Global-Assault)"
        )
    return None


def main() -> None:
    tracked = subprocess.check_output(["git", "ls-files", "-z"]).split(b"\0")
    failures: list[str] = []
    origin = subprocess.run(
        ["git", "remote", "get-url", "origin"], capture_output=True, text=True
    )
    if origin.returncode == 0:
        failure = remote_failure(origin.stdout)
        if failure:
            failures.append(failure)
    for raw_name in filter(None, tracked):
        name = raw_name.decode()
        if any(name.lower().endswith(suffix) for suffix in FORBIDDEN_SUFFIXES):
            failures.append(f"forbidden tracked artifact: {name}")
            continue
        path = Path(name)
        if not path.is_file():
            # A tracked file may be intentionally deleted in the current
            # worktree before the deletion is staged or committed.
            continue
        data = path.read_bytes()
        if any(pattern.search(data) for pattern in FORBIDDEN_PATTERNS):
            failures.append(f"private path or token pattern: {name}")
    if failures:
        raise SystemExit("\n".join(failures))
    print(f"Repository safety check passed ({len(tracked)} tracked files)")


if __name__ == "__main__":
    main()
