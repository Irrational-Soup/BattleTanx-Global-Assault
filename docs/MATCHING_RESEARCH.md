# Reproducible KMC GCC matching findings

This note records compiler behavior established while completing the matching
decompilation. Each item names the evidence and its limits. These are
hypotheses to test in another KMC GCC 2.7.2 project, not universal C rewrite
rules. Exact object or ROM comparison remains the deciding evidence.

## Experimental method

For difficult functions, the useful sequence was:

1. establish a dependency-complete translation unit at its real link address;
2. compare production KMC assembly with a second assembler path to distinguish
   compiler output from assembler hazards;
3. find the first divergent compiler pass using `-da` RTL dumps;
4. alter one source property at a time and retain compiled negative controls;
5. inspect local/global allocation priorities only after confirming compiler
   parity; and
6. re-gate the complete text and owned rodata, not an isolated function body.

Diagnostic compiler patches were trace-only. A trace was accepted only when
tracing on/off emitted identical instructions and the diagnostic compiler
matched the pinned KMC compiler. Private compiler modifications never entered
the production build.

## Findings with repeated evidence

### Source scopes and uses affect allocation more than apparent semantics

GCC 2.7.2 allocates pseudos using reference counts and live ranges. Equivalent
C can therefore change saved-register order, caller-saved pressure, spill-slot
count, and frame size.

- In `func_800A77A8`, one index shared across two loops raised the counter's
  allocation priority above the loop-strength-reduced pointer and produced the
  retail registers. Separate block-local indices did not.
- In `func_8008B82C`, reusing an incoming parameter as the current-position
  pointer created the retail five-saved-register shape; a block-local pointer
  stayed caller-saved.
- In `func_80080CC8`, assigning `&hit` inside a call argument allowed loop
  optimization to hoist the address into the expected saved register. Passing
  plain `&hit` did not.

Implication: before adding artificial `register` declarations, test authentic
scope, reuse, and inline-boundary hypotheses and inspect allocator evidence.

### CSE follows control-flow facts aggressively

The compiler propagates facts along followed jump edges, sometimes removing an
instruction that retail retains.

- In `func_800B74B4`, a 16-bit scan-start parameter rebuilt the same
  zero-extended value tested on the incoming edge, allowing CSE to prove it
  zero and fold an `sltu`. A full-width start parameter preserved the retail
  comparison. Making the scan result `u16` then merged duplicate extensions
  and removed a compensating copy.
- In `func_800B5130` and `func_800B49E0`, CSE shared one zero-extension among a
  direction-table lookup, call argument, and row multiplication. Keeping an
  `int` raw counter and a block-local `u16 dir` produced distinct pseudos and
  restored the retail raw multiply.

Implication: when one cast appears to affect distant code, inspect equivalence
classes before changing control flow or introducing volatile accesses.

### Inline expansion changes loop optimization thresholds

The standalone body of an inline function need not optimize like an inlined
copy. `func_800B4F38` has no ROM call references, consistent with a public
inline function emitted out of line while also being expanded into
`func_800B5130`.

In measured GCC loop dumps, two near-identical copies crossed the address-hoist
desirability boundary at 98 versus 99 loop-time instructions. Inline parameter
copies can exist at the loop pass and disappear later, changing hoisting even
when final instructions look unrelated.

Implication: reconstruct translation-unit and inline provenance before treating
standalone/inlined disagreement as different source text.

### Struct grouping is an aliasing decision, not merely documentation

In `func_8009FFB8`, declaring six debug globals as two `Vec3` records instead
of six independent floats changed alias analysis. This prevented player-field
loads from moving across stores, relieved floating-point register pressure,
restored the retail frame, and removed spill instructions. It was the key
source correction before safe regional register normalization.

Similarly, an `InfoPair` struct assignment in `func_800A77A8` reproduced a
retail paired-load/paired-store schedule that manual scalar assignments did
not.

Implication: recovered aggregate boundaries influence scheduling and CSE. Test
them with layout assertions and full-object comparison.

