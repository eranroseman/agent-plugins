#!/usr/bin/env bash
# The engine's shape: two entry points, one of them a wrapper; a usage text;
# the documented prerequisite split, with both scripts run under an empty
# PATH; a doctor that describes an empty machine rather than dying on it; the
# conditional halves reporting their own absence; and the report-only
# checks. Needs no network and no CLI. The shell lint is tests/test-lint-shell.sh, the upgrade path is
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
  | bash "$REPO_ROOT/scripts/upstream-watch" --newest-stable-tag)" \
  || fail "upstream-watch --newest-stable-tag failed"
[ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"

# bin/doctor is the same engine in check mode, not a second implementation.
[ "$(grep -c . "$DOCTOR")" -le 6 ] || fail "bin/doctor should be a thin wrapper over bin/setup --check"
grep -q -- '--check' "$DOCTOR" || fail "bin/doctor must invoke bin/setup --check"

"$SETUP" --help >/dev/null 2>&1 || fail "bin/setup --help must exit 0"
"$SETUP" --nonsense >/dev/null 2>&1 && fail "an unknown argument must not exit 0"

# The bash floor is stated in three places and must be one number; the
# refusal itself cannot run on a machine whose bash is above it.
for f in "$SETUP" "$REPO_ROOT/tests/run.sh" "$REPO_ROOT/README.md"; do
  grep -q 'bash.*4\.4 or later' "$f" || fail "$f does not state the bash 4.4 floor"
done

# Prerequisites: fatal for setup, conditional for the doctor. An empty PATH
# removes every one of the five, so setup must refuse and the doctor must not.
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

# Every doctor run below inherited this test's own PATH once, which would now
# reach the freshness check's api.github.com wherever curl is present (spec
# §12, #24). This fixture keeps the rest of the real machine's behavior --
# claude and codex answer for real when this machine has them, the way these
# checks always exercised them -- and only curl is missing.
NOCURL="$H/nocurl"
link_tools "$NOCURL" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
for t in claude codex; do
  p="$(command -v "$t" 2>/dev/null)" || continue
  ln -sf "$p" "$NOCURL/$t" || fail "could not link $t into $NOCURL"
done

# The doctor on an empty machine: describes it, exits 1, dies on nothing.
if out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$NOCURL" /bin/bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/doctor on an empty HOME must exit 1, got $status"
printf '%s\n' "$out" | grep -q 'FAIL:' || fail "the doctor reported no failure on an empty HOME"

# The Claude and Codex halves report their own absence rather than assuming
# it. This fixture carries the engine's own tools and nothing else, so this
# run needs no network and exercises the gating assertion on every machine,
# rather than only on one where neither CLI sits under /usr/bin.
NOCLI="$H/nocli"
link_tools "$NOCLI" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$NOCLI" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'SKIP: claude' \
  || fail "with claude off PATH the doctor must report the Claude half as skipped"
printf '%s\n' "$out" | grep -q 'SKIP: codex' \
  || fail "with codex off PATH the doctor must report the Codex half as skipped"

# Report-only checks: present on every run, never repaired.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$NOCURL" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'telemetry' \
  || fail "the doctor does not report the telemetry variable"
printf '%s\n' "$out" | grep -q 'auto-update' \
  || fail "the doctor does not report the auto-update state"

# A scratch HOME whose marketplace entry is a directory has no clone to compare,
# so the staleness check must skip rather than fail.
mkdir -p "$H/.claude/plugins" || fail "could not create $H/.claude/plugins"
cat >"$H/.claude/plugins/known_marketplaces.json" <<JSON || fail "could not write known_marketplaces.json"
{"eranroseman":{"source":{"source":"directory","path":"$REPO_ROOT"},"installLocation":"$REPO_ROOT"}}
JSON
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$NOCURL" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'SKIP: the marketplace source is a directory' \
  || fail "a directory marketplace source must skip the staleness check, not fail it"

printf 'setup-doctor: two entry points, prerequisites split as documented\n'
