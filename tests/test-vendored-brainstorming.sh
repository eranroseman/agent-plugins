#!/usr/bin/env bash
# The vendored brainstorming skill must equal upstream at the pinned sha in
# every byte and file mode, except: a provenance header right after the
# frontmatter, and line 3 (the description). Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-development/skills/brainstorming"
[ -d "$V" ] || fail "missing $V"
UP="$(fetch_upstream)" || fail "could not fetch upstream at $(upstream_sha)"
U="$UP/skills/brainstorming"
sha="$(upstream_sha)"

# Same file set.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"

# Every file: identical executable bit. Every file but SKILL.md: identical bytes.
while IFS= read -r f; do
  if [ -x "$U/$f" ] && [ ! -x "$V/$f" ]; then fail "$f lost its executable bit"; fi
  if [ ! -x "$U/$f" ] && [ -x "$V/$f" ]; then fail "$f gained an executable bit"; fi
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream"
done < <(cd "$V" && find . -type f | sort)

# SKILL.md frontmatter: name untouched, line 3 is a description, narrowed text present.
[ "$(sed -n 1p "$V/SKILL.md")" = "---" ] || fail "line 1 is not a frontmatter fence"
[ "$(sed -n 2p "$V/SKILL.md")" = "name: brainstorming" ] || fail "name changed"
# Line 3: the narrowed description, verbatim.
want='description: "Design front door of the superpowers spine. Classifies a build request as spike, bounded, or architectural, then takes it from intent to an approved design, and to a written spec for architectural work, before any implementation. Use for \"let'"'"'s build, add, or change X\". Not for open-ended ideation, and not for stress-testing an existing plan."'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the narrowed description, verbatim"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"

# Lines 5-9: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/obra/superpowers at $sha" \
  "     path: skills/brainstorming/" \
  "     MIT, © 2025 Jesse Vincent. The only local change is the description in the frontmatter above." \
  "     Do not hand-edit below this line; re-vendor from upstream to update." \
  "-->")"
[ "$(sed -n 5,9p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-9 are not the provenance header"

# Body: drop line 3 and lines 5-9; rest must equal upstream minus line 3.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5,9d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header and the description"

printf 'vendored-brainstorming: matches upstream %s except header + description\n' "$sha"
