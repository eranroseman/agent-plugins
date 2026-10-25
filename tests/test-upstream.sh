#!/usr/bin/env bash
# The one test that holds this repository to its upstreams (spec §7.3, T45):
# every record of vendored.json and every subset entry of the marketplace,
# each pin fetched once.
#
# For each record: the pin fetches and the checkout's HEAD is the pin; a tag
# ref peels to the sha; each copy (a `trees` pair) equals upstream at the pin
# in file set, bytes and modes, except the declared changes in DECLARED, each
# of which must still differ from upstream and whose upstream side must be
# present exactly once upstream (§7.1); and the LICENSE of each plugin the
# record's paths lie under carries a section opening with the repository's
# URL whose Copyright lines equal upstream's LICENSE's at the pin (§7.4).
# A section for a repository no record holds fails.
#
# For each entry: `strict` is false, since with a manifest under `path`,
# `strict: true` would take upstream's manifest and widen the entry silently,
# where `strict: false` and the skills list fail to load instead (§6.4); a tag
# ref peels to the sha; no plugin manifest and no hooks/hooks.json sits under
# `path` at the pin, and a `skills` directory there, where one exists, holds
# only listed skills, so a default scan adds nothing (T34); each listed path
# holds a SKILL.md named after its directory; `version` equals upstream's
# .claude-plugin/plugin.json where upstream has one; and the basenames of the
# skill directories under `path`, a duplicate itself a failure, equal the
# listed skills plus the declared exclusions in EXCLUSIONS, disjoint, so a new
# upstream skill is a decision at the next bump rather than a silent omission.
# No complement is kept beyond `path`: an upstream may ship a skill twice, at
# different paths, and a complement over the repository would fail on every
# name.
#
# Bare sibling names (T44): for a record whose pin is its entry's, every
# upstream skill name that a listed skill at the pin, a copy or a fork names
# as /name or in backticks must be one a marketplace entry delivers. The
# mattpocock record resolves through its entry, so the check runs on every
# suite run and must check at least one name.
# Needs network.
. "$(dirname "$0")/lib.sh"

# ---- Declared changes (§7.1, T25, T46) --------------------------------------
# One row per change: the local path, a kind, an anchor and the reason, tab-
# separated. `line`: the anchor is upstream's whole line, present exactly once
# in upstream's file; the local line at the same position, counted after the
# `added` lines are removed, differs, and the two files are equal with that
# line removed from both. `added`: the anchor is a line absent upstream and
# present exactly once locally, removed from the local side before the diff;
# the anchor <file> declares the whole file absent upstream. Every local
# change to a third-party skill needs a stated reason, and being new is not
# one; the wording of our side is asserted nowhere (§11.3).
DECLARED=(
  $'plugins/software-dev/skills/diagnosing-bugs/SKILL.md\tline\tdescription: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.\tupstream\'s triggers overlap superpowers:systematic-debugging\'s almost entirely; the rewrite was measured against a control (roster spec §6.1)'
  $'plugins/software-dev/skills/adhd/SKILL.md\tadded\tdisable-model-invocation: true\tthe invocation gate, Claude Code\'s half: about ten agent calls, a cost only the user can authorize'
  $'plugins/software-dev/skills/adhd/agents/openai.yaml\tadded\t<file>\tthe invocation gate, Codex\'s half'
)

# ---- Declared exclusions, per entry (§7.3, T36) -----------------------------
# Lines of `skill<TAB>reason`: the skill directories under the entry's path
# that the entry does not list, each with one reason. An exclusion upstream
# no longer has fails; so does a listed skill that is also excluded.
declare -A EXCLUSIONS=(
  ["mattpocock"]=$'diagnosing-bugs\tsoftware-dev ships a copy with a changed description (§11.2)
setup-matt-pocock-skills\tsoftware-dev ships it forked under the same name (Q81)
to-spec\tcollides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)
to-tickets\tcollides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)
implement\tcollides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)
tdd\tcollides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)
code-review\tcollides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)
grill-me\ta four-line alias whose whole body calls grilling, which the entry lists (ruling of 2026-09-16)
ask-matt\tnever evaluated; surfaced by the complement check on 2026-09-16
claude-handoff\tnever evaluated; surfaced by the complement check on 2026-09-16
git-guardrails-claude-code\tnever evaluated; surfaced by the complement check on 2026-09-16
loop-me\tnever evaluated; surfaced by the complement check on 2026-09-16
migrate-to-shoehorn\tnever evaluated; surfaced by the complement check on 2026-09-16
scaffold-exercises\tnever evaluated; surfaced by the complement check on 2026-09-16
setup-pre-commit\tnever evaluated; surfaced by the complement check on 2026-09-16
setup-ts-deep-modules\tnever evaluated; surfaced by the complement check on 2026-09-16
writing-beats\tnever evaluated; surfaced by the complement check on 2026-09-16
writing-fragments\tnever evaluated; surfaced by the complement check on 2026-09-16
writing-shape\tnever evaluated; surfaced by the complement check on 2026-09-16
implement-spec\timplements the output of /to-spec and /to-tickets, which superpowers\' slot excludes (Q85)
pr\tnever evaluated; new at v1.3.0, surfaced by the v1.3.1 complement; a candidate on #48 (Q85)
retro\tnever evaluated; new at v1.3.0, surfaced by the v1.3.1 complement; a candidate on #48 (Q85)'
)

