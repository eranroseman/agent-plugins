#!/usr/bin/env bash
# Every reference to a file in a document this repository owns resolves (#59).
# Two forms: a relative markdown link, and the form this repository mostly
# uses, a path in backticks. A token in backticks is a
# candidate when it contains a slash; a trailing :N, :N-M or :N,M is dropped,
# and so is a leading ./. It resolves at the document's own directory, the
# repository root, or a plugin root (plugins/*/), so a spec or plan may name a
# path plugin-relative. Fenced blocks are not scanned, for either form: a tree
# diagram is a picture, not a reference, and a quoted manifest or command
# output is frozen.
# A span in backticks that carries whitespace is a command: each of its words is
# classified on its own once a NAME= prefix and surrounding quotes are dropped,
# except that a URL word keeps its NAME=-looking text, since the strip is
# skipped for a URL; a word that is not shaped like a path is command syntax,
# counted.
#
# What does not resolve is one of eight classes, each counted and printed so
# a zero is visible, or it fails naming the file, line and token:
#   1. a URL;
#   2. a name that is not a working-tree path by its shape: ~ (home), $
#      anywhere (a variable), / (absolute), " (quoted syntax), an elision (.../, …/, or
#      ending in ... or …), :( (git's own path syntax), refs/ (a git ref),
#      repos/ (a GitHub API route), .git/ (git's own directory, which a
#      linked worktree keeps elsewhere: never a working-tree path);
#   3. a placeholder or glob: <, *, ?, {, [, |;
#   4. an owner/repo slug, with an optional #ref or @ref: two segments whose
#      first is not a directory at any root, nor one git remembers there, so
#      a misspelled two-segment path is still checked, and so is one under a
#      directory a move removed;
#   5. a namespaced path: owner/repo:path or owner/repo@ref:path, the
#      other-repository convention CONTEXT.md sets, held like a slug to an
#      owner that is no directory here; a hex revision before the colon
#      (rev:path); or plugin@marketplace:key;
#   6. a path git check-ignore accepts: runtime-only, classified by the file
#      that ignores it;
#   7. a path declared absent by decision, in DECLARED_ABSENT below;
#   8. under docs/superpowers/ only, the history tier: a path git shows
#      deleted on this branch's history passes, since git history is the
#      archive; a renamed path fails naming its successor at HEAD, followed
#      through later renames; a path with no history is a typo and fails.
. "$(dirname "$0")/lib.sh"

cd "$REPO_ROOT" || fail "could not cd to the repository root"
[ "$(git rev-parse --is-shallow-repository)" = false ] \
  || fail "the history tier reads every commit and this clone is shallow; fetch the history (actions/checkout: fetch-depth: 0)"

# Paths named because they must not exist, or absent by a recorded decision.
DECLARED_ABSENT=(
  'hooks/hooks.json'        # the path Codex loads by fallback: named so nothing sits there
  'docs/adr/'               # docs/agents/domain.md names it; this repository keeps no ADRs (#26, #37)
  '.github/actionlint.yaml' # the runner-label override ubuntu-latest makes unnecessary (names-and-surface spec §14)
  'bin/setpu'               # the names-and-surface spec's example of a typo this test must catch
  'plugins/ghost/'          # the suite-and-ci spec's mutation, created and removed inside the mutation
  '.claude/settings.json'   # the project-scope file `claude plugin install --scope project` would write; named so it is never written
)

docs="$(checked_markdown)"
[ -n "$docs" ] || fail "checked_markdown() listed nothing; the ownership derivation went vacuous"

