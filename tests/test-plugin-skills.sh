#!/usr/bin/env bash
# What the marketplace delivers, held statically (spec §10.2, §15.3):
#   - every qualified reference <p>:<s> in a shipped text resolves to a skill
#     or agent a marketplace entry delivers: the local plugin's skills/<s> or
#     agents/<s>.md, or a subset entry's listed skill; any other prefix fails.
#     A token after / is the tail of the house owner/repo:path form and one
#     after // a URL authority; both are skipped by shape. superpowers: tokens
#     are carved out: no entry here lists obra's skills, and
#     tests/install-check.sh asserts each against the superpowers the README's
#     blocks install (Q87, T47). The idioms left are in EXCEPTIONS below, one
#     comment each; an exception whose prefix is a marketplace entry fails, so
#     a dead reference with a known prefix can never be exempted, and one that
#     matches no token fails, so the list cannot rot;
#   - a permanent negative fixture: the same scan over a scratch copy carrying
#     nosuch:thing and software-dev:no-such-skill fails on both, by file, line
#     and token;
#   - every local skill's frontmatter name equals its directory, and every
#     local agent's its file stem;
#   - no skill name appears twice across the local plugins' skill directories
#     and the entries' listed skills: a bare call on Claude Code reaches one
#     skill only while its name is unique;
#   - every scripts/<file> a SKILL.md names ships under that skill;
#   - a user-invocable-only skill carries both gates, Claude's frontmatter
#     field and Codex's policy file, never one without the other;
#   - no shipped text names a local agent bare in backticks: the Agent tool
#     accepts only <plugin>:<name> (measured 2026-09-06).
# Needs no network.
. "$(dirname "$0")/lib.sh"

EXCEPTIONS=(
  'file:line'     # a report card's location field, in consistency-audit and finding-duplicate-functions
  'bug:triage'    # the scaffolder's example of a tracker's own label name
  'wayfinder:map' # the wayfinder label in the scaffolder's tracker templates
)

local_plugins="$(jq -r '.plugins[] | select(.source | type == "string") | .name' "$MARKETPLACE")"
[ -n "$local_plugins" ] || fail "no local plugin in $MARKETPLACE"
entries="$(entry_rows | cut -f1)"

# True when a marketplace entry delivers $2 under the prefix $1.
delivers() {
  local p="$1" s="$2"
  if grep -qxF -- "$p" <<<"$local_plugins"; then
    [ -f "$REPO_ROOT/plugins/$p/skills/$s/SKILL.md" ] || [ -f "$REPO_ROOT/plugins/$p/agents/$s.md" ]
  elif grep -qxF -- "$p" <<<"$entries"; then
    entry_skills "$p" | grep -qxF -- "$s"
  else
    return 1
  fi
}

