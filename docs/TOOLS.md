# Tool and test map

This document separates reusable infrastructure from BattleTanx adapters and
asset-specific utilities. The distinction matters: copying a script that has
ROM addresses embedded in it is not reuse.

The exhaustive per-file catalogue is [TOOL_REFERENCE.md](TOOL_REFERENCE.md).
It is generated from `config/tooling_inventory.toml`; `make check-tools` fails
if a top-level Python/shell tool is missing, duplicated, deleted, or if the
rendered reference is stale.

## Stable reusable layer

| Capability | Interface | Evidence |
|---|---|---|
| Project policy | `tools/decompkit/config.py` and `config/decompkit.toml` | Temporary-project path/range test |
| TSV inventories | `tools/decompkit/tables.py` | Strict shape, duplicate, and overlap checks |
| Progress reports | `decompkit.report.build_report` | Toy project plus the 1,879-function production report |
| Narrow unit verification | `decompkit.units.UnitVerifier` | Injected fake compiler/reference plus real KMC adapter tests |
| Whole-image verification | `decompkit.image`, `verify_rebuilt_image.py` | SHA-256, size, and first-difference fixture tests |
| Resource extraction/reassembly | `decompkit.resources` | Synthetic complete-coverage, overlap, path, size, and hash tests plus the real 8 MiB rebuild |
| Candidate compilation | `tools/decomp_compile.py` | KMC/ASN64 pipeline tests and retail-address comparisons |
| Candidate diagnosis | `decomp_context.py`, `decomp_score.py`, `decomp_alloc_report.py` | Structured JSON/TSV outputs and compiler-dump tests |
| Register mapping | `decompkit.registers`, `decomp_register_atlas.py` | Every single-register swap, regional swaps across opcode-aligned near-matches, plus exhaustive bounded permutations across independent register classes |
| Assembly disposition | `decompkit.assembly`, `audit_assembly_segments.py` | Synthetic Splat fixture separating generated code, embedded data, padding, microcode, and authentic assembly |
| Fail-closed rewriting | `decompkit.rewrite` | Exact fire counts, unique function gates, bijective token maps, and complete line permutations |
| GCC allocation evidence | `decompkit.gcc_alloc`, `decomp_alloc_report.py` | Synthetic GCC 2.x dumps with distinct pre/post-reload assignments |
| External compiler adapters | `decompkit.adapters`, `decompkit_verify_units.py` | Synthetic subprocess compiler and arbitrary image-address mapping |
| Bounded search | `decomp_xbatch.py`, `decomp_batch.py`, `decomp_beam.py`, `decomp_permuter.py` | Deterministic seeds, bounded evaluations, retained ledgers |
| Portfolio orchestration | `decomp_make_batch.py`, `decomp_campaign.py`, `decomp_worklist.py`, `decomp_siblings.py` | Resumable manifests and ranked outputs |

`decomp_compile.py` is a BattleTanx compiler adapter today. Its public `build`
result is deliberately the adapter boundary consumed by `UnitVerifier`.
Another project should implement that result contract rather than fork the
verification algorithm.

`decomp_register_atlas.py` consumes portable JSON instead of invoking this
repository's compiler. Project adapters can export their disassembly to that
format. This prevents the shared engine from assuming MIPS register names or
incorrectly mixing GPR, FPR, ABI-reserved, or architecture-specific classes.

## Stable project adapters

- `generate_decomp_report.py` loads TOML policy and invokes the reusable report
  engine. Its old flags remain supported.
- `verify_decomp_units.py` connects `UnitVerifier` to this repository's KMC,
  ASN64, linker, symbols, and base-ROM reader.
- `build_code.sh`, `cmpfunc_strict.sh`, and the bootstrap scripts establish the
  exact historical toolchain and should be adapted per project.
- `extract_resources.py`, `build_rom.py`, and `reproduce.py` connect the
  portable region engine to BattleTanx's verified ROM map and present the
  one-command owned-ROM workflow.
- `check_o2r_readiness.py` validates the staged runtime-resource ledger and
  rejects O2R-ready claims without a serializer, resource type, and factory.
- `normalize_kmc_gcc_asm.py`, `normalize_libgcc_asm.py`, and
  `segment_billboard_normalizer.py` are title/compiler-output policy. Their
  fail-closed rule design is reusable; their concrete rewrites are not.

## Format libraries and title-specific front ends

Reusable codec/format modules include `lzari.py`, `n64_texture.py`,
`btga_world.py`, and `modern_asn64.py`. Their `inventory_*`, `extract_*`, and
`pack_*` companions are command-line front ends. BattleTanx table addresses
belong in those front ends or data manifests, not in the codec primitives.

The ROM verifier, asset-corpus verifier, typed-rodata verifier, symbol importer,
and ELF section utilities are deterministic release/build tools. Each has a
corresponding focused test or is exercised by `make verify-code`/`make
verify-assets`.

## Experimental-to-production rule

Compiler probes and candidate generators may begin as short-lived experiments.
Promote one only when it has:

1. a documented input and output contract;
2. deterministic operation or an explicit seed;
3. no private paths, ROM bytes, generated assembly, or hardware evidence;
4. fail-closed validation for transformations;
5. a synthetic fixture that does not require copyrighted input; and
6. a narrow byte comparison followed by the repository-wide gate.

The measured tool evaluations and compiler experiments are recorded in
[N64_TOOLING.md](N64_TOOLING.md), [COMPILER.md](COMPILER.md), and
[NORMALIZER_ASSISTED.md](NORMALIZER_ASSISTED.md). Those documents state what
was tested, what failed, and what conclusions the evidence supports; they are
not generic folklore or unverified recipes.

## Test tiers

- `make check-tools`: reusable package, report, and narrow-verifier tests. No
  private ROM is needed.
- `make check`: complete Python test suite plus repository safety audit.
- `make verify-code`: authoritative byte-identical reconstructed-ROM gate.
- `make verify-assets`: authoritative inventory/repack gate for the supplied
  private base ROM.
- `make build-rom`: compiles the source prefix, extracts the local resource
  map, and requires the complete 8 MiB output to match the retail SHA-256.

Host-only tests validate parsers and transformations, not Vita correctness.
Future Vita gates must cross-build for little-endian ARMv7-A ILP32, inspect ELF
floating-point attributes and alignment, and then use supervised physical
hardware testing.
