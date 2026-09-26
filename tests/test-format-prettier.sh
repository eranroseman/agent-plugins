#!/usr/bin/env bash
# Every JSON, JSONC, YAML and markdown file this repository owns is formatted
# as prettier formats it under .prettierrc.yaml (spec §8). One list, asserted
# non-empty: on an empty list `prettier --check` exits 0 with only a stderr
# complaint (measured, 3.9.6), which is a false green. A file it has no
# parser for exits 2, which is why the list is filtered by extension.
# needs: prettier
. "$(dirname "$0")/lib.sh"

files="$(checked_prettier)"
[ -n "$files" ] || fail "checked_prettier() listed nothing"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
prettier --log-level warn --check $files || fail "prettier would reformat the files above; run scripts/format"
printf 'format-prettier: %s file(s) formatted\n' "$(printf '%s\n' "$files" | grep -c .)"
