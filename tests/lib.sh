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
fetch_upstream() {
  local sha dir
  sha="$(upstream_sha)"
  dir="${UPSTREAM_DIR:-${TMPDIR:-/tmp}/software-development-upstream-superpowers}"
  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" remote add origin https://github.com/obra/superpowers.git
  git -C "$dir" fetch -q --depth 1 origin "$sha"
  git -C "$dir" checkout -q FETCH_HEAD
  printf '%s\n' "$dir"
}
