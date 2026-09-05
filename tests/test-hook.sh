#!/usr/bin/env bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (2) emit it as the documented JSON
# envelope so that a JSON parser recovers the payload byte-for-byte,
# (3) be wired by claude-hooks.json, (4) escape every C0 control character, not
# just the common five, and (5) fail rather than emit a rules-only envelope when
# payload.md is missing. Needs network access for (1).
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

H="$REPO_ROOT/plugins/software-development/hooks"
[ -f "$H/payload.md" ] || fail "missing $H/payload.md"
[ -f "$H/payload-rules.md" ] || fail "missing $H/payload-rules.md"
[ -f "$H/claude-hooks.json" ] || fail "missing $H/claude-hooks.json"
[ -x "$H/session-start" ] || fail "$H/session-start missing or not executable"

# (1) payload exactness
UP="$(fetch_upstream)"
src="$UP/skills/using-superpowers/SKILL.md"
[ "$(sed -n 30p "$src")" = '- "Let'"'"'s build X" → superpowers:brainstorming first, then implementation skills.' ] \
  || fail "upstream line 30 is not the expected superpowers:brainstorming line; re-audit the edit"
expected="$(mktemp)"
{
  printf '<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n'
  printf '**Below is the full content of your %s skill - your introduction to using skills. For all other skills, use the %s tool:**\n\n' \
    "'superpowers:using-superpowers'" "'Skill'"
  sed '30s/superpowers:brainstorming/software-development:brainstorming/' "$src"
  printf '</EXTREMELY_IMPORTANT>\n'
} > "$expected"
diff "$expected" "$H/payload.md" || fail "payload.md != upstream using-superpowers inside upstream's frame with one edit"
[ "$(grep -c 'software-development:brainstorming' "$H/payload.md")" -eq 1 ] || fail "expected exactly one software-development:brainstorming"
if grep -q 'superpowers:brainstorming' "$H/payload.md"; then fail "a superpowers:brainstorming reference survived"; fi

# (1b) the authored rules file: non-empty, exactly one trailing newline, and
# every qualified superpowers reference names a skill the curated entry lists.
[ -s "$H/payload-rules.md" ] || fail "payload-rules.md is empty"
[ "$(tail -c 1 "$H/payload-rules.md" | wc -l)" -eq 1 ] || fail "payload-rules.md must end with a newline"
[ "$(tail -c 2 "$H/payload-rules.md" | wc -l)" -eq 1 ] || fail "payload-rules.md must end with exactly one newline"
grep -q 'worktree' "$H/payload-rules.md" || fail "payload-rules.md does not carry the worktree rule"
if grep -q 'superpowers:brainstorming' "$H/payload-rules.md"; then fail "payload-rules.md names superpowers:brainstorming"; fi
curated="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  printf '%s\n' "$curated" | grep -qxF -- "$name" \
    || fail "payload-rules.md names superpowers:$name, which the curated entry does not list"
done < <(grep -o 'superpowers:[a-z-]*' "$H/payload-rules.md" | sed 's/^superpowers://' | sort -u)

# (2) envelope round-trip
# CLAUDE_PLUGIN_ROOT mirrors how claude-hooks.json invokes the script; session-start
# itself resolves payload.md via dirname "$0" and never reads the variable, so
# the ${CLAUDE_PLUGIN_ROOT} expansion asserted in section 3 is checked as a
# string and not exercised as an expansion.
out="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/software-development" "$H/session-start")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  || fail "output is not the SessionStart envelope: $out"
[ "$(printf '%s' "$out" | jq 'keys | length')" -eq 1 ] || fail "envelope has extra top-level keys"
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') \
     <(cat "$H/payload.md"; printf '\n'; cat "$H/payload-rules.md") \
  || fail "additionalContext does not round-trip to payload.md + blank line + payload-rules.md"
len="$(printf '%s' "$out" | jq '.hookSpecificOutput.additionalContext | length')"
[ "$len" -lt 8000 ] || fail "additionalContext is $len code points; the tripwire is 8000"

# (3) wiring: the Claude manifest declares the hook file, and nothing sits at
# the path Codex loads by fallback when its manifest has no hooks key.
PLUGIN="$REPO_ROOT/plugins/software-development"
HJ="$H/claude-hooks.json"
[ -z "$(find "$REPO_ROOT/plugins" -name hooks.json)" ] || fail "no plugins/**/hooks/hooks.json may exist: Codex loads that path by fallback"
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$HJ")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$HJ")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HJ")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$HJ")" = 'hooks' ] || fail "claude-hooks.json top level must contain only 'hooks'"
[ "$(jq -r '.hooks' "$PLUGIN/.claude-plugin/plugin.json")" = './hooks/claude-hooks.json' ] || fail "Claude manifest must declare hooks: ./hooks/claude-hooks.json"
[ "$(jq -r '.version' "$PLUGIN/.claude-plugin/plugin.json")" = '0.2.0' ] || fail "Claude manifest version must be 0.2.0"
[ "$(jq -r '.version' "$PLUGIN/.codex-plugin/plugin.json")" = '0.2.0' ] || fail "Codex manifest version must be 0.2.0"
[ "$(jq 'has("hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'false' ] || fail "Codex manifest must not declare hooks"
[ "$(jq '.interface.capabilities | index("Lifecycle hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'null' ] || fail "Codex manifest must not claim Lifecycle hooks"

for f in "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/.codex-plugin/plugin.json" "$MARKETPLACE"; do
  if grep -q 'bridge rules' "$f"; then fail "$f still advertises bridge rules"; fi
  if grep -q 'Lifecycle hooks' "$f"; then fail "$f still advertises Lifecycle hooks"; fi
done

# (4) the encoder escapes control characters, not just the common five
T="$(mktemp -d)"
cp "$H/session-start" "$T/session-start"
sample=$'x\x01\x0c\x1b\x1fy "q" \\ end'
printf '%s' "$sample" > "$T/payload.md"
: > "$T/payload-rules.md"   # the script now reads it; empty keeps the expectation the sample alone
out="$("$T/session-start")"
printf '%s' "$out" | jq -e . >/dev/null || fail "control characters produced invalid JSON"
[ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" = "$sample" ] \
  || fail "control characters did not round-trip"

# (5) a missing payload.md must fail loudly: $(...) does not inherit -e, so
# `cat payload.md; printf '\n'; cat payload-rules.md` would let a present
# payload-rules.md's zero exit mask the missing file and silently emit a
# rules-only envelope. Assert the fixed `&&`-joined form fails instead.
T2="$(mktemp -d)"
cp "$H/session-start" "$T2/session-start"
printf 'some rules\n' > "$T2/payload-rules.md"
if "$T2/session-start" >/dev/null 2>&1; then
  fail "session-start must exit non-zero when payload.md is missing"
fi

echo "hook: payload exact, envelope round-trips, wiring correct, control characters escaped"
