# N64 Tooling Notes

This is a project-specific review of tools listed by [n64.dev](https://n64.dev/).
It is not a dependency list. New tools must preserve the repository's exact-ROM
comparison gate and must not turn equivalent-but-different code into a match.

## Local trial results

The following results were measured on 2026-10-08 without adding repository
dependencies:

- `m2c` generated a structurally accurate 51-line first pass for
  `func_800F6344` in 0.57 seconds. It recovered the branches, repeated player
  lookup, field offsets, and calls, but not safe types or project-ready struct
  declarations. Use it to remove transcription work, then rewrite and verify
  with `cmpfunc_strict.sh`.
- The hand-cleaned version of that candidate reached the correct size with only
  five differing words on its first strict comparison. This supports using
  `m2c` for initial control flow, but does not support treating its output as a
  match.
- `asm-differ` starts successfully in an isolated environment, but needs a
  project adapter for the KMC/IDO selection, real ROM addresses, linker symbols,
  and normalizer. The existing strict comparator remains the better unattended
  gate; `asm-differ` would mainly improve interactive diagnosis.
- `decomp-permuter` starts successfully, but its stock import path assumes a
  conventional Make-produced object. It needs a compile adapter that invokes
  this repository's compiler and normalizer and preserves relocation/rodata
  context. Trial it on two-to-twenty-word near misses after that adapter exists,
  not on structurally wrong functions.
- The current `m3c` repository is a Pokemon Snap-specific prototype with
  hard-coded developer paths, a fixed Ninja build, and a TODO where permuter
  integration should be. Do not adopt it; its useful idea is already covered by
  explicitly chaining `m2c`, a project-specific compiler wrapper, and the
  permuter.
- SN Systems ASN64 behavior was tested across 1,050 production C units. The
  repository's public-domain `tools/modern_asn64.py` matches 926 units from raw
  KMC GCC output, including every unit matched by the GPL oracle used for
  comparison. Six ROM-derived rules cover symbol-plus-base memory macros,
  large offsets, floating-point compare hazards, `remu`, and two multiply
  hazards. Production initially uses this assembler only for the seven units
  listed in `config/us/asn64_units.tsv`; compiler/register rewrites remain on
  the normalizer path.

## Use now

- `tools/decomp_batch.py` runs a TSV portfolio of candidate functions through
  `tools/decomp_permuter.py`. The search deduplicates generated source before
  compilation, deduplicates identical compiler output before scoring, divides
  a fixed compiler-worker budget across functions, and retains per-function
  ledgers plus an aggregate report under `build/decomp_search/`. Use bounded
  searches across many near matches instead of an unbounded run on one
  register-allocation plateau. A zero-word result is reported as exact only
  after its complete text span and owned rodata match at their retail
  addresses. Mutations are exploratory and still require source review.
  Select `--pipeline production`, `raw-kmc`, or `asn64` to prevent an existing
  normalizer rule from being mistaken for a clean source/compiler match.
- `tools/decomp_make_batch.py` consumes prior `INVENTORY.tsv` and
  `NEAR_MISSES.tsv` files, filters them against the current decomp report,
  selects the best recorded candidate for each still-unmatched function, and
  infers multi-function unit starts. This is the standard way to generate the
  next ranked batch without manually revisiting stale or already-integrated
  targets.
  The preprocessor supplies m2c's field/bitwise helper macros and explicit N64
  primitive widths, allowing saved raw m2c drafts to be scored alongside
  hand-cleaned candidates.
- [asm-differ](https://github.com/simonlindholm/asm-differ): add or adapt a
  local configuration for rapid, symbol-aware assembly diffs while editing a
  function. This should sit in front of the narrow object/ROM comparator; it
  does not replace the comparator or `make verify-code`.
- [decomp-permuter](https://github.com/simonlindholm/decomp-permuter): useful
  for the remaining small and medium near-misses involving expression order,
  temporary lifetimes, register allocation, and statement placement. The
  repository's `decomp_permuter.py` is the project-specific adapter: it invokes
  the exact KMC GCC path and selectable assembler pipeline, retains relocation
  and rodata context, and performs the unmasked unit comparison.
  A direct trial of upstream's broader randomizer on `func_800A4468` evaluated
  roughly 700 variants in one minute, but its only reported improvement changed
  behavior and its ordinary object scorer could not model the unit's relocated
  rodata faithfully. Keep the exact project adapter as the unattended gate;
  use upstream manual `PERM_*` alternatives only as an idea generator.
- [m2c](https://github.com/matt-kempster/m2c): continue using it to produce a
  readable first-pass C control-flow model from MIPS assembly. Treat output as
  a candidate, never as matching evidence.
- [splat](https://github.com/ethteck/splat) and
  [spimdisasm](https://github.com/Decompollaborate/spimdisasm): retain as the
  ROM segmentation and disassembly foundation. Prefer improving the existing
  configuration over introducing a parallel extraction pipeline.
- [ultralib](https://github.com/decompals/ultralib) and
  [libreultra](https://github.com/n64decomp/libreultra): use as provenance and
  source-shape references for the remaining libultra functions. Compiler,
  version, flags, section ownership, and bytes still have to be verified in
  this repository.

## Evaluate after the current integration batch

- [Abu Recipe Maker 64](https://github.com/melalawi/abu-recipe-maker-64)
  and [Abu Cake Unbake 64](https://github.com/melalawi/abu-cake-unbake-64)
  provide a useful separation between creative candidate generation and an
  objective build/prove/land stage. Their architecture is worth comparing
  against `decomp_context.py` and the campaign runner, especially immutable
  recipes and structured results. Do not vendor them casually: Unbake is
  GPL-3.0-or-later, and their BattleTanx configuration is evidence to test,
  not a substitute for this project's retail-address gate.
- [Coddog](https://github.com/ethteck/coddog) is the next retrieval tool to
  trial. Run the remaining functions against independently matched C, then use
  the returned whole-function and region-level siblings to seed types, inline
  helpers, macros, and translation-unit grouping. Similarity is hypothesis
  guidance only; it is never matching evidence.
- [Mario Golf 64](https://github.com/monde-lointain/mariogolf64) uses the same
  KMC GCC 2.7.2 flag family and contains useful libmus, libkmc, libnaudio,
  libnusys, and libultra references. Its general build permits NONMATCHING
  code, so every borrowed source shape must be independently compiled and
  compared here.
- The historical
  [EN64 BattleTanx: Global Assault symbol list](https://en64.shoutwiki.com/wiki/BattleTanx:_Global_Assult)
  corroborates numerous SDK/audio symbol identities and addresses. Treat it as
  naming evidence only; it is an old community reference under CC BY-SA 3.0,
  not source or byte-match evidence.
- [Hack64](https://hack64.net/wiki/doku.php?id=nintendo_64), the Ultra64 SDK
  manuals, and the F3DEX/S2DEX graphics notes are best used when a large target
  is probably an expansion of graphics or SDK macros. Recover the macro family
  and arguments first, then compile with this repository's actual headers and
  toolchain.

- [bdiff](https://github.com/encounter/bdiff): useful as a fast first-pass binary
  triage tool for locating changed runs before using the project's
  symbol-aware and instruction-aware comparators. It is not sufficient match
  evidence by itself.
- [n64sym](https://github.com/shygoo/n64sym): useful when identifying remaining
  SDK/library functions from RAM or code fingerprints. It is evidence for a
  symbol name, not proof of source or byte identity.
- [rabbitizer](https://github.com/Decompollaborate/rabbitizer): useful as a
  maintained MIPS instruction decoder if the local comparison, boundary-audit,
  or normalizer tests need richer opcode analysis. Prefer it over adding
  hand-maintained instruction masks.
- [romjudge](https://github.com/jkbenaim/romjudge): potentially useful as an
  additional ROM header/byte-order/checksum sanity check around releases. It
  should supplement, not replace, the known-base-ROM hash and reconstruction
  comparison.
- [y64_linker](https://github.com/ethteck/y64_linker): potentially useful for
  inspecting MIPS64 ELF relocations and extracting sections while diagnosing
  the remaining jump-table and rodata-placement problems. Validate its output
  against the repository's real linker map and ROM addresses.

## Difficult static-analysis cases

- [N64LoaderWV](https://github.com/zeroKilo/N64LoaderWV): consider for a
  Ghidra workspace when assembly plus relocation evidence is insufficient to
  establish function boundaries, jump-table ownership, or shared data. Keep
  Ghidra-derived names and types provisional until corroborated by the ROM and
  build.
- [n64ops](https://github.com/PeterLemon/N64): a compact R4300i/RCP/RSP opcode
  reference for checking unusual instructions, delay-slot behavior, and
  coprocessor operations. The VR4300 and official SDK references remain the
  authority when sources disagree.

## Later runtime validation

- [Mupen64+ Reverser Edition](https://www.retroreversing.com/mupen64RE): useful
  for breakpoints, memory inspection, and tracing when static analysis cannot
  establish behavior or data ownership.
- [ares](https://ares-emu.net/) and
  [cen64](https://github.com/n64dev/cen64): useful as higher-accuracy emulator
  checks after reconstruction remains exact and runtime tests are needed.
  Emulator success is not a substitute for byte matching or supervised tests
  on physical N64 hardware.

## Not priorities for matching decompilation

Asset exporters, modern N64 homebrew libraries/toolchains, ROM packers, and
flash-cart uploaders solve different problems. Reconsider them only for asset
documentation, an N64-native test harness, or explicitly supervised hardware
testing. They should not be mixed into the matching pipeline, and none of them
changes the decision to defer PS Vita-specific work until the portable source
base is substantially complete.

### Portfolio-wide automated campaigns

`tools/decomp_campaign.py` is the normal entry point for broad searches. It
collects all saved candidates for functions that are still unmatched in the
live report, establishes fresh baselines under both the production and ASN64
pipelines, ranks them, and searches the best candidates concurrently. It does
not edit production sources and writes a consolidated leaderboard below
`build/decomp_search/campaigns/`.

```sh
.venv/bin/python tools/decomp_campaign.py \
  --name remaining-20261010 --pipelines production,asn64 \
  --shortlist 24 --iters 500 --targets 8 --jobs 16 --resume
```

The cheap baseline stage always covers the complete candidate inventory. The
mutation stage is deliberately bounded and spends compiler time on the
closest current outputs rather than stale handoff scores. Use `--resume` after
an interruption to reuse completed stage results.

For allocator/scheduler plateaus, use the deterministic beam engine instead
of issuing one-off experiments. Each generation expands every retained
machine-code shape across every enabled mutation family, compiles the set in
parallel, removes duplicate source and duplicate object output, and retains a
diverse top set for the next generation:

```sh
.venv/bin/python tools/decomp_batch.py targets.tsv \
  --name remaining-beam --engine beam --rounds 3 --beam 10 --samples 24 \
  --max-evals 600 --targets 4 --jobs 16 --pipeline production --stop-at-zero
```

The complete ranked experiment ledger and best candidate for each function
remain under `build/decomp_search/`; production sources are never edited.

The beam engine also supports `int_type` and `param_type` families for cases
where the disassembly or GCC dumps implicate integer narrowing, extension, or
incoming-argument priority. These explore signed and unsigned 8-, 16-, and
32-bit declarations. They are not semantics-preserving in the general case:
use them only to identify a plausible original type, then review behavior and
require an exact whole-unit gate before accepting the result.

The first bounded portfolio trials evaluated 549 distinct compiler outputs
from the generic families and another 571 from the type-aware families. They
confirmed the current plateaus for `func_800A4468`, `func_80081834`,
`func_800B0E38`, `func_800D6508`, `func_800854C4`, `func_800A7090`, and
`func_800A5858`; do not repeat those same search spaces without adding a new
compiler-directed hypothesis.

Beam searches stop after two consecutive unimproved generations by default.
Use `--plateau-rounds 0` only when an intentionally deep combinatorial search
justifies continuing through a measured plateau.

### Context-first diagnosis

Do not send the entire remaining inventory directly into a wide mutation
search. First create dependency-complete contexts and classify the mismatch:

```sh
.venv/bin/python tools/decomp_context.py targets.tsv \
  --output build/decomp_search/contexts/remaining --pipeline production
.venv/bin/python tools/decomp_siblings.py targets.tsv \
  --output build/decomp_search/contexts/remaining/siblings.tsv
.venv/bin/python tools/decomp_worklist.py \
  build/decomp_search/contexts/remaining \
  build/decomp_search/contexts/remaining/siblings.tsv \
  --alternate-contexts build/decomp_search/contexts/remaining-asn64 \
  --output build/decomp_search/contexts/remaining/worklist.tsv
```

The context ID covers the source, transitive headers reported by KMC GCC,
compiler/assembler/linker binaries, normalizer, symbol map, catalogue, pipeline,
and nonempty ROM reference span. Results are structured JSON, so text printed by
a failed comparator cannot be mistaken for a match. The worklist assigns a next
experiment by failure class and lists proven matched functions with similar
mnemonic n-grams. Retrieval is hypothesis guidance only; byte identity remains
the acceptance gate.

Use mutation search only after structural, type, ownership, and toolchain causes
have been eliminated. `--max-evals` is a deterministic per-target,
per-generation ceiling; the default is 2,000. The initial unrestricted pilot
would have generated roughly 9,000 candidates per target per generation and was
stopped as economically uninformative. A 600-evaluation cap retained useful
score movement while keeping individual targets bounded.

When an inventory row has no compiling candidate, regenerate it with
`tools/decomp_m2c_refresh.py` before searching. The refresh path can consume
separately reconstructed jump tables, add names for fall-through table targets,
and apply an explicitly recorded analysis-only delay-slot workaround. Generated
drafts remain under `build/decomp_search`; compiling them establishes a measured
baseline, not a matching claim.

Byte score is never a semantic acceptance test. In particular, unrestricted
statement swaps previously produced lower scores by changing linked-list update
order and by reading a temporary before assignment. `swap_stmts` now permits
only dependency-free scalar assignments with no calls, and `alias_uses` only
copies initialized values that are never reassigned. Beam output records its
mutation lineage and whether semantic review is required in `candidate.json`.
Even a zero-word candidate still needs human source review and the exact
whole-unit gate before integration.
