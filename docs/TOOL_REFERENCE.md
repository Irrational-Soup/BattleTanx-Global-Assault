# Complete tool reference

This file is generated from `config/tooling_inventory.toml`. Every maintained
top-level Python and shell tool must occur exactly once. Scope describes whether
the implementation is portable, a project/toolchain adapter, or title-specific.

## Portable decompkit interfaces

**Scope:** `portable`

**Evidence:** Synthetic temporary-project tests in tests/test_decompkit.py and make check-tools.

Architecture-neutral reporting, verification, register-search, image-comparison, and inventory entry points.

| Tool | Purpose |
|---|---|
| `audit_tooling.py` | Validate the complete tool inventory and optionally refresh its reference. |
| `decomp_register_atlas.py` | Exhaustively rank bounded register mappings between aligned instructions. |
| `decompkit_verify_units.py` | Verify units using decompkit's portable subprocess adapter protocol. |
| `generate_decomp_report.py` | Compatibility CLI for :mod:`decompkit.report`. |
| `verify_rebuilt_image.py` | Compare a complete rebuilt binary image against its reference. |

## Candidate measurement and search

**Scope:** `adapter`

**Evidence:** tests/test_decomp_search.py, tests/test_decomp_campaign.py, retained JSON/TSV ledgers, and narrow byte comparisons.

Deterministic candidate compilation, diagnosis, bounded mutation, sibling retrieval, and portfolio orchestration over the BattleTanx KMC adapter.

| Tool | Purpose |
|---|---|
| `asmlift_prepare.py` | Extract one splat function and make its local labels acceptable to Asmlift. |
| `decomp_alloc_report.py` | Report GCC 2.7.2 local/global register-allocation evidence. |
| `decomp_batch.py` | Run bounded candidate searches across a portfolio of decompilation targets. |
| `decomp_beam.py` | Deterministic batched beam search for matching-decomp candidates. |
| `decomp_campaign.py` | Run a resumable, portfolio-wide matching-decomp search campaign. |
| `decomp_compile.py` | Shared KMC GCC 2.7.2 build/disassembly library for the matching tools. |
| `decomp_context.py` | Create immutable build contexts and structured diagnoses for decomp candidates. |
| `decomp_flag_sweep.py` | Sweep evidence-backed KMC GCC flag sets across unresolved candidates. |
| `decomp_m2c_refresh.py` | Regenerate and gate fresh m2c drafts for unscorable worklist targets. |
| `decomp_make_batch.py` | Build a ranked decomp_batch manifest from prior TSV experiment inventories. |
| `decomp_permuter.py` | permute.py - decomp-permuter-style random source search on the project's exact pipeline. |
| `decomp_score.py` | Structured mismatch classifier for one function of a KMC GCC candidate. |
| `decomp_siblings.py` | Rank already reconstructed functions as structural references for targets. |
| `decomp_worklist.py` | Combine context diagnoses and sibling retrieval into an explicit work ledger. |
| `decomp_xbatch.py` | Evaluate an explicit matrix of source hypotheses with the repository gate. |
| `run_decomp_campaign.py` | Re-gate maintained decompilation candidates as one parallel campaign. |

## Pinned toolchain bootstraps

**Scope:** `adapter`

**Evidence:** Pinned URLs/checksums or revisions in each script; exercised by setup/toolchain builds and compiler calibration.

Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project.