# The scan over the shipped texts under the root $1. Sets SCANNED, RESOLVED,
# SKIPPED (superpowers: tokens), EXCEPTED, USED (the exceptions matched) and
# FAILURES, one line each.
scan() {
  local root="$1" f n raw tok p s
  SCANNED=0 RESOLVED=0 SKIPPED=0 EXCEPTED=0 USED="" FAILURES=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$root/$f" ] || fail "$f is tracked but absent under $root"
    SCANNED=$((SCANNED + 1))
    while IFS=: read -r n raw; do
      [ -n "$raw" ] || continue
      tok="$(sed -E 's#^[^a-z/]+##' <<<"$raw")"
      case "$tok" in /*) continue ;; esac # owner/repo:path or a URL authority
      p="${tok%%:*}"
      s="${tok#*:}"
      if [ "$p" = superpowers ]; then
        SKIPPED=$((SKIPPED + 1)) # held by tests/install-check.sh (T47)
        continue
      fi
      if printf '%s\n' "${EXCEPTIONS[@]}" | grep -qxF -- "$tok"; then
        EXCEPTED=$((EXCEPTED + 1))
        USED="$USED $tok"
        continue
      fi
      if delivers "$p" "$s"; then
        RESOLVED=$((RESOLVED + 1))
      else
        FAILURES="$FAILURES"$'\n'"$f:$n: $tok names nothing a marketplace entry delivers"
      fi
    done < <(grep -noE '(^|[^A-Za-z0-9_-])/{0,2}[a-z][a-z0-9-]*:[a-z][a-z0-9-]*' "$root/$f" || true)
  done < <(shipped_texts)
}

# The exceptions' own shape: no marketplace prefix.
for e in "${EXCEPTIONS[@]}"; do
  p="${e%%:*}"
  if grep -qxF -- "$p" <<<"$local_plugins" || grep -qxF -- "$p" <<<"$entries"; then
    fail "the exception $e carries a marketplace entry's prefix; a dead reference cannot be exempted"
  fi
done

scan "$REPO_ROOT"
[ -z "$FAILURES" ] || fail "these references resolve to nothing an install delivers:$FAILURES"
for e in "${EXCEPTIONS[@]}"; do
  case " $USED " in *" $e "*) ;; *) fail "the exception $e matches no token; drop it" ;; esac
done
scanned="$SCANNED" resolved="$RESOLVED" skipped="$SKIPPED" excepted="$EXCEPTED"

# The permanent negative fixture: a scratch copy of the shipped texts, two
# dead references injected, both caught by file, line and token.
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT
while IFS= read -r f; do
  if ! { mkdir -p "$T/$(dirname "$f")" && cp "$REPO_ROOT/$f" "$T/$f"; }; then
    fail "could not copy $f into the fixture"
  fi
done < <(shipped_texts)
first="$(shipped_texts | grep '/SKILL.md$' | head -n 1)"
printf '\nSee nosuch:thing and software-dev:no-such-skill.\n' >>"$T/$first" || fail "could not inject the dead references"
line="$(awk 'END { print NR }' "$T/$first")"
scan "$T"
grep -qF -- "$first:$line: nosuch:thing names nothing" <<<"$FAILURES" \
  || fail "the scan did not fail on nosuch:thing by file, line and token:"$'\n'"$FAILURES"
grep -qF -- "$first:$line: software-dev:no-such-skill names nothing" <<<"$FAILURES" \
  || fail "the scan did not fail on software-dev:no-such-skill by file, line and token:"$'\n'"$FAILURES"

# Names: each local skill's frontmatter name is its directory, each agent's
# its stem; no skill name twice across the plugins and the entries.
names=""
checked=0
for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
  skill="${skill%/}"
  plugin="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$skill")"
  skill_name_matches "$skill" "$plugin:$name"
  names="$names"$'\n'"$name"
  checked=$((checked + 1))
  # Gates travel as a pair.
  claude_gate=false
  codex_gate=false
  grep -qx 'disable-model-invocation: true' "$skill/SKILL.md" && claude_gate=true
  [ -f "$skill/agents/openai.yaml" ] && grep -qx '  allow_implicit_invocation: false' "$skill/agents/openai.yaml" && codex_gate=true
  [ "$claude_gate" = "$codex_gate" ] \
    || fail "$plugin:$name is user-invocable only on one agent CLI (Claude $claude_gate, Codex $codex_gate); each such skill carries both gates"
  # Every scripts/<file> the SKILL.md names ships under the skill.
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    tok="${tok%.}"
    [ -e "$skill/$tok" ] || fail "$plugin:$name names $tok, which the skill does not ship"
  done < <(grep -oE 'scripts/[A-Za-z0-9_.-]+' "$skill/SKILL.md" | sort -u)
done
[ "$checked" -ge 1 ] || fail "no local skill under plugins/*/skills"
agents=""
for ag in "$REPO_ROOT"/plugins/*/agents/*.md; do
  [ -f "$ag" ] || continue
  stem="$(basename "$ag" .md)"
  [ "$(sed -n 2p "$ag")" = "name: $stem" ] || fail "$ag: line 2 is not 'name: $stem'"
  agents="$agents"$'\n'"$stem"
done
while IFS= read -r e; do
  [ -n "$e" ] || continue
  names="$names"$'\n'"$(entry_skills "$e")"
done <<<"$entries"
dup="$(printf '%s\n' "$names" | grep . | sort | uniq -d)"
[ -z "$dup" ] || fail "a skill name is delivered twice, by a local plugin or a subset entry; a bare call on Claude Code needs it unique: $dup"

# A bare agent name in a shipped text.
while IFS= read -r stem; do
  [ -n "$stem" ] || continue
  bare="$(shipped_texts | while IFS= read -r f; do grep -nF -- "\`$stem\`" "$REPO_ROOT/$f" | sed "s#^#$f:#"; done || true)"
  [ -z "$bare" ] || fail "a shipped text names the agent $stem bare; the Agent tool accepts only <plugin>:$stem:"$'\n'"$bare"
done <<<"$agents"

printf 'plugin-skills: %s file(s) scanned, %s reference(s) resolve, %s superpowers: token(s) left to the install job, %s exception(s) used; %s skill(s) named, with paired gates and shipped scripts\n' \
  "$scanned" "$resolved" "$skipped" "$excepted" "$checked"
