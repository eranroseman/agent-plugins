#!/usr/bin/env bash
# The ownership derivation stays honest (spec §7.2, T23). The excluded files
# are the records' copies and nothing else: every `trees` key in vendored.json
# is a tracked directory that checked() does not list, and every `forks` key
# a tracked path that checked() lists, so a misspelled key fails rather than
# leaving a copy linted or a fork out of the linters. The checked list is
# non-empty, no checked path carries whitespace, a glob character, or a quoted
# path, which is what lets the tool tests expand `$(checked ...)` unquoted, one
# path per word, and every checked file that opens with a bash shebang is one
# checked_shell() lists. Needs no network.
. "$(dirname "$0")/lib.sh"

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"

n_trees=0
while IFS= read -r key; do
  [ -n "$key" ] || continue
  files="$(git -C "$REPO_ROOT" ls-files -- "$key" | grep . || true)"
  [ -n "$files" ] || fail "the trees key $key in vendored.json is not a tracked directory"
  listed="$(grep -xF -f <(printf '%s\n' "$files") <<<"$list" || true)"
  [ -z "$listed" ] || fail "checked() lists files of the copy $key; EXCLUDED is not derived from vendored.json:"$'\n'"$listed"
  n_trees=$((n_trees + 1))
done < <(tree_keys)
[ "$n_trees" -gt 0 ] || fail "vendored.json declares no copy; the derivation went vacuous"
n_forks=0
while IFS= read -r key; do
  [ -n "$key" ] || continue
  files="$(git -C "$REPO_ROOT" ls-files -- "$key" | grep . || true)"
  [ -n "$files" ] || fail "the forks key $key in vendored.json is not a tracked path"
  missing="$(grep -vxF -f <(printf '%s\n' "$list") <<<"$files" || true)"
  [ -z "$missing" ] || fail "the fork $key has files checked() does not list; a fork is linted:"$'\n'"$missing"
  n_forks=$((n_forks + 1))
done < <(fork_keys)

odd="$(grep '[[:space:]*?[\\"]' <<<"$list" || true)"
[ -z "$odd" ] \
  || fail "a tracked path carries whitespace, a glob character, or a quoted path; the tool tests expand the list unquoted:"$'\n'"$odd"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
# Derived rather than enumerated: every checked file
# whose first line names bash must be in checked_shell, so a shell file cannot
# leave the shell checkers' scope on one character. checked_shell's
# exact-shebang rule stands: this says what joining it costs, it does not
# relax it.
missing=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$(head -n 1 "$REPO_ROOT/$f")" in
    '#!'*bash*)
      grep -qxF -- "$f" <<<"$shell" || missing="$missing $f"
      ;;
  esac
done < <(printf '%s\n' "$list")
[ -z "$missing" ] \
  || fail "these checked file(s) open with a bash shebang and checked_shell() does not list them:$missing"$'\n'"their first line must be exactly '#!/usr/bin/env bash', or they leave shellcheck, shfmt and cspell unnoticed"

printf 'ownership: %s cop(y|ies) excluded, %s fork(s) linted; %s checked file(s), %s of them shell\n' \
  "$n_trees" "$n_forks" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
