#!/usr/bin/env bash
# The owned prose is spelled in US English (spec §8.1): the markdown outside
# the three record directories under docs/ (superpowers, research, archive),
# whose vocabulary is each author's and would triple the dictionary, plus the
# `#` comments of the shell and YAML files through cspell.config.yaml's
# override. A typo is fixed; a term is added to the config's word list. A
# spelling inside an authored SKILL.md is an edit to the skill and goes
# through superpowers:writing-skills.
# needs: cspell
. "$(dirname "$0")/lib.sh"

md="$(checked '*.md' ':(exclude)docs/superpowers' ':(exclude)docs/research' ':(exclude)docs/archive')"
[ -n "$md" ] || fail "the markdown list in cspell's scope is empty"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
yaml="$(checked '*.yml' '*.yaml')"
[ -n "$yaml" ] || fail "checked '*.yml' '*.yaml' listed nothing"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
cspell --no-progress $md $shell $yaml \
  || fail "cspell reported the words above: fix a typo, or add a term to cspell.config.yaml"
printf 'spelling: %s markdown, %s shell and %s YAML file(s) spelled\n' \
  "$(printf '%s\n' "$md" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)" "$(printf '%s\n' "$yaml" | grep -c .)"
