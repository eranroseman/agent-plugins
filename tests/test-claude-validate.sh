#!/usr/bin/env bash
# Schema-check every plugin manifest with Claude Code's own validator.
# --strict turns warnings (unknown fields, missing metadata) into failures.
. "$(dirname "$0")/lib.sh"

[ -f "$MARKETPLACE" ] || fail "missing $MARKETPLACE"
claude plugin validate --strict "$MARKETPLACE" || fail "claude plugin validate --strict $MARKETPLACE"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.claude-plugin/plugin.json" ] || continue
  claude plugin validate --strict "$p" || fail "claude plugin validate --strict $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugin manifests under plugins/"
