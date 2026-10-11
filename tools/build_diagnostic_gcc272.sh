#!/usr/bin/env bash
# Build a diagnostic-only stock GCC 2.7.2 cc1 for the MIPS backend.
#
# This never replaces or modifies .toolchain/kmc-gcc-2.7.2.  The resulting cc1
# is evidence tooling and must be calibrated against KMC for every candidate.
#
# Usage:
#   tools/build_diagnostic_gcc272.sh [OUT_DIR] [PATCH ...]
#
# PATCH files are applied after the modern-host compatibility edits and before
# configuration.  This lets a lane add allocation/reload/scheduler tracing
# without maintaining another compiler source tree.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/build/diagnostic-gcc-2.7.2"}
if (($#)); then shift; fi

URL=https://ftp.gnu.org/old-gnu/gcc/gcc-2.7.2.tar.gz
SHA256=7cd8bce5c3aeec59a72ecc2d3d5123864a817b14cdbd0680b1a969c3bccc5da5
ARCHIVE="$OUT/gcc-2.7.2.tar.gz"
SRC="$OUT/src"

mkdir -p "$OUT"
if [[ ! -f "$ARCHIVE" ]]; then
    curl -fsSL "$URL" -o "$ARCHIVE"
fi
printf '%s  %s\n' "$SHA256" "$ARCHIVE" | sha256sum -c -

if [[ ! -d "$SRC" ]]; then
    mkdir "$SRC"
    tar -xzf "$ARCHIVE" -C "$SRC" --strip-components=1

    # GCC 2.7.2 models this modern x86-64 build host like its historical
    # 64-bit Alpha host.  This affects host-side compiler data only, not the
    # 32-bit MIPS target ABI.
    chmod u+w "$SRC/config/i386/xm-i386.h" "$SRC/obstack.h"
    sed -i 's/#define HOST_BITS_PER_LONG 32/#define HOST_BITS_PER_LONG 64/' \
        "$SRC/config/i386/xm-i386.h"

    python3 - "$SRC/obstack.h" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
replacements = {
    '*((void **)__o->next_free)++ = ((void *)datum);':
        '*((void **)__o->next_free) = ((void *)datum), __o->next_free += sizeof (void *);',
    '*((int *)__o->next_free)++ = ((int)datum);':
        '*((int *)__o->next_free) = ((int)datum), __o->next_free += sizeof (int);',
    '#define obstack_ptr_grow_fast(h,aptr) (*((void **)(h)->next_free)++ = (void *)aptr)':
        '#define obstack_ptr_grow_fast(h,aptr) (*(void **)(h)->next_free = (void *)(aptr), (h)->next_free += sizeof (void *))',
    '#define obstack_int_grow_fast(h,aint) (*((int *)(h)->next_free)++ = (int)aint)':
        '#define obstack_int_grow_fast(h,aint) (*(int *)(h)->next_free = (int)(aint), (h)->next_free += sizeof (int))',
    '#define obstack_ptr_grow_fast(h,aptr) (*((char **)(h)->next_free)++ = (char *)aptr)':
        '#define obstack_ptr_grow_fast(h,aptr) (*(char **)(h)->next_free = (char *)(aptr), (h)->next_free += sizeof (char *))',
}
for old, new in replacements.items():
    s = s.replace(old, new)
open(p, 'w').write(s)
PY
fi

for patch_file in "$@"; do
    # Historical lane patches often recorded scratch-directory paths or names
    # such as global.c.orig_pre_ga.  Normalize only known GCC source basenames;
    # hunks and context remain untouched, so an incompatible patch still fails.
    normalized=$(mktemp "$OUT/trace-patch.XXXXXX")
    python3 - "$patch_file" "$normalized" <<'PY'
import os
import re
import sys

source, output = sys.argv[1:]
text = open(source).read()
known = (
    'global.c', 'local-alloc.c', 'reload.c', 'reload1.c', 'reorg.c',
    'sched.c', 'cse.c', 'loop.c', 'jump.c', 'toplev.c',
)

def header(match):
    prefix, path, suffix = match.groups()
    base = os.path.basename(path)
    for name in known:
        if base == name or base.startswith(name + '.'):
            return prefix + name + suffix
    return match.group(0)

text = re.sub(r'(?m)^(--- |\+\+\+ )(\S+)(.*)$', header, text)
open(output, 'w').write(text)
PY
    patch -d "$SRC" -p0 --forward < "$normalized"
    rm "$normalized"
done

if [[ ! -f "$SRC/Makefile" ]]; then
    (
        cd "$SRC"
        CFLAGS='-std=gnu89 -w -fcommon' \
            ./configure --target=mips-elf --host=i586-linux --build=i586-linux
    )
fi

make -C "$SRC" CFLAGS='-std=gnu89 -w -fcommon' cc1
printf 'diagnostic cc1: %s\n' "$SRC/cc1"
file "$SRC/cc1"
cat <<EOF
Calibration required before trusting traces:
  1. Compile the same preprocessed candidate with KMC cc1 and this cc1.
  2. Confirm tracing disabled versus enabled emits identical instructions.
  3. Confirm this cc1 and KMC have the same mismatch list for the target unit.
EOF
