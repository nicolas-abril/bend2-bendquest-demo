#!/bin/sh
set -eu
cd "$(dirname "$0")"
./check-proofs.sh
mkdir -p .build
bun "${BEND2_CORE:-../bend2-core}/bend2/main.ts" main.bend -o .build/bendquest.c
# dev is -O1: Apple clang 17's -O0 backend fails on the generated C with
# "live register clobbered by inserted prologue instructions".
case "${1:-dev}" in
  dev) opt=-O1 ;;
  release) opt=-O2 ;;
  *) echo 'usage: ./build.sh [dev|release]' >&2; exit 1 ;;
esac
clang -std=c11 -w -fno-slp-vectorize "$opt" .build/bendquest.c -o .build/bendquest \
  -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib -lpthread -lm \
  -framework Cocoa -framework IOKit -framework CoreVideo \
  -framework CoreAudio -framework AudioToolbox
echo 'Built Bendquest. Run ./run.sh or ./run.sh server 4977.'
