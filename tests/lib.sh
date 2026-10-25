#!/usr/bin/env bash
# Shared helpers for tests/*.sh and scripts/format. Source this file; do not execute it.
set -euo pipefail
# A git hook can export an absolute GIT_DIR and GIT_INDEX_FILE (measured
# 2026-10-25); every git call in a file that sources this one (the tests,
# tests/install-check.sh and scripts/format) means REPO_ROOT or a scratch
# repository. tests/run.sh does not source it.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
VENDORED_JSON="$REPO_ROOT/vendored.json"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# ---- Pins: the subset entries and the records (spec §6, §7.2) ---------------
# The one git-subdir entry whose source.url is the repository $2's, as
# https://github.com/<owner>/<repo>.git: its field $1 (sha, or ref). A record
# without a pin of its own takes its pin here (T24); no match, or more than
# one, fails.
entry_field_for_repo() {
  local field="$1" repo="$2" vals n
  vals="$(jq -r --arg u "https://github.com/$repo.git" --arg f "$field" \
    '.plugins[] | select(.source.source? == "git-subdir" and .source.url == $u) | .source[$f]' "$MARKETPLACE")" \
    || fail "could not read $MARKETPLACE"
  n="$(printf '%s\n' "$vals" | grep -c . || true)"
  [ "$n" -eq 1 ] || fail "$n subset entries pin $repo; a record without a pin of its own needs exactly one"
  printf '%s\n' "$vals"
}
upstream_sha() { entry_field_for_repo sha "$1"; }
upstream_ref() { entry_field_for_repo ref "$1"; }

# One line per record of vendored.json: repo, ref, sha, tab-separated, the
# pin resolved: a record carries both ref and sha, or neither and takes its
# entry's; one without the other fails, so a record that loses its sha by
# mistake is never skipped. Every record carries a repo, and trees and forks,
# {} when empty; one without fails, so no record is skipped. jq hands the
# fields over joined by the unit separator, which is not IFS whitespace, so a
# record's empty ref and sha survive the read. A fail inside upstream_ref or
# upstream_sha ends only its command substitution, having printed its FAIL,
# so each capture exits on the status rather than failing a second time.
record_rows() {
  local repo ref sha
  jq -e '.records | type == "array" and length > 0' "$VENDORED_JSON" >/dev/null 2>&1 \
    || fail "$VENDORED_JSON carries no records array"
  jq -e '[.records[] | (.repo | type == "string" and length > 0) and (.trees | type == "object") and (.forks | type == "object")] | all' "$VENDORED_JSON" >/dev/null 2>&1 \
    || fail "a record in $VENDORED_JSON lacks a repo, a trees object or a forks object"
  while IFS=$'\x1f' read -r repo ref sha; do
    if [ -z "$ref" ] && [ -z "$sha" ]; then
      ref="$(upstream_ref "$repo")" || exit 1
      sha="$(upstream_sha "$repo")" || exit 1
    elif [ -z "$ref" ] || [ -z "$sha" ]; then
      fail "the $repo record carries one of ref and sha without the other"
    fi
    [ "${#sha}" -eq 40 ] || fail "$repo: the pinned sha is not 40 characters: '$sha'"
    printf '%s\t%s\t%s\n' "$repo" "$ref" "$sha"
  done < <(jq -r '.records[] | [.repo, (.ref // ""), (.sha // "")] | join("\u001f")' "$VENDORED_JSON")
}

# The pairs of the $1 map (trees or forks) of the record $2: local path, then
# upstream path, tab-separated, one per line.
record_map() {
  jq -r --arg m "$1" --arg r "$2" '.records[] | select(.repo == $r) | .[$m] | to_entries[] | [.key, .value] | @tsv' "$VENDORED_JSON"
}
# Every copy's path, and every fork's, one per line, across every record.
tree_keys() { jq -r '.records[].trees | keys[]' "$VENDORED_JSON"; }
fork_keys() { jq -r '.records[].forks | keys[]' "$VENDORED_JSON"; }

