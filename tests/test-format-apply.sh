#!/usr/bin/env bash
# scripts/format restores what the three format checks check (#62): in a
# scratch clone, one shell, one markdown and one JSON file are un-formatted,
# scripts/format runs, and the checks pass. A clone, not a copy, because
# every list comes from git ls-files; the working tree's scripts/format is
# copied in, so a mutation is seen before it is committed. The mutation this
# exists for is scripts/format reduced to `exit 0`, which the suite could
# not see.
# needs: shfmt prettier markdownlint-cli2
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT
git clone -q --local "$REPO_ROOT" "$T/repo" || fail "could not clone the checkout"
R="$T/repo"
# The working tree's formatter and its list helpers, not the committed ones:
# a clone carries HEAD, and the mutation this test exists for is made in the
# working tree before it is committed.
cp "$REPO_ROOT/scripts/format" "$R/scripts/format" || fail "could not copy scripts/format into the clone"
cp "$REPO_ROOT/tests/lib.sh" "$R/tests/lib.sh" || fail "could not copy tests/lib.sh into the clone"

# Three files, each broken in a way its checker names and its formatter
# repairs: four-space indents in a shell file; a heading with no space after
# its hash and three trailing spaces in markdown (MD018 and MD009, both
# fixable); one JSON file collapsed to a line.
printf '#!/usr/bin/env bash\nif true; then\n    echo x\nfi\n' >"$R/tests/scratch-shell.sh" || fail "could not write the shell file"
printf '#Title\n\n- an item   \n- another\n' >"$R/docs/agents/scratch.md" || fail "could not write the markdown file"
jq -c . "$R/skills.json" >"$R/skills.tmp" || fail "could not collapse skills.json"
mv "$R/skills.tmp" "$R/skills.json" || fail "could not replace skills.json"
git -C "$R" add tests/scratch-shell.sh docs/agents/scratch.md || fail "could not stage the scratch files"

for t in test-format-shell test-format-prettier test-lint-markdown; do
  bash "$R/tests/$t.sh" >/dev/null 2>&1 && fail "$t passed on the un-formatted clone; the fixture proves nothing"
done
bash "$R/scripts/format" >/dev/null 2>&1 || fail "scripts/format failed on the clone"
for t in test-format-shell test-format-prettier test-lint-markdown; do
  bash "$R/tests/$t.sh" >/dev/null 2>&1 || fail "$t still fails after scripts/format ran:"$'\n'"$(bash "$R/tests/$t.sh" 2>&1)"
done

printf 'format-apply: scripts/format restores a shell, a markdown and a JSON file the checks rejected\n'
