#!/usr/bin/env bash
# Run Codex's own plugin validator on every plugin. Each must pass cleanly,
# except for one recorded bullet on one skill (Deviation D7, below) — any
# other failure, bullet-shaped or not, fails the test.
# The validator ships with codex-cli under ~/.codex/skills/.system; CI fetches
# the same two files from openai/codex and points CODEX_PLUGIN_VALIDATOR at them.
. "$(dirname "$0")/lib.sh"

VALIDATOR="${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}"
[ -f "$VALIDATOR" ] || fail "Codex validator not found at $VALIDATOR (set CODEX_PLUGIN_VALIDATOR)"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  # One recorded exception. validate_plugin.py requires Claude's
  # disable-model-invocation to be false or absent, on every directory under
  # <plugin>/skills. The vendored scaffolder keeps upstream's `true` because
  # that is the field Claude reads; Codex reads policy.allow_implicit_invocation
  # in agents/openai.yaml, which is set to false and vendored byte-for-byte, and
  # the Codex runtime never reads the frontmatter field at all. Any other bullet
  # from the validator still fails the test.
  known='- skill `setup-matt-pocock-skills` frontmatter field `disable-model-invocation` must be false'
  if ! out="$(python3 "$VALIDATOR" "$p" 2>&1)"; then
    # A non-zero exit with no `- ` bullet at all — a traceback, a missing
    # dependency, a message-format change — is not the one recorded
    # exception and must fail loudly rather than fall through the filter
    # below with an empty $others.
    printf '%s\n' "$out" | grep -q '^- ' || fail "Codex validator failed on $p with no bullets:
$out"
    # -e is required: the pattern begins with a dash and would otherwise be
    # read as options. `|| true` because both greps exit 1 when the only
    # bullet is the known one, which is the case that must pass.
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -e "$known" || true)"
    [ -z "$others" ] || fail "Codex validator rejected $p:
$others"
  fi
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