### Literal-pool ownership reveals translation-unit boundaries

Constants emitted by neighboring functions can share one pool only when the
functions share a translation unit. The `func_800B6F40`/`func_800B739C` pool
and several gameplay-family investigations used pool order and first-use order
to constrain source grouping. Immediate construction versus pooled literals
also exposed branch-join structure in `func_8008B82C`.

Implication: compare text and rodata as one unit and record ownership explicitly.

### KMC assembler hazards must be separated from compiler decisions

The production and ASN64 paths repeatedly emitted identical compiler assembly
but different final `nop` placement. Confirmed cases include labels directly
before `mul.s`, floating-point compare/branch hazards, consecutive multiplies,
and HI/LO timing.

Implication: a source rewrite is unjustified until raw compiler assembly has
been compared. Assembler compatibility rules should be opcode-specific,
function-gated when necessary, counted, and tested with drift negatives.

## Normalizer-assisted matching

Some final units reproduce retail through narrowly scoped compiler-output
normalization. This is still a decompilation, but it is classified separately
from a clean source/compiler match. The acceptance standard is:

- recovered, defined C with no register pins, inline assembly, or volatile
  matching tricks;
- exact source/output pattern and function gate;
- exact fire count with failure on drift;
- transformations limited to proven register renaming, independent scheduling,
  safe narrow spills, or documented assembler behavior;
- negative tests and complete unit comparison; and
- final coverage by `make verify-code`.

See [NORMALIZER_ASSISTED.md](NORMALIZER_ASSISTED.md) for the unit ledger. For
`func_8009FFB8`, a value-level verifier additionally simulated old and new
blocks over whole-function liveness, rejecting transformations that did not
preserve values at joins and calls.

### Exhaustive register searches

Register-allocation residues should be measured instead of attacked through
unbounded source mutation. `decomp_register_atlas.py` enumerates every
bijection in caller-declared register groups and ranks the aligned instruction
operands. It can prove that a residue is a simple swap or cycle and identify
the smallest diagnostic allocation change.

The search size is the product of each group factorial. Keep integer and
floating-point registers separate, and exclude fixed ABI registers unless the
target evidence permits them. A zero-cost mapping proves only that aligned
instructions differ by that mapping; it does not establish the source cause or
compiler pass. Structural, opcode, and control-flow differences must be fixed
before a mapping can support a normalizer rule.

### Allocation dumps and checkpoint traces

GCC 2.7.2's `.greg` dump is produced after reload; it is not evidence of the
pre-reload allocation by itself. `decompkit.gcc_alloc` therefore exposes the
ordinary dump assignment and an optional instrumented `PRE_RELOAD_REG` record
as separate fields, including an explicit `reload_changed_assignment` flag.
This distinction prevented several apparent allocator choices from being
misattributed during the final grid and matrix investigations.

The parser is compiler-invocation agnostic. Another project can feed dumps
from its own GCC build and provide a target-specific hard-register name table.
The bundled MIPS names are merely the default used by this repository.

## Approaches that did not generalize

- Exact size is weak evidence: an incorrect spill pair can compensate for
  missing hazard `nop`s.
- Broad random source mutation plateaued when the first divergence was a
  specific CSE, scheduler, or allocator decision.
- `register asm`, volatile, and inline assembly can force bytes but destroy the
  recovered source model and are disallowed here.
- Host/emulator success says nothing about N64 byte identity or Vita hardware
  correctness.
- C++ compilation was explicitly tested for the grid family; it made both the
  target and an already matched sibling worse. The relevant translation unit
  was C, despite the historical toolchain including C++.

## Reusing this research

Start with the structured tools described in [DECOMPKIT.md](DECOMPKIT.md) and
[TOOLS.md](TOOLS.md). Preserve candidate sources, compiler dumps, exact commands,
and negative controls in ignored build directories. Promote only the conclusion
and a minimal reproducible test into version control; never commit ROM-derived
assembly or private hardware evidence.
