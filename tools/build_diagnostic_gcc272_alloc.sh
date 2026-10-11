#!/usr/bin/env bash
# Convenience build for the maintained allocation/scheduling diagnostic patch set.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/build/diagnostic-gcc-2.7.2-alloc"}

exec "$ROOT/tools/build_diagnostic_gcc272.sh" "$OUT" \
    "$ROOT/claude-work/output/close-80091768-final/trace/gcc-patch/alloc-sched-trace.patch" \
    "$ROOT/tools/diagnostic_gcc272/pre_reload_trace.patch"
