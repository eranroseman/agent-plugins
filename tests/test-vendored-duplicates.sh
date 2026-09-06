#!/usr/bin/env bash
# finding-duplicate-functions is a rewritten fork of obra/superpowers-lab, not
# a copy: only its two prompt templates are upstream's and those must stay
# byte-identical at the recorded commit, so a drift there is visible rather
# than silent. The rest is authored here and is checked for shape, not
# content. Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-dev/skills/finding-duplicate-functions"
[ -d "$V" ] || fail "missing $V"

SHA="51111f74f24058117752d9aa917cb19859f8ec86"
UP="$(fetch_pinned https://github.com/obra/superpowers-lab.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-superpowers-lab")"
U="$UP/skills/finding-duplicate-functions"
[ -d "$U" ] || fail "upstream has no skills/finding-duplicate-functions at $SHA"

# The two templates carried unchanged.
for f in scripts/categorize-prompt.md scripts/find-duplicates-prompt.md; do
  [ -f "$U/$f" ] || fail "upstream has no $f at $SHA"
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream at $SHA; PROVENANCE.md says it is carried unchanged"
done

# The six files the fork ships, and the two executables.
diff <(printf '%s\n' ./PROVENANCE.md ./SKILL.md ./scripts/categorize-prompt.md ./scripts/cluster.py \
                     ./scripts/extract-functions.py ./scripts/find-duplicates-prompt.md) \
     <(cd "$V" && find . -type f | sort) \
  || fail "file set is not the six the fork ships"
[ -x "$V/scripts/cluster.py" ] || fail "scripts/cluster.py lost its executable bit"
[ -x "$V/scripts/extract-functions.py" ] || fail "scripts/extract-functions.py lost its executable bit"
# Parsed, not compiled: py_compile writes a __pycache__ into the skill tree,
# which the file-set assertion above would then count on the next run.
python3 -c 'import ast, sys
for path in sys.argv[1:]:
    ast.parse(open(path).read(), path)' "$V/scripts/cluster.py" "$V/scripts/extract-functions.py" \
  || fail "a script does not parse"

# Frontmatter untouched in shape; lines 5-10 are the provenance header, verbatim.
[ "$(sed -n 2p "$V/SKILL.md")" = "name: finding-duplicate-functions" ] || fail "name changed"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"
expected_header="$(printf '%s\n' \
  "<!-- Forked from https://github.com/obra/superpowers-lab at commit $SHA" \
  "     path: skills/finding-duplicate-functions/" \
  "     MIT, (c) 2025 Jesse Vincent. A rewritten fork, not a copy: scripts/categorize-prompt.md and" \
  "     scripts/find-duplicates-prompt.md are upstream's, byte for byte; everything else is authored here." \
  "     PROVENANCE.md records what changed and why. Edit this skill here; there is nothing to re-vendor." \
  "-->")"
[ "$(sed -n 5,10p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-10 are not the provenance header"

# PROVENANCE.md and the LICENSE name the same commit.
grep -q "$SHA" "$V/PROVENANCE.md" || fail "PROVENANCE.md does not name commit $SHA"
grep -q "^$SHA); its two prompt templates" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE carries no provenance notice naming commit $SHA for the fork"

printf 'vendored-duplicates: two templates match obra/superpowers-lab %s; six files, two executables\n' "$SHA"