cache_for() { cache_dir "upstream-$(tr / - <<<"$1")"; }

# The declared rows for the local path $1: kind, anchor, reason, tab-separated.
declared_for() {
  local r
  for r in "${DECLARED[@]}"; do
    if [ "${r%%$'\t'*}" = "$1" ]; then printf '%s\n' "${r#*$'\t'}"; fi
  done
}

# The length of the run of newlines that ends the file $1, 0 when its last
# byte is not a newline: what $(cat) strips, which the diff in compare_file
# therefore never sees.
eol_run() {
  local all body
  all="$(wc -c <"$1")" || fail "could not read $1"
  body="$(cat "$1")" || fail "could not read $1"
  printf '%s\n' "$((all - $(printf '%s' "$body" | wc -c)))"
}

# Upstream's file $3 against the local file $2, both named $1 in messages,
# under the declared rows for $1 (§7.1's two rules).
compare_file() {
  local key="$1" lf="$2" uf="$3" rows kind anchor reason loc up n pos lrun urun
  rows="$(declared_for "$key")"
  if [ -z "$rows" ]; then
    cmp -s "$uf" "$lf" || fail "$key differs from upstream at the pin, with no declared change"
    return
  fi
  loc="$(cat "$lf")"
  up="$(cat "$uf")"
  while IFS=$'\t' read -r kind anchor reason; do
    if [ "$kind" != added ] || [ "$anchor" = '<file>' ]; then continue; fi
    n="$(grep -cxF -- "$anchor" <<<"$loc" || true)"
    [ "$n" -eq 1 ] || fail "$key: the declared addition '$anchor' appears $n times locally, not once"
    if grep -qxF -- "$anchor" <<<"$up"; then fail "$key: the declared addition '$anchor' is present upstream at the pin; retire the declared change"; fi
    loc="$(grep -vxF -- "$anchor" <<<"$loc" || true)"
  done <<<"$rows"
  while IFS=$'\t' read -r kind anchor reason; do
    [ "$kind" = line ] || continue
    n="$(grep -cxF -- "$anchor" <<<"$up" || true)"
    [ "$n" -eq 1 ] || fail "$key: the declared line's upstream side appears $n times upstream at the pin, not once; retire or re-anchor the declared change ($reason)"
    pos="$(grep -nxF -- "$anchor" <<<"$up" | cut -d: -f1)"
    [ "$(sed -n "${pos}p" <<<"$loc")" != "$anchor" ] \
      || fail "$key: the declared change at line $pos was reverted; it equals upstream's line ($reason)"
    loc="$(sed "${pos}d" <<<"$loc")"
    up="$(sed "${pos}d" <<<"$up")"
  done <<<"$rows"
  diff <(printf '%s\n' "$up") <(printf '%s\n' "$loc") \
    || fail "$key differs from upstream at the pin beyond its declared changes"
  lrun="$(eol_run "$lf")" || exit 1
  urun="$(eol_run "$uf")" || exit 1
  [ "$lrun" = "$urun" ] \
    || fail "$key: the last bytes differ from upstream's at the pin (an end-of-file newline)"
}

