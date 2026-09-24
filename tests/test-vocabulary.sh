#!/usr/bin/env bash
# Every retired form is gone from the files this repository owns (spec §5.4).
# CONTEXT.md lists, on each `_Avoid_:` line, the bare surface forms a winning
# term retired; this test reads those lists and greps every checked file for
# each form, whole word, case-insensitive, so the list is a mechanism rather
# than a rule. `_` is not a word character to the pattern, so an identifier
# carrying a retired form is a hit; `-` is, so a repository name joined by a
# hyphen is not, and there is no exception list. Outside the scan: CONTEXT.md,
# whose subject is the retired forms, and docs/superpowers/, where a spec's
# substitution table and an older plan's quoted output keep them (spec §5.4
# says which higher rungs were tried there).
. "$(dirname "$0")/lib.sh"

CONTEXT="$REPO_ROOT/CONTEXT.md"
[ -f "$CONTEXT" ] || fail "missing $CONTEXT"

forms="$(sed -n 's/.*_Avoid_: *//p' "$CONTEXT" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . || true)"
[ -n "$forms" ] || fail "CONTEXT.md carries no _Avoid_ line; nothing to enforce"
odd="$(printf '%s\n' "$forms" | grep -vE '^[a-z]+( [a-z]+)*$' || true)"
[ -z "$odd" ] || fail "an _Avoid_ list in CONTEXT.md carries something other than a bare lower-case form:"$'\n'"$odd"

files="$(checked ':(exclude)CONTEXT.md' ':(exclude)docs/superpowers')"
[ -n "$files" ] || fail "checked() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"

hits=""
n=0
while IFS= read -r form; do
  n=$((n + 1))
  # shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
  found="$(grep -n -i -H -E "(^|[^[:alnum:]-])$form([^[:alnum:]-]|$)" -- $files || true)"
  [ -z "$found" ] || hits="$hits"$'\n'"$(printf '%s\n' "$found" | sed "s/\$/  [$form]/")"
done <<<"$forms"
[ -z "$hits" ] || fail "a retired form survives in an owned file (file:line:text [form]):$hits"
printf 'vocabulary: %s retired form(s) absent from %s owned file(s)\n' "$n" "$(printf '%s\n' "$files" | grep -c .)"
