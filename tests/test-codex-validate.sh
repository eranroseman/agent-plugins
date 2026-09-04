#!/usr/bin/env bash
# Run Codex's own plugin validator on every plugin. Both must pass cleanly.
# The validator ships with codex-cli under ~/.codex/skills/.system; CI fetches
# the same two files from openai/codex and points CODEX_PLUGIN_VALIDATOR at them.
. "$(dirname "$0")/lib.sh"

VALIDATOR="${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}"
[ -f "$VALIDATOR" ] || fail "Codex validator not found at $VALIDATOR (set CODEX_PLUGIN_VALIDATOR)"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  python3 "$VALIDATOR" "$p" || fail "Codex validator rejected $p"
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
