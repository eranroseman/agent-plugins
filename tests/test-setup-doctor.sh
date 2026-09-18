#!/usr/bin/env bash
# The engine's shape: two entry points, one of them a wrapper; shellcheck
# clean; a usage text; the documented prerequisite split; and a doctor that
# describes an empty machine rather than dying on it. Every assertion but the
# last needs no network and no CLI; the upgrade-path block at the end is gated
# on claude and fetches the pinned upstream tree.
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
DOCTOR="$REPO_ROOT/bin/doctor"
[ -x "$SETUP" ] || fail "bin/setup missing or not executable"
[ -x "$DOCTOR" ] || fail "bin/doctor missing or not executable"

# upstream-watch's tag filter, with no network: the newest stable release
# wins over a prerelease, a -dev build, and a parallel tag series.
got="$(printf '%s\n' archify-dsh-v0.1.0 v2.16.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 \
  | bash "$REPO_ROOT/bin/upstream-watch" --newest-stable-tag)" \
  || fail "upstream-watch --newest-stable-tag failed"
[ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"

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

# The Claude half reports its own absence rather than assuming it.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="/usr/bin:/bin" bash "$DOCTOR" 2>&1 || true)"
if command -v claude >/dev/null 2>&1 && [ -x /usr/bin/claude ]; then
  printf 'NOTE: claude is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: claude' \
    || fail "with claude off PATH the doctor must report the Claude half as skipped"
fi

# The Codex half is gated the same way, and says so.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="/usr/bin:/bin" bash "$DOCTOR" 2>&1 || true)"
if command -v codex >/dev/null 2>&1 && [ -x /usr/bin/codex ]; then
  printf 'NOTE: codex is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: codex' \
    || fail "with codex off PATH the doctor must report the Codex half as skipped"
fi

# Report-only checks: present on every run, never repaired.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'telemetry' \
  || fail "the doctor does not report the telemetry variable"
printf '%s\n' "$out" | grep -q 'auto-update' \
  || fail "the doctor does not report the auto-update state"

# A scratch HOME whose marketplace entry is a directory has no clone to compare,
# so the staleness check must skip rather than fail.
mkdir -p "$H/.claude/plugins"
cat > "$H/.claude/plugins/known_marketplaces.json" <<JSON
{"eranroseman":{"source":{"source":"directory","path":"$REPO_ROOT"},"installLocation":"$REPO_ROOT"}}
JSON
out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'SKIP: the marketplace source is a directory' \
  || fail "a directory marketplace source must skip the staleness check, not fail it"

# Every fenced block in an Install or Update section of either README must
# appear verbatim in the usage text, so a command cannot be documented in one
# place and not the other. Scoped to those two headings -- not every fenced
# block in the file -- so a non-command sample under an unrelated heading (a
# JSON example under Environment, say) cannot produce a false failure.
help_text="$("$SETUP" --help 2>&1)"
# Extract fenced blocks whose nearest preceding "## " heading starts with
# "Install" or "Update" (so "## Updates" counts too). \036 is the record
# separator awk prints between blocks; no README carries it.
extract_scoped_blocks() {
  awk '
    /^## / { insection = ($0 ~ /^## (Install|Update)/); next }
    /^```/ { infence = !infence; if (!infence && insection) print "\036"; next }
    infence && insection { print }
  ' "$1"
}
# $1 the README path, $2 the minimum number of Install/Update blocks it must
# contribute -- the "found 0" guard from before, now per file, so a renamed
# heading cannot silently drop a whole README out of coverage.
check_readme_blocks() {
  local readme="$1" min="$2" blocks=0 buf=""
  while IFS= read -r line; do
    if [ "$line" = "$(printf '\036')" ]; then
      [ -n "$buf" ] || continue
      case "$help_text" in
        *"$buf"*) blocks=$((blocks + 1)) ;;
        *) fail "a fenced Install/Update block in $readme is missing from bin/setup --help: $buf" ;;
      esac
      buf=""
    elif [ -z "$buf" ]; then
      buf="$line"
    else
      buf="$buf
$line"
    fi
  done < <(extract_scoped_blocks "$readme")
  [ "$blocks" -ge "$min" ] \
    || fail "expected at least $min fenced Install/Update block(s) in $readme, found $blocks"
}
check_readme_blocks "$REPO_ROOT/README.md" 2
check_readme_blocks "$REPO_ROOT/plugins/software-dev/README.md" 1

printf 'setup-doctor: two entry points, lint clean, prerequisites split as documented\n'
