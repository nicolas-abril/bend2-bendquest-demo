#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
command_tmp=$(mktemp -d)
trap 'rm -rf "$command_tmp"' EXIT HUP INT TERM
for source in live_commands_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$command_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$command_tmp/check.c" -o "$command_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$command_tmp/check" > "$command_tmp/actual" <<'PYRUN'
import subprocess, sys
from pathlib import Path
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60, cwd=Path(sys.argv[1]).parent)
PYRUN
  sed -n 's/^#| //p' "$source" > "$command_tmp/expected"
  diff -u "$command_tmp/expected" "$command_tmp/actual"
  cat "$command_tmp/actual"
done
