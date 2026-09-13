#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
rebuild_tmp=$(mktemp -d)
trap 'rm -rf "$rebuild_tmp"' EXIT HUP INT TERM
bun "$core/bend2/main.ts" rebuild_check.bend -o "$rebuild_tmp/check.c"
clang -std=c11 -w -O0 -fno-slp-vectorize "$rebuild_tmp/check.c" -o "$rebuild_tmp/check" \
  -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
  -framework Cocoa -framework IOKit -framework CoreVideo \
  -framework CoreAudio -framework AudioToolbox
python3 - "$rebuild_tmp/check" > "$rebuild_tmp/actual" <<'PYRUN'
import subprocess, sys
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60)
PYRUN
sed -n 's/^#| //p' rebuild_check.bend > "$rebuild_tmp/expected"
diff -u "$rebuild_tmp/expected" "$rebuild_tmp/actual"
cat "$rebuild_tmp/actual"
