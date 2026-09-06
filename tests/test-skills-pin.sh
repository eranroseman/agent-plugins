#!/usr/bin/env bash
# upstream/skills.json must be well-formed, every declared ref must exist as a
# tag on its repo, and every listed skill name must resolve to exactly one
# SKILL.md at that ref, the way `skills add --skill <name>` resolves it. The
# two declared sources use different layouts -- mattpocock/skills nests a
# category level, obra/superpowers-developing-for-claude-code is flat -- so
# the search is by directory basename, not by a hardcoded path. Needs network.
. "$(dirname "$0")/lib.sh"

S="$REPO_ROOT/upstream/skills.json"
[ -f "$S" ] || fail "missing $S"
jq -e . "$S" >/dev/null 2>&1 || fail "$S is not well-formed JSON"

# The scaffolder is vendored into this plugin (spec section 8). Installing it
# through skills.sh as well would leave the unadapted copy, whose file-pick
# rule writes CLAUDE.md, one invocation away from the adapted one.
if jq -e '[.sources[].skills[]] | index("setup-matt-pocock-skills")' "$S" >/dev/null 2>&1; then
  fail "setup-matt-pocock-skills is vendored by this plugin; it must not also be declared here"
fi

total="$(jq '[.sources[].skills[]] | length' "$S")"
[ "$total" -eq 19 ] || fail "expected 19 declared skills, got $total"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

while IFS="$(printf '\t')" read -r repo ref; do
  [ -n "$repo" ] || continue
  url="https://github.com/$repo.git"
  git ls-remote --exit-code --tags "$url" "refs/tags/$ref" >/dev/null 2>&1 \
    || fail "$repo has no tag $ref"
  d="$work/$(printf '%s' "$repo" | tr / -)"
  mkdir -p "$d" || fail "could not create $d"
  git -C "$d" init -q || fail "git init failed in $d"
  git -C "$d" remote add origin "$url" || fail "git remote add failed in $d"
  git -C "$d" fetch -q --depth 1 origin "refs/tags/$ref" \
    || fail "could not fetch $repo at $ref"
  git -C "$d" checkout -q FETCH_HEAD || fail "could not check out $repo at $ref"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    matches=0
    while IFS= read -r f; do
      [ "$(basename "$(dirname "$f")")" = "$name" ] && matches=$((matches + 1))
    done < <(find "$d" -name SKILL.md -not -path '*/.git/*')
    [ "$matches" -eq 1 ] \
      || fail "$repo@$ref: '$name' resolves to $matches SKILL.md files, expected 1"
  done < <(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .skills[]' "$S")
done < <(jq -r '.sources[] | [.repo, .ref] | @tsv' "$S")

printf 'skills-pin: 19 declared skills, every ref a real tag, every name resolving once\n'
