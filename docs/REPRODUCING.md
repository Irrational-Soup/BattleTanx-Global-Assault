# Reproducing the decompilation and resources

The supported workflow starts with one legally obtained, local, big-endian
USA Rev 0 `.z64` dump. The repository does not download a ROM and does not
accept a byte-swapped `.n64` or `.v64` image. Verification happens before any
extraction.

The automated toolchain bootstrap currently targets Linux/WSL. It requires
Python 3 with `venv`, GNU Make, `curl`, `tar`, SHA-1/SHA-256 utilities, CMake,
and a C++ compiler. Either install big-endian `mips-linux-gnu` binutils or use
a Debian/Ubuntu host with `apt-get` and `dpkg-deb`; the bootstrap downloads the
package into `.toolchain` without requiring root. Network access is needed only
for the pinned toolchain downloads and Python packages.

## One command from a fresh clone

```sh
python3 tools/reproduce.py /absolute/path/to/BattleTanxGA.z64
```

This command, in order:

1. confirms this is the N64 decompilation repository;
2. creates `.venv` and installs the pinned Python requirements;
3. verifies the input's format, 8 MiB size, USA Rev 0 SHA-1, and SHA-256,
   then copies it to the ignored canonical path `baseroms/us/baserom.z64`;
4. installs the checksum/revision-pinned MIPS, IDO, and KMC toolchains under
   `.toolchain`;
5. generates the splat outputs and linker symbols;
6. compiles the recovered sources and proves the rebuilt `0x101000`-byte code
   image matches the retail prefix;
7. extracts the complete resource tree under `assets/extracted/us`;
8. builds `build/us/battletanx_ga.z64` from the compiled prefix and extracted
   region files, requiring the documented whole-ROM SHA-256;
9. executes the independent structured asset round-trip gate; and
10. runs the repository test and safety suite.

The final unchanged build has SHA-256
`88268ce770ff39f2ca839848b842c87866df6c5ddaf775f180b2522c18ff6221`.
All ROMs, extracted resources, generated assembly, toolchains, and build
products are ignored by Git.

Use `--skip-toolchain` only when the pinned toolchains are already installed,
`--skip-tests` for an iterative local rebuild, or `--raw-only` to omit the
editable and preview exports. `--show-plan` prints every command without
executing it.

## Separate stages

After `make setup`, the same workflow is available as ordinary build targets:

```sh
make toolchain
make verify-code
make resources
make build-rom
make verify-assets
make check
```

To extract from an explicit verified ROM without copying it first:

```sh
.venv/bin/python tools/extract_resources.py /path/to/BattleTanxGA.z64
```

To rebuild after the code image and raw resources already exist:

```sh
.venv/bin/python tools/build_rom.py --require-original
```

Dropping `--require-original` permits experiments with modified raw resources,
but such an image is not a matching build and may require N64 header checksum
repair before it can boot. The exact reconstruction gate always uses
`--require-original`.

## Resource tree

`assets/extracted/us/raw/manifest.json` is the lossless build contract. Each
entry records a ROM range, semantic category, filename, size, and retail
SHA-256. The region files cover every byte after the independently compiled
prefix. A logical region crossing the boundary is retained whole; the builder
requires its overlapping bytes to agree with the compiled prefix.

The additional exports are intended for inspection and editing:

| Path | Contents |
| --- | --- |
| `lzari/` | every decoded LZARI stream and split bundle components |
| `images/` | all decoded LZARI image previews and manifest |
| `worlds/` | structured world JSON plus fixed-record components |
| `scripts/` | all 17 script/cutscene files split by stream |
| `libmus/` | all 26 libmus files and inter-file alignment bytes |
| `world-pools/` | referenced raw geometry, state, and texture chunks |
| `world-textures/` | decoded world-texture previews |
| `world-geometry.obj` | combined inspection geometry |
| `reports/` | machine-readable inventories for every decoded family |
| `rom-layout.json` | complete, non-overlapping accounting of the 8 MiB ROM |

Editable structured assets are rebuilt with the `pack_*` tools documented in
[Asset formats](ASSET_FORMATS.md). The raw region manifest remains the final
layout input; a future mod pipeline can replace its files with packer outputs
without changing the extraction or image-composition primitives.

## O2R and modern-port packaging

[SpaghettiKart's `ExtractAssets` workflow](https://github.com/HarbourMasters/SpaghettiKart/blob/main/docs/BUILDING.md)
is a useful model for the user experience: an owned ROM is converted locally
into runtime resources before compiling or running the port. O2R would be a
useful optional export for a future libultraship-based desktop or Vita runtime,
particularly for resource lookup and mod packs.

O2R is intentionally not this repository's canonical reconstruction input.
It is a converted runtime archive and does not preserve, by itself, retail ROM
placement, compression, padding, overlaps, or byte identity. The lossless
region manifest proves those properties without requiring libultraship. A
future O2R adapter should consume the structured exports above and sit after
the verified extraction layer:

```text
owned .z64 -> verified raw manifest -> structured resources -> optional O2R
                    |                         |
                    + compiled code ----------+-> exact N64 ROM
```

That boundary gives modern ports the packaging benefits without making the
matching decompilation depend on one runtime ecosystem or archive version.
The concrete migration ledger, validation command, and acceptance boundary are
documented in [O2R runtime-resource path](O2R_PORT_PATH.md).

## Reuse in other decompilation projects

The title-specific extractor obtains its ranges from BattleTanx's recovered
tables, but region serialization and reconstruction live in
`decompkit.resources`. Other projects can supply their own ordered range map,
choose a compiled-prefix boundary, and reuse `extract_regions()` and
`rebuild_image()` unchanged. The synthetic tests cover overlap agreement,
hash enforcement, complete coverage, and deterministic manifests.
