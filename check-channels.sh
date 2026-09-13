#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
channel_tmp=$(mktemp -d)
trap 'rm -rf "$channel_tmp"' EXIT HUP INT TERM
for source in connection_check.bend restart_effects_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$channel_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$channel_tmp/check.c" -o "$channel_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$channel_tmp/check" > "$channel_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$channel_tmp/expected"
  diff -u "$channel_tmp/expected" "$channel_tmp/actual"
  cat "$channel_tmp/actual"
done
