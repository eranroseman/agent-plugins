#!/usr/bin/env bash
# Run Codex's own plugin validator on every plugin. Each must pass cleanly,
# except for one recorded bullet on each user-invocable-only skill (Deviation
# D7, below) — any other failure, bullet-shaped or not, fails the test.
# The validator ships with codex-cli under ~/.codex/skills/.system; CI fetches
# the same two files from openai/codex and points CODEX_PLUGIN_VALIDATOR at
# them.
# needs: python3 pyyaml codex-validator
. "$(dirname "$0")/lib.sh"

VALIDATOR="${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}"
[ -f "$VALIDATOR" ] || fail "Codex validator not found at $VALIDATOR (set CODEX_PLUGIN_VALIDATOR)"
# One validator, two copies, both checked (#3). The local copy -- whatever
# codex-cli installed, or the file CODEX_PLUGIN_VALIDATOR names -- must be
# the bytes CI fetches from openai/codex at the pinned sha, for both files
# the validator is made of. sha256, because sha256sum is the repository's
# one hashing tool; recorded 2026-09-17 from raw.githubusercontent.com at
# the sha below and byte-identical to the codex-cli 0.147.0 copies. The day
# codex-cli moves the files, this fails and the message says what to do.
PIN=f3f6922519fa38487c8250c2b8a670a39a2cf9ff
VALIDATOR="$(readlink -f "$VALIDATOR")" || fail "could not resolve $VALIDATOR"
VDIR="${VALIDATOR%/*}"
for pair in \
  'validate_plugin.py f4eeadb733b28b0c3e714de263a76d6542866a672f3e99bdffcf4dbcdf85e944' \
  'identifier_validation.py a6d51ce4a9a7e8f85626ff5808a467a67574e7f8cdf1167ffb467c5f67e57223'; do
  f="${pair%% *}"
  want="${pair#* }"
  [ -f "$VDIR/$f" ] || fail "$f is missing beside $VALIDATOR; the validator is two files"
  got="$(sha256sum "$VDIR/$f")" || fail "could not hash $VDIR/$f"
  got="${got%% *}"
  [ "$got" = "$want" ] \
    || fail "$f at $VDIR is not the copy CI pins (openai/codex@${PIN:0:7}); re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a copy fetched by the recipe in .github/workflows/validate.yml"
done

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  # The recorded exceptions. validate_plugin.py requires Claude's
  # disable-model-invocation to be false or absent, on every directory under
  # <plugin>/skills. Every user-invocable-only skill keeps `true` because
  # that is the field Claude reads; Codex reads policy.allow_implicit_invocation
  # in agents/openai.yaml, which is set to false, and the Codex runtime never
  # reads the frontmatter field at all. Any other bullet from the validator
  # still fails the test.
  # Three user-invocable-only skills, each carrying the field Claude reads
  # beside the yaml policy Codex reads: the vendored scaffolder, the
  # first-party consistency audit, and the vendored adhd.
  # tests/test-plugin-skills.sh asserts the pair.
  known="$(printf '%s\n' \
    '- skill `setup-repository` frontmatter field `disable-model-invocation` must be false' \
    '- skill `consistency-audit` frontmatter field `disable-model-invocation` must be false' \
    '- skill `adhd` frontmatter field `disable-model-invocation` must be false')"
  if ! out="$(python3 "$VALIDATOR" "$p" 2>&1)"; then
    # A non-zero exit with no `- ` bullet at all -- a traceback, a missing
    # dependency, a message-format change -- is not one of the three
    # recorded exceptions and must fail loudly rather than fall through the
    # filter below with an empty $others.
    printf '%s\n' "$out" | grep -q '^- ' || fail "Codex validator failed on $p with no bullets:
$out"
    # -f with a process substitution, not -e: there is more than one pattern
    # and each begins with a dash, which would otherwise be read as options.
    # `|| true` because the inverting grep exits 1 when every bullet is a
    # known one, which is the case that must pass; the no-bullets case was
    # caught above.
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -f <(printf '%s\n' "$known") || true)"
    [ -z "$others" ] || fail "Codex validator rejected $p:
$others"
  fi
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
printf 'codex-validate: %s plugin(s) validated; both validator files match openai/codex@%s\n' "$found" "${PIN:0:7}"