| Tool | Purpose |
|---|---|
| `bootstrap_armips.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `bootstrap_f3dex2.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `bootstrap_ido.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `bootstrap_kmc_gcc.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `bootstrap_mips_binutils.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `bootstrap_ultralib.sh` | Download, verify, patch, and build the historical compilers, assemblers, SDK sources, and diagnostic GCC variants required by this project. |
| `build_diagnostic_gcc272.sh` | Build a diagnostic-only stock GCC 2.7.2 cc1 for the MIPS backend. This never replaces or modifies .toolchain/kmc-gcc-2.7.2.  The resulting cc1 is evidence tooling and must be calibrated against KMC for every candidate. Usage: tools/build_diagnostic_gcc272.sh [OUT_DIR] [PATCH ...] PATCH files are applied after the modern-host compatibility edits and before configuration.  This lets a lane add allocation/reload/scheduler tracing without maintaining another compiler source tree. |
| `build_diagnostic_gcc272_alloc.sh` | Convenience build for the maintained allocation/scheduling diagnostic patch set. |

## Build and ELF plumbing

**Scope:** `adapter`

**Evidence:** make verify-code plus focused ELF/placement tests in the repository test suite.

Build the reconstructed code image and perform deterministic ELF32/MIPS section, symbol, and placement operations.

| Tool | Purpose |
|---|---|
| `build_code.sh` | Build the reconstructed code image and perform deterministic ELF32/MIPS section, symbol, and placement operations. |
| `cmpfunc_strict.sh` | cmpfunc.py currently exits zero for both MATCH and DIFF.  Its RESULT line is authoritative, so convert that textual result into a useful process status. |
| `fix_ido_symtab.py` | Make IDO 5.3 assembler objects acceptable to GNU ld: put LOCAL symbols before GLOBAL ones in .symtab. |
| `generate_linker_symbols.py` | Convert splat symbol files into non-overriding linker-script symbols. |
| `insert_elf32_section_bytes.py` | Insert zero bytes before a symbol inside a fixed-size ELF32 section. |
| `place_unit_rodata.py` | Place selected C-unit rodata, data, and bss sections at retail VMAs. |
| `rename_retail_asm_labels.py` | Rename generated asm definitions shadowed by typed C rodata objects. |
| `set_elf32_mips_o32.py` | Mark a 32-bit big-endian MIPS ELF object as o32/32-bit mode. |
| `splice_unit_rodata.py` | Splice fixed-VMA unit rodata/data sections into the code image. |
| `trim_elf32_section.py` | Trim assembler-owned tail padding from a generated ELF32 section. |

## Compiler and assembler compatibility

**Scope:** `adapter`

**Evidence:** tests/test_kmc_pipeline.py, tests/test_asn64_conformance.py, and complete make verify-code coverage.

Reproduce documented historical compiler/assembler output differences with function-gated, fail-closed transformations.

| Tool | Purpose |
|---|---|
| `modern_asn64.py` | Preprocesses an input asm file to match asn64's reordering and macro expansion, then passes it to the provided assembler. VitaTanxGA lane copy of RocketRet/modern-asn64 @ 20d21729ce6a2e7bc8a4a91ec9505cab0d6e50f9 (Unlicense). Lane changes are marked "LANE <rule-id>"; provenance for every rule is in ../PROVENANCE.tsv. No code or logic in this file is taken from GPL sources; GPL n64link was used only as a black-box output oracle. Set MODERN_ASN64_DISABLE=<id>[,<id>...] to switch individual lane rules off (used by negative tests). |
| `normalize_kmc_gcc_asm.py` | Make KMC GCC 2.7.2 assembly scheduling deterministic. |
| `normalize_libgcc_asm.py` | Reproduce the retail assembler's unfilled libgcc return delay slots. |
| `segment_billboard_normalizer.py` | func_8009FFB8 (segment_billboard_matrix): lane-proven regional allocation / scheduling rules.  Generated from claude-work/output/close-9ffb8 (rules9.py, rules9_blocks.py); every block rule was verified there by value-level simulation (slots9.verify_slots / websafe) against whole-function liveness. ROT  : saved-register roles s4->s5, s5->s6, s6->s4 (frame save/restore lines stay tied to their physical registers). P1   : entry copies scheduled into the prologue (retail order). H1   : the c.eq.s -> bc1t slot vacated by P1 receives the MIPS III hazard nop. P2,R3,R3b,R4 : per-value FP register renaming (plus two independent store swaps) in the length, relative, plane/side and clipping blocks. |

## Repository and ROM release gates

**Scope:** `title-specific`

**Evidence:** make check, make verify-code, make verify-assets, and SHA-256/reference-range documentation.

Verify the supported private ROM, source hygiene, translation units, typed data, complete asset corpus, and full ROM accounting.

| Tool | Purpose |
|---|---|
| `check_repository.py` | Fail when private/generated artifacts or host-specific paths are tracked. |
| `inventory_rom_layout.py` | Account for every byte in the BattleTanx: Global Assault retail ROM. |
| `prepare_rom.py` | Locate a local supported dump, verify it, and copy it to the canonical path. |
| `verify_asset_corpus.py` | Verify every known retail resource family without extracting ROM data. |
| `verify_decomp_units.py` | Narrow integration gate for selected reconstructed C translation units. |
| `verify_rom.py` | Verify and identify the supported BattleTanx GA ROM without modifying it. |
| `verify_typed_rodata.py` | Compile and ROM-compare all transitional typed rodata units in parallel. |

## Reusable format primitives

**Scope:** `portable`

**Evidence:** Codec round trips, texture fixtures, world-layout tests, and complete asset-corpus rebuilds.

Independent codecs and binary-format helpers whose algorithms do not embed ROM addresses.

| Tool | Purpose |
|---|---|
| `decode_libmus_wave.py` | Decode one Sound Tools PTR/WBK wave to an inspection-only PCM16 WAV. |
| `lzari.py` | Decode BattleTanx: Global Assault's big-endian LZARI streams. |
| `n64_texture.py` | Decode the N64 texture layouts used by BattleTanx: Global Assault. |

## BattleTanx asset inventories

**Scope:** `title-specific`

**Evidence:** tests/test_asset_tools.py, tests/test_rom_inventory.py, and make verify-assets.

Decode and account for BattleTanx-specific tables, compressed streams, scripts, worlds, geometry, textures, display lists, and retained debug/object data.

| Tool | Purpose |
|---|---|
| `btga_world.py` | Parse the fixed-record sections of a Global Assault world bundle. |
| `extract_lzari_images.py` | Extract the game's LZARI-compressed N64 images as PNG previews. |
| `extract_lzari_worlds.py` | Extract structured manifests for every LZARI-compressed Global Assault world. |
| `inventory_libmus_assets.py` | Validate, inventory, and optionally split Global Assault's libmus assets. |
| `inventory_lzari_assets.py` | Inventory and optionally extract ROM-resident LZARI asset streams. |
| `inventory_script_assets.py` | Decode and optionally split the game's 17 script/cutscene assets. |
| `inventory_stale_debug.py` | Inventory the compact debug-name table left in the retail ROM. |
| `inventory_stale_object.py` | Verify the stale, unlinked Steps object fragment retained in the ROM. |
| `inventory_world_display_lists.py` | Inventory F3DEX2 command streams inside the three raw world pools. |
| `inventory_world_geometry.py` | Decode and validate F3DEX2 meshes in the raw world geometry pool. |
| `inventory_world_pools.py` | Inventory raw GEO, PB, and TEX chunks referenced by decoded worlds. |
| `inventory_world_textures.py` | Recover world-texture metadata from paired texture and state display lists. |

## BattleTanx asset rebuilders

**Scope:** `title-specific`

**Evidence:** Round-trip tests and make verify-assets comparisons against every owned retail byte.

Rebuild independently extracted BattleTanx audio, compressed bundles, scripts, worlds, and raw world pools for lossless comparison.

| Tool | Purpose |
|---|---|
| `pack_libmus_assets.py` | Rebuild the contiguous libmus store from its independently split files. |
| `pack_lzari_bundle.py` | Build and compress a seven-component BattleTanx asset bundle. |
| `pack_script_assets.py` | Rebuild split BattleTanx: Global Assault script/cutscene assets. |
| `pack_script_json.py` | Rebuild a script/cutscene asset from inventory_script_assets JSON. |
| `pack_world_json.py` | Rebuild and LZARI-compress a world emitted by extract_lzari_worlds.py. |
| `pack_world_pools.py` | Rebuild raw world pools from extracted chunks and unreferenced gaps. |

## One-time provenance import

**Scope:** `title-specific`

**Evidence:** Imported symbol ledger, function catalogue validation, and make verify-code.

Import externally refined symbol boundaries while preserving provenance and requiring subsequent local byte verification.

| Tool | Purpose |
|---|---|
| `import_recomp_symbols.py` | Annotate seed symbols using btgarecomp's refined function boundaries. |