# The copy $2 (a REPO_ROOT-relative path) against $3 (a path under the
# checkout $4) of the repository $1: file set, modes, bytes.
compare_tree() {
  local repo="$1" local_path="$2" up_path="$3" U="$4" f up_files loc_files added lmode umode
  [ -d "$U/$up_path" ] || fail "$repo has no $up_path at its pin"
  up_files="$(cd "$U/$up_path" && find . -type f | sed 's#^\./##' | sort)"
  loc_files="$(git -C "$REPO_ROOT" -c core.quotePath=false ls-files -- "$local_path" | sed "s#^$local_path/##" | sort)"
  added="$(for r in "${DECLARED[@]}"; do
    if [ "$(cut -f2 <<<"$r")" = added ] && [ "$(cut -f3 <<<"$r")" = '<file>' ]; then
      case "${r%%$'\t'*}" in "$local_path"/*) printf '%s\n' "${r%%$'\t'*}" | sed "s#^$local_path/##" ;; esac
    fi
  done | sort)"
  diff <(printf '%s\n' "$up_files" "$added" | grep . | sort) <(printf '%s\n' "$loc_files") \
    || fail "$local_path: the file set is not upstream's at the pin plus the declared additions (upstream above, local below)"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if printf '%s\n' "$added" | grep -qxF -- "$f"; then
      [ ! -e "$U/$up_path/$f" ] || fail "$local_path/$f is declared an addition but upstream ships it at the pin"
      continue
    fi
    lmode="$(git -C "$REPO_ROOT" ls-files -s -- "$local_path/$f" | cut -d' ' -f1)"
    umode="$(git -C "$U" ls-files -s -- "$up_path/$f" | cut -d' ' -f1)"
    [ "$lmode" = "$umode" ] || fail "$local_path/$f has mode $lmode; upstream's at the pin is $umode"
    compare_file "$local_path/$f" "$REPO_ROOT/$local_path/$f" "$U/$up_path/$f"
    FILES=$((FILES + 1))
  done <<<"$loc_files"
}

# The section of the LICENSE $1 opening with the URL $2: from that line to the
# next line of dashes (T26). Empty when there is none.
license_section() {
  awk -v u="$2" '
    /^-{10,}$/ { if (inside) exit; expect = 1; next }
    expect && $0 == u { inside = 1 }
    { expect = 0 }
    inside { print }
  ' "$1"
}

# The Copyright lines of the section for $1 in each plugin LICENSE its paths
# lie under equal, as a set, upstream's LICENSE's at the pin (T6, T8).
check_copyright() {
  local repo="$1" U="$2" want got p lic section
  [ -f "$U/LICENSE" ] || fail "$repo ships no LICENSE at its pin; nothing then grants the copy"
  want="$({ grep '^Copyright' "$U/LICENSE" || true; } | sort -u)"
  [ -n "$want" ] || fail "$repo's LICENSE at the pin carries no Copyright line"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    lic="$REPO_ROOT/plugins/$p/LICENSE"
    [ -f "$lic" ] || fail "plugins/$p has no LICENSE"
    section="$(license_section "$lic" "https://github.com/$repo")"
    [ -n "$section" ] || fail "plugins/$p/LICENSE has no section opening with https://github.com/$repo"
    got="$({ grep '^Copyright' <<<"$section" || true; } | sort -u)"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") \
      || fail "plugins/$p/LICENSE's section for $repo does not carry upstream's Copyright line(s) at the pin (upstream above, ours below)"
    SECTIONS=$((SECTIONS + 1))
  done < <({
    record_map trees "$repo"
    record_map forks "$repo"
  } | cut -f1 | cut -d/ -f2 | sort -u)
}

# T44, for the record $2 whose pin is the entry $1's: every upstream skill name
# ($6, one per line) that a listed skill ($5, paths under $4 in the checkout
# $3), a copy or a fork names as /name or in backticks is delivered by a
# marketplace entry.
sibling_names() {
  local repo="$2" U="$3" path="$4" listed="$5" up_names="$6" delivered files f names n
  delivered="$({
    for d in "$REPO_ROOT"/plugins/*/skills/*/; do basename "$d"; done
    while IFS=$'\t' read -r e _; do
      if [ -n "$e" ]; then entry_skills "$e"; fi
    done < <(entry_rows)
  } | sort -u)"
  files="$({
    while IFS= read -r lp; do
      [ -n "$lp" ] || continue
      find "$U/$path/$lp" -name '*.md' -type f
    done <<<"$listed"
    {
      record_map trees "$repo"
      record_map forks "$repo"
    } | cut -f1 | while IFS= read -r k; do
      tracked="$(git -C "$REPO_ROOT" -c core.quotePath=false ls-files -- "$k")" || fail "git ls-files failed for $k"
      printf '%s\n' "$tracked" | { grep '\.md$' || true; } | while IFS= read -r p; do printf '%s/%s\n' "$REPO_ROOT" "$p"; done
    done
  })"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    names="$({
      grep -oE '(^|[^A-Za-z0-9_/-])/[a-z][a-z0-9-]+' "$f" | sed -E 's#^.*/##'
      grep -oE '`[a-z][a-z0-9-]+`' "$f" | tr -d '`'
    } | sort -u | grep -xF -f <(printf '%s\n' "$up_names") || true)"
    for n in $names; do
      grep -qxF -- "$n" <<<"$delivered" \
        || fail "${f#"$REPO_ROOT"/} names $n, a $repo skill no marketplace entry delivers (T44)"
      SIBLINGS=$((SIBLINGS + 1))
    done
  done <<<"$files"
}

