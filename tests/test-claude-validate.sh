#!/usr/bin/env bash
# Schema-check the marketplace manifest and every plugin manifest with Claude
# Code's own validator.
# --strict turns warnings (unknown fields, missing metadata) into failures.
# needs: claude
. "$(dirname "$0")/lib.sh"

[ -f "$MARKETPLACE" ] || fail "missing $MARKETPLACE"
claude plugin validate --strict "$MARKETPLACE" || fail "claude plugin validate --strict $MARKETPLACE"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.claude-plugin/plugin.json" ] || fail "$p has no .claude-plugin/plugin.json"
  claude plugin validate --strict "$p" || fail "claude plugin validate --strict $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugin manifests under plugins/"
