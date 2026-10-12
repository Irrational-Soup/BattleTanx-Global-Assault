# Reusable matching-decompilation toolkit

The reporting and narrow verification machinery is available as the importable
`tools/decompkit` package. Project policy lives in `config/decompkit.toml`; it
is not embedded in the library. Existing script names remain compatibility
command-line entry points.

## Components

- `decompkit.config` resolves paths, tracked address ranges, source-bearing
  segment kinds, and compiler-pipeline manifests.
- `decompkit.tables` strictly parses TSV ownership and manifest tables.
- `decompkit.report` builds an objdiff v2/decomp.dev report from explicit
  catalogues, layouts, ownership, and address policy.
- `decompkit.units.UnitVerifier` performs byte-exact text and rodata checks.
  Compiler and reference-byte readers are injected, so it is not tied to KMC,
  MIPS, an N64 ROM, or this repository.
- `decompkit.image` compares complete reconstructed images, reporting both
  SHA-256 values, sizes, and the first differing offset. The accompanying
  `verify_rebuilt_image.py` command never treats a matching prefix as a
  matching complete image.

The tools deliberately do not infer target architecture. Consumers provide
their own compiler adapter and reference reader. Vita work remains ARMv7-A,
little-endian ILP32; inspect ELF attributes for hard-float versus softfp rather
than inferring an ABI from Cortex-A9 capabilities.

## Configuration

Copy `config/decompkit.toml`, then change all project paths and ranges. Paths
are relative to `project.root`, which is relative to the TOML file.

```toml
[project]
root = ".."
functions = "config/us/functions.toml"
splat = "config/us/splat.yaml"
source_dir = "src/code"
report_source_root = "src"
rodata = "config/us/unit_rodata.tsv"
data = "config/us/unit_data.tsv"
exclusions = "config/us/data_exclusions.tsv"
report_output = "build/us/report.json"

[report]
vram_delta = 0x80000000
code_end = 0x100000
image_start = 0x1000
image_end = 0x90000
source_kinds = ["c", "hasm"]

[units]
manifests = [
  { path = "config/us/clean_units.tsv", pipeline = "production" },
]
```

## Commands and API

```sh
python3 tools/generate_decomp_report.py --config config/decompkit.toml
python3 tools/verify_decomp_units.py --config config/decompkit.toml unit_name
python3 tools/verify_rebuilt_image.py reference.z64 rebuilt.z64
make check-tools
```

The report command also accepts `--functions`, `--splat`, and `--output`
overrides. Other projects construct
`UnitVerifier(config, build, reference_bytes)`: `build` is their compiler/linker
adapter, while `reference_bytes(address, size)` reads their authoritative image.

## Rules for reusable additions

`tests/test_decompkit.py` creates an unrelated temporary toy project. This
proves the library works without BattleTanx paths, addresses, pipeline names,
toolchain, or ROM. Project totals remain in title-specific tests.

1. Put algorithms and parsers in `decompkit` with dependencies injected.
2. Put title-specific paths, addresses, and pipelines in TOML/TSV.
3. Keep scripts as thin adapters and stable compatibility commands.
4. Test shared behavior with temporary fixtures, never a private ROM.
5. Keep byte comparison—not behavioral similarity—as the matching gate.

Lane-local experiments should be promoted only after gaining a documented
input format, deterministic output, fail-closed validation, and fixture tests.
