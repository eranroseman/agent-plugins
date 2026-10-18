#!/usr/bin/env bash
# The watch, run whole and offline (spec §12.4). A PATH stub stands in for the
# network: a `git` whose `ls-remote` answers come from a table in this test,
# so the cases exercise the call sites the scheduled run uses, not a mode.
# The watch is copied into a scratch root beside a fixture marketplace with
# two git-subdir entries, one on a tag and one on a branch, a fixture
# vendored.json and a fixture skills.json. The cases:
#   1. the stable-tag filter: a tag entry pinned at the newest stable tag is
#      current, and prereleases, -dev builds and a parallel tag series never
#      count (Q66);
#   2. tag and branch pins (Q29, T1, T39): a tag entry behind its newest
#      stable tag, a branch entry behind its tip, and a branch tree behind its
#      tip each exit 1 and are named; all current exit 0.
# Needs no network.
. "$(dirname "$0")/lib.sh"

W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/scripts" "$W/.claude-plugin" "$W/bin" || fail "could not seed $W"
cp "$REPO_ROOT/scripts/upstream-watch" "$W/scripts/" || fail "could not copy the watch"

TAG_URL="https://example.invalid/tag-upstream.git"
BRANCH_URL="https://example.invalid/branch-upstream.git"
TREE_URL="https://github.com/example/tree-upstream.git"
SKILLS_URL="https://github.com/example/skills-upstream.git"
TAG_SHA="1111111111111111111111111111111111111111"
BRANCH_SHA="2222222222222222222222222222222222222222"
TREE_SHA="3333333333333333333333333333333333333333"
NEWER="4444444444444444444444444444444444444444"

# The fixture desired state. The tag entry's version is upstream's, the
# branch entry's is this repository's; neither matters to the watch.
write_marketplace() { # $1 the tag entry's ref, $2 its sha, $3 the branch entry's sha
  cat >"$W/.claude-plugin/marketplace.json" <<JSON
{
  "name": "fixture",
  "plugins": [
    {
      "name": "tagged",
      "source": { "source": "git-subdir", "url": "$TAG_URL", "path": "skills", "ref": "$1", "sha": "$2" },
      "version": "2.16.0",
      "strict": false,
      "skills": ["./one"]
    },
    {
      "name": "branched",
      "source": { "source": "git-subdir", "url": "$BRANCH_URL", "path": "dist", "ref": "main", "sha": "$3" },
      "version": "0.1.0",
      "strict": false,
      "skills": ["./skills/two"]
    }
  ]
}
JSON
}
write_vendored() { # $1 the tree's sha
  cat >"$W/vendored.json" <<JSON
{
  "\$comment": "fixture",
  "plugins/p/skills/three": {
    "repo": "example/tree-upstream",
    "branch": "main",
    "sha": "$1",
    "upstream_path": "skills/three",
    "kind": "vendored"
  }
}
JSON
}
printf '{"sources":[{"repo":"example/skills-upstream","ref":"v1.0.0","skills":["four"],"not_adopted":[],"via_subset_entry":[]}]}\n' >"$W/skills.json" \
  || fail "could not write the fixture skills.json"

# The git stub: `ls-remote` answered from answers.tsv (url, refname, sha);
# with no refspec it lists the tags of the url, as `--tags --refs` does. Any
# other verb is exit 99, so the watch cannot reach a real remote from here.
cat >"$W/bin/git" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = ls-remote ] || exit 99
shift
while [ "$#" -gt 0 ]; do
  case "$1" in --*) shift ;; *) break ;; esac
done
url="$1"
shift
if [ "$#" -eq 0 ]; then
  awk -F'\t' -v u="$url" '$1 == u && $2 ~ /^refs\/tags\// && $2 !~ /\^\{\}$/ { print $3 "\t" $2 }' "$ANSWERS"
else
  for spec in "$@"; do
    awk -F'\t' -v u="$url" -v s="$spec" '$1 == u && $2 == s { print $3 "\t" $2 }' "$ANSWERS"
  done
fi
STUB
chmod +x "$W/bin/git" || fail "could not make the git stub executable"
export ANSWERS="$W/answers.tsv"

