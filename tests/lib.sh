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

# Shallow-fetch obra/superpowers at the pinned sha and print the checkout path.
# Reuses an existing checkout whose HEAD already matches. Override the location
# with UPSTREAM_DIR.
# Every git command is guarded here rather than at the call sites. A caller
# writing `UP="$(fetch_upstream)" || fail ...` suspends set -e inside this
# function, so an unguarded mid-function failure would fall through to the
# closing printf and return 0, making that `|| fail` dead code.
fetch_upstream() {
  local sha dir
  sha="$(upstream_sha)" || fail "could not read the pinned sha from $MARKETPLACE"
  [ "${#sha}" -eq 40 ] || fail "no 40-char pinned sha in $MARKETPLACE (got '$sha')"
  dir="${UPSTREAM_DIR:-${TMPDIR:-/tmp}/software-dev-upstream-superpowers}"
  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir" || fail "could not create $dir"
  git -C "$dir" init -q || fail "git init failed in $dir"
  git -C "$dir" remote add origin https://github.com/obra/superpowers.git \
    || fail "git remote add failed in $dir"
  git -C "$dir" fetch -q --depth 1 origin "$sha" \
    || fail "could not fetch obra/superpowers at $sha into $dir (no network, or the pinned sha is gone)"
  git -C "$dir" checkout -q FETCH_HEAD || fail "could not check out FETCH_HEAD in $dir"
  printf '%s\n' "$dir"
}
