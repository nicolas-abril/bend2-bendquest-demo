#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
spin_tmp=$(mktemp -d)
trap 'rm -rf "$spin_tmp"' EXIT HUP INT TERM
for source in spin_plans_check.bend live_combat_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$spin_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$spin_tmp/check.c" -o "$spin_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$spin_tmp/check" > "$spin_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$spin_tmp/expected"
  diff -u "$spin_tmp/expected" "$spin_tmp/actual"
  cat "$spin_tmp/actual"
done
