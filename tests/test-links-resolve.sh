#!/usr/bin/env bash
# Every relative markdown link in a maintained document must resolve. This is a
# regression guard, not a coverage check: it is satisfied by a document with no
# links at all, and it fires the first time someone adds one that is wrong.
#
# Scope is the documents this repository maintains. Specs and plans under
# docs/superpowers/ are excluded deliberately: they are frozen records of what
# was decided, never amended after the fact, so a link that breaks when a file
# moves is not something anyone would go back and fix. The vendored SKILL.md is
# excluded too — tests/test-vendored-scaffolder.sh pins its whole file set
# against upstream, which covers its five links.
. "$(dirname "$0")/lib.sh"

cd "$REPO_ROOT" || fail "could not cd to the repository root"

docs="README.md AGENTS.md CLAUDE.md"
for r in plugins/*/README.md; do [ -f "$r" ] && docs="$docs $r"; done

checked=0
scanned=0
for f in $docs; do
  [ -f "$f" ] || continue
  scanned=$((scanned + 1))
  dir="$(dirname "$f")"
  # [text](target) — skip external URLs and bare anchors
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in http://*|https://*|mailto:*|'#'*) continue ;; esac
    target="${target%%#*}"                       # drop any anchor
    [ -n "$target" ] || continue
    checked=$((checked + 1))
    case "$target" in
      /*) resolved="$REPO_ROOT$target" ;;
      *)  resolved="$dir/$target" ;;
    esac
    [ -e "$resolved" ] || fail "$f links [$target], which does not exist (looked at $resolved)"
  done < <(grep -oE '\]\([^)]+\)' "$f" | sed 's/^](//; s/)$//')
done

printf 'links-resolve: %s relative link(s) across %s maintained document(s) resolve\n' \
  "$checked" "$scanned"
