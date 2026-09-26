#!/usr/bin/env bash
# The doctor's report-only pass says everything it can see (spec §10). The
# archify update-check variable in its three states, read from the
# environment and from the env map in settings.json, which this script never
# writes (#50); every skills.sh install the desired state does not declare,
# by name, source and ref, with a none line, a SKIP without a lockfile and a
# FAIL on one jq cannot parse (#54); the two CLI versions, so a renamed verb
# shows as a fact change (#44); and a sensemaking manifest whose version
# cannot be read, which once reported OK (#17). Needs no network and no CLI:
# claude and codex are stubs that answer --version and nothing else.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "2.1.273 (Claude Code)\\n"; exit 0; }\nexit 1\n' >"$BIN/claude" \
  || fail "could not write the claude stub"
printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "codex-cli 0.147.0\\n"; exit 0; }\n[ "$*" = "plugin list --json" ] && { printf "{\\"installed\\":[]}\\n"; exit 0; }\nexit 1\n' >"$BIN/codex" \
  || fail "could not write the codex stub"
chmod +x "$BIN/claude" "$BIN/codex" || fail "could not make the stubs executable"

# $1 a HOME (created), $2 extra env assignments for `env`; leaves the output in OUT.
run_doctor() {
  local home="$1"
  shift
  mkdir -p "$home/.agents/skills" || fail "could not create $home"
  # shellcheck disable=SC2086  # the assignments are one word each by construction
  OUT="$(env -u ARCHIFY_UPDATE_CHECK_DISABLED HOME="$home" CODEX_HOME="$home/.codex" PATH="$BIN" "$@" /bin/bash "$DOCTOR" 2>&1 || true)"
}

# 1. #50, unset in both places: the check is on, and the README is named.
run_doctor "$T/h1"
saw "NOTE: archify's update check is on: ARCHIFY_UPDATE_CHECK_DISABLED is unset in the environment and in ~/.claude/settings.json; see the plugin README (this script never sets it)" \
  || fail "unset: the archify line is wrong or missing:"$'\n'"$OUT"

# 2. #50, =1 in the environment: off, and which source said so.
run_doctor "$T/h2" ARCHIFY_UPDATE_CHECK_DISABLED=1
saw "NOTE: archify's update check is off: ARCHIFY_UPDATE_CHECK_DISABLED=1 in the environment" \
  || fail "=1 in the environment: the archify line is wrong or missing:"$'\n'"$OUT"

# 3. #50, =true in settings.json's env map: still on, because check-update.mjs
# tests for exactly 1; and the file is not written, hashed before and after.
mkdir -p "$T/h3/.claude" || fail "could not seed h3"
printf '{"env":{"ARCHIFY_UPDATE_CHECK_DISABLED":"true"}}\n' >"$T/h3/.claude/settings.json" || fail "could not write settings.json"
before="$(sha256sum "$T/h3/.claude/settings.json")"
run_doctor "$T/h3"
saw "NOTE: archify's update check is still on: ARCHIFY_UPDATE_CHECK_DISABLED=true in the env map in ~/.claude/settings.json, and check-update.mjs tests for exactly 1" \
  || fail "=true in settings.json: the archify line is wrong or missing:"$'\n'"$OUT"
[ "$(sha256sum "$T/h3/.claude/settings.json")" = "$before" ] || fail "the doctor wrote settings.json"

# 4. #54: three undeclared installs, one of them the vendored scaffolder's
# unadapted twin, beside every declared one; each note names its remedy.
mkdir -p "$T/h4/.agents" || fail "could not seed h4"
jq '{version: 3,
     skills: ((reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value}))
       + {"tdd": {source: "mattpocock/skills", ref: "v1.2.3"},
          "typesafe-ai": {source: "typesafe-ai/skills"},
          "setup-matt-pocock-skills": {source: "mattpocock/skills", ref: "v1.2.3"}}),
     dismissed: {}}' "$REPO_ROOT/skills.json" >"$T/h4/.agents/.skill-lock.json" \
  || fail "could not synthesize the lockfile"
run_doctor "$T/h4"
saw "NOTE: skills.sh install tdd (mattpocock/skills at v1.2.3) is not in the skills.sh desired state; remove it with 'npx skills remove tdd -g'" \
  || fail "undeclared tdd was not reported with source and ref:"$'\n'"$OUT"
