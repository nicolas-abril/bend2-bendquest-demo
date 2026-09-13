#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
target_tmp=$(mktemp -d)
trap 'rm -rf "$target_tmp"' EXIT HUP INT TERM
for source in combat_targets_check.bend live_combat_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$target_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$target_tmp/check.c" -o "$target_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$target_tmp/check" > "$target_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$target_tmp/expected"
  diff -u "$target_tmp/expected" "$target_tmp/actual"
  cat "$target_tmp/actual"
done
