#!/usr/bin/env bash
# The machines the doctor cannot read (spec §6.2). For each, bin/setup --check
# must exit non-zero and never print the line `clean`; most cases also assert
# the line that names what could not be read. Each fixture is a scratch
# checkout -- a symlinked bin/setup beside a corrupted desired-state file -- so
# the real marketplace.json is never touched. Needs no network and no CLI:
# every fixture PATH omits claude, codex, node and npx, so both CLI halves
# report skipped and nothing can reach the network.
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

# A restricted PATH: everything the engine runs in check mode, minus the
# names given. Prints the directory.
bin_without() {
  local dir="$T/bin-without${1:+-$1}" t x skip tools=()
  for t in bash git jq grep find date readlink basename dirname cut \
    mv ln mkdir cat sha256sum; do
    skip=0
    for x in "$@"; do [ "$t" != "$x" ] || skip=1; done
    [ "$skip" -eq 1 ] || tools+=("$t")
  done
  link_tools "$dir" "${tools[@]}"
  printf '%s\n' "$dir"
}

# A scratch checkout named $1 under $T: a symlinked bin/setup, so REPO_ROOT
# resolves to the scratch directory, and intact copies of both desired-state
# files for the case to corrupt. Prints its path.
scratch_repo() {
  local r="$T/$1"
  mkdir -p "$r/bin" "$r/.claude-plugin" || fail "could not seed $r"
  ln -s "$REPO_ROOT/bin/setup" "$r/bin/setup" || fail "could not link bin/setup into $r"
  cp "$MARKETPLACE" "$r/.claude-plugin/marketplace.json" || fail "could not copy the marketplace into $r"
  cp "$REPO_ROOT/skills.json" "$r/skills.json" || fail "could not copy skills.json into $r"
  printf '%s\n' "$r"
}

# $1 a label, $2 the scratch checkout, $3 the HOME, $4 the PATH directory.
# Runs bin/setup --check, asserts the two properties every unreadable machine
# must have, and leaves the output in OUT for the case's own assertions.
run_case() {
  local label="$1" repo="$2" home="$3" path="$4" status
  mkdir -p "$home" || fail "$label: could not create $home"
  if OUT="$(env HOME="$home" CODEX_HOME="$home/.codex" PATH="$path" \
    /bin/bash "$repo/bin/setup" --check 2>&1)"; then status=0; else status=$?; fi
  [ "$status" -ne 0 ] || fail "$label: bin/setup --check exited 0:"$'\n'"$OUT"
  printf '%s\n' "$OUT" | grep -qx 'clean' \
    && fail "$label: the doctor called an unread machine clean:"$'\n'"$OUT"
  return 0
}
saw() { printf '%s\n' "$OUT" | grep -q -- "$1"; }

# A HOME whose skill root exists, so every check gets past ensure_links'
# root guard and reaches the desired state it reads. Prints the path.
seeded_home() {
  mkdir -p "$T/home-$1/.agents/skills" || fail "could not seed home-$1"
  printf '%s\n' "$T/home-$1"
}

BIN="$(bin_without)"

# 1. A malformed marketplace.json: jq fails on every read, and each reader
# says so rather than iterating nothing.
R="$(scratch_repo malformed)"
printf '{\n' >"$R/.claude-plugin/marketplace.json" || fail "could not corrupt the marketplace"
run_case "malformed marketplace" "$R" "$(seeded_home 1)" "$BIN"
saw 'the subset entries could not be read whole from' \
  || fail "malformed marketplace: ensure_clones did not report the unreadable desired state:"$'\n'"$OUT"
saw "the subset entries' skill list could not be read from" \
  || fail "malformed marketplace: ensure_links did not report the unreadable desired state:"$'\n'"$OUT"