# ---- paths in backticks ----------------------------------------------------
# The roots a token resolves at, for a document in $1: its directory, the
# repository root, each plugin root.
roots_for() {
  printf '%s\n' "$1" .
  local p
  for p in plugins/*/; do printf '%s\n' "${p%/}"; done
}

# The history tier for $1, a path relative to the repository root. Sets
# TIER_VERDICT to `deleted`, `renamed <successor>`, or nothing when git has no
# commit for it, and caches the answer in TIER. Call it directly, never
# inside $(...), whose subshell would take the cache with it.
# A rename is read from the commit's own --name-status, never from a log over
# the old path, which reports a rename as a deletion (spec §22); a directory
# is read through the files under it. The chain is followed until a
# successor exists at HEAD or the file was deleted.
declare -A TIER=()
TIER_VERDICT=""
history_tier() {
  local p="$1"
  TIER_VERDICT=""
  case "$p" in ../*) return 0 ;; esac # outside the repository: git has nothing to say
  [ -n "${TIER[$p]+set}" ] || TIER[$p]="$(history_tier_walk "$p")"
  TIER_VERDICT="${TIER[$p]}"
}
history_tier_walk() {
  local p="$1" c line st new
  while :; do
    c="$(git log HEAD -1 --format=%h -- "$p")"
    [ -n "$c" ] || return 0
    line="$(git show --name-status -M --format= "$c" \
      | awk -F'\t' -v p="${p%/}" '
          $2 == p || index($2, p "/") == 1 {
            if ($1 ~ /^R/) { print; exit }
            seen = $0
          }
          END { if (seen != "") print seen }')"
    [ -n "$line" ] || return 0
    st="${line%%$'\t'*}"
    case "$st" in
      D*)
        printf 'deleted\n'
        return 0
        ;;
      R*)
        new="$(printf '%s' "$line" | cut -f3)"
        if [ -e "$new" ]; then
          printf 'renamed %s\n' "$new"
          return 0
        fi
        p="$new"
        ;;
      *)
        return 0
        ;;
    esac
  done
}

# A line that names a renamed path beside its successor is a rename record,
# not a stale reference: $1 the line, $2 the successor at HEAD. The successor
# counts when a span on the line names it, its basename, or a directory it
# sits under.
names_successor() {
  local line="$1" new="$2" span dir
  while IFS= read -r span; do
    span="${span#\`}"
    span="${span%\`}"
    span="${span%/}"
    [ -n "$span" ] || continue
    [ "$span" = "$new" ] && return 0
    [ "$span" = "${new##*/}" ] && return 0
    dir="${new%/*}"
    while [ "$dir" != "$new" ] && [ -n "$dir" ]; do
      [ "$span" = "$dir" ] && return 0
      case "$dir" in */*) dir="${dir%/*}" ;; *) break ;; esac
    done
  done < <(grep -o '`[^`]*`' <<<"$line")
  return 1
}

n_ok=0 n_url=0 n_shape=0 n_glob=0 n_slug=0 n_ns=0 n_ignored=0 n_declared=0 n_history=0 n_renamed=0 n_syntax=0
failures=""
cur_line=""

# $1 document, $2 line number, $3 the span as written, $4 the token to check.
classify() {
  local doc="$1" n="$2" raw="$3" tok="$4" r first isdir key verdict
  case "$tok" in
    *://* | mailto:*)
      n_url=$((n_url + 1))
      return
      ;;
    '~'* | *'$'* | /* | '"'* | .../* | …/* | *... | *… | ':('* | refs/* | repos/* | .git/*)
      n_shape=$((n_shape + 1))
      return
      ;;
    *'<'* | *'*'* | *'?'* | *'{'* | *'['* | *'|'*)
      n_glob=$((n_glob + 1))
      return
      ;;
  esac
  # Class 5, two shapes. A revision or a plugin@marketplace before the colon
  # is namespaced by shape alone. owner/repo before the colon is namespaced
  # only when owner is no directory at any root and none git remembers there,
  # the test class 4 applies to a slug, so a misspelled two-segment path with
  # a colon suffix is not one (#65).
  if printf '%s' "$tok" | grep -qE '^([0-9a-f]{7,40}|[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+):[^[:space:]]+'; then
    n_ns=$((n_ns + 1))
    return
  fi
  tok="${tok#./}"
  if printf '%s' "$tok" | grep -qE '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+((@[^:/]+)?:[^[:space:]]+|([#@][^/]+)?)$'; then
    first="${tok%%/*}"
    isdir=0
    while IFS= read -r r; do
      [ -d "$r/$first" ] && isdir=1
      # A directory a move removed is still this repository's, not an owner's:
      # upstream/ after the manifest moved to the root.
      key="$r/$first"
      key="${key#./}"
      case "$key" in .. | ../*) continue ;; esac
      history_tier "$key"
      [ -z "$TIER_VERDICT" ] || isdir=1
    done < <(roots_for "$(dirname "$doc")")
    if [ "$isdir" -eq 0 ]; then
      case "$tok" in
        *:*) n_ns=$((n_ns + 1)) ;;
        *) n_slug=$((n_slug + 1)) ;;
      esac
      return
    fi
  fi
  while IFS= read -r r; do
    if [ -e "$r/$tok" ]; then
      n_ok=$((n_ok + 1))
      return
    fi
  done < <(roots_for "$(dirname "$doc")")
  if git check-ignore -q -- "$tok" 2>/dev/null; then
    n_ignored=$((n_ignored + 1))
    return
  fi
  for r in "${DECLARED_ABSENT[@]}"; do
    if [ "$tok" = "$r" ]; then
      n_declared=$((n_declared + 1))
      return
    fi
  done
  case "$doc" in
    docs/superpowers/*)
      while IFS= read -r r; do
        if [ "$r" = . ]; then history_tier "$tok"; else history_tier "$r/$tok"; fi
        verdict="$TIER_VERDICT"
        case "$verdict" in
          deleted)
            n_history=$((n_history + 1))
            return
            ;;
          renamed*)
            if names_successor "$cur_line" "${verdict#renamed }"; then
              n_renamed=$((n_renamed + 1))
              return
            fi
            failures="$failures"$'\n'"$doc:$n: \`$raw\` names a file that was renamed; it is now ${verdict#renamed }"
            return
            ;;
        esac
      done < <(roots_for "$(dirname "$doc")")
      ;;
  esac
  failures="$failures"$'\n'"$doc:$n: \`$raw\` does not resolve at the document's directory, the repository root or any plugin root"
}

# One pass per document. A fence opens on a run of three or more backticks
# or tildes and closes on a run of the same character at least as long, so a
# four-backtick fence can quote a three-backtick one.
links=0
scanned=0
for f in $docs; do
  [ -f "$f" ] || fail "$f is tracked but absent from the working tree"
  scanned=$((scanned + 1))
  doc="$f"
  dir="$(dirname "$f")"
  n=0
  fence=""
  while IFS= read -r line; do
    n=$((n + 1))
    cur_line="$line"
    case "$line" in
      '```'* | '~~~'*)
        run="${line%%[^\`~]*}"
        if [ -z "$fence" ]; then
          fence="$run"
          continue
        elif [ "${run:0:1}" = "${fence:0:1}" ] && [ "${#run}" -ge "${#fence}" ]; then
          fence=""
          continue
        fi
        ;;
    esac
    [ -z "$fence" ] || continue
    # A markdown link: skip external URLs and bare anchors; drop an anchor.
    while IFS= read -r target; do
      [ -n "$target" ] || continue
      case "$target" in http://* | https://* | mailto:* | '#'*) continue ;; esac
      target="${target%%#*}"
      [ -n "$target" ] || continue
      links=$((links + 1))
      case "$target" in
        /*) resolved="$REPO_ROOT$target" ;;
        *) resolved="$dir/$target" ;;
      esac
      [ -e "$resolved" ] || failures="$failures"$'\n'"$f:$n: the link [$target] does not exist (looked at $resolved)"
    done < <(grep -oE '\]\([^)]+\)' <<<"$line" | while IFS= read -r t; do
      t="${t#"]("}"
      printf '%s\n' "${t%)}"
    done)
    while IFS= read -r span; do
      span="${span#\`}"
      span="${span%\`}"
      case "$span" in */*) ;; *) continue ;; esac
      case "$span" in
        *[[:space:]]*)
          read -ra words <<<"$span"
          for word in "${words[@]}"; do
            case "$word" in */*) ;; *) continue ;; esac
            case "$word" in
              *://* | mailto:*) ;;
              *) word="${word#*=}" ;;
            esac
            word="$(printf '%s' "$word" | sed -E "s/^[\"'(]+//; s/[\"'),;:]+\$//; s/([^.])\.\$/\\1/; s/:[0-9]+([-,][0-9]+)*\$//")"
            if printf '%s' "$word" | grep -qE '^[A-Za-z0-9_.@#~$-]+(/[A-Za-z0-9_.@#~$-]*)+$'; then
              classify "$doc" "$n" "$span" "$word"
            else
              n_syntax=$((n_syntax + 1))
            fi
          done
          ;;
        *)
          case "$span" in
            *://* | mailto:*) word="$span" ;;
            *) word="${span#*=}" ;;
          esac
          classify "$doc" "$n" "$span" "$(printf '%s' "$word" | sed -E "s/^[\"'(]+//; s/[\"'),;:]+\$//; s/([^.])\.\$/\\1/; s/:[0-9]+([-,][0-9]+)*\$//")"
          ;;
      esac
    done < <(grep -o '`[^`]*`' <<<"$line")
  done <"$f"
done

[ -z "$failures" ] || fail "these references do not resolve:$failures"
printf 'links-resolve: %s link(s) and %s backticked path(s) resolve across %s document(s); skipped %s URL(s), %s by shape, %s placeholder(s), %s slug(s), %s namespaced, %s ignored, %s declared absent, %s deleted in history, %s renamed beside the successor, %s command word(s)\n' \
  "$links" "$n_ok" "$scanned" "$n_url" "$n_shape" "$n_glob" "$n_slug" "$n_ns" "$n_ignored" "$n_declared" "$n_history" "$n_renamed" "$n_syntax"
