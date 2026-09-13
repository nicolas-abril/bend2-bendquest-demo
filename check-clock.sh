#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
clock_tmp=$(mktemp -d)
trap 'rm -rf "$clock_tmp"' EXIT HUP INT TERM
for source in clock_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$clock_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$clock_tmp/check.c" -o "$clock_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$clock_tmp/check" > "$clock_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$clock_tmp/expected"
  diff -u "$clock_tmp/expected" "$clock_tmp/actual"
  cat "$clock_tmp/actual"
done
