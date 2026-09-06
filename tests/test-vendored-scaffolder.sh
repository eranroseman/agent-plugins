#!/usr/bin/env bash
# The vendored scaffolder must equal mattpocock/skills at the ref this
# repository declares, except for a provenance header and the local changes the
# header names: SKILL.md's frontmatter name and description, five stripped
# regions of its body (the title, the tracker explainer, the file-pick rule,
# Section D, and the Agent skills block), and the Codex display name in
# agents/openai.yaml. The five seed templates must be byte-identical, which is
# what keeps a re-vendor cheap.
# Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-development/skills/setup-repository"
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

# Upstream keeps its own directory name; only the vendored copy is renamed.
U="$d/skills/engineering/setup-matt-pocock-skills"
[ -d "$U" ] || fail "upstream has no skills/engineering/setup-matt-pocock-skills at $SHA"

# Same file set: SKILL.md, agents/openai.yaml, and the five seed templates.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"
[ "$(cd "$V" && find . -type f | wc -l)" -eq 7 ] || fail "expected 7 vendored files"

# The five seed templates: identical bytes. SKILL.md and agents/openai.yaml
# carry the declared local changes and are checked separately below.
while IFS= read -r f; do
  case "$f" in ./SKILL.md|./agents/openai.yaml) continue ;; esac
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream; templates are taken byte-for-byte"
done < <(cd "$V" && find . -type f | sort)

# agents/openai.yaml: one line differs, the Codex display name, because the
# skill is renamed. Everything else is upstream's.
diff <(grep -v '^  display_name:' "$U/agents/openai.yaml") \
     <(grep -v '^  display_name:' "$V/agents/openai.yaml") \
  || fail "agents/openai.yaml differs from upstream outside display_name"
grep -qx '  display_name: "Setup Repository"' "$V/agents/openai.yaml" \
  || fail "agents/openai.yaml must carry the renamed Codex display name"

# Frontmatter: the fences and the invocation gate are upstream's byte-for-byte;
# `name` follows the rename and `description` is ours. The two harnesses gate
# differently and each skill carries both: Claude reads this field, Codex reads
# policy.allow_implicit_invocation in agents/openai.yaml. Upstream ships them as
# a pair on all 21 of its gated skills.
diff <(sed -n '1p;4,5p' "$U/SKILL.md") <(sed -n '1p;4,5p' "$V/SKILL.md") \
  || fail "the frontmatter fences or the invocation gate were edited"
[ "$(sed -n '2p' "$V/SKILL.md")" = "name: setup-repository" ] \
  || fail "frontmatter line 2 must read 'name: setup-repository'"
sed -n '3p' "$V/SKILL.md" | grep -q '^description: ' \
  || fail "frontmatter line 3 must be the description"
grep -qx 'disable-model-invocation: true' "$V/SKILL.md" \
  || fail "the vendored skill must keep Claude's gate, disable-model-invocation: true"
grep -qx '  allow_implicit_invocation: false' "$V/agents/openai.yaml" \
  || fail "the vendored skill must keep Codex's gate, allow_implicit_invocation: false"

# Lines 6-12: the whole provenance header, verbatim. It is the only place the
# local changes are enumerated for a reader, so the test pins it word for word.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/mattpocock/skills at tag $REF, commit $SHA" \
  "     path: skills/engineering/setup-matt-pocock-skills/" \
  "     MIT, (c) 2026 Matt Pocock. Local changes: in this file, the frontmatter" \
  "     name and description, the title, the tracker explainer's skill list, the" \
  "     file-pick rule under '4. Write', Section D in step 2, and the Agent skills" \
  "     block it writes; in agents/openai.yaml, the Codex display name." \
  "-->")"
[ "$(sed -n '6,12p' "$V/SKILL.md")" = "$expected_header" ] \
  || fail "lines 6-12 are not the provenance header"

