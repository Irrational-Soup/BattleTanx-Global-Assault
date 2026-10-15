# Reusable matching-decompilation toolkit

The reporting and narrow verification machinery is available as the importable
`tools/decompkit` package. Project policy lives in `config/decompkit.toml`; it
is not embedded in the library. Existing script names remain compatibility
command-line entry points.

## Components

- `decompkit.config` resolves paths, tracked address ranges, source-bearing
  segment kinds, and compiler-pipeline manifests.
- `decompkit.tables` strictly parses TSV ownership and manifest tables.
- `decompkit.report` builds an objdiff v2 progress report from explicit
  catalogues, layouts, ownership, and address policy.
- `decompkit.units.UnitVerifier` performs byte-exact text and rodata checks.
  Compiler and reference-byte readers are injected, so it is not tied to KMC,
  MIPS, an N64 ROM, or this repository.
- `decompkit.image` compares complete reconstructed images, reporting both
  SHA-256 values, sizes, and the first differing offset. The accompanying
  `verify_rebuilt_image.py` command never treats a matching prefix as a
  matching complete image.
- `decompkit.resources` serializes an injected region map into deterministic
  local files and reconstructs a complete image from those files plus an
  independently compiled prefix. It validates coverage, overlap agreement,
  paths, sizes, and optional pristine hashes without assuming a console, ROM
  byte order, or title-specific table.
- `decompkit.registers` ranks every single-register swap or exhaustively ranks
  explicitly bounded register bijections over an architecture-neutral
  instruction representation. It rejects factorially large searches rather
  than consuming unbounded time.
- `decompkit.assembly` inventories Splat `asm`/`hasm` rows and separates
  generated code, embedded data, padding, microcode, and authentic assembly.
- `decompkit.rewrite` provides exact-fire-count replacement, unique function
  selection, simultaneous token renaming, and checked line permutations for
  fail-closed normalizers.
- `decompkit.gcc_alloc` parses GCC 2.x local/global allocation dumps and
  optional instrumented pre-reload records without invoking a compiler.
  Pre-reload and post-reload assignments remain explicitly separate.
- `decompkit.adapters.CommandBuildAdapter` lets any compiler/linker pipeline
  participate through versioned JSON request/response files and an argv-only
  subprocess (never a shell). `ImageReference` injects the project's address
  mapping rather than assuming an N64 ROM layout.

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
python3 tools/decomp_register_atlas.py built.json reference.json \
  --group 's0,s1,s2=s0,s1,s2' --group 'f20,f22=f20,f22'
python3 tools/decomp_register_atlas.py built.json reference.json \
  --single-swaps --improving-only --group 's0,s1,s2=s0,s1,s2'
python3 tools/decomp_register_atlas.py built.json reference.json \
  --regional-swaps --group 's0,s1,s2=s0,s1,s2'
python3 tools/decomp_register_atlas.py built.json reference.json \
  --regional-swaps --align-opcodes --group 'f0,f2,f4,f6=f0,f2,f4,f6'
python3 tools/decomp_register_atlas.py built.json reference.json \
  --window 300:420 --align-opcodes --group 's4,s5,s6=s4,s5,s6'
python3 tools/audit_assembly_segments.py --splat config/us/splat.yaml \
  --asm-root asm/us --json build/us/assembly-inventory.json
make assembly-report
python3 tools/decompkit_verify_units.py --config project.toml \
  --reference baserom.z64 \
  --adapter-command 'python3 adapter.py {request} {response}'
make check-tools
```

The assembly inventory distinguishes full generated-code candidates from tiny
orphan fragments that lack a function return. Those fragments remain visible
as `ambiguous-fragment`; the audit does not inflate them into missing functions
or silently assert that they are padding.

`--align-opcodes` keeps insertions, deletions, and opcode substitutions as
structural mismatch cost while searching each equal-opcode region separately.
Use it for near-matches containing an assembler hazard `nop`; reported windows
retain the candidate stream's original instruction indices and addresses.
`--window START:END` exhausts every bounded permutation in one selected region,
including three-or-more-register cycles that pair swaps cannot discover. The
ordinary factorial search-space limit still applies.

For a project with an independently rebuilt prefix and a mapped resource tail:

```python
from decompkit.resources import extract_regions, rebuild_image

manifest = extract_regions(reference, regions, output_dir, include_after=len(prefix))
rebuilt = rebuild_image(prefix, manifest, output_dir, require_pristine_resources=True)
```

Regions are dictionaries containing `start`, `end`, and optional `name` and
`kind` fields. The generated manifest is portable JSON; title-specific code is
responsible only for deriving an authoritative non-overlapping range map.

The register-atlas JSON format is independent of objdump:

```json
[{"opcode": "addiu", "operands": ["s0", "s1", "4"]}]
```

Architecture adapters preserve non-register operands verbatim and place only
genuinely interchangeable registers in the same `--group`. The tool reports
the exact search-space size and ranks every bijection. Its default maximum is
100,000 permutations; increase it deliberately with `--limit`.

### Compiler adapter protocol

The portable unit-verifier CLI writes this request:

```json
{"format":"decompkit-build-request-v1","source":"/abs/unit.c","vram":4096,"pipeline":"production"}
```

The adapter compiles and links the unit, then writes:

```json
{
  "format": "decompkit-build-response-v1",
  "text_hex": "27bdffe0...",
  "text_size": 64,
  "rodata_hex": "3f800000",
  "rodata_vram": 8192
}
```

`rodata_hex` may be `null` or omitted. Commands are parsed as argv and must
contain separate `{request}` and `{response}` entries. This boundary makes the
verifier reusable with IDO, GCC, SN64, proprietary wrappers, or a test double
without embedding their flags and paths in the verification algorithm.

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
