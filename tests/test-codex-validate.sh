#!/usr/bin/env bash
# Run Codex's own plugin validator on every local plugin. Each must pass
# cleanly, except for one recorded bullet on each user-invocable-only skill:
# validate_plugin.py requires Claude's disable-model-invocation to be false or
# absent, and every such skill keeps `true` because that is the field Claude
# reads, while Codex reads policy.allow_implicit_invocation in
# agents/openai.yaml, set to false; tests/test-plugin-skills.sh holds the pair.
# The exceptions are derived from the policy files, so a skill gaining the gate
# needs no edit here, and any other bullet fails the test.
#
# The validator is two files from openai/codex at a pinned sha (Q69), fetched
# here without blobs and checked against their sha256: codex-cli no longer ships
# them, since 0.159 rewrites ~/.codex/skills/.system at startup without
# plugin-creator. CODEX_PLUGIN_VALIDATOR names a copy in place of the fetch.
# Offline, this fails rather than skips, as test-upstream.sh does.
# needs: python3 pyyaml
. "$(dirname "$0")/lib.sh"

PIN=f3f6922519fa38487c8250c2b8a670a39a2cf9ff
UPSTREAM_DIR=codex-rs/skills/src/assets/samples/plugin-creator/scripts
declare -A WANT=(
  ["validate_plugin.py"]=f4eeadb733b28b0c3e714de263a76d6542866a672f3e99bdffcf4dbcdf85e944
  ["identifier_validation.py"]=a6d51ce4a9a7e8f85626ff5808a467a67574e7f8cdf1167ffb467c5f67e57223
)

# True when both files under $1 hash to the pins.
pinned_copy() {
  local f got
  for f in "${!WANT[@]}"; do
    [ -f "$1/$f" ] || return 1
    got="$(sha256sum "$1/$f")" || return 1
    [ "${got%% *}" = "${WANT[$f]}" ] || return 1
  done
}

if [ -n "${CODEX_PLUGIN_VALIDATOR:-}" ]; then
  VALIDATOR="$(readlink -f "$CODEX_PLUGIN_VALIDATOR")" || fail "could not resolve $CODEX_PLUGIN_VALIDATOR"
  VDIR="${VALIDATOR%/*}"
else
  # A depth-1 fetch without blobs and a checkout of the two paths: 2 seconds and
  # 464 KB (measured 2026-10-01). Kept under the user's cache directory, and
  # reused while this user owns it and both files still match (#73).
  CACHE="$(cache_dir "codex-validator-${PIN:0:7}")" || exit 1
  VDIR="$CACHE/$UPSTREAM_DIR"
  if ! { [ -O "$CACHE" ] && pinned_copy "$VDIR"; }; then
    rm -rf "$CACHE" || fail "could not remove $CACHE to fetch it again; a cache this user cannot clear, or does not own, is never reused"
    mkdir -p "$CACHE" || fail "could not create $CACHE"
    git -C "$CACHE" init -q || fail "git init failed in $CACHE"
    git -C "$CACHE" remote add origin https://github.com/openai/codex.git || fail "git remote add failed in $CACHE"
    git -C "$CACHE" fetch -q --depth 1 --filter=blob:none origin "$PIN" \
      || fail "could not fetch openai/codex at $PIN (no network, or the pinned sha is gone)"
    git -C "$CACHE" checkout -q FETCH_HEAD -- "$UPSTREAM_DIR/validate_plugin.py" "$UPSTREAM_DIR/identifier_validation.py" \
      || fail "could not check out the validator's two files at $PIN"
  fi
  VALIDATOR="$VDIR/validate_plugin.py"
fi
for f in "${!WANT[@]}"; do
  [ -f "$VDIR/$f" ] || fail "$f is missing beside $VALIDATOR; the validator is two files"
  got="$(sha256sum "$VDIR/$f")" || fail "could not hash $VDIR/$f"
  [ "${got%% *}" = "${WANT[$f]}" ] \
    || fail "$f at $VDIR is not openai/codex@${PIN:0:7}'s; re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a pinned copy"
done

# The exceptions, derived: one bullet per skill whose Codex policy file sets
# allow_implicit_invocation: false.
known="$(for y in "$REPO_ROOT"/plugins/*/skills/*/agents/openai.yaml; do
  user_invocable_only "$y" || continue
  s="$(basename "$(dirname "$(dirname "$y")")")"
  printf -- '- skill `%s` frontmatter field `disable-model-invocation` must be false\n' "$s"
done)"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  if ! out="$(python3 "$VALIDATOR" "$p" 2>&1)"; then
    # A non-zero exit with no `- ` bullet at all -- a traceback, a missing
    # dependency, a message-format change -- is not a recorded exception and
    # must fail loudly rather than fall through the filter below.
    printf '%s\n' "$out" | grep -q '^- ' || fail "Codex validator failed on $p with no bullets:
$out"
    # -f with a process substitution, not -e: more than one pattern, each
    # beginning with a dash. `|| true` because the inverting grep exits 1
    # when every bullet is a known one, the case that must pass.
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -f <(printf '%s\n' "$known") || true)"
    [ -z "$others" ] || fail "Codex validator rejected $p:
$others"
  fi
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
printf 'codex-validate: %s plugin(s) validated against openai/codex@%s; %s user-invocable-only skill(s) excepted\n' \
  "$found" "${PIN:0:7}" "$(printf '%s\n' "$known" | grep -c .)"