# Below the frontmatter and the header, strip each side's declared regions by
# that side's own sentinels and require the remainder to be identical.
require_once() {
  # $1 file, $2 sentinel, $3 label. A sentinel that stops matching is what a
  # re-vendor looks like; without this the strip would swallow to EOF on both
  # sides and the comparison would pass on two empty strings.
  local n
  n="$(grep -cxF -- "$2" "$1" || true)"
  [ "$n" = "1" ] || fail "$3: sentinel '$2' matches $n time(s); expected exactly 1"
}

strip_regions() {
  # $1 label, $2 file, then first-line/last-line sentinel pairs
  local label="$1" src="$2" work="$d/strip-work" next="$d/strip-next"
  shift 2
  cp "$src" "$work" || fail "$label: could not copy $src"
  while [ "$#" -gt 0 ]; do
    require_once "$work" "$1" "$label"
    require_once "$work" "$2" "$label"
    awk -v a="$1" -v b="$2" '
      $0 == a { skip = 1 }
      skip != 1 { print }
      $0 == b && skip == 1 { skip = 0 }
    ' "$work" > "$next" || fail "$label: awk failed while stripping '$1'"
    [ -s "$next" ] || fail "$label: stripping '$1' left nothing"
    mv "$next" "$work" || fail "$label: could not advance the working copy"
    shift 2
  done
  cat "$work"
}

# Region 4 ends at '### 3. Confirm and edit' on both sides: ours inserts a whole
# section before that heading, so ending at Section D's last line would leave
# our side one blank line longer. Region 5 likewise ends at the paragraph after
# the fenced block, because ours adds prose there.
sed '1,5d' "$U/SKILL.md" > "$d/up.md" || fail "could not strip upstream frontmatter"
up_body="$(strip_regions upstream "$d/up.md" \
  "# Setup Matt Pocock's Skills" \
  "# Setup Matt Pocock's Skills" \
  '> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-tickets`, `triage`, and `to-spec` read from and write to it — they need to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.' \
  '> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-tickets`, `triage`, and `to-spec` read from and write to it — they need to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.' \
  '**Pick the file to edit:**' \
  'Never create `AGENTS.md` when `CLAUDE.md` already exists (or vice versa) — always edit the one that'"'"'s already there.' \
  '### 3. Confirm and edit' \
  '### 3. Confirm and edit' \
  '```markdown' \
  'Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when `triage` is installed and Section B ran. When it isn'"'"'t, both are omitted.')"

sed '1,12d' "$V/SKILL.md" > "$d/ours.md" || fail "could not strip our frontmatter and header"
our_body="$(strip_regions vendored "$d/ours.md" \
  '# Setup Repository' \
  '# Setup Repository' \
  '> Explainer: The "issue tracker" is where issues live for this repo. `triage` reads from and writes to it — it needs to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.' \
  '> Explainer: The "issue tracker" is where issues live for this repo. `triage` reads from and writes to it — it needs to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.' \
  '**Write `AGENTS.md`, and make `CLAUDE.md` an import:**' \
  'Never leave the block in `CLAUDE.md` alone: a Claude-only carrier leaves Codex reading nothing.' \
  '**Section D — Git convention.** Default to **merge locally**. Ask which of the three this repo uses:' \
  '### 3. Confirm and edit' \
  '```markdown' \
  'recorded no tracker, since the rule points at one.')"

diff <(printf '%s\n' "$up_body") <(printf '%s\n' "$our_body") \
  || fail "SKILL.md changed outside the header and the declared regions"

# The regions say what this design needs them to say. Each grep runs against the
# region it is about, not the whole file, so a match elsewhere cannot satisfy it.
extract() {
  # $1 file, $2 first line, $3 last line
  awk -v a="$2" -v b="$3" '
    $0 == a { inside = 1 }
    inside == 1 { print }
    $0 == b && inside == 1 { exit }
  ' "$1"
}

filepick="$(extract "$V/SKILL.md" '**Write `AGENTS.md`, and make `CLAUDE.md` an import:**' \
  'Never leave the block in `CLAUDE.md` alone: a Claude-only carrier leaves Codex reading nothing.')"
