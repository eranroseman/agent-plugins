#!/usr/bin/env bash
# Every relative markdown link in a document this repository owns must
# resolve. A regression guard, not a coverage check: it is satisfied by a
# document with no links, and it fires the first time someone adds one that
# is wrong. The form this repository's references mostly take, a path in
# backticks, is #59 and not this test.
#
# Scope is every owned markdown file (spec §4), the specs and plans included.
# A spec is a maintained record: it moves when the tree moves, as a3c797f
# moved the hook design's §4.2 with the plugin rename. A plan freezes once
# executed, but a link path is not its prose, so a broken one is fixed. The
# vendored SKILL.md files are excluded by the derivation; their drift tests
# pin whole file sets against upstream, which covers their links.
. "$(dirname "$0")/lib.sh"

cd "$REPO_ROOT" || fail "could not cd to the repository root"

docs="$(checked '*.md')"
[ -n "$docs" ] || fail "checked '*.md' listed nothing; the ownership derivation went vacuous"

checked=0
scanned=0
for f in $docs; do
  [ -f "$f" ] || continue
  scanned=$((scanned + 1))
  dir="$(dirname "$f")"
  # [text](target) — skip external URLs and bare anchors
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in http://* | https://* | mailto:* | '#'*) continue ;; esac
    target="${target%%#*}" # drop any anchor
    [ -n "$target" ] || continue
    checked=$((checked + 1))
    case "$target" in
      /*) resolved="$REPO_ROOT$target" ;;
      *) resolved="$dir/$target" ;;
    esac
    [ -e "$resolved" ] || fail "$f links [$target], which does not exist (looked at $resolved)"
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed 's/^](//; s/)$//')
done

printf 'links-resolve: %s relative link(s) across %s owned document(s) resolve\n' \
  "$checked" "$scanned"
