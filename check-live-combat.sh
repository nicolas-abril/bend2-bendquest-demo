#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
combat_tmp=$(mktemp -d)
trap 'rm -rf "$combat_tmp"' EXIT HUP INT TERM
for source in live_combat_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$combat_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$combat_tmp/check.c" -o "$combat_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$combat_tmp/check" > "$combat_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$combat_tmp/expected"
  diff -u "$combat_tmp/expected" "$combat_tmp/actual"
  cat "$combat_tmp/actual"
done
