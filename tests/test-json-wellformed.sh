#!/usr/bin/env bash
# Every marketplace manifest, plugin manifest, and hooks file must parse as JSON.
. "$(dirname "$0")/lib.sh"

found=0
while IFS= read -r f; do
  jq empty "$f" || fail "not valid JSON: $f"
  found=$((found + 1))
done < <(find "$REPO_ROOT/.claude-plugin" "$REPO_ROOT/.agents" "$REPO_ROOT/plugins" \
           -name '*.json' -not -path '*/skills/*' 2>/dev/null | sort)

[ "$found" -gt 0 ] || fail "no manifests found"
printf 'json: %s files well-formed\n' "$found"
