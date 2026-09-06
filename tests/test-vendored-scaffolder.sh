#!/usr/bin/env bash
# The vendored scaffolder must equal mattpocock/skills at the ref this
# repository declares, except for a provenance header and two regions of
# SKILL.md: the file-pick rule and the Agent skills block. The six non-SKILL.md
# files must be byte-identical, which is what keeps a re-vendor cheap.
# Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-development/skills/setup-matt-pocock-skills"
[ -d "$V" ] || fail "missing $V"

REF="v1.2.3"
SHA="6acc160e4e0cd062dbbbd7a1b26ae92855edf07e"      # the commit v1.2.3 peels to
TAG_OBJ="835450ef244ab7335f75d95b83e7d979eae22a6d"  # v1.2.3 is annotated; ls-remote prints this

d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT
git -C "$d" init -q || fail "git init failed in $d"
git -C "$d" remote add origin https://github.com/mattpocock/skills.git \
  || fail "git remote add failed"
git -C "$d" fetch -q --depth 1 origin "$SHA" \
  || fail "could not fetch mattpocock/skills at $SHA"
git -C "$d" checkout -q FETCH_HEAD || fail "could not check out $SHA"
[ "$(git -C "$d" rev-parse HEAD)" = "$SHA" ] || fail "checkout HEAD != $SHA"
git ls-remote --exit-code --tags https://github.com/mattpocock/skills.git \
  "refs/tags/$REF" | grep -q "$TAG_OBJ" || fail "tag $REF no longer names $TAG_OBJ"

U="$d/skills/engineering/setup-matt-pocock-skills"
[ -d "$U" ] || fail "upstream has no skills/engineering/setup-matt-pocock-skills at $SHA"

# Same file set: SKILL.md, agents/openai.yaml, and the five seed templates.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"
[ "$(cd "$V" && find . -type f | wc -l)" -eq 7 ] || fail "expected 7 vendored files"

# Every file but SKILL.md: identical bytes.
while IFS= read -r f; do
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream; templates are taken byte-for-byte"
done < <(cd "$V" && find . -type f | sort)

# Frontmatter is byte-identical, invocation gate included. The two harnesses
# gate differently and each skill carries both: Claude reads this field, Codex
# reads policy.allow_implicit_invocation in agents/openai.yaml. Upstream ships
# them as a pair on all 21 of its gated skills.
diff <(sed -n '1,5p' "$U/SKILL.md") <(sed -n '1,5p' "$V/SKILL.md") \
  || fail "the frontmatter was edited; only the two regions below may change"
grep -qx 'disable-model-invocation: true' "$V/SKILL.md" \
  || fail "the vendored skill must keep Claude's gate, disable-model-invocation: true"
grep -qx '  allow_implicit_invocation: false' "$V/agents/openai.yaml" \
  || fail "the vendored skill must keep Codex's gate, allow_implicit_invocation: false"

# Lines 6-10: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/mattpocock/skills at tag $REF, commit $SHA" \
  "     path: skills/engineering/setup-matt-pocock-skills/" \
  "     MIT, (c) 2026 Matt Pocock. Two local changes, both in this file: the file-pick" \
  "     rule under '4. Write', and the Agent skills block it writes." \
  "-->")"
[ "$(sed -n '6,10p' "$V/SKILL.md")" = "$expected_header" ] \
  || fail "lines 6-10 are not the provenance header"

# Below the frontmatter and the header, strip the two edited regions from each
# side by that side's own sentinels, and require the remainder to be identical.
strip() {
  # $1 file, $2 first line of the region, $3 last line of the region
  awk -v a="$2" -v b="$3" '
    $0 == a { skip = 1 }
    skip != 1 { print }
    $0 == b && skip == 1 { skip = 0 }
  ' "$1"
}
# Region two ends at the paragraph after the fenced block on both sides: ours
# adds prose there, so stripping only the fence would leave it unmatched.
sed '1,5d' "$U/SKILL.md" > "$d/up.md" || fail "could not strip upstream frontmatter"
strip "$d/up.md" '**Pick the file to edit:**' \
  'Never create `AGENTS.md` when `CLAUDE.md` already exists (or vice versa) — always edit the one that'"'"'s already there.' \
  > "$d/up1.md"
up_body="$(strip "$d/up1.md" '```markdown' \
  'Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when `triage` is installed and Section B ran. When it isn'"'"'t, both are omitted.')"

sed '1,10d' "$V/SKILL.md" > "$d/ours.md" || fail "could not strip our frontmatter and header"
strip "$d/ours.md" '**Write `AGENTS.md`, and make `CLAUDE.md` an import:**' \
  'Never leave the block in `CLAUDE.md` alone: a Claude-only carrier leaves Codex reading nothing.' \
  > "$d/ours1.md"
our_body="$(strip "$d/ours1.md" '```markdown' \
  'recorded no tracker, since the rule points at one.')"

diff <(printf '%s\n' "$up_body") <(printf '%s\n' "$our_body") \
  || fail "SKILL.md changed outside the header and the two declared regions"

# The two regions say what this design needs them to say.
grep -q 'exactly one line, `@AGENTS.md`' "$V/SKILL.md" \
  || fail "the file-pick rule does not make CLAUDE.md an @AGENTS.md import"
grep -q '### Git' "$V/SKILL.md" || fail "the block carries no Git section"
grep -q '### Task reports' "$V/SKILL.md" || fail "the block carries no Task reports section"
grep -q '.superpowers/sdd/' "$V/SKILL.md" || fail "the task-reports rule lost its subject"

# The LICENSE's third provenance notice names the same ref and commit.
grep -q "at tag $REF, commit $SHA" "$REPO_ROOT/plugins/software-development/LICENSE" \
  || fail "LICENSE provenance does not name $REF / $SHA"

printf 'vendored-scaffolder: matches mattpocock/skills %s except header + two regions\n' "$REF"