# $1 the tag entry's newest tag set, one sha for every tag listed; $2 the
# branch tip; $3 the tree tip. The tag entry's tags: a stable release, a
# newer stable release, prereleases, a -dev build and a parallel series.
write_answers() { # $1 newest stable tag name, $2 its sha, $3 branch tip, $4 tree tip
  {
    for t in archify-dsh-v0.1.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 v2.16.0 "$1"; do
      printf '%s\trefs/tags/%s\t%s\n' "$TAG_URL" "$t" "$TAG_SHA"
    done
    printf '%s\trefs/tags/%s\t%s\n' "$TAG_URL" "$1" "$2"
    printf '%s\trefs/tags/v2.16.0\t%s\n' "$TAG_URL" "$TAG_SHA"
    printf '%s\trefs/heads/main\t%s\n' "$BRANCH_URL" "$3"
    printf '%s\trefs/heads/main\t%s\n' "$TREE_URL" "$4"
    printf '%s\trefs/tags/v1.0.0\t%s\n' "$SKILLS_URL" "$TREE_SHA"
  } | sort -u >"$ANSWERS"
}

run_watch() { # prints the report; status in $status
  status=0
  out="$(cd "$W" && PATH="$W/bin:$PATH" bash scripts/upstream-watch 2>&1)" || status=$?
}

# 1. The stable-tag filter. Everything current: the tag entry at v2.16.0,
# which is the newest stable tag; exit 0 and the entry's current line.
write_marketplace v2.16.0 "$TAG_SHA" "$BRANCH_SHA"
write_vendored "$TREE_SHA"
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 0 ] || fail "with every pin current the watch exited $status, not 0:"$'\n'"$out"
grep -qF -- '`v2.16.0`' <<<"$out" || fail "the current tag entry's line does not name its tag:"$'\n'"$out"
grep -qF 'Everything matches' <<<"$out" || fail "a clean run must say so:"$'\n'"$out"
# Pinned one stable release back: exit 1, and the line names v2.16.0, never a
# prerelease or the parallel series.
write_marketplace v2.15.0 "$TAG_SHA" "$BRANCH_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a tag entry behind the newest stable tag must exit 1, got $status:"$'\n'"$out"
grep -qF -- 'the newest stable tag is `v2.16.0`' <<<"$out" || fail "the drifted tag entry does not name v2.16.0:"$'\n'"$out"
grep -qE 'v2\.17\.0-dev|v2\.16\.1-rc|v2\.16\.0-beta|archify-dsh' <<<"$out" \
  && fail "a prerelease or a parallel tag series was reported as the newest stable tag:"$'\n'"$out"

# 2. Tag and branch pins. A newer stable tag appears: the tag entry drifts.
write_marketplace v2.16.0 "$TAG_SHA" "$BRANCH_SHA"
write_answers v2.17.0 "$NEWER" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a tag entry behind a new stable tag must exit 1, got $status:"$'\n'"$out"
grep -qF -- 'the newest stable tag is `v2.17.0`' <<<"$out" || fail "the new tag was not named:"$'\n'"$out"
grep -qF 'tagged' <<<"$out" || fail "the drifted entry was not named:"$'\n'"$out"
# The branch entry behind its tip.
write_answers v2.16.0 "$TAG_SHA" "$NEWER" "$TREE_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a branch entry behind its tip must exit 1, got $status:"$'\n'"$out"
grep -qF -- "main is \`$NEWER\`" <<<"$out" || fail "the branch entry's drift does not name the tip:"$'\n'"$out"
grep -qF 'branched' <<<"$out" || fail "the drifted branch entry was not named:"$'\n'"$out"
# The tree behind its tip.
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$NEWER"
run_watch
[ "$status" -eq 1 ] || fail "a tree behind its tip must exit 1, got $status:"$'\n'"$out"
grep -qF 'plugins/p/skills/three' <<<"$out" || fail "the drifted tree was not named:"$'\n'"$out"
# All current again: exit 0.
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 0 ] || fail "with every pin current again the watch exited $status:"$'\n'"$out"

# A ref that is both a branch and a tag is the watch's own failure, exit 2.
printf '%s\trefs/heads/v2.16.0\t%s\n' "$TAG_URL" "$NEWER" >>"$ANSWERS"
run_watch
[ "$status" -eq 2 ] || fail "a ref that is both a branch and a tag must exit 2, got $status:"$'\n'"$out"
grep -qF 'both a branch and a tag' <<<"$out" || fail "the double ref was not named:"$'\n'"$out"

printf 'upstream-watch: offline, the stable-tag filter holds and tag, branch and tree pins each report drift and clean\n'
