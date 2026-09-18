#!/usr/bin/env bash
# Run every tests/test-*.sh and exit 1 if any fails. Same entry point for
# local runs and CI.
#
#   tests/run.sh             a test whose declared need is unmet is skipped
#   tests/run.sh --no-skip   an unmet need is a FAIL; CI runs this
#
# Three things are hard (spec §5.1): bash 4 or later, jq and git. The shared
# substrate cannot run without them, so absent one no test's verdict means
# anything, and the run refuses with the complete list, exit 2. Everything
# else is a need: a test declares it on one line of its header comment,
# `# needs: claude` or `# needs: python3 pyyaml codex-validator`; each name
# is probed once per run, and a test whose need is unmet does not run. The
# six lint and format tools are held to the versions in tests/tools.txt: a
# version that differs is unmet, and the line names both. A need no probe
# knows is exit 2, so a misspelled need cannot skip a test quietly.
#
# Every run writes tests/results.tsv (gitignored, rewritten): a header naming
# the tree, then one row per test. A report cites the file (spec §5.4).
set -uo pipefail
cd "$(dirname "$0")/.." || {
  printf 'FAIL: could not cd to the repository root\n' >&2
  exit 1
}

NO_SKIP=0
case "${1:-}" in
  '') ;;
  --no-skip) NO_SKIP=1 ;;
  *)
    printf 'usage: tests/run.sh [--no-skip]\n' >&2
    exit 2
    ;;
esac

RESULTS=tests/results.tsv
REGISTRY=tests/tools.txt
rm -f "$RESULTS"

# The hard prerequisites, refused as one list in the shape bin/setup uses.
missing=""
[ "${BASH_VERSINFO[0]}" -ge 4 ] \
  || missing="$missing, bash 4 or later (found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"
command -v jq >/dev/null 2>&1 || missing="$missing, jq"
command -v git >/dev/null 2>&1 || missing="$missing, git"
[ -z "$missing" ] || {
  printf 'the test suite needs:%s\n' "${missing#,}" >&2
  exit 2
}
[ -f "$REGISTRY" ] || {
  printf 'FAIL: %s is missing\n' "$REGISTRY" >&2
  exit 2
}

# The version a tool reports: the first dotted triple in its version output.
tool_version() {
  case "$1" in
    actionlint) actionlint -version ;;
    *) "$1" --version ;;
  esac 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

# The version tests/tools.txt declares for $1; exit 1 when it declares none.
registry_version() {
  awk -v t="$1" '$1 == t { print $2; found = 1 } END { exit !found }' "$REGISTRY"
}

# One probe per need, run once and remembered. On an unmet need WANT holds
# what was needed ("claude", "shfmt 3.14.1") and FOUND what was there ("" when
# absent, "3.8.0" on a version mismatch); on a met need WANT is empty. A name
# the registry lists is held to its version; the other four are probed by
# presence. $2 is the declaring test, for the error on an unknown name.
declare -A WANT=() FOUND=()
probe() {
  local need="$1" want found
  [ -z "${WANT[$need]+set}" ] || return 0
  WANT[$need]=""
  FOUND[$need]=""
  if want="$(registry_version "$need")"; then
    if ! command -v "$need" >/dev/null 2>&1; then
      WANT[$need]="$need $want"
    else
      found="$(tool_version "$need")"
      if [ "$found" != "$want" ]; then
        WANT[$need]="$need $want"
        FOUND[$need]="${found:-unknown}"
      fi
    fi
    return 0
  fi
  case "$need" in
    claude | python3)
      command -v "$need" >/dev/null 2>&1 || WANT[$need]="$need"
      ;;
    pyyaml)
      python3 -c 'import yaml' >/dev/null 2>&1 || WANT[$need]="pyyaml"
      ;;
    codex-validator)
      [ -f "${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}" ] \
        || WANT[$need]="codex-validator (the file codex-cli installs, or a copy fetched by the recipe in .github/workflows/validate.yml, named by CODEX_PLUGIN_VALIDATOR)"
      ;;
    *)
      printf 'ERROR: %s declares a need no probe knows: %s\n' "$2" "$need" >&2
      exit 2
      ;;
  esac
}

# The `# needs:` line of a test's header: the block of comment lines that
# opens the file, ending at the first line that is not one.
declared_needs() {
  local line
  while IFS= read -r line; do
    case "$line" in
      '#!'*) ;;
      '# needs: '*)
        printf '%s\n' "${line#'# needs: '}"
        return 0
        ;;
      '#'*) ;;
      *) return 0 ;;
    esac
  done <"$1"
  return 0
}

# The header: short sha, `dirty` when the tree differs from HEAD, UTC time.
# tests/results.tsv is gitignored, so the run's own output never counts.
tree="$(git rev-parse --short HEAD 2>/dev/null || printf 'no-commit')"
[ -z "$(git status --porcelain 2>/dev/null)" ] || tree="$tree dirty"
printf '# %s %s\n' "$tree" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$RESULTS"

passed=0 failed=0 skipped=0 unmet_list=""
for t in tests/test-*.sh; do
  unmet=""
  # shellcheck disable=SC2046  # the needs line is space-separated names by contract
  for need in $(declared_needs "$t"); do
    probe "$need" "$t"
    [ -z "${WANT[$need]}" ] && continue
    unmet="$unmet, ${WANT[$need]}${FOUND[$need]:+; found ${FOUND[$need]}}"
    item="${WANT[$need]}${FOUND[$need]:+ (found ${FOUND[$need]})}"
    case ", $unmet_list, " in
      *", $item, "*) ;;
      *) unmet_list="$unmet_list, $item" ;;
    esac
  done
  if [ -n "$unmet" ]; then
    unmet="${unmet#, }"
    if [ "$NO_SKIP" -eq 1 ]; then
      printf 'FAIL %s (needs %s)\n' "$t" "$unmet"
      printf '%s\tFAIL\t-\tneeds %s\n' "$t" "$unmet" >>"$RESULTS"
      failed=$((failed + 1))
    else
      printf 'SKIP %s (needs %s)\n' "$t" "$unmet"
      printf '%s\tSKIP\t-\tneeds %s\n' "$t" "$unmet" >>"$RESULTS"
      skipped=$((skipped + 1))
    fi
    continue
  fi
  log="$(mktemp)"
  bash "$t" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  last="$(tail -n 1 "$log" | tr '\t' ' ')"
  rm -f "$log"
  if [ "$status" -eq 0 ]; then
    printf 'PASS %s\n' "$t"
    printf '%s\tPASS\t%s\t%s\n' "$t" "$status" "$last" >>"$RESULTS"
    passed=$((passed + 1))
  else
    printf 'FAIL %s\n' "$t"
    printf '%s\tFAIL\t%s\t%s\n' "$t" "$status" "$last" >>"$RESULTS"
    failed=$((failed + 1))
  fi
done

summary="$passed passed, $failed failed, $skipped skipped"
[ -z "$unmet_list" ] || summary="$summary for want of: ${unmet_list#, }"
printf '%s\n' "$summary"
[ "$failed" -eq 0 ]
