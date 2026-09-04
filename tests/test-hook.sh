#!/usr/bin/env bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (2) emit it as the documented JSON
# envelope so that a JSON parser recovers the payload byte-for-byte, and
# (3) be wired by hooks.json. Needs network access for (1).
. "$(dirname "$0")/lib.sh"

H="$REPO_ROOT/plugins/software-development/hooks"
[ -f "$H/payload.md" ] || fail "missing $H/payload.md"
[ -f "$H/hooks.json" ] || fail "missing $H/hooks.json"
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
rm -f "$expected"
[ "$(grep -c 'software-development:brainstorming' "$H/payload.md")" -eq 1 ] || fail "expected exactly one software-development:brainstorming"
if grep -q 'superpowers:brainstorming' "$H/payload.md"; then fail "a superpowers:brainstorming reference survived"; fi

# (2) envelope round-trip
out="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/software-development" "$H/session-start")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  || fail "output is not the SessionStart envelope: $out"
[ "$(printf '%s' "$out" | jq 'keys | length')" -eq 1 ] || fail "envelope has extra top-level keys"
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') "$H/payload.md" \
  || fail "additionalContext does not round-trip to payload.md"

# (3) wiring
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$H/hooks.json")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$H/hooks.json")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$H/hooks.json")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$H/hooks.json")" = 'hooks' ] || fail "hooks.json top level must contain only 'hooks' (Codex rejects unknown top-level keys)"

echo "hook: payload exact, envelope round-trips, wiring correct"
