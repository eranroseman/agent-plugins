#!/usr/bin/env bash
# The curated writing-clearly-and-concisely entry points at a real
# softaworks/agent-toolkit sha, uses upstream's own published plugin shape
# under dist/ rather than the whole skills/ tree, lists exactly its one skill,
# and carries a version this repository authors, since upstream ships none.
# The dist copy must equal the source tree at the pin, or the entry serves
# something other than what the source repository shows. Needs network.
. "$(dirname "$0")/lib.sh"

NAME="writing-clearly-and-concisely"
entry() { jq -r --arg n "$NAME" ".plugins[] | select(.name == \$n) | $1" "$MARKETPLACE"; }

[ "$(entry '.source.source')" = "git-subdir" ] || fail "source.source must be git-subdir"
[ "$(entry '.source.url')" = "https://github.com/softaworks/agent-toolkit.git" ] || fail "source.url"
[ "$(entry '.source.path')" = "dist/plugins/$NAME" ] \
  || fail "source.path must be upstream's published plugin directory, not the whole skills tree"
[ "$(entry '.strict')" = "false" ] || fail "strict must be false"
[ "$(entry '.skills | length')" -eq 1 ] || fail "the entry must list exactly one skill"
[ "$(entry '.skills[0]')" = "./skills/$NAME" ] || fail "the listed skill must be ./skills/$NAME"

# The sha and the version move together (spec section 6.4): upstream has no
# version to mirror, so the pair is pinned here, and a bump edits both this
# test and the manifest in one change.
SHA="3027f20f3181758385a1bb8c022d4041dfb4de84"
VERSION="0.1.0"
[ "$(entry '.source.sha')" = "$SHA" ] \
  || fail "the entry's sha moved without this test: bump sha and version together, then update SHA and VERSION here"
[ "$(entry '.version')" = "$VERSION" ] \
  || fail "the entry's version is not $VERSION; a sha bump must move the version with it"

# software-dev pulls it in as a dependency, the way it pulls superpowers.
jq -e '.dependencies | index("writing-clearly-and-concisely")' \
  "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json" >/dev/null \
  || fail "software-dev must declare $NAME as a dependency"

UP="$(fetch_pinned https://github.com/softaworks/agent-toolkit.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-agent-toolkit")"
[ -f "$UP/dist/plugins/$NAME/skills/$NAME/SKILL.md" ] || fail "no dist plugin at $SHA"
[ -f "$UP/skills/$NAME/SKILL.md" ] || fail "no source skill at $SHA"
diff -r "$UP/dist/plugins/$NAME/skills/$NAME" "$UP/skills/$NAME" \
  || fail "dist and source trees differ at $SHA; the entry would serve something the source does not show"
[ "$(sed -n 2p "$UP/skills/$NAME/SKILL.md")" = "name: $NAME" ] || fail "upstream skill name changed"
grep -q 'Copyright (c) 2026 Leonardo Flores' "$UP/LICENSE" || fail "upstream LICENSE holder changed; re-check the marketplace description"

printf 'curated-writing: dist == source at %s, version %s, one skill, a software-dev dependency\n' "$SHA" "$VERSION"