saw "NOTE: skills.sh install typesafe-ai (typesafe-ai/skills at no ref) is not in the skills.sh desired state; remove it with 'npx skills remove typesafe-ai -g'" \
  || fail "undeclared typesafe-ai was not reported with its missing ref named:"$'\n'"$OUT"
saw "NOTE: skills.sh install setup-matt-pocock-skills (mattpocock/skills at v1.2.3) is not in the skills.sh desired state; remove it with 'npx skills remove setup-matt-pocock-skills -g'" \
  || fail "the scaffolder's twin lost its remedy:"$'\n'"$OUT"
saw 'every skills.sh install in the lockfile is in the skills.sh desired state' \
  && fail "the none line was printed beside undeclared installs:"$'\n'"$OUT"

# 5. #54: a lockfile that matches the desired state exactly: the none line.
seed_lockfile "$T/h5"
run_doctor "$T/h5"
saw 'NOTE: every skills.sh install in the lockfile is in the skills.sh desired state' \
  || fail "a lockfile matching the desired state did not print the none line:"$'\n'"$OUT"

# 6. #54: no lockfile is a SKIP; an unparsable one is a FAIL, never the all-clear.
run_doctor "$T/h6"
saw 'SKIP: no skills.sh lockfile at' || fail "no lockfile: not a SKIP:"$'\n'"$OUT"
mkdir -p "$T/h7/.agents" || fail "could not seed h7"
printf '{\n' >"$T/h7/.agents/.skill-lock.json" || fail "could not corrupt the lockfile"
run_doctor "$T/h7"
saw 'FAIL: the lockfile at' || fail "an unparsable lockfile: not a FAIL:"$'\n'"$OUT"
saw 'is in the skills.sh desired state' && fail "an unparsable lockfile printed the none line:"$'\n'"$OUT"

# 7. #44: both CLI versions, as facts.
run_doctor "$T/h8"
saw 'NOTE: claude 2.1.273 (Claude Code)' || fail "the claude version was not reported:"$'\n'"$OUT"
saw 'NOTE: codex codex-cli 0.147.0' || fail "the codex version was not reported:"$'\n'"$OUT"

# 8. #17's false OK: a sensemaking manifest with no readable version is a
# FAIL in the Claude half, not an OK. A scratch checkout, since the manifest
# is the desired state and the doctor reads it beside itself.
scratch_repo() {
  local r="$T/$1"
  mkdir -p "$r/bin" "$r/.claude-plugin" "$r/plugins/sensemaking/.claude-plugin" "$r/plugins/software-dev/.claude-plugin" \
    || fail "could not seed $r"
  ln -s "$REPO_ROOT/bin/setup" "$r/bin/setup" || fail "could not link bin/setup into $r"
  cp "$MARKETPLACE" "$r/.claude-plugin/marketplace.json" || fail "could not copy the marketplace"
  cp "$REPO_ROOT/skills.json" "$r/skills.json" || fail "could not copy skills.json"
  cp "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json" "$r/plugins/software-dev/.claude-plugin/" \
    || fail "could not copy the software-dev manifest"
  printf '%s\n' "$r"
}
for shape in '{' '{"name":"sensemaking","version":""}'; do
  R="$(scratch_repo "sm-$RANDOM")"
  printf '%s\n' "$shape" >"$R/plugins/sensemaking/.claude-plugin/plugin.json" || fail "could not write the manifest"
  mkdir -p "$T/h9/.agents/skills" || fail "could not seed h9"
  OUT="$(env HOME="$T/h9" CODEX_HOME="$T/h9/.codex" PATH="$BIN" /bin/bash "$R/bin/setup" --check 2>&1 || true)"
  saw 'FAIL: sensemaking version unreadable from plugins/sensemaking/.claude-plugin/plugin.json' \
    || fail "manifest $shape: the unreadable version was not a FAIL:"$'\n'"$OUT"
  saw 'OK:   sensemaking@eranroseman' && fail "manifest $shape: the Claude half reported sensemaking OK:"$'\n'"$OUT"
done

printf 'doctor-report: archify variable in three states, undeclared installs named, both CLI versions, unreadable sensemaking version is a FAIL\n'