# 2. Well-formed, with every git-subdir entry removed: zero subset entries
# is a desired-state defect, not a clean machine.
R="$(scratch_repo no-subset)"
jq 'del(.plugins[] | select(.source.source? == "git-subdir"))' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not remove the git-subdir entries"
run_case "no subset entries" "$R" "$(seeded_home 2)" "$BIN"
saw 'no subset (git-subdir) entry could be read' \
  || fail "no subset entries: the zero-entry guard did not fire:"$'\n'"$OUT"
saw "no subset entry declares a skill" \
  || fail "no subset entries: the zero-skill guard did not fire:"$'\n'"$OUT"

# 3. The first git-subdir entry without `.skills`: the jq program that feeds
# ensure_links aborts before printing a single row (exit 5, zero rows). The
# non-zero exit catches it, and a row count would too; fixture 4 is the shape
# only the exit status can see. This block moved here from
# tests/test-doctor-faults.sh, where its comment described fixture 4's shape
# while seeding this one (#38).
first="$(jq -r '[.plugins[] | select(.source.source? == "git-subdir")][0].name' "$MARKETPLACE")" \
  || fail "could not read the first git-subdir entry"
R="$(scratch_repo first-no-skills)"
jq --arg n "$first" 'del(.plugins[] | select(.name == $n) | .skills)' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not strip .skills from $first"
run_case "first entry without .skills" "$R" "$(seeded_home 3)" "$BIN"
saw "the subset entries' skill list could not be read from" \
  || fail "first entry without .skills: the unreadable list was not reported:"$'\n'"$OUT"

# 4. The second git-subdir entry without `.skills`: jq aborts after the first
# entry's thirteen rows (exit 5, thirteen rows). A row count passes; only
# the exit status catches it. Both issue bodies attributed this shape to the
# wrong entry, which is why the two fixtures sit side by side.
second="$(jq -r '[.plugins[] | select(.source.source? == "git-subdir")][1].name' "$MARKETPLACE")" \
  || fail "could not read the second git-subdir entry"
if [ -z "$second" ] || [ "$second" = null ]; then fail "the marketplace declares fewer than two git-subdir entries"; fi
R="$(scratch_repo second-no-skills)"
jq --arg n "$second" 'del(.plugins[] | select(.name == $n) | .skills)' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not strip .skills from $second"
run_case "second entry without .skills" "$R" "$(seeded_home 4)" "$BIN"
saw "the subset entries' skill list could not be read from" \
  || fail "second entry without .skills: the partial list was not reported:"$'\n'"$OUT"

# 5. jq off PATH. jq is not an optional agent CLI like claude or codex, whose
# absence makes one half genuinely inapplicable: it is the reader of this
# repository's own desired state, so without it every check is unanswered.
# The home passes the one guard that needs no jq -- a skill root that merely
# exists, the converged-then-drifted machine the doctor is for -- so nothing
# stands between "could not read" and a false all-clear. Moved here from
# tests/test-setup-doctor.sh.
R="$(scratch_repo jqless)"
mkdir -p "$T/home-5/.local/share/software-dev/upstream/superpowers/.git" "$T/home-5/.agents/skills" \
  || fail "could not seed the jqless home"
run_case "jq off PATH" "$R" "$T/home-5" "$(bin_without jq)"
saw 'jq is not on PATH' || fail "jq off PATH: the doctor did not name the tool it was missing:"$'\n'"$OUT"
saw 'for want of: jq' || fail "jq off PATH: the verdict does not say which tool left the machine unchecked:"$'\n'"$OUT"

# 6. sha256sum off PATH: the duplicate check cannot compare content, says so,
# and the verdict names it.
R="$(scratch_repo hashless)"
run_case "sha256sum off PATH" "$R" "$(seeded_home 6)" "$(bin_without sha256sum)"
saw 'sha256sum is not on PATH' || fail "sha256sum off PATH: the skip was not reported:"$'\n'"$OUT"
saw 'for want of: sha256sum' || fail "sha256sum off PATH: the verdict does not name it:"$'\n'"$OUT"

