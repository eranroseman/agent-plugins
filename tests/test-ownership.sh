#!/usr/bin/env bash
# The ownership derivation stays honest (spec §4; #61 M7). Every row of the
# table in tests/lib.sh matches at least one tracked file and names a guard
# that exists, no two rows name the same guard, and each guard's own
# `guards` line -- read here, statically, so this holds without a network --
# names paths the row's pattern matches, so a guard cannot be repointed at a
# test that happens to mention the subject. The checked list is non-empty,
# lists none of the excluded files, and no checked path carries whitespace,
# a glob character, or a quoted path, which is what lets the tool tests
# expand `$(checked ...)` unquoted, one path per word.
. "$(dirname "$0")/lib.sh"

[ "${#GUARDED[@]}" -gt 0 ] || fail "no row is declared in tests/lib.sh's table"

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"

seen=""
for row in "${GUARDED[@]}"; do
  pat="${row%%$'\t'*}"
  guard="${row#*$'\t'}"
  if [ -z "$pat" ] || [ -z "$guard" ] || [ "$pat" = "$row" ]; then
    fail "a row in tests/lib.sh's table is not pattern<TAB>guard: '$row'"
  fi
  matches="$(git -C "$REPO_ROOT" ls-files | grep -E "$pat" || true)"
  [ -n "$matches" ] || fail "pattern '$pat' matches no tracked file; drop it from tests/lib.sh or fix it"
  [ -f "$REPO_ROOT/$guard" ] || fail "pattern '$pat' names a guard that does not exist: $guard"
  case " $seen " in
    *" $guard "*) fail "two rows name $guard as their guard; a guard binds to one row" ;;
  esac
  seen="$seen $guard"
  # The binding, read from the guard's one `guards` line.
  calls="$(grep -E '^guards ' "$REPO_ROOT/$guard" || true)"
  [ "$(printf '%s\n' "$calls" | grep -c .)" -eq 1 ] \
    || fail "$guard must call guards exactly once at the start of a line; found $(printf '%s\n' "$calls" | grep -c .)"
  read -ra words <<<"$calls"
  [ "${#words[@]}" -gt 1 ] || fail "$guard calls guards with no path"
  for p in "${words[@]:1}"; do
    grep -qE "$pat" <<<"$p" \
      || fail "$guard guards $p, which '$pat' does not match; the row and its guard disagree about what is excluded"
    grep -qxF -- "$p" <<<"$matches" \
      || fail "$guard guards $p, which is not a tracked file the pattern matches"
  done
  # The exclusion itself: the first file the row matches is not a checked file.
  first="$(printf '%s\n' "$matches" | head -n 1)"
  if grep -qxF -- "$first" <<<"$list"; then
    fail "checked() lists $first, which the row '$pat' excludes; EXCLUDED is not built from the table"
  fi
done

printf '%s\n' "$list" | grep -q '[[:space:]*?[\\"]' \
  && fail "a tracked path carries whitespace, a glob character, or a quoted path; the tool tests expand the list unquoted:"$'\n'"$(printf '%s\n' "$list" | grep '[[:space:]*?[\\"]')"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
printf '%s\n' "$shell" | grep -qx 'bin/setup' || fail "checked_shell() does not list bin/setup, a shell file with no extension"
# The floor under that pin, derived rather than enumerated: an expected list of
# shell files goes stale silently, which is the defect this suite exists to
# catch. Every checked file whose first line names bash must be in
# checked_shell, so a shell file cannot leave the shell checkers' scope on one
# character. checked_shell's exact-shebang rule (spec §4) stands: this says
# what joining it costs, it does not relax it.
missing=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$(head -n 1 "$REPO_ROOT/$f")" in
    '#!'*bash*)
      printf '%s\n' "$shell" | grep -qxF -- "$f" || missing="$missing $f"
      ;;
  esac
done < <(printf '%s\n' "$list")
[ -z "$missing" ] \
  || fail "these checked file(s) open with a bash shebang and checked_shell() does not list them:$missing"$'\n'"their first line must be exactly '#!/usr/bin/env bash', or they leave shellcheck, shfmt and cspell unnoticed"

printf 'ownership: %s row(s), each bound to its guard; %s checked file(s), %s of them shell\n' \
  "${#GUARDED[@]}" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
