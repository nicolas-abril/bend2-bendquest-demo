#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
rebinding_tmp=$(mktemp -d)
trap 'rm -rf "$rebinding_tmp"' EXIT HUP INT TERM
for source in rebinding_check.bend rebinding_server_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$rebinding_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$rebinding_tmp/check.c" -o "$rebinding_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$rebinding_tmp/check" > "$rebinding_tmp/actual" <<'PYRUN'
import subprocess, sys
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60)
PYRUN
  sed -n 's/^#| //p' "$source" > "$rebinding_tmp/expected"
  diff -u "$rebinding_tmp/expected" "$rebinding_tmp/actual"
  cat "$rebinding_tmp/actual"
done
