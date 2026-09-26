#!/usr/bin/env bash
# Every markdown file this repository owns passes markdownlint-cli2 under
# .markdownlint-cli2.jsonc (spec §8). Formatter first, then linter: prettier
# retires most findings free, and scripts/format runs --fix for the rest it can;
# what remains -- a fence with no language, a heading style -- is fixed by
# hand once.
# needs: markdownlint-cli2
. "$(dirname "$0")/lib.sh"

md="$(checked_markdown)"
[ -n "$md" ] || fail "checked '*.md' listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
markdownlint-cli2 $md || fail "markdownlint-cli2 reported the findings above"
printf 'lint-markdown: %s markdown file(s) clean\n' "$(printf '%s\n' "$md" | grep -c .)"
