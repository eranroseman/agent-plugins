#!/usr/bin/env bash
# Every JSON file this repository owns parses. The list is derived, never
# hardcoded (#27): a manifest in a new directory joins the moment it is
# tracked, and the vendored set is excluded by the one derivation rather than
# by a second `-not -path` that had to be kept in step with it.
. "$(dirname "$0")/lib.sh"

found=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  jq empty "$REPO_ROOT/$f" || fail "not valid JSON: $f"
  found=$((found + 1))
done < <(checked '*.json')

[ "$found" -gt 0 ] || fail "checked '*.json' listed nothing; the ownership derivation went vacuous"
printf 'json: %s files well-formed\n' "$found"
