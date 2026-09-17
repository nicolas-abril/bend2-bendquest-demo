#!/bin/sh
set -eu
cd "$(dirname "$0")"
core=${BEND2_CORE:-../bend2-core}
creation_tmp=$(mktemp -d)
trap 'rm -rf "$creation_tmp"' EXIT HUP INT TERM
for source in creation_check.bend creation_server_check.bend; do
  bun "$core/bend2/main.ts" "$source" -o "$creation_tmp/check.c"
  case "$source" in
    creation_server_check.bend)
      clang -std=c11 -w -O0 -fno-slp-vectorize "$creation_tmp/check.c" -o "$creation_tmp/check" \
        -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
        -framework Cocoa -framework IOKit -framework CoreVideo \
        -framework CoreAudio -framework AudioToolbox ;;
    *) clang -std=c11 -w -O0 -fno-slp-vectorize "$creation_tmp/check.c" -o "$creation_tmp/check" -lpthread -lm ;;
  esac
  "$creation_tmp/check" --threads 2 --gpu off > "$creation_tmp/actual"
  sed -n 's/^#| //p' "$source" > "$creation_tmp/expected"
  diff -u "$creation_tmp/expected" "$creation_tmp/actual"
  cat "$creation_tmp/actual"
done
