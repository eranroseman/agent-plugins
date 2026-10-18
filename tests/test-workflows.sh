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

# A broken desired-state file must fail the watch before it reads any upstream:
# exit 2, the file named, and the git stub's log empty. The stub records every
# call and answers nothing, so a watch that reached for a remote shows here.
W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/scripts" "$W/.claude-plugin" "$W/bin" || fail "could not seed $W"
cp "$REPO_ROOT/scripts/upstream-watch" "$W/scripts/" || fail "could not copy the watch"
cp "$REPO_ROOT/skills.json" "$REPO_ROOT/vendored.json" "$W/" \
  || fail "could not copy the watch's desired state"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s"\nexit 99\n' "$W/git.log" >"$W/bin/git" \
  || fail "could not write the git stub"
chmod +x "$W/bin/git" || fail "could not make the git stub executable"
printf '{\n' >"$W/.claude-plugin/marketplace.json" || fail "could not break marketplace.json"
status=0
out="$(PATH="$W/bin:$PATH" bash "$W/scripts/upstream-watch" 2>&1)" || status=$?
[ "$status" -eq 2 ] || fail "with a broken marketplace, upstream-watch exited $status, not 2:"$'\n'"$out"
grep -qF "$W/.claude-plugin/marketplace.json" <<<"$out" \
  || fail "the broken marketplace was not named:"$'\n'"$out"
[ ! -s "$W/git.log" ] || fail "the watch read an upstream before rejecting the broken marketplace:"$'\n'"$(cat "$W/git.log")"
# A marketplace with no subset entry is the case the old process substitution
# turned into a clean verdict: zero rows, zero iterations, DRIFT still 0.
printf '{"plugins":[]}\n' >"$W/.claude-plugin/marketplace.json" || fail "could not empty marketplace.json"
status=0
out="$(PATH="$W/bin:$PATH" bash "$W/scripts/upstream-watch" 2>&1)" || status=$?
[ "$status" -eq 2 ] || fail "with no subset entry, upstream-watch exited $status, not 2:"$'\n'"$out"
grep -qF "$W/.claude-plugin/marketplace.json" <<<"$out" \
  || fail "a marketplace with no subset entry was not named:"$'\n'"$out"
[ ! -s "$W/git.log" ] || fail "the watch read an upstream with no subset entry to compare:"$'\n'"$(cat "$W/git.log")"

printf 'workflows: %s workflow(s) linted, every uses: sha-pinned, permissions declared, credentials not persisted\n' \
  "$(printf '%s\n' "$files" | grep -c .)"