# 7. An empty HOME: nothing is installed, and the doctor describes that
# rather than dying on it.
R="$(scratch_repo empty-home)"
run_case "empty HOME" "$R" "$T/home-7" "$BIN"
saw 'FAIL:' || fail "empty HOME: no FAIL line at all:"$'\n'"$OUT"
saw 'the skill root is missing' || fail "empty HOME: the skill root was not reported:"$'\n'"$OUT"

# 8. skills.json whose declared skill names are all empty strings:
# it passes the exit-status guard (jq exits 0) and the non-empty guard (each
# row is repo<TAB>ref<TAB>), and before the loop split every iteration hit
# `[ -n "$name" ] || continue` and the check printed nothing at all -- the
# seventh shape (spec §6.1). An empty field is reported as malformed, never
# skipped.
R="$(scratch_repo empty-skill-names)"
jq '.sources |= map(.skills |= map(""))' "$REPO_ROOT/skills.json" \
  >"$R/skills.json" || fail "could not blank the skill names"
run_case "all-empty skill names" "$R" "$(seeded_home 8)" "$BIN"
saw 'a declared skill line is malformed' \
  || fail "all-empty skill names: ensure_skills_sh did not report the malformed rows:"$'\n'"$OUT"

# 9. A git-subdir entry whose name is the empty string. With a tab IFS,
# `read` dropped the empty leading field and shifted every value left, so
# the entry was reported under its URL; the split by parameter expansion
# keeps each field where it was and reports the empty one (spec §6.3).
R="$(scratch_repo empty-entry-name)"
jq '(.plugins[] | select(.name == "superpowers") | .name) = ""' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not blank the entry name"
run_case "empty entry name" "$R" "$(seeded_home 9)" "$BIN"
saw "a subset entry is malformed: name=''" \
  || fail "empty entry name: ensure_clones did not name the empty field:"$'\n'"$OUT"
saw 'the https://github.com/obra/superpowers.git entry' \
  && fail "empty entry name: the URL was read as the name:"$'\n'"$OUT"

# 10. A check that reports nothing (spec §6.1). After the loop splits and the
# counted all-clear no desired-state shape is silent any more, which is the
# point of them, so the silent check is manufactured: a copy of bin/setup
# whose last line, `main "$@"`, is preceded by a redefinition of
# ensure_fresh_clone that prints nothing. The bracket around it must name
# it as a FAIL, counted in the verdict, and the run must not read as clean.
[ "$(tail -n 1 "$REPO_ROOT/bin/setup")" = 'main "$@"' ] \
  || fail "bin/setup no longer ends in 'main \"\$@\"'; this fixture needs to know where to override"
R="$(scratch_repo silent-check)"
rm "$R/bin/setup" || fail "could not drop the symlink for the silent-check copy"
{
  sed '$d' "$REPO_ROOT/bin/setup"
  printf 'ensure_fresh_clone() { :; }\nmain "$@"\n'
} >"$R/bin/setup" \
  || fail "could not write the silent-check copy"
run_case "silent check" "$R" "$(seeded_home 10)" "$BIN"
saw 'FAIL: check ensure_fresh_clone reported nothing; this machine is unchecked, not verified' \
  || fail "silent check: the bracket around it did not name it:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -qE '^[0-9]+ check\(s\) failed$' \
  || fail "silent check: it was not counted in the verdict:"$'\n'"$OUT"

# 11. A non-scalar `version` in the second git-subdir entry: jq's @tsv aborts
# after the first entry's row (exit 5, one row). A loop fed by process
# substitution ran that one row and reported one clone; the capture reports
# the abort (#61 M13). `null` would not do: @tsv renders it as an empty
# string without error.
R="$(scratch_repo non-scalar-version)"
jq --arg n "$second" '(.plugins[] | select(.name == $n) | .version) = {"x": 1}' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not corrupt the second entry's version"
run_case "non-scalar version" "$R" "$(seeded_home 11)" "$BIN"
saw 'the subset entries could not be read whole from' \
  || fail "non-scalar version: the partial read was not reported:"$'\n'"$OUT"

printf 'doctor-silence: 11 unreadable machines, none reported clean\n'
