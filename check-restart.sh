#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
restart_tmp=$(mktemp -d)
trap 'rm -rf "$restart_tmp"' EXIT HUP INT TERM
for source in restart_check.bend restart_server_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$restart_tmp/check.c"
  clang -std=c11 -w -O0 -fno-slp-vectorize "$restart_tmp/check.c" -o "$restart_tmp/check" \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
    -framework Cocoa -framework IOKit -framework CoreVideo \
    -framework CoreAudio -framework AudioToolbox
  python3 - "$restart_tmp/check" > "$restart_tmp/actual" <<'PYRUN'
import subprocess, sys
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60)
PYRUN
  sed -n 's/^#| //p' "$source" > "$restart_tmp/expected"
  diff -u "$restart_tmp/expected" "$restart_tmp/actual"
  cat "$restart_tmp/actual"
done
