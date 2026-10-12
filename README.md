# BattleTanx: Global Assault — matching decompilation

[![Decompilation: 100%](https://img.shields.io/badge/decompilation-100%25-brightgreen)](https://decomp.dev/TheGh0stShip/BattleTanx-Global-Assault)
[![Functions: 1879/1879](https://img.shields.io/badge/functions-1879%2F1879-brightgreen)](https://decomp.dev/TheGh0stShip/BattleTanx-Global-Assault)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)](COPYING)

This repository contains a **complete matching decompilation** of
**BattleTanx: Global Assault** for Nintendo 64 (USA Rev 0). All 1,879
catalogued functions and all source-owned data in the defined loaded-program
scope reconstruct byte-for-byte. The result is readable C, authentic source
assembly where appropriate, documented compiler-normalizer rules, and a
reproducible build that matches retail ROM offsets `0x000000–0x101000`.

The recovered N64 source is now the foundation for **VitaTanxGA**, the planned
PS Vita port. Portability work will remain separate from the matching source
and its binary-evidence gates.

No ROM or ROM-derived assets are included. Supply your own legally obtained dump.

## Supported ROM

- Title: `BATTLETANXGA`
- Region/revision: USA, Rev 0 (`NBQE`)
- Format: big-endian `.z64`
- Size: 8 MiB
- SHA-1: `805248fb0a0ee694cad8d7dc927b631d860dd8cf`

## Bootstrap

```sh
cp /path/to/BattleTanxGA.z64 "BattleTanx - Global Assault (USA).z64"
make setup
make split
make verify-code
make check
```

`make setup` creates a local Python environment, verifies the dump, and copies it to the ignored canonical path. `make split` disassembles the known first-MiB code region with splat. `make verify-code` assembles and links that region and requires it to match ROM offsets `0x000000-0x101000` byte-for-byte. If GNU MIPS binutils or armips are not installed locally, the build installs checksum-pinned copies under the ignored `.toolchain/` directory without requiring root; building armips requires CMake and a C++ compiler. Generated assembly is intentionally ignored; reviewed C, RSP assembly, and project metadata are the source of truth.

## Current status

- **Code: 100%.** All 1,879 catalogue functions and all 632,132 function-body bytes are represented by production C or authentic source assembly.
- **Data: 100%.** All 115,617 tracked initialized/read-only bytes in the loaded executable scope are source-owned and matched.
- **Binary gate: exact.** `make verify-code` reconstructs ROM offsets `0x000000–0x101000` byte-for-byte, including the header, IPL3, loaded program, RSP boot, F3DEX FIFO 2.07, and n_audio microcode.
- **Whole-ROM hash: not yet a build output.** The complete 8 MiB reference ROM
  has SHA-256 `88268ce770ff39f2ca839848b842c87866df6c5ddaf775f180b2522c18ff6221`,
  while the current build emits and verifies the reconstructed `0x101000`-byte
  prefix. Asset families have independent lossless gates, but they are not yet
  assembled into one independently rebuilt 8 MiB ROM.
- The function catalogue, corrected boundaries, compiler identifications, imported-source provenance, and normalizer-assisted exceptions are documented and reproducible.
- The matching LZARI codec and audited ROM tables identify 271 compressed streams: 75 game-world bundles, 195 images, and one leftover BattleTanx world. Their 1,174,975 stored bytes expand to 2,886,765 bytes and canonically re-encode to every retail byte. `tools/inventory_lzari_assets.py` inventories them, `tools/extract_lzari_images.py` converts all six observed N64 texture layouts into local PNG previews, and `tools/extract_lzari_worlds.py` emits validated fixed-record world manifests without committing ROM-derived data.
- The complete loading path is reconstructed in matching C: individual asset DMA/loading, the eight-function LZARI decoder, both world loaders, relocation walkers, and the compressed-bank directory. `make verify-assets` independently parses and losslessly rebuilds every known resource family while accounting for all 8 MiB of the retail ROM.
- The complete 26-file libmus store is independently validated and can be losslessly split/rebuilt locally: 76 SFX waves, 93 effects, 231 music waves, and 21 songs occupying 2,289,292 indexed ROM bytes plus 66 alignment bytes. All 307 non-overlapping ADPCM waves are independently replaceable and inspection-decodable; `tools/pack_libmus_assets.py` reconstructs both large wave banks and the complete store without opaque fallback slices.
- Normalizer-assisted units require narrowly gated, documented rules with exact fire counts; they are identified separately from pure source matches in [the normalizer-assisted record](docs/NORMALIZER_ASSISTED.md).
- CI publishes Code and Data categories in the objdiff v2 `us_report` artifact. Data progress counts only source-owned bytes already proven identical; merely locating or extracting an opaque asset does not count as a match.

### What “100%” means

The completion claim covers the repository's defined matching-decompilation
scope: the 1,879-function catalogue and tracked initialized data in the loaded
N64 program image. Remaining generated `asm` segments are data, alignment,
RSP/microcode material, or binary regions intentionally outside the C-function
catalogue—not missing gameplay functions. Semantic renaming can continue
without changing the 100% binary-match result.

### Next phase

The matching milestone is complete. The next major effort is the portable
runtime and PS Vita target. Vita work must preserve the original 32-bit game
semantics, use the ARMv7-A ILP32 toolchain, verify hard-float/softfp ELF
compatibility, and pass supervised physical-hardware testing before any
release claim. See the [architecture and portability contract](docs/ARCHITECTURE.md).

One incidental discovery from the source recovery: rodata at `0x80072694`
contains developer-credit Easter-egg strings including “Murray likes fries.”

See also the [reusable decompilation toolkit](docs/DECOMPKIT.md),
[tool and test map](docs/TOOLS.md),
[reproducible matching research](docs/MATCHING_RESEARCH.md),
[library fingerprints](docs/LIBRARIES.md), [asset formats](docs/ASSET_FORMATS.md),
[compiler notes](docs/COMPILER.md), and
[research provenance](docs/PROVENANCE.md).

## License

Project-authored code and imported GPL research are licensed under GPL-3.0; see `COPYING`. BattleTanx: Global Assault and its game data remain the property of their respective rights holders.
