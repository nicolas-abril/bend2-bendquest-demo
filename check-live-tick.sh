#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
tick_tmp=$(mktemp -d)
trap 'rm -rf "$tick_tmp"' EXIT HUP INT TERM
for source in live_tick_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$tick_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$tick_tmp/check.c" -o "$tick_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$tick_tmp/check" > "$tick_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$tick_tmp/expected"
  diff -u "$tick_tmp/expected" "$tick_tmp/actual"
  cat "$tick_tmp/actual"
done