grep -q 'exactly one line, `@AGENTS.md`' <<<"$filepick" \
  || fail "the file-pick rule does not make CLAUDE.md an @AGENTS.md import"

gitsection="$(extract "$V/SKILL.md" \
  '**Section D — Git convention.** Default to **merge locally**. Ask which of the three this repo uses:' \
  '### 3. Confirm and edit')"
for opt in 'Merge locally' 'Open a pull request' 'Rebase, then fast-forward'; do
  grep -qF -- "**$opt**" <<<"$gitsection" || fail "Section D does not offer '$opt'"
done

block="$(extract "$V/SKILL.md" '```markdown' 'recorded no tracker, since the rule points at one.')"
grep -qx '### Git' <<<"$block" || fail "the block carries no Git section"
grep -qx '### Design discipline' <<<"$block" || fail "the block carries no Design discipline section"
grep -qF 'Eliminate the problem > add a mechanism > add a rule' <<<"$block" \
  || fail "the Design discipline section does not carry the ladder"
grep -qF 'name the rungs you ruled out and why' <<<"$block" \
  || fail "the ladder lost its enforceable half, the obligation to justify landing on prose"
grep -qx '### Task reports' <<<"$block" || fail "the block carries no Task reports section"
# The rule no longer names `.superpowers/sdd/`: an agent running SDD learns the
# workspace's path and fate from SDD itself, so the anchor was assumable weight
# in a file every agent loads. What it cannot learn elsewhere is the closed set
# of durable homes, and that a decline is one of them.
grep -qF 'Concern' <<<"$block" || fail "the task-reports rule lost its subject"
grep -qF 'a recorded decline' <<<"$block" \
  || fail "the task-reports rule lost the closed set of durable homes"

# The two sections the block writes verbatim must equal this repository's own
# AGENTS.md byte for byte. "Verbatim" otherwise names two different strings
# depending on which file you read it from, and running the skill here would
# silently rewrite the section it was copied from. Hand-syncing them failed
# twice; this is the mechanism that replaces remembering.
for h in '### Design discipline' '### Task reports'; do
  ours="$(awk -v h="$h" '$0==h{f=1;print;next} f && /^#/{exit} f' "$REPO_ROOT/AGENTS.md")"
  [ -n "$ours" ] || fail "AGENTS.md has no $h section to compare the block against"
  theirs="$(awk -v h="$h" '$0==h{f=1;print;next} f && (/^#/ || $0=="```"){exit} f' <<<"$block")"
  diff <(printf '%s\n' "$ours") <(printf '%s\n' "$theirs") \
    || fail "$h differs between AGENTS.md and the block the skill writes verbatim"
done

# Every upstream engineering skill this file names in backticks must be one an
# install actually gets: declared in upstream/skills.json, or vendored by this
# plugin. Upstream prose names its own siblings freely; when the roster drops
# one, the reference goes stale silently, and a re-vendor can introduce more.
bt='`'
available="$(
  jq -r '[.sources[].skills[]] | .[]' "$REPO_ROOT/upstream/skills.json"
  find "$REPO_ROOT/plugins" -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' -printf '%f\n'
)"
named=0
while IFS= read -r s; do
  grep -qF -- "$bt$s$bt" "$V/SKILL.md" || continue
  named=$((named + 1))
  grep -qxF -- "$s" <<<"$available" \
    || fail "SKILL.md names \`$s\`, which is neither declared in upstream/skills.json nor vendored here"
done < <(find "$U/.." -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
[ "$named" -gt 0 ] || fail "SKILL.md names no upstream skill at all; the resolution check went vacuous"

# The LICENSE's third provenance notice names the same ref and commit.
grep -q "at tag $REF, commit $SHA" "$REPO_ROOT/plugins/software-development/LICENSE" \
  || fail "LICENSE provenance does not name $REF / $SHA"

printf 'vendored-scaffolder: matches mattpocock/skills %s except header + declared regions; %s skill name(s) resolve\n' "$REF" "$named"