# The path of the cache $1 under this user's cache directory, where
# tests/test-upstream.sh keeps its checkouts and tests/test-codex-validate.sh
# its validator: not under ${TMPDIR:-/tmp}, a predictable path another local
# user can pre-create (#73, #81). Each caller still refuses a cache this user
# does not own. XDG_CACHE_HOME counts only when absolute, as the XDG spec
# says: a relative one would put the caches inside the checkout, where
# tests/run.sh refuses the next run. A fail here ends only the caller's
# command substitution, so each capture exits on the status.
cache_dir() {
  local base
  case "${XDG_CACHE_HOME:-}" in
    /*) base="$XDG_CACHE_HOME" ;;
    *)
      case "${HOME:-}" in
        /*) base="$HOME/.cache" ;;
        *) fail "no HOME and no absolute XDG_CACHE_HOME; nowhere to keep the cache" ;;
      esac
      ;;
  esac
  printf '%s/software-dev/%s\n' "$base" "$1"
}

# Shallow-fetch $1 (a git URL) at commit $2 into $3 and print the path.
# Reuses an existing checkout only when this user owns it, its HEAD is the pin
# and its working tree is clean, untracked and ignored files included whatever
# status.showUntrackedFiles says: callers compare the tree's bytes, and `find`
# lists what git ignores. Ownership is tested before any git command runs
# there: git runs the core.fsmonitor of a repository another user planted
# wherever safe.directory, the only other guard, lets it, and
# `safe.directory = *` or a git without the April 2022 ownership check
# (CVE-2022-24765) lets it everywhere. Anything else is removed and fetched
# again. Every command is guarded here rather than at the call sites. A caller
# writing `UP="$(fetch_pinned ...)" || fail ...` suspends set -e inside this
# function, so an unguarded mid-function failure would fall through to the
# closing printf and return 0, making that `|| fail` dead code.
fetch_pinned() {
  local url="$1" sha="$2" dir="$3" dirt
  [ "${#sha}" -eq 40 ] || fail "fetch_pinned needs a 40-char sha (got '$sha')"
  if [ -O "$dir" ] && [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ] \
    && dirt="$(git -C "$dir" status --porcelain --ignored --untracked-files=normal)" && [ -z "$dirt" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir" || fail "could not remove $dir to fetch it again; a cache this user cannot clear, or does not own, is never reused"
  mkdir -p "$dir" || fail "could not create $dir"
  git -C "$dir" init -q || fail "git init failed in $dir"
  git -C "$dir" remote add origin "$url" || fail "git remote add failed in $dir"
  git -C "$dir" fetch -q --depth 1 origin "$sha" \
    || fail "could not fetch $url at $sha into $dir (no network, or the pinned sha is gone)"
  git -C "$dir" checkout -q FETCH_HEAD || fail "could not check out FETCH_HEAD in $dir"
  [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ] \
    || fail "$url: the checkout's HEAD is $(git -C "$dir" rev-parse HEAD), not the pinned $sha; an annotated tag's object was pinned where its commit should be"
  printf '%s\n' "$dir"
}

# The commit the tag $2 names at $1, a URL: the peeled object of an annotated
# tag, the tag itself for a lightweight one; empty when there is no such tag.
peel_tag() {
  local sha
  sha="$(git ls-remote --tags "$1" "refs/tags/$2^{}" | cut -f1)"
  [ -n "$sha" ] || sha="$(git ls-remote --tags "$1" "refs/tags/$2" | cut -f1)"
  printf '%s\n' "$sha"
}

# A fixture PATH: $1 is the directory, created if absent, and every later
# argument a tool linked into it from wherever this shell resolves it, so the
# script under test sees those names and nothing else. Callers write their
# stubs -- a shfmt that reports a version the registry does not declare --
# beside the links.
link_tools() {
  local dir="$1" t p
  shift
  mkdir -p "$dir" || fail "could not create $dir"
  for t in "$@"; do
    p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
    ln -sf "$p" "$dir/$t" || fail "could not link $t into $dir"
  done
}

# ---- The marketplace's subset entries (spec §6) -----------------------------
# One line per git-subdir entry: name, url, path, ref, sha, version,
# tab-separated; version empty when the entry declares none.
entry_rows() {
  jq -r '.plugins[] | select(.source.source? == "git-subdir")
         | [.name, .source.url, .source.path, .source.ref, .source.sha, (.version // "")] | @tsv' "$MARKETPLACE" \
    || fail "could not read the subset entries from $MARKETPLACE"
}

# The last segment of each path the entry $1 lists, one per line: the skill
# names both agent CLIs show under the entry's prefix. split/last rather than
# a basename pipe, which drew a false SIGPIPE failure under pipefail in scratch.
entry_skills() {
  jq -r --arg n "$1" '.plugins[] | select(.name == $n) | .skills[]? | split("/") | last' "$MARKETPLACE" \
    || fail "could not read the skills of the entry $1 from $MARKETPLACE"
}

# ---- Shipped texts (spec §10.2) ----------------------------------------------
# Every text an agent reads from a local plugin: the markdown under every
# skill, every plugin agent, and every skill's Codex policy file, copies and
# forks included; not READMEs, which name retired skills on purpose. Read by
# tests/test-plugin-skills.sh's scan and by tests/install-check.sh's check of
# the UNPINNED plugins' references (T47). Tracked, not present, like checked().
shipped_texts() {
  git -C "$REPO_ROOT" -c core.quotePath=false ls-files 'plugins/*/skills/**/*.md' 'plugins/*/agents/*.md' 'plugins/*/skills/*/agents/openai.yaml'
}

# The plugins the README's blocks install from their upstreams' own
# marketplaces, unpinned (Q78, Q88): the prefix their skills carry on both
# agent CLIs, then the Claude Code install id. No entry here lists their
# skills, so tests/test-plugin-skills.sh carves their references out and
# tests/install-check.sh asserts each against what installed.
UNPINNED=(
  $'superpowers\tsuperpowers@superpowers-marketplace'
  $'writing-clearly-and-concisely\twriting-clearly-and-concisely@agent-toolkit'
)
# True when $1 is an UNPINNED prefix.
unpinned_prefix() {
  local u
  for u in "${UNPINNED[@]}"; do [ "${u%%$'\t'*}" = "$1" ] && return 0; done
  return 1
}

# The frontmatter `name` of the SKILL.md in the directory $1 equals the
# directory's name, which both agent CLIs dispatch by. $2 labels the failure.
skill_name_matches() {
  local dir="$1" label="${2:-$1}" name
  [ -f "$dir/SKILL.md" ] || fail "$label has no SKILL.md"
  name="$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } /^name:/ { sub(/^name:[ ]*/, ""); print; exit }' "$dir/SKILL.md")"
  [ "$name" = "$(basename "$dir")" ] \
    || fail "$label: frontmatter name '$name' is not the directory name '$(basename "$dir")'; both agent CLIs dispatch by name"
}

