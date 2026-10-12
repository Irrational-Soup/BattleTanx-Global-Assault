#!/usr/bin/env python3
"""Compatibility CLI for :mod:`decompkit.report`."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from decompkit.report import *  # noqa: F401,F403,E402
from decompkit.report import main  # noqa: E402


if __name__ == "__main__":
    main()
