#!/usr/bin/env bash
# Shared helpers for tests/test-*.sh. Source this file; do not execute it.
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
