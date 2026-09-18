#!/usr/bin/env bash
# tests/run.sh itself (spec §5): the hard gate refuses with a list; a
# declared need that is unmet skips the test, or fails it under --no-skip; a
# registry tool at the wrong version is unmet and the line names both
# versions; a need no probe knows is exit 2; and every run writes
# tests/results.tsv with a header naming the tree and one row per test.
# Proved on a scratch repository carrying synthetic tests, never on this one.
# Needs no network.
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

# The scratch repository: the runner and the registry copied in, the result
# file ignored, one commit so the header has a sha, and four synthetic tests.
R="$T/repo"
mkdir -p "$R/tests" || fail "could not create $R/tests"
cp "$REPO_ROOT/tests/run.sh" "$R/tests/run.sh" || fail "could not copy run.sh"
cp "$REPO_ROOT/tests/tools.txt" "$R/tests/tools.txt" || fail "could not copy tools.txt"
printf 'tests/results.tsv\n' > "$R/.gitignore" || fail "could not write .gitignore"
printf '#!/usr/bin/env bash\n# passes, and says so\nprintf "alpha ok\\n"\n' > "$R/tests/test-a-pass.sh" \
  || fail "could not write test-a-pass.sh"
printf '#!/usr/bin/env bash\n# fails with status 3\nprintf "beta broke\\n"\nexit 3\n' > "$R/tests/test-b-fail.sh" \
  || fail "could not write test-b-fail.sh"
printf '#!/usr/bin/env bash\n# needs: claude\nexit 0\n' > "$R/tests/test-c-needs-claude.sh" \
  || fail "could not write test-c-needs-claude.sh"
printf '#!/usr/bin/env bash\n# needs: shfmt\nexit 0\n' > "$R/tests/test-d-needs-shfmt.sh" \
  || fail "could not write test-d-needs-shfmt.sh"
git -C "$R" init -q || fail "git init failed in $R"
git -C "$R" add -A || fail "git add failed in $R"
git -C "$R" -c user.email=t@example.com -c user.name=t commit -q -m seed || fail "could not seed a commit"
sha="$(git -C "$R" rev-parse --short HEAD)" || fail "could not read the scratch sha"

# A PATH carrying what the runner uses and nothing it must not: no claude,
# and a stub shfmt reporting a version the registry does not declare.
BIN="$T/bin"
mkdir -p "$BIN" || fail "could not create $BIN"
for t in bash dirname rm git jq awk grep head tail tee tr date mktemp cat; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t" || fail "could not link $t into $BIN"
done
printf '#!/usr/bin/env bash\nprintf "v0.0.1\\n"\n' > "$BIN/shfmt" || fail "could not write the shfmt stub"
chmod +x "$BIN/shfmt" || fail "could not make the shfmt stub executable"
NOJQ="$T/bin-nojq"
mkdir -p "$NOJQ" || fail "could not create $NOJQ"
for t in bash dirname rm git; do ln -sf "$BIN/$t" "$NOJQ/$t" || fail "could not link $t into $NOJQ"; done

# 1. The hard gate: without jq the run refuses with the list, exit 2, and
# writes no result file.
if out="$(env PATH="$NOJQ" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "without jq the runner must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -qx 'the test suite needs: jq' \
  || fail "the refusal must name what is missing in the documented shape:"$'\n'"$out"
[ ! -e "$R/tests/results.tsv" ] || fail "a refused run must not leave a result file"

# 2. A skipping run: the failing test fails, the unmet needs skip and are
# summed, the exit status is 1 for the failure alone.
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "a run with one failing test must exit 1, got $status:"$'\n'"$out"
for line in \
  'PASS tests/test-a-pass.sh' \
  'FAIL tests/test-b-fail.sh' \
  'SKIP tests/test-c-needs-claude.sh (needs claude)' \
  'SKIP tests/test-d-needs-shfmt.sh (needs shfmt 3.14.1; found 0.0.1)' \
  '1 passed, 1 failed, 2 skipped for want of: claude, shfmt 3.14.1 (found 0.0.1)'
do
  printf '%s\n' "$out" | grep -qxF -- "$line" || fail "missing line: $line"$'\n'"$out"
done
RES="$R/tests/results.tsv"
[ -f "$RES" ] || fail "the run wrote no $RES"
sed -n 1p "$RES" | grep -qE "^# $sha [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" \
  || fail "the header must be '# <sha> <UTC time>' on a clean tree: $(sed -n 1p "$RES")"
for row in \
  "$(printf 'tests/test-a-pass.sh\tPASS\t0\talpha ok')" \
  "$(printf 'tests/test-b-fail.sh\tFAIL\t3\tbeta broke')" \
  "$(printf 'tests/test-c-needs-claude.sh\tSKIP\t-\tneeds claude')" \
  "$(printf 'tests/test-d-needs-shfmt.sh\tSKIP\t-\tneeds shfmt 3.14.1; found 0.0.1')"
do
  grep -qxF -- "$row" "$RES" || fail "missing row in results.tsv: $row"$'\n'"$(cat "$RES")"
done
[ "$(grep -c . "$RES")" -eq 5 ] || fail "results.tsv should hold a header and four rows:"$'\n'"$(cat "$RES")"

# 3. --no-skip: an unmet need is a FAIL, counted, and the run is red for it.
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" --no-skip 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "--no-skip with unmet needs must exit 1, got $status:"$'\n'"$out"
for line in \
  'FAIL tests/test-c-needs-claude.sh (needs claude)' \
  'FAIL tests/test-d-needs-shfmt.sh (needs shfmt 3.14.1; found 0.0.1)' \
  '1 passed, 3 failed, 0 skipped for want of: claude, shfmt 3.14.1 (found 0.0.1)'
do
  printf '%s\n' "$out" | grep -qxF -- "$line" || fail "missing line under --no-skip: $line"$'\n'"$out"
done
grep -qxF -- "$(printf 'tests/test-c-needs-claude.sh\tFAIL\t-\tneeds claude')" "$RES" \
  || fail "under --no-skip the result row must read FAIL:"$'\n'"$(cat "$RES")"

# 4. A dirty tree is named as such.
printf 'scratch\n' > "$R/untracked" || fail "could not dirty the scratch tree"
env PATH="$BIN" /bin/bash "$R/tests/run.sh" >/dev/null 2>&1 || true
sed -n 1p "$RES" | grep -qE "^# $sha dirty [0-9]{4}-" \
  || fail "the header must say dirty when git status is non-empty: $(sed -n 1p "$RES")"
rm -f "$R/untracked"

# 5. A need no probe knows is exit 2, naming the test and the need.
printf '#!/usr/bin/env bash\n# needs: nosuchtool\nexit 0\n' > "$R/tests/test-e-unknown.sh" \
  || fail "could not write test-e-unknown.sh"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "an unknown need must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'tests/test-e-unknown.sh declares a need no probe knows: nosuchtool' \
  || fail "the unknown need must be named with its test:"$'\n'"$out"
rm -f "$R/tests/test-e-unknown.sh"

# 6. A wholly green run exits 0 with no `for want of`.
rm -f "$R/tests/test-b-fail.sh" "$R/tests/test-c-needs-claude.sh" "$R/tests/test-d-needs-shfmt.sh"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 0 ] || fail "an all-green run must exit 0, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -qxF '1 passed, 0 failed, 0 skipped' \
  || fail "the summary of a green run must carry no 'for want of':"$'\n'"$out"

printf 'runner: hard gate refuses, needs skip or fail, versions compared, results.tsv written\n'