RECORDS=0 FILES=0 SECTIONS=0 ENTRIES=0 EXCLUDED_N=0 SIBLINGS=0

# Every declared row names a tracked file under a copy and one of the two
# kinds, so a stale or mistyped row fails by name before any fetch.
for r in "${DECLARED[@]}"; do
  p="${r%%$'\t'*}"
  under=0
  while IFS= read -r key; do
    case "$p" in "$key"/*) under=1 ;; esac
  done < <(tree_keys)
  [ "$under" -eq 1 ] || fail "the declared change for $p names a path under no copy in vendored.json"
  kind="$(cut -f2 <<<"$r")"
  case "$kind" in
    line | added) ;;
    *) fail "the declared change for $p has the kind '$kind'; the kinds are line and added" ;;
  esac
  [ "$(git -C "$REPO_ROOT" -c core.quotePath=false ls-files -- ":(literal)$p")" = "$p" ] \
    || fail "the declared change for $p names a path that is not a tracked file"
done

# ---- The records -------------------------------------------------------------
# Captured first: read through process substitution, a record_rows failure
# would end the loop early and be lost, and the run would go red only later.
rows="$(record_rows)"
while IFS=$'\t' read -r repo ref sha; do
  [ -n "$repo" ] || continue
  url="https://github.com/$repo.git"
  U="$(fetch_pinned "$url" "$sha" "$(cache_for "$repo")")"
  heads="$(git ls-remote "$url" "refs/heads/$ref")" || fail "$repo: could not list the refs of $url (no network?)"
  if [ -z "$heads" ]; then
    peeled="$(peel_tag "$url" "$ref")"
    [ -n "$peeled" ] || fail "$repo: $ref is neither a branch nor a tag at $url"
    [ "$peeled" = "$sha" ] || fail "$repo: the tag $ref names $peeled, not the pinned $sha; move ref and sha together"
  fi
  while IFS=$'\t' read -r local_path up_path; do
    [ -n "$local_path" ] || continue
    compare_tree "$repo" "$local_path" "$up_path" "$U"
  done < <(record_map trees "$repo")
  while IFS=$'\t' read -r local_path up_path; do
    [ -n "$local_path" ] || continue
    [ -d "$U/$up_path" ] || fail "$repo: the fork $local_path began from $up_path, which the pin no longer has; re-read the record"
  done < <(record_map forks "$repo")
  check_copyright "$repo" "$U"
  RECORDS=$((RECORDS + 1))
done <<<"$rows"
[ "$RECORDS" -gt 0 ] || fail "vendored.json holds no record"

# A section for a repository no record holds.
for lic in "$REPO_ROOT"/plugins/*/LICENSE; do
  while IFS= read -r url; do
    [ -n "$url" ] || continue
    record_rows | cut -f1 | grep -qxF -- "${url#https://github.com/}" \
      || fail "${lic#"$REPO_ROOT"/} has a section for $url, which no record holds"
  done < <(awk '/^-{10,}$/ { expect = 1; next } expect && /^https:\/\/github\.com\// { print } { expect = 0 }' "$lic")
done

# ---- The entries -------------------------------------------------------------
# Every EXCLUSIONS key names a subset entry, so an entry that leaves the
# marketplace cannot leave its exclusions behind.
for k in "${!EXCLUSIONS[@]}"; do
  entry_rows | cut -f1 | grep -qxF -- "$k" || fail "EXCLUSIONS names $k, which is no subset entry of the marketplace; retire it"
