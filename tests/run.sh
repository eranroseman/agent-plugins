#!/usr/bin/env bash
# Run every tests/test-*.sh and exit 1 if any fails.
# Same entry point for local runs and CI.
set -uo pipefail
cd "$(dirname "$0")/.." || { printf 'FAIL: could not cd to the repository root\n' >&2; exit 1; }
status=0
for t in tests/test-*.sh; do
  if bash "$t"; then
    printf 'PASS %s\n' "$t"
  else
    printf 'FAIL %s\n' "$t"
    status=1
  fi
done
exit "$status"
