#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../../bend2-core}
disconnect_tmp=$(mktemp -d)
trap 'rm -rf "$disconnect_tmp"' EXIT HUP INT TERM
for source in disconnect_check.bend disconnect_server_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$disconnect_tmp/check.c"
  case "$source" in
    disconnect_server_check.bend)
      clang -std=c11 -w -O0 -fno-slp-vectorize "$disconnect_tmp/check.c" -o "$disconnect_tmp/check" \
        -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
        -framework Cocoa -framework IOKit -framework CoreVideo \
        -framework CoreAudio -framework AudioToolbox ;;
    *) clang -std=c11 -w -O0 -fno-slp-vectorize "$disconnect_tmp/check.c" -o "$disconnect_tmp/check" -lpthread -lm ;;
  esac
  python3 - "$disconnect_tmp/check" > "$disconnect_tmp/actual" <<'PYRUN'
import subprocess, sys
subprocess.run([sys.argv[1], '--threads', '2', '--gpu', 'off'], check=True, timeout=60)
PYRUN
  sed -n 's/^#| //p' "$source" > "$disconnect_tmp/expected"
  diff -u "$disconnect_tmp/expected" "$disconnect_tmp/actual"
  cat "$disconnect_tmp/actual"
done