done
while IFS=$'\t' read -r name url path ref sha version; do
  [ -n "$name" ] || continue
  repo="${url#https://github.com/}"
  repo="${repo%.git}"
  U="$(fetch_pinned "$url" "$sha" "$(cache_for "$repo")")"
  [ "$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .strict' "$MARKETPLACE")" = false ] \
    || fail "$name: strict must be false; see the header comment"
  heads="$(git ls-remote "$url" "refs/heads/$ref")" || fail "$name: could not list the refs of $url (no network?)"
  if [ -z "$heads" ]; then
    peeled="$(peel_tag "$url" "$ref")"
    [ -n "$peeled" ] || fail "$name: $ref is neither a branch nor a tag at $url"
    [ "$peeled" = "$sha" ] || fail "$name: the tag $ref names $peeled, not the pinned $sha; move ref and sha together"
  fi
  [ -d "$U/$path" ] || fail "$name: no $path at the pin"
  manifests="$(cd "$U/$path" && find . -path '*/.claude-plugin/plugin.json' -o -path '*/.codex-plugin/plugin.json' -o -path './plugin.json')"
  [ -z "$manifests" ] || fail "$name: a plugin manifest sits under $path at the pin, which neither agent CLI reads the entry under:"$'\n'"$manifests"
  [ ! -e "$U/$path/hooks/hooks.json" ] || fail "$name: $path/hooks/hooks.json exists at the pin; Codex would load it"
  listed="$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .skills[] | sub("^\\./"; "")' "$MARKETPLACE")"
  [ -n "$listed" ] || fail "$name lists no skill"
  if [ -d "$U/$path/skills" ]; then
    for d in "$U/$path"/skills/*/; do
      [ -f "$d/SKILL.md" ] || continue
      rel="skills/$(basename "$d")"
      grep -qxF -- "$rel" <<<"$listed" || fail "$name: $path/$rel holds a skill the entry does not list; a default scan would add it"
    done
  fi
  while IFS= read -r lp; do
    [ -n "$lp" ] || continue
    skill_name_matches "$U/$path/$lp" "$name: $lp"
  done <<<"$listed"
  if [ -f "$U/.claude-plugin/plugin.json" ]; then
    upv="$(jq -r '.version // empty' "$U/.claude-plugin/plugin.json")"
    if [ -n "$upv" ]; then
      [ "$upv" = "$version" ] || fail "$name: version $version is not upstream's $upv at the pin; move them together"
    fi
  fi
  up_names="$(cd "$U/$path" && find . -name SKILL.md -type f | sed 's#/SKILL.md$##; s#.*/##' | sort)"
  dup="$(uniq -d <<<"$up_names")"
  [ -z "$dup" ] || fail "$name: a basename holds more than one SKILL.md under $path at the pin: $dup"
  excl="$(printf '%s\n' "${EXCLUSIONS[$name]-}" | grep . || true)"
  while IFS=$'\t' read -r s reason; do
    [ -n "$s" ] || continue
    [ -n "$reason" ] || fail "$name: the exclusion $s carries no reason"
    grep -qxF -- "$s" <<<"$up_names" || fail "$name: the exclusion $s is not a skill under $path at the pin; retire it"
    if entry_skills "$name" | grep -qxF -- "$s"; then fail "$name: $s is both listed and excluded"; fi
    EXCLUDED_N=$((EXCLUDED_N + 1))
  done <<<"$excl"
  diff <(printf '%s\n' "$up_names") <({
    entry_skills "$name"
    printf '%s\n' "$excl" | cut -f1
  } | grep . | sort) \
    || fail "$name: the skill directories under $path at the pin (above) are not the listed skills plus the declared exclusions (below); list or exclude each new skill with its reason"
  if jq -e --arg r "$repo" '.records[] | select(.repo == $r) | (has("sha") | not)' "$VENDORED_JSON" >/dev/null 2>&1; then
    sibling_names "$name" "$repo" "$U" "$path" "$listed" "$up_names"
  fi
  ENTRIES=$((ENTRIES + 1))
done < <(entry_rows)
[ "$ENTRIES" -gt 0 ] || fail "the marketplace holds no subset entry"
[ "$SIBLINGS" -gt 0 ] || fail "no sibling name was checked; the mattpocock record resolves through its entry, so the check must run"

printf 'upstream: %s record(s) at their pins, %s copied file(s) held with %s declared change(s), %s LICENSE section(s) carry upstream'"'"'s copyright; %s entr(y|ies) at their pins with %s exclusion(s); %s sibling name(s) resolve\n' \
  "$RECORDS" "$FILES" "${#DECLARED[@]}" "$SECTIONS" "$ENTRIES" "$EXCLUDED_N" "$SIBLINGS"
