#!/usr/bin/env bash
# skills.json must be well-formed, every declared ref must exist as a
# tag on its repo, and every listed skill name must resolve to exactly one
# SKILL.md at that ref, the way `skills add --skill <name>` resolves it. The
# three declared sources use different layouts -- mattpocock/skills nests a
# category level, obra/superpowers-developing-for-claude-code and tt-a1i/archify
# are flat -- so the search is by directory basename, not by a hardcoded path.
# Needs network.
. "$(dirname "$0")/lib.sh"

S="$REPO_ROOT/skills.json"
[ -f "$S" ] || fail "missing $S"
jq -e . "$S" >/dev/null 2>&1 || fail "$S is not well-formed JSON"

# The three buckets per source are disjoint, and each not_adopted entry
# carries a reason: the collision policy lives in skills.json, and a name
# in two buckets is two policies (#53).
while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  # A source missing either bucket array would make the two checks below
  # iterate null and die unnamed under set -e; name the source first.
  natype="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | (.not_adopted | type)' "$S")"
  [ "$natype" = "array" ] || fail "$repo: skills.json carries no not_adopted array"
  vatype="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | (.via_subset_entry | type)' "$S")"
  [ "$vatype" = "array" ] || fail "$repo: skills.json carries no via_subset_entry array"
  dup="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r)
    | [.skills[], (.not_adopted[].name), .via_subset_entry[]] | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$S")"
  [ -z "$dup" ] || fail "$repo: a name sits in two buckets: $dup"
  bare="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .not_adopted[] | select((.reason // "") == "") | .name' "$S")"
  [ -z "$bare" ] || fail "$repo: a not_adopted entry carries no reason: $bare"
done < <(jq -r '.sources[].repo' "$S")

total="$(jq '[.sources[].skills[]] | length' "$S")"
[ "$total" -eq 19 ] || fail "expected 19 declared skills, got $total"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

per_source=""
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
  # The complement: the basename of each SKILL.md directory upstream ships
  # at the ref, the repository root excluded, a duplicate basename itself a
  # failure, equal the union of the three buckets, so a new upstream skill
  # is a visible decision at the next ref bump rather than a silent omission.
  upstream="$(find "$d" -name SKILL.md -not -path '*/.git/*' | while IFS= read -r f; do
    dir="${f%/SKILL.md}"
    [ "$dir" != "$d" ] || continue
    printf '%s\n' "${dir##*/}"
  done | sort)"
  dupbase="$(printf '%s\n' "$upstream" | uniq -d)"
  [ -z "$dupbase" ] || fail "$repo@$ref: a basename resolves to more than one SKILL.md: $dupbase"$'\n'"$(find "$d" -name SKILL.md -not -path '*/.git/*' | grep -F "/$dupbase/")"
  declared_set="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | [.skills[], (.not_adopted[].name), .via_subset_entry[]] | .[]' "$S" | sort)"
  only_up="$(comm -23 <(printf '%s\n' "$upstream") <(printf '%s\n' "$declared_set"))"
  only_here="$(comm -13 <(printf '%s\n' "$upstream") <(printf '%s\n' "$declared_set"))"
  # shellcheck disable=SC2086  # word-splitting the names onto one line is the point
  [ -z "$only_up" ] || fail "$repo@$ref ships skills no bucket names; declare or record each: $(printf '%s ' $only_up)"
  # shellcheck disable=SC2086  # word-splitting the names onto one line is the point
  [ -z "$only_here" ] || fail "$repo@$ref does not ship these names a bucket carries: $(printf '%s ' $only_here)"
  n_decl="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .skills | length' "$S")"
  n_not="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .not_adopted | length' "$S")"
  n_via="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .via_subset_entry | length' "$S")"
  per_source="$per_source $repo: $n_decl declared, $n_not not adopted, $n_via via a subset entry, of $(printf '%s\n' "$upstream" | grep -c .);"
done < <(jq -r '.sources[] | [.repo, .ref] | @tsv' "$S")

printf 'skills-pin: %s declared skills, every ref a real tag, every name resolving once;%s\n' "$total" "$per_source"
