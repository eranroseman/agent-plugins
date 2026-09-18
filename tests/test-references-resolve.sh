#!/usr/bin/env bash
# The marketplace listing promises directories that exist and dependency
# names that resolve to real plugins. Nothing else checks either claim
# statically; an install would be the first thing to notice a stale path or
# a renamed dependency.
. "$(dirname "$0")/lib.sh"

# Check A: every Claude marketplace entry with a plain-string source names a
# real plugin.json whose own name agrees with the marketplace entry's name.
found=0
while IFS= read -r entry; do
  name="$(jq -r '.name' <<<"$entry")"
  src="$(jq -r '.source' <<<"$entry" | sed 's#^\./##')"
  manifest="$REPO_ROOT/$src/.claude-plugin/plugin.json"
  [ -f "$manifest" ] || fail "$name: $src has no .claude-plugin/plugin.json"
  [ "$(jq -r '.name' "$manifest")" = "$name" ] || fail "$name: manifest name differs"
  found=$((found + 1))
done < <(jq -c '.plugins[] | select(.source | type == "string")' "$MARKETPLACE")

[ "$found" -gt 0 ] || fail "no string-source marketplace entries found"

# Check B: every plugin's declared dependency names a real marketplace plugin.
# The dependencies key is optional; a manifest without it is not a failure.
names="$(jq -r '.plugins[].name' "$MARKETPLACE")"
depcount=0
for pf in "$REPO_ROOT"/plugins/*/.claude-plugin/plugin.json; do
  pname="$(jq -r '.name' "$pf")"
  while IFS= read -r dep; do
    depcount=$((depcount + 1))
    grep -qxF "$dep" <<<"$names" || fail "$pname: dependency '$dep' is not a marketplace plugin"
  done < <(jq -r '.dependencies[]?' "$pf")
done

[ "$depcount" -gt 0 ] || fail "no dependencies found"

# Check C: the two manifests of each plugin agree on every field they share
# (#1). Compared as one projected object under jq -S, so a drifted key shows
# itself in the diff. description is excluded on purpose: software-dev's two
# differ by design ("and its inspector" on the Claude side, where the
# subagent ships) and tests/test-hook.sh guards that direction. The Codex
# manifest's skills pointer must resolve to a directory.
pairs=0
proj='{name, version, author, homepage, repository, license, keywords}'
for p in "$REPO_ROOT"/plugins/*/; do
  name="$(basename "$p")"
  cm="$p/.claude-plugin/plugin.json"
  xm="$p/.codex-plugin/plugin.json"
  [ -f "$cm" ] || fail "$name has no .claude-plugin/plugin.json"
  [ -f "$xm" ] || fail "$name has no .codex-plugin/plugin.json"
  diff <(jq -S "$proj" "$cm") <(jq -S "$proj" "$xm") \
    || fail "$name: the Claude and Codex manifests disagree on a shared field (the diff above)"
  skills="$(jq -r '.skills // empty' "$xm")"
  [ -n "$skills" ] || fail "$name: the Codex manifest declares no skills pointer"
  [ -d "$p/$skills" ] || fail "$name: the Codex manifest's skills pointer '$skills' is not a directory under $p"
  pairs=$((pairs + 1))
done
[ "$pairs" -gt 0 ] || fail "no plugin directories under plugins/"

printf 'references-resolve: %s string-source path(s) resolve, %s dependency name(s) resolve, %s manifest pair(s) agree\n' "$found" "$depcount" "$pairs"
