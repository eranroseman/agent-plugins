#!/usr/bin/env bash
# Invariants over every skill the two plugins ship, plus the shape of the
# authored assets that have no upstream to drift from. Each is a mechanism
# for a rule that would otherwise live in prose:
#   - a gated skill carries both gates, the field Claude reads and the yaml
#     policy Codex reads, never one without the other;
#   - every <plugin>:<skill> reference in a SKILL.md resolves to something an
#     install actually gets, so a repointed or vendored skill cannot leave a
#     dangling name behind (the class of superpowers:brainstorming, which the
#     curated entry excludes);
#   - the rethink stub exists in neither plugin.
# Needs no network.
. "$(dirname "$0")/lib.sh"

curated="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
checked=0

for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
  plugin="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$skill")"
  md="$skill/SKILL.md"
  [ -f "$md" ] || fail "$plugin/skills/$name has no SKILL.md"
  checked=$((checked + 1))

  # Gates travel as a pair.
  claude_gated=false; codex_gated=false
  grep -qx 'disable-model-invocation: true' "$md" && claude_gated=true
  [ -f "$skill/agents/openai.yaml" ] && grep -qx '  allow_implicit_invocation: false' "$skill/agents/openai.yaml" && codex_gated=true
  [ "$claude_gated" = "$codex_gated" ] \
    || fail "$plugin:$name is gated on one harness only (Claude $claude_gated, Codex $codex_gated); each gated skill carries both"

  # Qualified references resolve.
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    p="${ref%%:*}"; s="${ref#*:}"
    case "$p" in
      superpowers)
        printf '%s\n' "$curated" | grep -qxF -- "$s" \
          || fail "$plugin:$name names $ref, which the curated superpowers entry does not list" ;;
      software-dev|sensemaking)
        # A skill, or a plugin agent, which resolves by the same prefix.
        [ -f "$REPO_ROOT/plugins/$p/skills/$s/SKILL.md" ] || [ -f "$REPO_ROOT/plugins/$p/agents/$s.md" ] \
          || fail "$plugin:$name names $ref, which $p ships neither as a skill nor as an agent" ;;
    esac
  done < <(grep -o '\b\(superpowers\|software-dev\|sensemaking\):[a-z][a-z0-9-]*' "$md" | sort -u)
done
[ "$checked" -ge 3 ] || fail "expected at least 3 plugin skills, found $checked"

[ ! -e "$REPO_ROOT/plugins/sensemaking/skills/rethink" ] || fail "the rethink stub must not ship in sensemaking"
[ ! -e "$REPO_ROOT/plugins/software-dev/skills/rethink" ] || fail "the rethink stub must not ship in software-dev"

# rethink-audit: the one repointed reference.
RA="$REPO_ROOT/plugins/sensemaking/skills/rethink-audit/SKILL.md"
grep -q 'software-dev:brainstorming' "$RA" || fail "rethink-audit does not name software-dev:brainstorming"

printf 'plugin-skills: %s skills checked; gates paired, references resolve, rethink absent\n' "$checked"
