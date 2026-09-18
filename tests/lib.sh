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

# ---- Ownership (spec §4) ----------------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: vendored, where an upstream pin constrains the
# bytes and the paired drift test asserts them. Six patterns, anchored at the
# start of the path, each beside the test that guards it;
# tests/test-ownership.sh checks every pair. #21 may devendor payload.md or
# setup-repository/SKILL.md: that edits these two arrays and nothing else.
# adhd/agents/openai.yaml is authored here but sits inside a vendored
# directory; the directory is excluded whole, because the drift test's
# file-set assertion governs it and tests/test-plugin-skills.sh already
# asserts the one policy line the file exists to carry.
VENDORED_PATTERNS=(
  '^plugins/sensemaking/skills/adhd/'
  '^plugins/software-dev/skills/brainstorming/'
  '^plugins/software-dev/skills/diagnosing-bugs/'
  '^plugins/software-dev/skills/setup-repository/'
  '^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\.md$'
  '^plugins/software-dev/hooks/payload\.md$'
)
# shellcheck disable=SC2034  # read by tests/test-ownership.sh
VENDORED_GUARDS=(
  tests/test-vendored-adhd.sh
  tests/test-vendored-brainstorming.sh
  tests/test-vendored-diagnosing-bugs.sh
  tests/test-vendored-scaffolder.sh
  tests/test-vendored-duplicates.sh
  tests/test-hook.sh
)
EXCLUDED="$(IFS='|'; printf '%s' "${VENDORED_PATTERNS[*]}")"

# Tracked files this repository owns, one path per line relative to
# REPO_ROOT. Arguments are git pathspecs: checked '*.md', or
# checked '*.md' ':(exclude)docs/superpowers'. `git -C`, never bare: ls-files
# is cwd-relative and this file never changes directory. Tracked, not
# present: a new file joins when it is staged, which is also the moment
# anything else in the repository notices it, and the stale worktree under
# .kilo/ that a `find` would see is not listed. Every caller asserts the
# list is non-empty: an empty list is a false green for most tools.
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
