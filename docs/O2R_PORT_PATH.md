# O2R runtime-resource path

O2R is a useful target for a future native runtime, but it is not a substitute
for the matching decompilation's lossless ROM manifest. The intended flow is:

```text
user-owned verified .z64
  -> lossless extraction and structured title-specific exports
  -> versioned runtime resource serializers
  -> Torch-generated game .o2r
  -> libultraship resource factories used by the native runtime
```

The first two stages exist. The latter two do not yet. A ZIP of raw extracted
files renamed to `.o2r` is not an O2R integration: the runtime must have concrete
resource types and factories that understand every emitted entry.

`config/o2r_resources.toml` is the migration ledger. Validate it with:

```sh
.venv/bin/python tools/check_o2r_readiness.py
```

The validator rejects a `runtime-ready` claim unless the entry names a
deterministic serializer, a versioned runtime resource type, and a runtime
factory. Non-ready entries must state their blocker.

## Archive separation

Follow the pattern used by current HarbourMasters projects: the game archive is
generated locally from the user's verified ROM, while optional port-owned assets
live in a separate archive. Neither archive nor extracted copyrighted data is
committed here. Torch recipes should consume the verified structured exports
rather than independently rediscovering ROM offsets.

## Implementation order

1. Define endian-safe, pointer-free schemas for textures and one world slice.
2. Implement deterministic serializers and native factories for those schemas.
3. Add a headless round-trip test from local extraction through factory load.
4. Pin compatible Torch/libultraship revisions and generate the game archive.
5. Expand the ledger family by family; keep raw fallback regions out of the
   native runtime.
