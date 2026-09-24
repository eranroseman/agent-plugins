#!/usr/bin/env bash
# Every JSON, YAML and markdown file this repository owns is formatted as
# prettier formats it under .prettierrc.yaml (spec §8). Three lists, each
# asserted non-empty: on an empty list `prettier --check` exits 0 with only
# a stderr complaint (measured, 3.9.6), which is a false green. A file it has
# no parser for exits 2, which is why the lists are filtered by extension.
# needs: prettier
. "$(dirname "$0")/lib.sh"

json="$(checked '*.json')"
[ -n "$json" ] || fail "checked '*.json' listed nothing"
yaml="$(checked '*.yml' '*.yaml')"
[ -n "$yaml" ] || fail "checked '*.yml' '*.yaml' listed nothing"
md="$(checked '*.md')"
[ -n "$md" ] || fail "checked '*.md' listed nothing"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
prettier --log-level warn --check $json $yaml $md || fail "prettier would reformat the files above; run scripts/format"
printf 'format-prettier: %s JSON, %s YAML, %s markdown file(s) formatted\n' \
  "$(printf '%s\n' "$json" | grep -c .)" "$(printf '%s\n' "$yaml" | grep -c .)" "$(printf '%s\n' "$md" | grep -c .)"
