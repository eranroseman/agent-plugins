#!/usr/bin/env bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (1b) name only skills the superpowers
# subset entry lists in its working-rules file, (2) emit both files as the
# documented JSON envelope so that a JSON parser recovers the additional
# context byte-for-byte, (3) be wired by claude-hooks.json, (4) escape every
# C0 control character, not just the common five, and (5) fail rather than
# emit a rules-only envelope when using-superpowers.md is missing. Needs
# network access for (1).
. "$(dirname "$0")/lib.sh"

# fail() exits immediately, so temporaries have to be freed from a trap or a
# failing assertion leaks them.
cleanup() {
  [ -n "${expected:-}" ] && rm -f "$expected"
  [ -n "${T:-}" ] && rm -rf "$T"
  [ -n "${T2:-}" ] && rm -rf "$T2"
  return 0
}
trap cleanup EXIT

H="$REPO_ROOT/plugins/software-dev/hooks"
[ -f "$H/using-superpowers.md" ] || fail "missing $H/using-superpowers.md"
[ -f "$H/working-rules.md" ] || fail "missing $H/working-rules.md"
[ -f "$H/claude-hooks.json" ] || fail "missing $H/claude-hooks.json"
[ -x "$H/session-start" ] || fail "$H/session-start missing or not executable"
guards plugins/software-dev/hooks/using-superpowers.md

# (1) using-superpowers.md is the recipe's output, exactly. The frame is read
# from upstream's own hooks/session-start rather than transcribed here, and
# the recipe lives in scripts/bump-superpowers so a bump and this test cannot
# diverge.
UP="$(fetch_upstream)"
src="$UP/skills/using-superpowers/SKILL.md"
[ "$(sed -n 30p "$src")" = '- "Let'"'"'s build X" → superpowers:brainstorming first, then implementation skills.' ] \
  || fail "upstream line 30 is not the expected superpowers:brainstorming line; re-audit the edit"
expected="$(mktemp)"
bash "$REPO_ROOT/scripts/bump-superpowers" --emit-using-superpowers "$UP" >"$expected" \
  || fail "scripts/bump-superpowers --emit-using-superpowers failed"
diff "$expected" "$H/using-superpowers.md" || fail "using-superpowers.md != the recipe's output for the pinned clone"
[ "$(grep -c 'software-dev:brainstorming' "$H/using-superpowers.md")" -eq 1 ] || fail "expected exactly one software-dev:brainstorming"
if grep -q 'superpowers:brainstorming' "$H/using-superpowers.md"; then fail "a superpowers:brainstorming reference survived"; fi

# (1b) the first-party rules file names only skills the subset entry lists:
# a working rule that points at a skill the marketplace does not ship is a
# dangling name in every session. Cross-checked against the marketplace,
# which no copy of the file could do.
[ -s "$H/working-rules.md" ] || fail "working-rules.md is empty"
subset="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  printf '%s\n' "$subset" | grep -qxF -- "$name" \
    || fail "working-rules.md names superpowers:$name, which the subset entry does not list"
done < <(grep -o 'superpowers:[a-z-]*' "$H/working-rules.md" | sed 's/^superpowers://' | sort -u)

# (2) envelope round-trip
# CLAUDE_PLUGIN_ROOT mirrors how claude-hooks.json invokes the script; session-start
# itself resolves using-superpowers.md via dirname "$0" and never reads the
# variable, so the ${CLAUDE_PLUGIN_ROOT} expansion asserted in section 3 is
# checked as a string and not exercised as an expansion.
out="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/software-dev" "$H/session-start")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  || fail "output is not the SessionStart envelope: $out"
[ "$(printf '%s' "$out" | jq 'keys | length')" -eq 1 ] || fail "envelope has extra top-level keys"
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') \
  <(
    cat "$H/using-superpowers.md"
    printf '\n'
    cat "$H/working-rules.md"
  ) \
  || fail "additionalContext does not round-trip to using-superpowers.md + blank line + working-rules.md"
len="$(printf '%s' "$out" | jq '.hookSpecificOutput.additionalContext | length')"
[ "$len" -lt 8000 ] || fail "additionalContext is $len code points; the tripwire is 8000"

# (3) wiring: the Claude manifest declares the hook file, and nothing sits at
# the path Codex loads by fallback when its manifest has no hooks key.
PLUGIN="$REPO_ROOT/plugins/software-dev"
HJ="$H/claude-hooks.json"
[ -z "$(find "$REPO_ROOT/plugins" -name hooks.json)" ] || fail "no plugins/**/hooks/hooks.json may exist: Codex loads that path by fallback"
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$HJ")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$HJ")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HJ")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$HJ")" = 'hooks' ] || fail "claude-hooks.json top level must contain only 'hooks'"
[ "$(jq -r '.hooks' "$PLUGIN/.claude-plugin/plugin.json")" = './hooks/claude-hooks.json' ] || fail "Claude manifest must declare hooks: ./hooks/claude-hooks.json"
[ "$(jq 'has("hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'false' ] || fail "Codex manifest must not declare hooks"
[ "$(jq '.interface.capabilities | index("Lifecycle hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'null' ] || fail "Codex manifest must not claim Lifecycle hooks"
# Scoped to the Codex manifest alone, never folded into the loop below: the
# Claude manifest's own description legitimately says "and its inspector" --
# consistency-audit's subagent ships there -- so a check spanning both files
# would fail on the true claim while catching the false one.
grep -qi 'inspector' "$PLUGIN/.codex-plugin/plugin.json" \
  && fail "Codex manifest advertises an inspector; a Codex plugin cannot ship a subagent"

for f in "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/.codex-plugin/plugin.json" "$MARKETPLACE"; do
  if grep -q 'bridge rules' "$f"; then fail "$f still advertises bridge rules"; fi
  if grep -q 'Lifecycle hooks' "$f"; then fail "$f still advertises Lifecycle hooks"; fi
done

# (4) the encoder escapes control characters, not just the common five
T="$(mktemp -d)"
cp "$H/session-start" "$T/session-start"
sample=$'x\x01\x0c\x1b\x1fy "q" \\ end'
printf '%s' "$sample" >"$T/using-superpowers.md"
: >"$T/working-rules.md" # the script reads it; empty keeps the expectation the sample alone
out="$("$T/session-start")"
printf '%s' "$out" | jq -e . >/dev/null || fail "control characters produced invalid JSON"
[ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" = "$sample" ] \
  || fail "control characters did not round-trip"

# (5) a missing using-superpowers.md must fail loudly: $(...) does not inherit
# -e, so `cat using-superpowers.md; printf '\n'; cat working-rules.md` would
# let a present working-rules.md's zero exit mask the missing file and
# silently emit a rules-only envelope. Assert the `&&`-joined form fails.
T2="$(mktemp -d)"
cp "$H/session-start" "$T2/session-start"
printf 'some rules\n' >"$T2/working-rules.md"
if "$T2/session-start" >/dev/null 2>&1; then
  fail "session-start must exit non-zero when using-superpowers.md is missing"
fi

echo "hook: using-superpowers exact, envelope round-trips, wiring correct, control characters escaped"
