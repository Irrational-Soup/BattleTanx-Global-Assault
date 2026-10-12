"""Reusable building blocks for matching-decompilation repositories.

The package deliberately contains no game addresses or repository paths.
Projects provide those through a ``decompkit.toml`` file, while command-line
wrappers may inject compiler and ROM adapters for their own toolchains.
"""

# Keep package import side-effect free.  In particular, the legacy reporting
# CLI imports ``decompkit.config`` and is also re-exported by
# ``decompkit.report``; eager imports here would create a cycle.
__all__ = (
    "adapters", "config", "gcc_alloc", "image", "registers", "report", "rewrite",
    "tables", "tool_inventory", "units"
)
