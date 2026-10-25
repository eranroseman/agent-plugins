#!/usr/bin/env bash
# The plugin and its entries install (spec §14). On a fresh scratch HOME the
# README's install blocks run as a user runs them, with the marketplace source
# replaced by this checkout and nothing else, and what loaded is asserted on
# both agent CLIs. Claude Code, from `claude plugin details`: each local
# plugin's skills equal its skill directories and its agents the stems under
# agents/, and each subset entry's skills equal the last segments of its list.
# Codex, from `codex debug prompt-input`: each local plugin's model-visible
# skills equal its skill directories less those whose Codex policy file sets
# allow_implicit_invocation: false, and each entry's its list less the skills
# whose policy file in the installed cache does; the cache is never the
# oracle for what loads, since both agent CLIs cache the whole path. Every
# token under an UNPINNED prefix (tests/lib.sh) in the shipped texts names a
# skill the plugin installed under that prefix lists on Claude Code and shows
# in Codex's catalogue (T47). Over the whole machine (T53): `claude plugin
# list` names exactly the marketplace's entries from eranroseman and every
# UNPINNED install id, and no skill name is listed twice in Codex's
# catalogue, bare or under any prefix.
#
#   tests/install-check.sh            install into a fresh scratch HOME, then assert
#   tests/install-check.sh --assert   assert only, over the HOME and CODEX_HOME in the environment
#
# Outside tests/run.sh's glob: it needs both agent CLIs at their newest stable
# versions, which the validate job does not install, and the runner has no
# probe for codex. The install job in .github/workflows/validate.yml runs it.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
README="$REPO_ROOT/README.md"

