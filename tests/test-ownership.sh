#!/usr/bin/env bash
# The ownership derivation stays honest (spec §4). Every vendored pattern in
# tests/lib.sh matches at least one tracked file and is paired with a drift
# test that names what it excludes, so nothing sits in the excluded set
# without a test behind it. The checked list is non-empty, and no checked
# path carries whitespace, a glob character, or a quoted path, which is what
# lets the tool tests expand `$(checked ...)` unquoted, one path per word.
. "$(dirname "$0")/lib.sh"

[ "${#VENDORED_PATTERNS[@]}" -eq "${#VENDORED_GUARDS[@]}" ] \
  || fail "VENDORED_PATTERNS and VENDORED_GUARDS differ in length; every pattern needs its guard"
[ "${#VENDORED_PATTERNS[@]}" -gt 0 ] || fail "no vendored pattern is declared"

i=0
while [ "$i" -lt "${#VENDORED_PATTERNS[@]}" ]; do
  pat="${VENDORED_PATTERNS[$i]}"
  guard="${VENDORED_GUARDS[$i]}"
  i=$((i + 1))
  git -C "$REPO_ROOT" ls-files | grep -qE "$pat" \
    || fail "pattern '$pat' matches no tracked file; drop it from tests/lib.sh or fix it"
  [ -f "$REPO_ROOT/$guard" ] || fail "pattern '$pat' names a guard that does not exist: $guard"
  # The subject: the fourth path segment with regex escapes removed --
  # plugins/<plugin>/<skills|hooks>/<subject>. The guard must name it.
  subject="${pat#^plugins/*/}"
  subject="${subject#*/}"
  subject="${subject%%/*}"
  subject="${subject%\$}"
  subject="${subject//\\/}"
  [ -n "$subject" ] || fail "pattern '$pat' yields no subject; the guard check would match anything"
  grep -qF -- "$subject" "$REPO_ROOT/$guard" \
    || fail "$guard never names '$subject', so nothing asserts the bytes '$pat' excludes"
done

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"
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
printf '%s\n' "$list" | grep -q '^plugins/software-dev/hooks/payload\.md$' \
  && fail "checked() lists the vendored payload.md"

printf 'ownership: %s vendored pattern(s) each guarded; %s checked file(s), %s of them shell\n' \
  "${#VENDORED_PATTERNS[@]}" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
