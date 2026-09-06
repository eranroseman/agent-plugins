#!/usr/bin/env bash
# The vendored diagnosing-bugs skill must equal mattpocock/skills at the ref
# upstream/skills.json declares, in every byte and file mode, except: a
# provenance header right after the frontmatter, and line 3, the description,
# rewritten so Codex shows it whole and it shares no trigger word with
# systematic-debugging (spec section 6.1). It must not be gated, and it must
# not also be declared for skills.sh. Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-dev/skills/diagnosing-bugs"
[ -d "$V" ] || fail "missing $V"

REF="v1.2.3"
SHA="6acc160e4e0cd062dbbbd7a1b26ae92855edf07e"   # the commit v1.2.3 peels to
# One upstream state for the whole mattpocock set: the vendored copy and the
# skills.sh install must come from the same tag, or a bump moves one without
# the other.
declared="$(jq -r '.sources[] | select(.repo == "mattpocock/skills") | .ref' "$REPO_ROOT/upstream/skills.json")"
[ "$declared" = "$REF" ] \
  || fail "upstream/skills.json pins mattpocock/skills at $declared and this test at $REF; move them together"
git ls-remote --tags https://github.com/mattpocock/skills.git "refs/tags/$REF^{}" | grep -q "^$SHA" \
  || fail "tag $REF no longer peels to $SHA"

UP="$(fetch_pinned https://github.com/mattpocock/skills.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-mattpocock")"
U="$UP/skills/engineering/diagnosing-bugs"
[ -d "$U" ] || fail "upstream has no skills/engineering/diagnosing-bugs at $SHA"

# Same file set: SKILL.md, agents/openai.yaml, scripts/hitl-loop.template.sh.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"
[ "$(cd "$V" && find . -type f | wc -l)" -eq 3 ] || fail "expected 3 vendored files"

# Every file: identical executable bit. Every file but SKILL.md: identical bytes.
while IFS= read -r f; do
  if [ -x "$U/$f" ] && [ ! -x "$V/$f" ]; then fail "$f lost its executable bit"; fi
  if [ ! -x "$U/$f" ] && [ -x "$V/$f" ]; then fail "$f gained an executable bit"; fi
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream"
done < <(cd "$V" && find . -type f | sort)

# Frontmatter: name untouched, line 3 is the rewritten description, verbatim.
[ "$(sed -n 1p "$V/SKILL.md")" = "---" ] || fail "line 1 is not a frontmatter fence"
[ "$(sed -n 2p "$V/SKILL.md")" = "name: diagnosing-bugs" ] || fail "name changed"
want='description: Use when a bug resists reproduction, or for a performance regression.'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the rewritten description, verbatim"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"
desc="${want#description: }"
[ "${#desc}" -le 122 ] || fail "the description is ${#desc} characters; Codex truncates at 122"

# Lines 5-10: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/mattpocock/skills at tag $REF, commit $SHA" \
  "     path: skills/engineering/diagnosing-bugs/" \
  "     MIT, (c) 2026 Matt Pocock. The only local change is the description in the frontmatter above:" \
  "     69 characters, so Codex shows it whole, and disjoint from systematic-debugging's triggers." \
  "     Do not hand-edit below this line; re-vendor from upstream to update." \
  "-->")"
[ "$(sed -n 5,10p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-10 are not the provenance header"

# Body: drop line 3 and lines 5-10; rest must equal upstream minus line 3.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5,10d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header and the description"

# Not gated, on either harness: an agent reaches for it unprompted when a bug
# resists reproduction (spec section 6.1).
if grep -q 'disable-model-invocation' "$V/SKILL.md"; then fail "diagnosing-bugs must not be gated on Claude"; fi
if grep -q 'allow_implicit_invocation: false' "$V/agents/openai.yaml"; then fail "diagnosing-bugs must not be gated on Codex"; fi

# Vendored means not also installed bare, or the unadapted copy sits beside it.
if jq -e '[.sources[].skills[]] | index("diagnosing-bugs")' "$REPO_ROOT/upstream/skills.json" >/dev/null 2>&1; then
  fail "diagnosing-bugs is vendored here and must not also be declared in upstream/skills.json"
fi

# The LICENSE's provenance notice names the same tag and commit.
grep -q "skills/engineering/diagnosing-bugs/, at tag $REF, commit" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE carries no provenance notice for skills/diagnosing-bugs/"
grep -q "^$SHA)" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE provenance for diagnosing-bugs does not name commit $SHA"

printf 'vendored-diagnosing-bugs: matches mattpocock/skills %s except header + description (%s chars)\n' "$REF" "${#desc}"
