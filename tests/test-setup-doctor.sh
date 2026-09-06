#!/usr/bin/env bash
# The engine's shape: two entry points, one of them a wrapper; shellcheck
# clean; a usage text; the documented prerequisite split; and a doctor that
# describes an empty machine rather than dying on it. Needs no network.
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
DOCTOR="$REPO_ROOT/bin/doctor"
[ -x "$SETUP" ] || fail "bin/setup missing or not executable"
[ -x "$DOCTOR" ] || fail "bin/doctor missing or not executable"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$SETUP" "$DOCTOR" "$REPO_ROOT/bin/bump-superpowers" \
    || fail "shellcheck reported problems in bin/"
else
  printf 'SKIP: shellcheck is not installed; bin/ was not linted\n'
fi

# bin/doctor is the same engine in check mode, not a second implementation.
[ "$(grep -c . "$DOCTOR")" -le 6 ] || fail "bin/doctor should be a thin wrapper over bin/setup --check"
grep -q -- '--check' "$DOCTOR" || fail "bin/doctor must invoke bin/setup --check"

"$SETUP" --help >/dev/null 2>&1 || fail "bin/setup --help must exit 0"
"$SETUP" --nonsense >/dev/null 2>&1 && fail "an unknown argument must not exit 0"

# Prerequisites: fatal for setup, gated for the doctor. An empty PATH removes
# every one of the five, so setup must refuse and the doctor must not.
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT
# /bin/bash by absolute path: with an empty PATH, `bash` itself would not
# resolve and the failure would be the shell's 127, not the script's 2.
# Every capture below is wrapped in `if`: lib.sh is `set -e`, and a bare
# `out="$(cmd)"` whose command exits non-zero kills the test on that line,
# before `status=$?` runs. These commands are all meant to exit non-zero.
if out="$(env -i HOME="$H" PATH="$H/nowhere" /bin/bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "bin/setup must exit 2 when a fatal prerequisite is missing (got $status)"
printf '%s\n' "$out" | grep -q 'claude' || fail "the refusal must name the missing tools: $out"

# The doctor on an empty machine: describes it, exits 1, dies on nothing.
if out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/doctor on an empty HOME must exit 1, got $status"
printf '%s\n' "$out" | grep -q 'FAIL:' || fail "the doctor reported no failure on an empty HOME"

printf 'setup-doctor: two entry points, lint clean, prerequisites split as documented\n'
