#!/usr/bin/env bash
# Every shell file this repository authors is shellcheck clean, style and
# info findings included, at the shellcheck version tests/tools.txt declares.
# Two exclusions, both structural rather than per-site: SC1091 because the
# tests source lib.sh through a path shellcheck cannot follow, and SC2016
# because the expected-output strings are single-quoted on purpose and must
# not expand. The vendored skills' scripts are upstream's and are covered by
# the drift tests instead.
# needs: shellcheck
. "$(dirname "$0")/lib.sh"

files="$(checked_shell)"
[ -n "$files" ] || fail "checked_shell() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
shellcheck -e SC1091 -e SC2016 $files || fail "shellcheck reported problems"
printf 'lint-shell: %s shell file(s) clean\n' "$(printf '%s\n' "$files" | grep -c .)"