# True when the Codex policy file $1 keeps its skill out of the model's
# catalogue: the skill is user-invocable only on Codex.
user_invocable_only() { [ -f "$1" ] && grep -qx '  allow_implicit_invocation: false' "$1"; }

# ---- Ownership (spec §7.2, Q62) ---------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: a copy, a tree in a record's `trees` map, which is
# upstream's bytes at the pin and is held there by tests/test-upstream.sh. A
# fork is first-party and is linted. The exclusion is derived from
# vendored.json, so a copy that leaves the records joins the linters the same
# moment, and tests/test-ownership.sh holds the derivation: every trees key a
# tracked directory checked() does not list, every forks key one it lists.
EXCLUDED="$(jq -r '[.records[].trees | keys[]] | map("^" + . + "/") | join("|")' "$VENDORED_JSON")" \
  || {
    printf 'FAIL: could not derive the excluded trees from vendored.json\n' >&2
    exit 1
  }
[ -n "$EXCLUDED" ] || EXCLUDED='^$'

# Tracked files this repository owns, one path per line relative to
# REPO_ROOT. Arguments are git pathspecs: checked '*.md', or
# checked '*.md' ':(exclude)docs/superpowers'. `git -C`, never bare: ls-files
# is cwd-relative and this file never changes directory. Tracked, not
# present: a new file joins when it is staged, which is also the moment
# anything else in the repository notices it, and a branch's worktree under
# .claude/worktrees/ that a `find` would see is not listed. tests/run.sh
# refuses to run while a file is neither tracked nor ignored (#72), so nothing
# it runs notices a new file that is not ignored before it is staged. Every
# caller asserts the list is non-empty: an empty list is a false green for
# most tools.
checked() {
  git -C "$REPO_ROOT" ls-files "$@" | { grep -vE "$EXCLUDED" || true; }
}

# The shell files: every checked file whose first line is the bash shebang.
# By shebang, not extension: the two scripts have none. Arguments narrow the
# list the same way checked's do. A tracked file absent from the working tree
# is a FAIL by name, not a silently shorter list: head's failure is not
# swallowed (#61 M4).
checked_shell() {
  local f line
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$REPO_ROOT/$f" ] || fail "$f is tracked but absent from the working tree"
    line="$(head -n 1 "$REPO_ROOT/$f")" || fail "could not read the first line of $f"
    if [ "$line" = '#!/usr/bin/env bash' ]; then
      printf '%s\n' "$f"
    fi
  done < <(checked "$@")
}

# The formatters' lists, spelled once (#62): what jq reads, what prettier
# formats (its jsonc parser covers .markdownlint-cli2.jsonc), what
# markdownlint and cspell read. Each takes further pathspecs the way checked
# does, so a caller can exclude a directory.
checked_json() { checked '*.json' "$@"; }
checked_yaml() { checked '*.yml' '*.yaml' "$@"; }
checked_markdown() { checked '*.md' "$@"; }
checked_prettier() { checked '*.json' '*.jsonc' '*.yml' '*.yaml' '*.md' "$@"; }

# shfmt's flags, read by tests/test-format-shell.sh and scripts/format (spec
# §8.1): the set measured closest to the code as written, 17 files and 272
# lines at aa8e78d; -sr was dropped because it restyled a further 140 lines.
# shellcheck disable=SC2034  # read by the test and by scripts/format
SHFMT_FLAGS=(-i 2 -ci -bn)
