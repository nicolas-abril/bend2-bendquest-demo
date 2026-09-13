#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ ! -x .build/bendquest ]; then ./build.sh; fi
if [ "${1:-}" = server ]; then
  BQ_SERVER_PORT="${2:-4977}"
  case "$BQ_SERVER_PORT" in
    ''|*[!0-9]*) echo 'Port must be an integer from 1 to 65535.' >&2; exit 1 ;;
  esac
  if [ "$BQ_SERVER_PORT" -lt 1 ] || [ "$BQ_SERVER_PORT" -gt 65535 ]; then
    echo 'Port must be an integer from 1 to 65535.' >&2; exit 1
  fi
  export BQ_SERVER_PORT
  shift
  if [ "$#" -gt 0 ]; then shift; fi
fi
exec .build/bendquest "$@"