# The lines of the fenced block of README.md whose info string's second word
# is $1 (T13); empty when there is none.
readme_block() {
  awk -v want="$1" '
    /^```/ {
      if (inblock) { inblock = 0; name = ""; next }
      inblock = 1
      split($0, w, " ")
      name = w[2]
      next
    }
    inblock && name == want { print }
  ' "$README"
}

# Run the block $1 under bash -euo pipefail, with the marketplace source
# replaced by this checkout's path and nothing else (Q64). Every other line,
# obra's and softaworks' included, runs as written.
run_block() {
  local body
  body="$(readme_block "$1")"
  [ -n "$body" ] || fail "README.md has no fenced block marked $1"
  printf '%s\n' "$body" | sed "s|eranroseman/agent-plugins|$REPO_ROOT|g" >"$HOME/block-$1.sh"
  printf '== %s ==\n' "$1"
  cat "$HOME/block-$1.sh"
  bash -euo pipefail "$HOME/block-$1.sh"
}

# The names on the $2 line (Skills or Agents) of `claude plugin details $1`,
# one per line, sorted; nothing for `Agents (0)`. The command is captured
# first, so a failing `claude plugin details` fails rather than passing as an
# empty set; since a fail here ends only the caller's command substitution,
# every call site exits on the status, the FAIL already printed.
details_names() {
  local out
  out="$(claude plugin details "$1")" || fail "claude plugin details $1 failed"
  sed -n "s/^  $2 ([0-9]*) *//p" <<<"$out" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . | sort || true
}

# Every skill in Codex's model-visible catalogue, as the catalogue names it
# (plugin:skill for a plugin's, bare for a skill root's), one per line. The
# prompt is captured first, so a failing `codex debug prompt-input` fails here
# even when it printed a prompt; as with details_names, the call site exits on
# the status.
codex_catalogue() {
  local out
  out="$(cd "$HOME" && codex debug prompt-input)" || fail "codex debug prompt-input failed"
  jq -r '.. | objects | select(has("text")) | .text' <<<"$out" \
    | grep -oE '^- [a-z][a-z0-9-]*(:[a-z][a-z0-9-]*)?: ' | sed 's/^- //; s/: $//' | sort || true
}

# $1 a label, $2 and $3 sets, one name per line, in any order.
expect_equal() {
  diff <(printf '%s\n' "$2" | grep . | sort) <(printf '%s\n' "$3" | grep . | sort) \
    || fail "$1: the sets differ (expected above, found below)"
}

MODE="${1:-}"
case "$MODE" in
  '')
    SCRATCH="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/install-check.XXXXXX")" || fail "mktemp failed"
    export HOME="$SCRATCH/home"
    export CODEX_HOME="$HOME/.codex"
    unset CLAUDE_CONFIG_DIR
    # Codex refuses a CODEX_HOME that does not exist (measured).
    mkdir -p "$CODEX_HOME" || fail "could not create $CODEX_HOME"
    # Named so a later --assert run, or a mutation, can find this machine.
    printf 'HOME=%s\nCODEX_HOME=%s\n' "$HOME" "$CODEX_HOME"
    ;;
  --assert)
    if [ -z "${HOME:-}" ] || [ -z "${CODEX_HOME:-}" ]; then fail "--assert needs HOME and CODEX_HOME in the environment"; fi
    ;;
  *)
    printf 'usage: tests/install-check.sh [--assert]\n' >&2
    exit 2
    ;;
esac
command -v claude >/dev/null 2>&1 || fail "claude is not on PATH"
command -v codex >/dev/null 2>&1 || fail "codex is not on PATH"
# A log line, not an assertion: a red run says which release broke it.
printf 'claude: %s\ncodex: %s\n' "$(claude --version)" "$(codex --version)"

if [ -z "$MODE" ]; then
  run_block install-claude
  run_block install-codex
fi

local_rows="$(jq -r '.plugins[] | select(.source | type == "string") | [.name, .source] | @tsv' "$MARKETPLACE")"
[ -n "$local_rows" ] || fail "no local plugin in $MARKETPLACE"

# ---- Claude Code -------------------------------------------------------------
while IFS=$'\t' read -r name src; do
  [ -n "$name" ] || continue
  dir="$REPO_ROOT/${src#./}"
  want_skills="$(for d in "$dir"/skills/*/; do basename "$d"; done)"
  want_agents="$(for a in "$dir"/agents/*.md; do if [ -f "$a" ]; then basename "$a" .md; fi; done)"
  got="$(details_names "$name@eranroseman" Skills)" || exit 1
  expect_equal "claude: $name's skills" "$want_skills" "$got"
  got="$(details_names "$name@eranroseman" Agents)" || exit 1
  expect_equal "claude: $name's agents" "$want_agents" "$got"
done <<<"$local_rows"
while IFS=$'\t' read -r name _; do
  [ -n "$name" ] || continue
  got="$(details_names "$name@eranroseman" Skills)" || exit 1
  expect_equal "claude: the entry $name's skills" "$(entry_skills "$name")" "$got"
done < <(entry_rows)

# ---- Codex -------------------------------------------------------------------
catalogue="$(codex_catalogue)" || exit 1
[ -n "$catalogue" ] || fail "codex debug prompt-input listed no skill"
visible_of() { grep "^$1:" <<<"$catalogue" | sed "s/^$1://" || true; }
while IFS=$'\t' read -r name src; do
  [ -n "$name" ] || continue
  dir="$REPO_ROOT/${src#./}"
  want="$(for d in "$dir"/skills/*/; do user_invocable_only "$d/agents/openai.yaml" || basename "$d"; done)"
  expect_equal "codex: $name's model-visible skills" "$want" "$(visible_of "$name")"
done <<<"$local_rows"
while IFS=$'\t' read -r name _; do
  [ -n "$name" ] || continue
  cache="$(find "$CODEX_HOME/plugins/cache/eranroseman/$name" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)"
  [ "$(printf '%s\n' "$cache" | grep -c .)" -eq 1 ] || fail "codex: expected one installed cache for $name, found:"$'\n'"$cache"
  want="$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .skills[] | sub("^\\./"; "")' "$MARKETPLACE" \
    | while IFS= read -r lp; do user_invocable_only "${cache%/}/$lp/agents/openai.yaml" || basename "$lp"; done)"
  expect_equal "codex: the entry $name's model-visible skills" "$want" "$(visible_of "$name")"
done < <(entry_rows)

# ---- Unpinned references (Q87, Q88, T47) -------------------------------------
# For each UNPINNED plugin, each <prefix>:<name> token in the shipped texts
# names a skill the installed plugin lists on Claude Code and shows in Codex's
# catalogue. No fixed set is asserted: every UNPINNED install is unpinned.
unpinned_references() {
  local u prefix id tokens installed t s n=0
  for u in "${UNPINNED[@]}"; do
    prefix="${u%%$'\t'*}"
    id="${u#*$'\t'}"
    tokens="$(while IFS= read -r f; do
      [ -f "$REPO_ROOT/$f" ] || fail "$f is tracked but absent from the working tree"
      grep -ohE "(^|[^A-Za-z0-9_/-])$prefix:[a-z][a-z0-9-]*" "$REPO_ROOT/$f" | sed -E "s/^.*$prefix:/$prefix:/" || true
    done < <(shipped_texts) | sort -u)"
    [ -n "$tokens" ] || fail "no $prefix: token in the shipped texts; the check went vacuous"
    installed="$(details_names "$id" Skills)" || exit 1
    [ -n "$installed" ] || fail "claude plugin details $id lists no skill"
    while IFS= read -r t; do
      s="${t#"$prefix":}"
      grep -qxF -- "$s" <<<"$installed" || fail "claude: $t names a skill the installed $id does not list"
      grep -qxF -- "$t" <<<"$catalogue" || fail "codex: $t is not in Codex's model-visible catalogue under $prefix:"
      n=$((n + 1))
    done <<<"$tokens"
  done
  printf 'unpinned: %s reference(s) resolve on both agent CLIs\n' "$n"
}
unpinned_references

# ---- The whole machine (T53) -------------------------------------------------
# Exactly the marketplace's entries from eranroseman and the UNPINNED plugins
# from their own marketplaces are installed on Claude Code, and no skill name
# is listed twice in Codex's catalogue, bare or under any prefix. A fresh
# install meets both; they are here for the gate's run over a machine the old
# script converged.
whole_machine() {
  local want list installed dup
  want="$({
    jq -r '.plugins[].name' "$MARKETPLACE" | sed 's/$/@eranroseman/'
    printf '%s\n' "${UNPINNED[@]#*$'\t'}"
  } | sort)"
  list="$(claude plugin list)" || fail "claude plugin list failed"
  installed="$(sed -n 's/^  ❯ //p' <<<"$list" | sort)"
  expect_equal "claude: the installed plugins" "$want" "$installed"
  dup="$(printf '%s\n' "$catalogue" | sed 's/^[^:]*://' | sort | uniq -d)"
  [ -z "$dup" ] || fail "codex: a skill name is listed twice in the catalogue; the cleanup block removes the old installs:"$'\n'"$(while IFS= read -r n; do grep -E "^([^:]*:)?$n\$" <<<"$catalogue"; done <<<"$dup")"
}
whole_machine

printf 'install-check: every local plugin and subset entry loads the skills it declares on Claude Code and Codex\n'
