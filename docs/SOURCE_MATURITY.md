# Source maturity and naming policy

The matching decompilation is complete, but a byte-exact program is not the
same thing as a fully recovered original source tree. Many functions still use
address-derived identities, some translation-unit boundaries remain inferred,
and compatible local types have not necessarily been unified into their
original declarations. This document defines how those areas should mature
without turning plausible guesses into apparent facts.

## Recommendation

Do not perform a repository-wide function rename or directory reorganization
based only on similarity to named functions. Similar instruction sequences,
shared callees, or matching field offsets are valuable research clues, but do
not by themselves prove a routine's purpose, its original name, or its source
file.

Instead, migrate one evidenced subsystem or translation unit at a time. This
keeps reviews intelligible, preserves archaeology by address, and makes a
wrong hypothesis cheap to correct.

## Naming evidence

A semantic name should carry one of these evidence levels:

1. **Recovered name.** A retail debug artifact, SDK/libmus source, symbol
   record, or independently identified upstream source establishes the name.
2. **Established behavior.** Callers, data types, side effects, return values,
   and subsystem context establish a narrow descriptive contract. These names
   describe observed behavior; they are not claimed to be original names.
3. **Provisional hypothesis.** Similarity or incomplete behavioral evidence
   suggests a role. Keep the address identity canonical and record the proposed
   name in a ledger or comment until stronger evidence appears.

Similarity to a named function is supporting evidence for levels 2 or 3, never
enough by itself for level 1.

Names should be specific to what is proven. Prefer `tank_fire_weapon` when the
receiver, effects, and callers establish that contract; prefer an address name
over a confident-sounding but speculative label such as `update_ai`.

## Stable address identity

Every semantic rename must retain a searchable mapping to its original ROM
address. The address belongs in the symbol/configuration record and, where
useful, the source filename during the transition. Existing call sites,
normalizer gates, rodata ownership, research notes, and external tooling must
remain traceable across the change.

Do not use a mass textual replacement as the migration record. Maintain a
machine-readable ledger with at least:

- ROM address and previous symbol;
- new source and linker symbol;
- evidence level and concise justification;
- translation-unit or subsystem assignment;
- commit introducing the change.

The project ledger is `config/source_renames.tsv`; Git history records the
introducing commit for each row. `make check-source-names` enforces the
`ADDRESS_description.c` convention for migrated and newly added game units.
Existing exceptions are frozen in `config/source_naming_legacy.txt`: new rows
are rejected, and migrations remove rows from that baseline.

`config/us/recovered_debug_symbols.tsv` is authoritative for the stale debug
symbols it contains. `docs/PROVENANCE.md`, `docs/GAME_CODE.md`, and the manual
symbol tables contain other evidence that must be reconciled rather than
overwritten.

## Directory and translation-unit policy

Directories represent proven ownership, not aesthetic grouping. The existing
`libmus/` and `n_audio/` directories are good examples because their library
identity and source families are independently supported.

Create a game subsystem directory only when multiple signals agree, such as:

- recovered or strongly supported translation-unit boundaries;
- shared private types, statics, literal pools, and inline helpers;
- coherent caller/callee and global-data ownership;
- matching compiler behavior when the functions are compiled together;
- known library or original-source provenance.

Do not organize files merely because functions appear to concern the same
high-level feature. A renderer can span several original files, and one
original file can contain helpers that look unrelated after inlining.

Moves should be incremental: one translation unit or compact subsystem per
commit. Avoid a repository-wide reshuffle that mixes path churn with type,
symbol, and source changes.

## Required gate for a rename or move

Each change must:

1. update source, headers, configuration tables, rodata/data ownership,
   normalizer gates, tests, and documentation as one coherent change;
2. preserve the old address-to-name mapping;
3. state the evidence level and supporting facts;
4. pass the narrow object comparison while being developed;
5. pass `make verify-code` before being described as matched;
6. pass repository tests and safety checks;
7. avoid including generated assembly, extracted assets, ROMs, or build
   products.

A rename is not allowed to hide a normalizer-assisted unit or change its
classification. Matching method and semantic confidence are separate facts.

## Higher-value maturity work

The most useful next work is not maximizing the percentage of pretty names.
Prioritize:

- reconstructing original translation units and private inline families;
- consolidating repeated compatible structures into evidence-backed headers;
- documenting subsystem APIs, global ownership, and callback signatures;
- generating call graphs, data-ownership reports, and the rename ledger from
  repository metadata;
- replacing one-off research scripts with parameterized `decompkit` commands
  and synthetic regression tests;
- keeping the N64 matching tree separate from host and Vita portability work.

This produces a source base that is easier to understand and reuse while
preserving the distinction between what is proven, what is descriptive, and
what remains a hypothesis.
