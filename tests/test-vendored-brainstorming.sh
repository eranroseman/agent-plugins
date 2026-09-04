#!/usr/bin/env bash
# The vendored brainstorming skill must equal upstream at the pinned sha in
# every byte and file mode, except: a provenance header right after the
# frontmatter, and line 3 (the description). Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-development/skills/brainstorming"
[ -d "$V" ] || fail "missing $V"
UP="$(fetch_upstream)"
U="$UP/skills/brainstorming"
sha="$(upstream_sha)"

# Same file set.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"

# Every file but SKILL.md: identical bytes and identical executable bit.
while IFS= read -r f; do
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream"
  if [ -x "$U/$f" ] && [ ! -x "$V/$f" ]; then fail "$f lost its executable bit"; fi
  if [ ! -x "$U/$f" ] && [ -x "$V/$f" ]; then fail "$f gained an executable bit"; fi
done < <(cd "$V" && find . -type f | sort)

# SKILL.md frontmatter: name untouched, line 3 is a description, narrowed text present.
[ "$(sed -n 1p "$V/SKILL.md")" = "---" ] || fail "line 1 is not a frontmatter fence"
[ "$(sed -n 2p "$V/SKILL.md")" = "name: brainstorming" ] || fail "name changed"
sed -n 3p "$V/SKILL.md" | grep -q '^description: "Design front door of the superpowers spine\.' \
  || fail "line 3 is not the narrowed description"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"

# Provenance header: immediately after the frontmatter, carries the pinned sha.
[ "$(sed -n 5p "$V/SKILL.md")" = "<!-- Vendored from https://github.com/obra/superpowers at $sha" ] \
  || fail "line 5 is not the provenance header with sha $sha"

# Body: strip the header block and line 3; the rest must equal upstream minus line 3.
diff <(sed '3d' "$U/SKILL.md") \
     <(sed -e '3d' -e '/^<!-- Vendored from https:\/\/github.com\/obra\/superpowers at /,/^-->$/d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header and the description"

printf 'vendored-brainstorming: matches upstream %s except header + description\n' "$sha"
