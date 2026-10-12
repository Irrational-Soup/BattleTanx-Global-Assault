# Native-port architecture

The matching N64 build and a native executable are two consumers of recovered
behavior, not two compiler configurations of one monolithic target.

```text
recovered game behavior
        |
        +-- N64 evidence build -> KMC/IDO -> normalizers -> matching .z64
        |
        `-- portable runtime -> platform API -> Windows / Vita / other target
```

Normalizer rules are used only on the N64 branch. They reproduce historical
MIPS register allocation, scheduling, and assembler behavior after compiling
otherwise meaningful C. They are neither linked into nor executed by a native
port. A normalizer-assisted function can enter the portable branch once its C
types, fixed-width assumptions, and dependencies have been reviewed.

Handwritten MIPS assembly, RSP microcode, direct MMIO, and libultra services are
different: a native CPU cannot execute them. Their behavior must be expressed
through portable code, a platform backend, or an explicit interpreter.

## Runtime boundary

The portable game layer should depend on narrow interfaces in these domains:

| Domain | Original dependency | Native responsibility |
|---|---|---|
| Rendering | RSP/RDP display lists and VI | Interpret or translate commands; present frames |
| Audio | libmus, n_audio, AI and RSP tasks | Mix decoded voices or provide a compatibility mixer |
| Input | SI/controller and PIF | Map host devices to stable game actions |
| Time | CP0 counters, retrace and scheduler | Monotonic clock and deterministic game ticks |
| Tasks/threads | libultra threads and message queues | Platform jobs, synchronization and queues |
| Storage | ROM DMA and controller pak | Resource views and durable save storage |
| Memory | N64 virtual/physical addresses | Owned buffers and explicit 32-bit address tokens |

The interface must describe behavior rather than reproduce libultra's ABI.
Keep N64 compatibility adapters possible, but do not expose MIPS registers,
KSEG addresses, or display-list memory layouts as a general host API.

## Data rules

- N64 ROM and resource fields are big-endian and explicitly sized.
- Windows x86-64 is normally little-endian LP64; Windows uses LLP64 for C data
  models. Neither matches N64 o32 layouts implicitly.
- Vita is little-endian ARMv7-A ILP32. Its 32-bit pointer size does not make
  N64 serialized structs safe to cast.
- Serialized pointers remain `uint32_t` address tokens until resolved against
  a validated resource arena. Never truncate a live host pointer.
- Cross-boundary layouts need `static_assert`/`_Static_assert` checks, while
  runtime-native objects should use natural target alignment rather than global
  packing.

## Staged bring-up

1. **Inventory and policy.** Keep `docs/PORTABILITY_INVENTORY.md` current with
   `make portability-report`. Classify every blocker by adapter, rewrite, or
   interpretation strategy.
2. **Portable foundation.** Introduce fixed-width game types, endian/resource
   readers, deterministic math tests, and the platform interface without
   changing matching source files.
3. **Headless host.** Compile a selected vertical slice on the development host
   with renderer/audio stubs. Validate state transitions against captured N64
   inputs and outputs.
4. **Resource runtime.** Load only resources extracted from the user's local
   verified ROM. Resolve N64 address tokens and test bounds/endianness.
5. **Windows executable.** Add window, input, audio, timing, and rendering
   backends. SDL is a suitable service layer; the rendering strategy remains a
   separate choice.
6. **Vita backend.** Cross-compile the same portable layer for ARMv7-A ILP32,
   inspect ELF attributes for ABI agreement, then test on supervised physical
   hardware.

Each stage keeps `make verify-code` as the N64 regression oracle. Host behavior
tests supplement that oracle; they do not replace it.

## Expansion Pak behavior

The retail game does not expose an Expansion Pak graphics or gameplay mode.
The only recovered `osMemSize` read is in the early monitor/dispatch code. When
more than 4 MiB is installed, it extends the KSEG0/KSEG1 limits in the monitor's
address-validity table so debug copy operations can reach the detected RDRAM.
No gameplay heap, asset pool, framebuffer, or renderer mode selects the extra
memory.

A native runtime therefore does not need an Expansion Pak mode. If the early
monitor is ever represented by a compatibility layer, preserve its address
validation semantics with explicit 32-bit address tokens rather than mapping
N64 virtual addresses into host pointers.

## First vertical slice

Do not begin by compiling all recovered source into an executable. Start with a
small loop that proves the architecture:

1. verify and open the user's local ROM/resource extraction;
2. decode one endian-sensitive world or texture record through portable APIs;
3. run one deterministic gameplay update with host input/time adapters;
4. emit a renderer-neutral command or headless state snapshot;
5. compare the result with an N64 reference fixture.

That slice exercises the difficult boundaries without requiring the complete
renderer, audio engine, scheduler, and save system at once.

## Acceptance criteria

A native target is not considered working merely because it links or runs in
an emulator. It must have:

- no compiled MIPS/RSP instructions in the native executable;
- no dereference of N64 MMIO or virtual addresses;
- explicit endian conversion at serialized boundaries;
- deterministic tests for the ported gameplay slice;
- a clean N64 `make verify-code` result;
- for Vita, a clean cross-build, compatible ARM ELF attributes, and supervised
  physical-hardware validation.
