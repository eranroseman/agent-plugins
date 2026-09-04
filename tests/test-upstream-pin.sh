#!/usr/bin/env bash
# The curated superpowers entry must point at a real upstream sha, list exactly
# the 13 skill directories that exist there, omit brainstorming, and carry the
# version upstream declares at that sha. Needs network access.
. "$(dirname "$0")/lib.sh"

[ -f "$MARKETPLACE" ] || fail "missing $MARKETPLACE"
sha="$(upstream_sha)"
[ "${#sha}" -eq 40 ] || fail "superpowers entry has no 40-char sha (got '$sha')"

UP="$(fetch_upstream)"
[ "$(git -C "$UP" rev-parse HEAD)" = "$sha" ] || fail "checkout HEAD != pinned sha"

mapfile -t listed < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##' | sort)
[ "${#listed[@]}" -eq 13 ] || fail "expected 13 listed skills, got ${#listed[@]}"
for s in "${listed[@]}"; do
  [ "$s" != "brainstorming" ] || fail "brainstorming must not be listed"
  [ -f "$UP/skills/$s/SKILL.md" ] || fail "upstream has no skills/$s/SKILL.md at $sha"
done

# listed + brainstorming must be the whole upstream set, so a new upstream skill
# is a visible decision at the next sha bump rather than a silent omission.
diff <(printf '%s\n' "${listed[@]}" brainstorming | sort) \
     <(find "$UP/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort) \
  || fail "listed skills + brainstorming != upstream skill directories"

want_version="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
have_version="$(jq -r '.version' "$UP/.claude-plugin/plugin.json")"
[ "$want_version" = "$have_version" ] || fail "version $want_version != upstream $have_version"

[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .source.source' "$MARKETPLACE")" = "git-subdir" ] || fail "source.source must be git-subdir"
[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .source.path' "$MARKETPLACE")" = "skills" ] || fail "source.path must be skills"
[ "$(jq -r '.plugins[] | select(.name == "superpowers") | .strict' "$MARKETPLACE")" = "false" ] || fail "strict must be false"

printf 'upstream-pin: 13 listed dirs exist at %s; brainstorming excluded; version %s\n' "$sha" "$want_version"
