#!/usr/bin/env bash
# Shared helpers for tests/test-*.sh and bin/format. Source this file; do not execute it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# The pinned obra/superpowers sha, read from the one place it is declared.
upstream_sha() {
  jq -r '.plugins[] | select(.name == "superpowers") | .source.sha' "$MARKETPLACE"
}

# Shallow-fetch $1 (a git URL) at commit $2 into $3 and print the path.
# Reuses an existing checkout whose HEAD already matches. Every git command is
# guarded here rather than at the call sites. A caller writing
# `UP="$(fetch_pinned ...)" || fail ...` suspends set -e inside this function,
# so an unguarded mid-function failure would fall through to the closing
# printf and return 0, making that `|| fail` dead code.
fetch_pinned() {
  local url="$1" sha="$2" dir="$3"
  [ "${#sha}" -eq 40 ] || fail "fetch_pinned needs a 40-char sha (got '$sha')"
  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir" || fail "could not create $dir"
  git -C "$dir" init -q || fail "git init failed in $dir"
  git -C "$dir" remote add origin "$url" || fail "git remote add failed in $dir"
  git -C "$dir" fetch -q --depth 1 origin "$sha" \
    || fail "could not fetch $url at $sha into $dir (no network, or the pinned sha is gone)"
  git -C "$dir" checkout -q FETCH_HEAD || fail "could not check out FETCH_HEAD in $dir"
  printf '%s\n' "$dir"
}

# obra/superpowers at the pinned sha. Override the location with UPSTREAM_DIR.
fetch_upstream() {
  local sha
  sha="$(upstream_sha)" || fail "could not read the pinned sha from $MARKETPLACE"
  [ "${#sha}" -eq 40 ] || fail "no 40-char pinned sha in $MARKETPLACE (got '$sha')"
  fetch_pinned https://github.com/obra/superpowers.git "$sha" \
    "${UPSTREAM_DIR:-${TMPDIR:-/tmp}/software-dev-upstream-superpowers}"
}

# A fixture PATH: $1 is the directory, created if absent, and every later
# argument a tool linked into it from wherever this shell resolves it, so the
# script under test sees those names and nothing else. Callers write their
# stubs -- a claude that exits 1, an npx that records -- beside the links.
link_tools() {
  local dir="$1" t p
  shift
  mkdir -p "$dir" || fail "could not create $dir"
  for t in "$@"; do
    p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
    ln -sf "$p" "$dir/$t" || fail "could not link $t into $dir"
  done
}

# ---- Ownership (spec §4; #61 M7) -------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: trees with a drift test, where an upstream pin
# constrains the bytes and the paired test asserts them. One table, one row
# per pattern: the pattern, anchored at the start of the path, a tab, then
# the test that guards it. A guard binds itself to its row by calling
# guards() on one line with the paths it holds to upstream, and
# tests/test-ownership.sh reads that line, so a row cannot name a test that
# checks something else. #21 may devendor a tree: that edits this table and
# nothing else. adhd/agents/openai.yaml is first-party but sits inside a
# vendored directory; the directory is excluded whole, because the drift
# test's file-set assertion governs it and tests/test-plugin-skills.sh
# already asserts the one policy line the file exists to carry.
GUARDED=(
  $'^plugins/sensemaking/skills/adhd/\ttests/test-vendored-adhd.sh'
  $'^plugins/software-dev/skills/brainstorming/\ttests/test-vendored-brainstorming.sh'
  $'^plugins/software-dev/skills/diagnosing-bugs/\ttests/test-vendored-diagnosing-bugs.sh'
  $'^plugins/software-dev/skills/setup-repository/\ttests/test-vendored-scaffolder.sh'
  $'^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\\.md$\ttests/test-vendored-duplicates.sh'
  $'^plugins/software-dev/hooks/payload\\.md$\ttests/test-hook.sh'
)
EXCLUDED="$(
  IFS='|'
  set -- "${GUARDED[@]%%$'\t'*}"
  printf '%s' "$*"
)"

# The pattern of the row whose guard is $1, a path relative to REPO_ROOT.
# Prints it; fails unless exactly one row names that guard.
guarded_pattern() {
  local guard="$1" row n=0 pat=""
  for row in "${GUARDED[@]}"; do
    [ "${row#*$'\t'}" = "$guard" ] || continue
    n=$((n + 1))
    pat="${row%%$'\t'*}"
  done
  [ "$n" -eq 1 ] || fail "$n row(s) of the table in tests/lib.sh name $guard as their guard; exactly one must"
  printf '%s\n' "$pat"
}

# Called by a drift test, on one line, with the repository-relative paths it
# is about to hold to upstream. The test is bound to its row: exactly one row
# names it, and every path given is tracked and matches that row's pattern.
# Before any fetch, so a broken binding fails without a network.
guards() {
  local me="tests/${BASH_SOURCE[1]##*/}" pat p
  pat="$(guarded_pattern "$me")" || exit 1
  [ "$#" -gt 0 ] || fail "$me calls guards with no path"
  for p in "$@"; do
    printf '%s\n' "$p" | grep -qE "$pat" \
      || fail "$me guards $p, which its row's pattern '$pat' does not match"
    git -C "$REPO_ROOT" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 \
      || fail "$me guards $p, which is not a tracked file"
  done
}

# Tracked files this repository owns, one path per line relative to
# REPO_ROOT. Arguments are git pathspecs: checked '*.md', or
# checked '*.md' ':(exclude)docs/superpowers'. `git -C`, never bare: ls-files
# is cwd-relative and this file never changes directory. Tracked, not
# present: a new file joins when it is staged, which is also the moment
# anything else in the repository notices it, and a branch's worktree under
# .claude/worktrees/ that a `find` would see is not listed. Every caller
# asserts the list is non-empty: an empty list is a false green for most
# tools.
checked() {
  git -C "$REPO_ROOT" ls-files "$@" | { grep -vE "$EXCLUDED" || true; }
}

# The shell files: every checked file whose first line is the bash shebang.
# By shebang, not extension: five of them have none. Arguments narrow the
# list the same way checked's do.
checked_shell() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ "$(head -n 1 "$REPO_ROOT/$f")" = '#!/usr/bin/env bash' ]; then
      printf '%s\n' "$f"
    fi
  done < <(checked "$@")
}

# shfmt's flags, read by tests/test-format-shell.sh and bin/format (spec
# §8.1): the set measured closest to the code as written, 17 files and 272
# lines at aa8e78d; -sr was dropped because it restyled a further 140 lines.
# shellcheck disable=SC2034  # read by the test and by bin/format
SHFMT_FLAGS=(-i 2 -ci -bn)
