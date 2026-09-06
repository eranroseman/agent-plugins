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

# The Claude half reports its own absence rather than assuming it.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="/usr/bin:/bin" bash "$DOCTOR" 2>&1 || true)"
if command -v claude >/dev/null 2>&1 && [ -x /usr/bin/claude ]; then
  printf 'NOTE: claude is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: claude' \
    || fail "with claude off PATH the doctor must report the Claude half as skipped"
fi

# The upgrade path. `claude plugin install` is a no-op on an already-installed
# plugin -- it prints "already installed", exits 0 and leaves the old version on
# disk -- so a machine holding an older version only moves under `claude plugin
# update`. The CI end-to-end job starts from an empty HOME and structurally
# cannot reach this path. The older install below is a real one rather than a
# hand-edited `version` field, because the CLI reads the version from the
# install path and answers "already at the latest version" to a seeded field.
if command -v claude >/dev/null 2>&1; then
  W="$(mktemp -d)"
  trap 'rm -rf "$H" "$W"' EXIT
  PJ="plugins/software-development/.claude-plugin/plugin.json"
  cp -a "$REPO_ROOT" "$W/repo" || fail "could not copy the checkout into $W"
  jq '.version = "0.0.1"' "$REPO_ROOT/$PJ" > "$W/lowered" || fail "could not lower the version"
  cp "$W/lowered" "$W/repo/$PJ"

  mkdir -p "$W/home"
  env HOME="$W/home" claude plugin marketplace add "$W/repo" >/dev/null 2>&1 \
    || fail "could not add the copied marketplace"
  env HOME="$W/home" claude plugin install software-development@eranroseman --scope user \
    >/dev/null 2>&1 || fail "could not seed the 0.0.1 install"
  # Back to the declared version, and refresh the catalogue, mirroring the
  # documented real-machine step. Measured 2026-09-05: a directory-source
  # marketplace is read live, so `update` moves without this line; a
  # github-source one is a local clone and would be stale.
  cp "$REPO_ROOT/$PJ" "$W/repo/$PJ"
  env HOME="$W/home" claude plugin marketplace update eranroseman >/dev/null 2>&1 \
    || fail "could not refresh the copied marketplace"

  # The pinned clone, seeded from the shared checkout, so the only thing left
  # for bin/setup to converge is the Claude half.
  CLONE="$W/home/.local/share/software-development/upstream/superpowers"
  mkdir -p "$(dirname "$CLONE")"
  cp -a "$(fetch_upstream)" "$CLONE" || fail "could not seed the pinned clone"

  # A bin directory without codex, mirroring test-doctor-faults.sh: on a
  # machine that has codex on PATH, ensure_codex is no longer a stub, and an
  # inherited PATH would make it add the real eranroseman marketplace by
  # cloning it over the network into this scratch CODEX_HOME on every run of
  # this test. Excluding codex here keeps that half reporting skipped, the
  # same as it does on the CI runner this path cannot otherwise reach.
  BIN="$W/bin"
  mkdir -p "$BIN"
  for t in bash git jq node npx claude sed awk grep find date readlink basename dirname \
           rm mv ln mkdir cp cat; do
    p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
    ln -sf "$p" "$BIN/$t"
  done

  want="$(jq -r .version "$REPO_ROOT/$PJ")"
  if out="$(env HOME="$W/home" CODEX_HOME="$W/home/.codex" SD_MARKETPLACE_SOURCE="$W/repo" \
      PATH="$BIN" bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
  got="$(jq -r '.plugins["software-development@eranroseman"][0].version' \
    "$W/home/.claude/plugins/installed_plugins.json")"
  [ "$got" = "$want" ] \
    || fail "bin/setup left software-development at $got, declared $want:"$'\n'"$out"
  [ "$status" -eq 0 ] \
    || fail "bin/setup did not converge on an upgradeable machine (exit $status):"$'\n'"$out"
else
  printf 'SKIP: claude is not installed, so the upgrade path was not exercised\n'
fi

# The Codex half is gated the same way, and says so.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="/usr/bin:/bin" bash "$DOCTOR" 2>&1 || true)"
if command -v codex >/dev/null 2>&1 && [ -x /usr/bin/codex ]; then
  printf 'NOTE: codex is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: codex' \
    || fail "with codex off PATH the doctor must report the Codex half as skipped"
fi

printf 'setup-doctor: two entry points, lint clean, prerequisites split as documented\n'
