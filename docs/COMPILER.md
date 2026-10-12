# Compiler identification

The executable contains multiple compiler families. Byte comparisons establish
working compiler configurations per translation unit; they do not establish
one original compiler or one set of flags for the entire game.

The matching build uses more than one original compiler family. SDK/archive
objects pin the decompals static recompilation of IDO 5.3 (`v1.2`, archive
SHA-1 `976b115acb973c3828a7215b531b203537135e38`). Game code beginning at
`0x8007B030` has a KMC GCC 2.7.2 instruction shape instead. The build pins the
decompals GCC 2.7.2 and GNU binutils 2.6 releases for those translation units;
their archive SHA-256 values are enforced by `tools/bootstrap_kmc_gcc.sh`.

KMC GCC emits deliberate filled delay slots inside explicit `.set noreorder`
regions. The initial `tools/normalize_kmc_gcc_asm.py` rules preserved those
compiler-owned regions and reproduced empty delay slots elsewhere instead of
accepting GNU assembler reorder scheduling. `func_8007B030`, `func_8007B03C`, `func_8007B1F0`, and
`func_8007B498` prove the pipeline byte-for-byte. The larger
`func_8007B65C` renderer submit loop, asset loader `func_8007BCF0`, video-mode
selector `func_8007BDFC`, and texture-tile builder `func_8007BEF0` independently
confirm the same pipeline across control flow, DMA/decompression calls, and
runtime display-list construction.

The normalizer has since gained additional rules, including function-specific
compiler-output rewrites; it must not be described as only inserting delay-slot
NOPs. See [normalizer-assisted classifications](NORMALIZER_ASSISTED.md).
Selected units instead assemble raw GCC output through `tools/modern_asn64.py`,
as declared in `config/us/asn64_units.tsv`. A clean-source claim must identify
the pipeline and distinguish assembler compatibility from compiler rewrites.

Some IDO objects use `-O2 -mips2 -non_shared -G 0`, with `-g3` selected per
translation unit when the retail scheduling requires it. In particular,
`func_8007B020` requires `-g3`, while `func_8007ADB0` only matches without it.
This is evidence that original per-file flags may differ and must be recovered
rather than imposed globally.

Every compiled function must still pass the byte-exact ROM comparison. Compiler
selection is per translation unit; neither the SDK's IDO match nor the first
GCC game-code object establishes one compiler for the entire executable.

## Diagnosing allocation through source structure

`lightning_path_subdivide` (`func_800E5BB8`) reproduces its complete 0x484-byte
text and 0x10-byte constant pool using standard gameplay flags
(`-O2 -G0 -mips3 -mgp32 -mfp32`). Both the production normalizer/KMC assembler
and raw compiler output through the ASN64 path produce the retail bytes. No
function-specific output rewrite or register binding is required.

Two compiler-stage observations explain the source form:

- A buffer pointer used only in the entry block was allocated locally to
  `s0`, before global allocation could place the main loop counter there.
  Keeping the pointer copy inside the loop-entry guard makes the original
  pointer cross a basic-block boundary. It then participates in global
  allocation, producing the retail saved-register assignment.
- Computing an endpoint as `base + count` in one expression changed the
  scheduling and local allocation of the preceding floating-point result.
  Initializing the pointer and advancing that same local in place reproduced
  the retail schedule. GCC 2.7.2's `sched.c:birthing_insn_p` uses the pseudo's
  assignment count when deciding whether to boost its scheduling priority;
  the resulting live lengths also affect `local-alloc.c:qty_compare`.

The scratch buffer's typed/flat union is an inferred representation, not a
recovered original declaration. Its flat float array allows the endpoint base
to be formed inside one array instead of forming an invalid pointer before the
distance member. Layout assertions and the complete object comparison guard
that representation. The caller's refinement counts are 4, 7, 13 and 25.

These are examples to test against RTL dumps, not universal rewrites. Confirm
the first divergent pass before using either pattern on another function.

Reusable support now lives in `decompkit.gcc_alloc` and
`decomp_register_atlas.py`. The former keeps ordinary post-reload `.greg`
assignments distinct from explicitly instrumented pre-reload observations;
the latter exhaustively tests bounded register bijections without claiming a
source-level cause. See [DECOMPKIT.md](DECOMPKIT.md) and
[MATCHING_RESEARCH.md](MATCHING_RESEARCH.md).
