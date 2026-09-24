#!/usr/bin/env bash
# Every shell file this repository owns is formatted as shfmt formats it with
# the flags tests/lib.sh declares (spec §8). scripts/format applies them.
# needs: shfmt
. "$(dirname "$0")/lib.sh"

files="$(checked_shell)"
[ -n "$files" ] || fail "checked_shell() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
shfmt -d "${SHFMT_FLAGS[@]}" $files || fail "shfmt would reformat the files above; run scripts/format"
printf 'format-shell: %s shell file(s) formatted\n' "$(printf '%s\n' "$files" | grep -c .)"
