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

files="$(checked '.github/workflows/*.yml' '.github/workflows/*.yaml')"
[ -n "$files" ] || fail "no workflow under .github/workflows; the list went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
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

# The watch reads the same pins the guard above checks: one line per
# distinct pin, and every uses: line accounted for. It exits 0 doing so: an
# unmatched glob never reaches grep.
pins="$(bash "$REPO_ROOT/scripts/upstream-watch" --workflow-pins)" \
  || fail "upstream-watch --workflow-pins exited $?, not 0"
# With no workflow file at all, the reader fails loudly, exit 2, naming the
# directory, rather than handing grep an empty list and so its stdin.
W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/scripts" || fail "could not seed $W"
cp "$REPO_ROOT/scripts/upstream-watch" "$W/scripts/" || fail "could not copy the watch"
status=0
out="$(bash "$W/scripts/upstream-watch" --workflow-pins 2>&1 </dev/null)" || status=$?
[ "$status" -eq 2 ] || fail "with no workflow file, --workflow-pins exited $status, not 2:"$'\n'"$out"
grep -qF '.github/workflows' <<<"$out" || fail "with no workflow file, the error does not name .github/workflows:"$'\n'"$out"
[ "$(printf '%s\n' "$pins" | grep -c .)" -eq 4 ] || fail "expected 4 distinct action pins, got:"$'\n'"$pins"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
# shellcheck disable=SC2013  # each word is a whole uses: pin, never split by whitespace within one
for line in $(grep -hoE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}' $files | sed -E 's/^uses:[[:space:]]*//'); do
  grep -qF -- "${line%@*} ${line#*@} " <<<"$pins" || fail "the watch does not read the pin $line"
done

printf 'workflows: %s workflow(s) linted, every uses: sha-pinned, permissions declared, credentials not persisted\n' \
  "$(printf '%s\n' "$files" | grep -c .)"
