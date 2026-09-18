#!/usr/bin/env bash
# The engine's shape: two entry points, one of them a wrapper; a usage text;
# the documented prerequisite split, with both scripts run under an empty
# PATH; a doctor that describes an empty machine rather than dying on it; the
# gated halves reporting their own absence; the report-only checks; and the
# README recipes against the usage text. Needs no network and no CLI. The
# shell lint is tests/test-lint-shell.sh, the upgrade path is
# tests/test-setup-upgrade.sh, and the machines the doctor cannot read are
# tests/test-doctor-silence.sh.
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
H="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$H"' EXIT
# /bin/bash by absolute path: with an empty PATH, `bash` itself would not
# resolve and the failure would be the shell's 127, not the script's 2. A
# command meant to exit non-zero is captured as `if out="$(...)"`: lib.sh is
# `set -e`, and a bare capture whose command fails kills the test on that
# line, before `status=$?` runs.
if out="$(env -i HOME="$H" PATH="$H/nowhere" /bin/bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "bin/setup must exit 2 when a fatal prerequisite is missing (got $status)"
# The refusal's own words, not a substring the script's path could supply:
# under the deployment path, `<path>: dirname: command not found` once
# carried `.claude` and satisfied a grep for `claude` on its own (#16).
printf '%s\n' "$out" | grep -q 'bin/setup needs these on PATH:.*claude' \
  || fail "the refusal must name the missing tools in its own words: $out"
printf '%s\n' "$out" | grep -q 'command not found' \
  && fail "bin/setup ran an external command before refusing:"$'\n'"$out"

# The doctor under the same empty PATH: nothing is fatal, every check opens
# on `needs jq`, the skill root is reported missing, and the verdict names
# the tool. The doctor resolves its own directory by parameter expansion and
# the shell by $BASH, which is why both scripts are invoked as
# `/bin/bash <script>` here rather than through their shebang.
if out="$(env -i HOME="$H" PATH="$H/nowhere" /bin/bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/doctor under an empty PATH must exit 1, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'command not found' \
  && fail "bin/doctor ran an external command under an empty PATH:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'the skill root is missing' \
  || fail "the doctor under an empty PATH did not report the skill root:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'for want of: jq' \
  || fail "the doctor under an empty PATH did not name jq in its verdict:"$'\n'"$out"

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
mkdir -p "$H/.claude/plugins" || fail "could not create $H/.claude/plugins"
cat > "$H/.claude/plugins/known_marketplaces.json" <<JSON || fail "could not write known_marketplaces.json"
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
help_text="$("$SETUP" --help 2>&1)" || fail "bin/setup --help failed"
# Extract fenced blocks whose nearest preceding h2 starts with "Install" or
# "Update" (so "## Updates" counts too). An h1 or an h2 closes the scope; an
# h3 stays inside its parent, which is what "every fenced block in the
# section" means (#18). \036 is the record separator awk prints between
# blocks; no README carries it.
extract_scoped_blocks() {
  awk '
    /^##? / { insection = ($0 ~ /^## (Install|Update)/); next }
    /^```/ { infence = !infence; if (!infence && insection) print "\036"; next }
    infence && insection { print }
  ' "$1"
}
# The scope rule, proved on a synthetic README carrying all three headings:
# a block under `### Sub` inside Install is in, blocks after a `# Top` or
# under `## Other` are out.
S="$H/scope.md"
printf '%s\n' '# Title' '```' 'h1-before' '```' '## Install' '```' 'in-install' '```' \
  '### Sub' '```' 'in-sub' '```' '# Top' '```' 'after-h1' '```' '## Update' '```' 'in-update' '```' \
  '## Other' '```' 'in-other' '```' > "$S" || fail "could not write $S"
got="$(extract_scoped_blocks "$S" | tr -d '\036' | grep . | tr '\n' ' ')" || true
[ "$got" = "in-install in-sub in-update " ] \
  || fail "extract_scoped_blocks must keep an h3 inside its section and close on an h1 or h2; got '$got'"
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

printf 'setup-doctor: two entry points, prerequisites split as documented, recipes match the usage text\n'
