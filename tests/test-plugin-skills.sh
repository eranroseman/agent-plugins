#!/usr/bin/env bash
# Invariants over every skill the two plugins ship, plus the shape of the
# first-party assets that have no upstream to drift from. Each is a mechanism
# for a rule that would otherwise live in prose:
#   - a user-invocable-only skill carries both gates, the field Claude reads and the yaml
#     policy Codex reads, never one without the other;
#   - every <plugin>:<skill> reference in a SKILL.md resolves to something an
#     install actually gets, so a repointed or vendored skill cannot leave a
#     dangling name behind (the class of superpowers:brainstorming, which the
#     subset entry excludes);
#   - consistency-audit ships with its inspector, the inspector carries no
#     permissionMode, and the skill names the inspector by the name a plugin
#     agent actually resolves to.
# Needs no network.
. "$(dirname "$0")/lib.sh"

subset="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
checked=0

for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
  plugin="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$skill")"
  md="$skill/SKILL.md"
  [ -f "$md" ] || fail "$plugin/skills/$name has no SKILL.md"
  checked=$((checked + 1))

  # Gates travel as a pair.
  claude_user_invocable=false
  codex_user_invocable=false
  grep -qx 'disable-model-invocation: true' "$md" && claude_user_invocable=true
  [ -f "$skill/agents/openai.yaml" ] && grep -qx '  allow_implicit_invocation: false' "$skill/agents/openai.yaml" && codex_user_invocable=true
  [ "$claude_user_invocable" = "$codex_user_invocable" ] \
    || fail "$plugin:$name is user-invocable only on one CLI (Claude $claude_user_invocable, Codex $codex_user_invocable); each such skill carries both gates"

  # Qualified references resolve.
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    p="${ref%%:*}"
    s="${ref#*:}"
    case "$p" in
      superpowers)
        printf '%s\n' "$subset" | grep -qxF -- "$s" \
          || fail "$plugin:$name names $ref, which the superpowers subset entry does not list"
        ;;
      software-dev | sensemaking)
        # A skill, or a plugin agent, which resolves by the same prefix.
        [ -f "$REPO_ROOT/plugins/$p/skills/$s/SKILL.md" ] || [ -f "$REPO_ROOT/plugins/$p/agents/$s.md" ] \
          || fail "$plugin:$name names $ref, which $p ships neither as a skill nor as an agent"
        ;;
    esac
  done < <(grep -o '\b\(superpowers\|software-dev\|sensemaking\):[a-z][a-z0-9-]*' "$md" | sort -u)
done
[ "$checked" -ge 3 ] || fail "expected at least 3 plugin skills, found $checked"

# rethink-audit: the one repointed reference.
RA="$REPO_ROOT/plugins/sensemaking/skills/rethink-audit/SKILL.md"
grep -q 'software-dev:brainstorming' "$RA" || fail "rethink-audit does not name software-dev:brainstorming"

# consistency-audit and its inspector.
CA="$REPO_ROOT/plugins/software-dev/skills/consistency-audit/SKILL.md"
AG="$REPO_ROOT/plugins/software-dev/agents/consistency-audit-inspector.md"
[ -f "$CA" ] || fail "missing $CA"
[ -f "$AG" ] || fail "missing $AG"
grep -qx 'disable-model-invocation: true' "$CA" || fail "consistency-audit must be user-invocable only on Claude Code"
[ "$(sed -n 2p "$AG")" = "name: consistency-audit-inspector" ] || fail "the inspector's name changed"
grep -qx 'tools: Read, Bash, WebFetch, WebSearch' "$AG" || fail "the inspector's tool grant changed"
if grep -q 'permissionMode' "$AG"; then fail "the inspector must not carry permissionMode (spec section 7.1)"; fi
# A plugin agent resolves as <plugin>:<agent>, measured 2026-09-06: the Agent
# tool rejects the bare name and lists caveman:cavecrew-investigator and its
# siblings. The skill must dispatch by the name that resolves.
[ "$(grep -c 'software-dev:consistency-audit-inspector' "$CA")" -ge 2 ] \
  || fail "consistency-audit must dispatch software-dev:consistency-audit-inspector, at least twice"
if grep -q '`consistency-audit-inspector`' "$CA"; then fail "consistency-audit still names the inspector bare"; fi
grep -q 'On Codex, where a plugin cannot ship a subagent' "$CA" \
  || fail "consistency-audit must state its Codex degradation in its own text (spec section 7.1)"

printf 'plugin-skills: %s skills checked; gates paired, references resolve, inspector shipped\n' "$checked"
