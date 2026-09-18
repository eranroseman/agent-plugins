#!/usr/bin/env bash
# The workflows' embedded `run:` shell is linted (#28), and the two
# properties actionlint cannot see are asserted beside it (spec §9.4):
# every `uses:` is pinned to a 40-character sha, every workflow declares
# `permissions:` at the top level, and every actions/checkout step sets
# persist-credentials: false. actionlint runs shellcheck over run: blocks
# when shellcheck is on PATH and quietly does not when it is absent, so both
# are needs. Measured 2026-09-17: actionlint 1.7.12 flags neither a missing
# permissions block nor a floating tag nor an unresolvable uses:, so the
# greps are not redundant with it.
# needs: actionlint shellcheck
. "$(dirname "$0")/lib.sh"

files="$(checked '.github/workflows/*.yml')"
[ -n "$files" ] || fail "no workflow under .github/workflows; the list went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
actionlint $files || fail "actionlint reported problems"

for f in $files; do
  unpinned="$(grep -nE '^[[:space:]]*-?[[:space:]]*uses:' "$f" \
    | grep -vE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}([[:space:]]|$)' || true)"
  [ -z "$unpinned" ] || fail "$f: a uses: line is not pinned to a 40-character sha:"$'\n'"$unpinned"
  grep -qE '^permissions:' "$f" || fail "$f declares no top-level permissions: block"
  checkouts="$(grep -cE 'uses:[[:space:]]*actions/checkout@' "$f" || true)"
  persists="$(grep -cE '^[[:space:]]*persist-credentials:[[:space:]]*false[[:space:]]*$' "$f" || true)"
  [ "$checkouts" -eq "$persists" ] \
    || fail "$f: $checkouts actions/checkout step(s) but $persists persist-credentials: false line(s)"
done

printf 'workflows: %s workflow(s) linted, every uses: sha-pinned, permissions declared, credentials not persisted\n' \
  "$(printf '%s\n' "$files" | grep -c .)"
