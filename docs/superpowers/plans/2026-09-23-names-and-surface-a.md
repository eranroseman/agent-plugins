# Names the Reader Already Knows — Implementation Plan A (milestone 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository say what it means in words a newcomer already knows, move four files to where a reader looks for them, end the root README's habit of restating what other files own, and leave a test behind for each: an ownership table no guard can be repointed from, a reference check over every backticked path, a vocabulary test over every `_Avoid_` word, and a `CONTEXT.md` that is the output of the renames.

**Architecture:** One branch, `names-and-surface`, cut from `main`. The ownership derivation in `tests/lib.sh` becomes one `(pattern, guard)` table read by a helper every drift test calls, so the hook file rename goes through it. Then three moves, one commit each: `skills.json` to the root, three scripts to `scripts/`, the silence fixture's layout with the first. Then one commit per retired word, largest first, each commit carrying the specs and plans under `docs/superpowers/` by reviewed diff. Then the reference check gains its backticked half over every owned markdown file, with a history tier under `docs/superpowers/` that archives deleted files and refuses stale names. Then the README and manifest pass, `CONTEXT.md`, and `tests/test-vocabulary.sh`, red first on a seeded mutant. Gate 1 closes the plan; plan B (milestone 4) is written after it against the settled tree.

**Tech Stack:** bash 5 (`set -euo pipefail` in the tests, no `set -e` in the engine), git, jq, GNU awk and sed, perl for the scratch substitution helper, shellcheck 0.9.0, shfmt 3.14.1, prettier 3.9.6, markdownlint-cli2 0.23.2, cspell 10.2.2, actionlint 1.7.12, `gh`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-20-names-and-surface-design.md`. Section numbers below (§5.1, §6, §8, …) refer to it; every task argues from it. `docs/superpowers/plans/2026-09-17-suite-and-ci.md` is the house style this plan follows.

**This is plan A of two.** The spec binds one branch and two plans (§2, §20): plan A is milestone 3, tasks 1–16 here; plan B, milestone 4, is written after gate 1 against the tree this plan leaves. Nothing from §10–§19 is done here, and no issue is closed here: the version bump and every disposition, #57's included, are plan B's (§19, §20). Two exceptions are recorded as deviations P6 and P7 below, where a line plan B would touch is a line this plan rewrites anyway.

## What was verified while planning (2026-09-23, tree at `19c5290`)

Every count below was measured in this checkout or in a scratch clone of it, not copied from the spec; where the two differ the plan says so. The spec's counts are at `1dd7362`, two commits back, both of which touch only the spec.

- **Files.** `git ls-files` lists 111 paths. `checked()` lists 88: 76 outside `docs/superpowers/` (`CONTEXT.md` among them), and 12 inside, 6 specs and 6 plans (13, with this file). `CONTEXT.md` exists and is one placeholder line; it is replaced in Task 14.
- **Retired words in the checked files outside `docs/superpowers/`**, lines and files, by the spec's own boundary pattern `(^|[^[:alnum:]-])FORM([^[:alnum:]-]|$)`, case-insensitive: `payload|payloads` 42 in 8; `curated|curation` 52 in 14; `declaration|declarations` 19 in 4; `gated` 22 in 9; `installer|installers` 3 in 3; `routing` 0; `carrier` 2 in 1 (the coupled pair of §5.3; the test line is the third site the spec counts); `authored` 11 in 9; `harness|harnesses` 23 in 10; `maintained record|working paper` 1 in 1. Inside `docs/superpowers/`, per document: `payload` 148 lines across all eleven, of which 69 are inside fenced blocks; `curated` 129; `harness` 62; `gated` 56; `authored` 50; `declaration` 25; `routing` 17; `carrier` 15; `installer` 15; the retired plugin name `software-development` 275 lines in 10 documents, 139 of them inside fences in the three biggest plans.
- **Moved-path references outside `docs/superpowers/`**: `upstream/skills.json` (now `skills.json`) at 26 sites in 10 files; `bin/upstream-watch`, `bin/bump-superpowers` and `bin/format` (now under `scripts/`) at 24 sites in 13 files, two of them in `.github/workflows/upstream-watch.yml`; `payload.md`, `payload-rules.md`, `--emit-payload`, `emit_payload` and `payload_tmp` at 45 sites in 8 files. Inside: the manifest's old path 68 lines, the three scripts 85, the two hook files 146.
- **The word-boundary claim** (§22): `printf 'payload_tmp\nharness-backup\nknowledge-harness\nclaude_gated\n' | grep -i -E '(^|[^[:alnum:]-])(payload|harness|gated)([^[:alnum:]-]|$)'` prints lines 1 and 4 only. `_` is a boundary; `-` is not.
- **cspell 10.2.2** knows `invocable`, `subset`, `namespaced`, `subdir`; it does not know `Strunk` (the spec's one JSON word), `pathspec` (singular; `pathspecs` is listed) or `unforgeable`. Whole-file cspell over the eight owned JSON files reports exactly one word, `Strunk's`, as the spec measured.
- **The three-root resolution rule changes what is red on day one.** With the document's directory, the repository root and each `plugins/*/` root as roots, `AGENTS.md`'s `hooks/` resolves at `plugins/software-dev/hooks/` and `PROVENANCE.md`'s `skills/finding-duplicate-functions` resolves at `plugins/software-dev/skills/finding-duplicate-functions`. Neither is a day-one red, contrary to §8's list; both edits are still made, by §6 and §5.5, and root `hooks/` has no git history at all (`git log --all -- hooks/` prints nothing), so the history tier could not have excused it either. Outside `docs/superpowers/` exactly two tokens are red at HEAD: `.worktrees/` and `worktrees/` in the working-rules file, which §8's class 6 clears through `.gitignore`.
- **The reference check's residue was measured twice**, with the scanner Task 12 lands (fenced blocks unscanned, a span with whitespace split into words, the classes of §8 plus the extensions in P1–P3): at HEAD, 151 tokens do not resolve, 149 of them under `docs/superpowers/`; in a scratch clone with the six moves of Tasks 2–4 applied and the test file renamed (`git clone --local`, six `git mv`, one commit), 267, the difference being the moved paths, which the history tier reports as renamed with their successors. Grouped by token, the residue is the table in Task 12; every row has a disposition. The run took 59 seconds against that residue, one `git log --all` per unique root-and-path; against a green tree it is a few seconds.
- **The history tier needs history.** `actions/checkout` fetches depth 1 by default, under which `git log --all -1 -- path` finds nothing for a deleted file and the tier reports a typo. Task 12 sets `fetch-depth: 0` on the `validate` job's checkout and makes the test refuse a shallow clone by name rather than run weaker.
- **`.kilo/worktrees/brass-settee`**, named by the suite-and-ci spec's claims table, is excluded on this machine through `.git/info/exclude`, which `git check-ignore` honours here and a fresh clone does not have. It joins `.gitignore` in Task 12 so class 6 holds on CI.
- **`same-line successor` cases.** With the moves applied, the spec's own rename statements (§3's table rows, §5.1, §6's bullets) name the old path beside the new one on the same line; four sites do not: §21's `bin/format` bullet and three §22 rows (`upstream/skills.json`, now `skills.json`; `bin/format`, now `scripts/format`; `plugins/software-development/README.md`, now `plugins/software-dev/README.md`). Deviation P4 covers all of them.
- **The scanner's code was run before the plan was handed over**: shellcheck 0.9.0 with `-e SC1091 -e SC2016` exits 0, shfmt `-i 2 -ci -bn` makes no change, cspell over its comments reports nothing, and the `…/` and `*…` patterns match under `LC_ALL=C` as well as under the UTF-8 locale.
- **Tools on this machine**: prettier, markdownlint-cli2, cspell, shfmt, shellcheck, actionlint at the registry's versions; gawk 5.2.1 as `awk`; perl 5. `gh` is logged in as the repository owner; `origin` is `https://github.com/eranroseman/agent-plugins.git`.

## Deviations decided while planning

Visible choices, each with a veto line.

- **P1. A backticked span carrying whitespace is a command, classified word by word.** §8 defines a candidate as a backticked token containing `/`; 263 of the tokens that fail at HEAD are commands (`bash tests/test-hook.sh`, `bin/setup --help`, `claude plugin marketplace add eranroseman/agent-plugins`) and no class of §8 covers them. Task 12's scanner splits such a span on whitespace, drops a `NAME=` prefix and surrounding quotes from each word, checks the words shaped like paths, and counts the rest as command syntax. This is what lets an inline command's path be held current, which §6 asks of fenced commands. Veto: treat the whole span as one token and let every inline command fail until it is rewritten.
- **P2. Three classes are widened, with the same rationale as the spec gives them.** Class 2 (a name that is not a working-tree path by its shape) also takes `:(` (a git pathspec prefix), `refs/` (a git ref), `repos/` (a GitHub API route) an elision at either end (`.../`, `…/`, `...`, `…`), and `$` anywhere in the token rather than only first (`refs/tags/$ref`, the watch's template `tests/test-subset-$name.sh`); class 3 (placeholders and globs) also takes `{`, `[` and `|`; class 5 (the other-repository convention) also accepts a bare name before the colon, so git's `rev:path` and Codex's `plugin@marketplace:key` are one shape with `owner/repo:path`. Veto: keep the spec's lists exactly and rewrite the twenty-odd sites by hand.
- **P3. The declared-absent list is keyed by token, not by file and token, and has six entries.** `hooks/hooks.json` is absent by decision wherever it is named, in 28 lines across seven documents, not only in the software-dev README; a per-file list would repeat it seven times. The six: `hooks/hooks.json`, `docs/adr/`, `.github/actionlint.yaml` (the runner-label override §14 declines), `bin/setpu` (§8's own example of a typo, a sentence whose subject is the token), `plugins/ghost/` (the suite-and-ci spec's mutation, created and removed inside it), and `tests/test-format-apply.sh` (named by §18, created by plan B, which drops the entry). Veto: a per-file list, and the four extra entries become hand edits.
- **P4. A renamed path beside its successor on the same line is a rename record, not a stale reference.** After the moves, the history tier fails every line of this spec that records a rename (`upstream/skills.json` → `skills.json`), because §6 forbids editing a sentence whose subject is the old path. The scanner passes a renamed token when a span on the same line names the successor, its basename, or a directory it sits under; the count is printed like the other classes. Four sites in the spec still fail and are edited once: the three §22 measurement rows take git's own `rev:path` form (`1dd7362:upstream/skills.json`, `1dd7362:bin/format`, `a3c797f:plugins/software-development/README.md`), which names the tree each measurement was made on, and §21's decline bullet gains the successor on its line. Veto: no rule, and about ten more declared-absent entries specific to this spec.
- **P5. Paths are made current in inline spans that quote tool output; fenced blocks that quote output are left alone.** §6's boundary keeps every word inside quotation marks and inside a fenced block that reproduces output; it says paths in a command fence are updated. An inline span such as `` `FAIL: not valid JSON: upstream/skills.json` `` (the manifest is `skills.json` now) is scanned (P1) and would fail forever otherwise, and a current reader running the command sees the new path. Two inline spans that quote a failure naming a path that never existed are moved into `text` fences unchanged. Veto: declare each such span absent by token.
- **P6. M4's reference-check half lands here.** §16 assigns M4 (a tracked file absent from the working tree is a FAIL naming it, not a silent skip) to plan B, but Task 12 rewrites `tests/test-links-resolve.sh` whole, and writing `[ -f "$f" ] || continue` into a new file is writing a known defect. `checked_shell()`'s half stays plan B's. Veto: keep the skip and let plan B remove it.
- **P7. Lines this plan rewrites in `tests/test-ownership.sh` take their plan-B shape.** §16's M8 (every `producer | grep -q && fail` becomes a here-string over a captured list) is plan B's; Task 1 rewrites the pattern loop and the two assertions that name the hook file, and those lines are written as here-strings. The lines Task 1 does not touch keep their shape for plan B. Veto: write the new lines in the old shape.
- **P8. The `guards` helper binds a drift test to its row by the paths it checks, and the static check reads that binding.** §16 says each guard reads its row through a helper and the ownership test asserts the guard calls it. #61 M7 showed that name-only and distinctness-only checks are both defeated by repointing a guard at a test that happens to name the subject. So the helper takes the paths the calling test is about to check and fails unless exactly one row names the caller and every path matches that row's pattern; the ownership test, offline, reads each guard's `guards` line and asserts its arguments match the row's pattern. The issue's own reproduction (repoint the brainstorming row at `tests/test-hook.sh`) is Task 1's red-first mutation. Veto: a helper that only looks the row up, and a static check that only greps for the call.
- **P9. The Codex `shortDescription` is rewritten under the new vocabulary, not made equal to the marketplace string.** §7 item 2 makes the tagline and the marketplace's top-level `description` one string and says the Codex `shortDescription` follows; the only Codex `shortDescription` carrying a retired word is software-dev's plugin manifest (`Curated software-dev skills`), and a plugin's short description cannot be the marketplace's tagline. It becomes `Software-development skills for Claude Code and Codex`. Veto: leave it and let `tests/test-vocabulary.sh` fail on `Curated`.
- **P10. `user-invoked` joins the `gated` rename.** Four sites describe the same property (`User-invoked only`, `user-invoked audit`, `user-invoked on both harnesses`, `must be user-invoked on Claude`) with a third word; `CONTEXT.md`'s entry is `user-invocable only`, Claude Code's own `skillOverrides` value, and a word used two ways is unified (§5.5). Veto: leave `user-invoked`; it is not an `_Avoid_` form and the test would not notice.
- **P11. The spec file named `2026-09-04-software-development-layout-and-tracer-design.md` keeps its name.** The retired plugin name is edited in prose and paths (§6), but the file name is the document's identity, every reference to it resolves, and a rename would rewrite the references for no reader's benefit. The substitution in Task 12 excludes it by pattern. Veto: `git mv` it and update the references.
- **P12. Terms are substituted by script outside fences, then reviewed; paths and identifiers are substituted everywhere, then reviewed.** §6 asks for a reviewed diff, not a blind substitution: the procedure here is a scripted first pass (a perl one-liner that skips fenced blocks, following a fence's length) followed by a hunk-by-hunk review against §6's boundary, reverting what stays, and a closing `git grep` whose kept-site count goes in the commit body. Veto: edit every site by hand from the grep list.

## Global Constraints

Copied from the spec unless marked; every task's requirements implicitly include this section.

- **Branch and gate.** All work on `names-and-surface`, cut from `main` at `19c5290` or later (Task 1). Gate 1 is Task 16: full suite green with `tests/results.tsv` cited, CI green on the pushed branch, `tests/test-vocabulary.sh` green, `CONTEXT.md` written and scanned by the reference check (§9). No merge to `main` here; plan B merges after gate 2 (§20).
- **Commit style.** Sentence-case subject, no type prefix, a body that says why, ending in `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Every commit names its paths: `git add <paths>` then `git commit -m … -- <paths>`; never `git add -A` or `git commit -a` (`.gitignore` records the reason). A `git mv` is staged by the `mv` itself.
- **Suite green after every commit** (§20). Run `bash tests/run.sh` before each commit; the network tests need network, and a test whose declared need this machine lacks is skipped, which is acceptable locally and not in CI.
- **Couplings held by tests, each pair edited in one commit:** `bin/setup`'s report strings and `tests/test-doctor-silence.sh`'s `saw` patterns and `tests/test-doctor-duplicates.sh`'s greps; `scripts/bump-superpowers`'s flag and `tests/test-hook.sh`; the carrier sentence in `setup-repository/SKILL.md` and `tests/test-vendored-scaffolder.sh` lines 144 and 165; the `authored here` header line in `finding-duplicate-functions/SKILL.md` and `tests/test-vendored-duplicates.sh` line 49; the README's Install and Update fenced blocks and `usage()` in `bin/setup` (held equal by `tests/test-setup-doctor.sh`); `AGENTS.md`'s `### Design discipline` and `### Task reports` sections and the block inside the scaffolder's `SKILL.md` (held byte-identical by `tests/test-vendored-scaffolder.sh`; neither is edited here).
- **The historical directory** (§4, §6). `docs/superpowers/` is edited for vocabulary and paths only, by reviewed diff (P12). The boundary: inside a fenced block that reproduces tool output, a manifest or a measurement, inside quotation marks, and in a sentence whose subject is the old word itself, every word stays; a fenced block that is a command to run has its paths and flags updated; everywhere else the new word or path is written. Content is never amended.
- **Vocabulary** (§5.1, §5.5), the winners: additional context; user, or no noun (`skills.sh` for the tool); instruction file; desired state (the verb _declare_ stays); first-party; user-invocable only; subset entry; skill selection; Claude Code, Codex, agent CLI (the generic, at durable sites only); historical artifact; vendored and forked as §5.5 defines them. `_Avoid_` forms: `payload, payloads`; `installer, installers`; `carrier`; `declaration, declarations`; `authored`; `gated`; `curated, curation`; `routing`; `harness, harnesses`; `maintained record, working paper`. No new file written by this plan may carry any of these forms in its comments or strings: `tests/test-vocabulary.sh` scans every checked shell, JSON and YAML file.
- **The other-repository convention** (§5.5): a path in another repository is written `owner/repo:path`, or `owner/repo@ref:path` when the ref matters.
- **Layout after Task 4:** `bin/` holds `setup` and `doctor`; `scripts/` holds `upstream-watch`, `bump-superpowers`, `format`; `skills.json` and (in plan B) `vendored.json` at the root; `plugins/software-dev/hooks/` holds `session-start`, `claude-hooks.json`, `using-superpowers.md`, `working-rules.md`.
- **Spelling.** `tests/test-spelling.sh` runs cspell over every checked markdown file outside `docs/superpowers/`, the comments of every shell and YAML file, and (after Task 13) every checked JSON file whole. New words this plan needs in `cspell.config.yaml`: `Strunk` (Task 13), `pathspec` (Task 12). Do not write `unforgeable`.
- **Formatting.** `scripts/format` (`bin/format` until Task 4) rewrites what the format checks check; run it before committing any markdown, JSON or YAML edit, and `shfmt -w -i 2 -ci -bn` on any shell file. This plan itself is a checked markdown file under `docs/superpowers/plans/` once staged: prettier and markdownlint run over it, and the reference check scans it with the history tier, so its fences carry a language and its old paths sit beside their successors.
- **The engine's floor** is unchanged here (bash 4 in `tests/run.sh`); the 4.4 floor is plan B's (§13).

---

### Task 1: The branch, and one ownership table no guard can be repointed from (§16 M7)

**Files:**

- Modify: `tests/lib.sh` (the Ownership section, lines 64–95)
- Modify: `tests/test-ownership.sh` (whole file)
- Modify: `tests/test-vendored-adhd.sh`, `tests/test-vendored-brainstorming.sh`, `tests/test-vendored-diagnosing-bugs.sh`, `tests/test-vendored-scaffolder.sh`, `tests/test-vendored-duplicates.sh`, `tests/test-hook.sh` (one `guards` line each)

**Interfaces:**

- Produces: `GUARDED`, an array of rows `pattern<TAB>guard` in `tests/lib.sh`; `EXCLUDED`, the patterns joined by `|`, unchanged in meaning; `guards <repo-relative path>...`, a function every drift test calls once, on one line, before it fetches anything; `checked()` and `checked_shell()` unchanged. Task 2 edits one row; Task 12 and Task 15 consume `checked()`.

- [ ] **Step 1: Cut the branch**

```bash
cd /home/eranr/agent-plugins && git switch -c names-and-surface main && git log --oneline -1
```

Expected: `names-and-surface` at `19c5290` or later. A worktree (`superpowers:using-git-worktrees`) is fine too; `.claude/worktrees/` is ignored.

- [ ] **Step 2: Reproduce #61 M7 on the tree as it stands**

Run:

```bash
sed -i 's#^  tests/test-vendored-brainstorming.sh$#  tests/test-hook.sh#' tests/lib.sh && bash tests/test-ownership.sh; git checkout -- tests/lib.sh
```

Expected: `ownership: 6 vendored pattern(s) each guarded; 88 checked file(s), 37 of them shell`, exit 0, with the brainstorming pattern guarded by a test that never checks brainstorming. That is the defect.

- [ ] **Step 3: Replace the Ownership section of `tests/lib.sh`**

Replace lines 64–95 (from `# ---- Ownership (spec §4)` through the `EXCLUDED=…` block) with:

```bash
# ---- Ownership (spec §4; #61 M7) -------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: trees with a drift test, where an upstream pin
# constrains the bytes and the paired test asserts them. One table, one row
# per pattern: the pattern, anchored at the start of the path, a tab, then
# the test that guards it. A guard binds itself to its row by calling
# guards() on one line with the paths it holds to upstream, and
# tests/test-ownership.sh reads that line, so a row cannot name a test that
# checks something else. #21 may devendor a tree: that edits this table and
# nothing else. adhd/agents/openai.yaml is first-party but sits inside a
# vendored directory; the directory is excluded whole, because the drift
# test's file-set assertion governs it and tests/test-plugin-skills.sh
# already asserts the one policy line the file exists to carry.
GUARDED=(
  $'^plugins/sensemaking/skills/adhd/\ttests/test-vendored-adhd.sh'
  $'^plugins/software-dev/skills/brainstorming/\ttests/test-vendored-brainstorming.sh'
  $'^plugins/software-dev/skills/diagnosing-bugs/\ttests/test-vendored-diagnosing-bugs.sh'
  $'^plugins/software-dev/skills/setup-repository/\ttests/test-vendored-scaffolder.sh'
  $'^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\\.md$\ttests/test-vendored-duplicates.sh'
  $'^plugins/software-dev/hooks/payload\\.md$\ttests/test-hook.sh'
)
EXCLUDED="$(
  IFS='|'
  set -- "${GUARDED[@]%%$'\t'*}"
  printf '%s' "$*"
)"

# The pattern of the row whose guard is $1, a path relative to REPO_ROOT.
# Prints it; fails unless exactly one row names that guard.
guarded_pattern() {
  local guard="$1" row n=0 pat=""
  for row in "${GUARDED[@]}"; do
    [ "${row#*$'\t'}" = "$guard" ] || continue
    n=$((n + 1))
    pat="${row%%$'\t'*}"
  done
  [ "$n" -eq 1 ] || fail "$n row(s) of the table in tests/lib.sh name $guard as their guard; exactly one must"
  printf '%s\n' "$pat"
}

# Called by a drift test, on one line, with the repository-relative paths it
# is about to hold to upstream. The test is bound to its row: exactly one row
# names it, and every path given is tracked and matches that row's pattern.
# Before any fetch, so a broken binding fails without a network.
guards() {
  local me="tests/${BASH_SOURCE[1]##*/}" pat p
  pat="$(guarded_pattern "$me")" || exit 1
  [ "$#" -gt 0 ] || fail "$me calls guards with no path"
  for p in "$@"; do
    printf '%s\n' "$p" | grep -qE "$pat" \
      || fail "$me guards $p, which its row's pattern '$pat' does not match"
    git -C "$REPO_ROOT" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 \
      || fail "$me guards $p, which is not a tracked file"
  done
}
```

`checked()` and `checked_shell()` below it are unchanged.

- [ ] **Step 4: Replace `tests/test-ownership.sh`**

```bash
#!/usr/bin/env bash
# The ownership derivation stays honest (spec §4; #61 M7). Every row of the
# table in tests/lib.sh matches at least one tracked file and names a guard
# that exists, no two rows name the same guard, and each guard's own
# `guards` line -- read here, statically, so this holds without a network --
# names paths the row's pattern matches, so a guard cannot be repointed at a
# test that happens to mention the subject. The checked list is non-empty,
# lists none of the excluded files, and no checked path carries whitespace,
# a glob character, or a quoted path, which is what lets the tool tests
# expand `$(checked ...)` unquoted, one path per word.
. "$(dirname "$0")/lib.sh"

[ "${#GUARDED[@]}" -gt 0 ] || fail "no row is declared in tests/lib.sh's table"

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"

seen=""
for row in "${GUARDED[@]}"; do
  pat="${row%%$'\t'*}"
  guard="${row#*$'\t'}"
  if [ -z "$pat" ] || [ -z "$guard" ] || [ "$pat" = "$row" ]; then
    fail "a row in tests/lib.sh's table is not pattern<TAB>guard: '$row'"
  fi
  matches="$(git -C "$REPO_ROOT" ls-files | grep -E "$pat" || true)"
  [ -n "$matches" ] || fail "pattern '$pat' matches no tracked file; drop it from tests/lib.sh or fix it"
  [ -f "$REPO_ROOT/$guard" ] || fail "pattern '$pat' names a guard that does not exist: $guard"
  case " $seen " in
    *" $guard "*) fail "two rows name $guard as their guard; a guard binds to one row" ;;
  esac
  seen="$seen $guard"
  # The binding, read from the guard's one `guards` line.
  calls="$(grep -E '^guards ' "$REPO_ROOT/$guard" || true)"
  [ "$(printf '%s\n' "$calls" | grep -c .)" -eq 1 ] \
    || fail "$guard must call guards exactly once at the start of a line; found $(printf '%s\n' "$calls" | grep -c .)"
  read -ra words <<<"$calls"
  [ "${#words[@]}" -gt 1 ] || fail "$guard calls guards with no path"
  for p in "${words[@]:1}"; do
    grep -qE "$pat" <<<"$p" \
      || fail "$guard guards $p, which '$pat' does not match; the row and its guard disagree about what is excluded"
    grep -qxF -- "$p" <<<"$matches" \
      || fail "$guard guards $p, which is not a tracked file the pattern matches"
  done
  # The exclusion itself: the first file the row matches is not a checked file.
  first="$(printf '%s\n' "$matches" | head -n 1)"
  if grep -qxF -- "$first" <<<"$list"; then
    fail "checked() lists $first, which the row '$pat' excludes; EXCLUDED is not built from the table"
  fi
done

printf '%s\n' "$list" | grep -q '[[:space:]*?[\\"]' \
  && fail "a tracked path carries whitespace, a glob character, or a quoted path; the tool tests expand the list unquoted:"$'\n'"$(printf '%s\n' "$list" | grep '[[:space:]*?[\\"]')"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
printf '%s\n' "$shell" | grep -qx 'bin/setup' || fail "checked_shell() does not list bin/setup, a shell file with no extension"
# The floor under that pin, derived rather than enumerated: an expected list of
# shell files goes stale silently, which is the defect this suite exists to
# catch. Every checked file whose first line names bash must be in
# checked_shell, so a shell file cannot leave the shell checkers' scope on one
# character. checked_shell's exact-shebang rule (spec §4) stands: this says
# what joining it costs, it does not relax it.
missing=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$(head -n 1 "$REPO_ROOT/$f")" in
    '#!'*bash*)
      printf '%s\n' "$shell" | grep -qxF -- "$f" || missing="$missing $f"
      ;;
  esac
done < <(printf '%s\n' "$list")
[ -z "$missing" ] \
  || fail "these checked file(s) open with a bash shebang and checked_shell() does not list them:$missing"$'\n'"their first line must be exactly '#!/usr/bin/env bash', or they leave shellcheck, shfmt and cspell unnoticed"

printf 'ownership: %s row(s), each bound to its guard; %s checked file(s), %s of them shell\n' \
  "${#GUARDED[@]}" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
```

- [ ] **Step 5: Run the ownership test and see it fail on the unbound guards**

Run: `bash tests/test-ownership.sh`
Expected: `FAIL: tests/test-vendored-adhd.sh must call guards exactly once at the start of a line; found 0`, exit 1. No guard is bound yet.

- [ ] **Step 6: Bind each drift test to its row**

Add one line to each test, directly after its `[ -d "$V" ] || fail "missing $V"` (or, in `tests/test-hook.sh`, after the four existence checks on lines 22–25):

`tests/test-vendored-adhd.sh`:

```bash
guards plugins/sensemaking/skills/adhd/SKILL.md plugins/sensemaking/skills/adhd/agents/openai.yaml
```

`tests/test-vendored-brainstorming.sh`:

```bash
guards plugins/software-dev/skills/brainstorming/SKILL.md
```

`tests/test-vendored-diagnosing-bugs.sh`:

```bash
guards plugins/software-dev/skills/diagnosing-bugs/SKILL.md plugins/software-dev/skills/diagnosing-bugs/agents/openai.yaml
```

`tests/test-vendored-scaffolder.sh`:

```bash
guards plugins/software-dev/skills/setup-repository/SKILL.md plugins/software-dev/skills/setup-repository/agents/openai.yaml
```

`tests/test-vendored-duplicates.sh`:

```bash
guards plugins/software-dev/skills/finding-duplicate-functions/scripts/categorize-prompt.md plugins/software-dev/skills/finding-duplicate-functions/scripts/find-duplicates-prompt.md
```

`tests/test-hook.sh`:

```bash
guards plugins/software-dev/hooks/payload.md
```

- [ ] **Step 7: Run the ownership test and see it pass**

Run: `bash tests/test-ownership.sh`
Expected: `ownership: 6 row(s), each bound to its guard; 88 checked file(s), 37 of them shell`.

- [ ] **Step 8: Prove the binding with the issue's own mutation, then a second**

The edits of Step 3 are not committed yet, so restore from a copy, never with `git checkout`. Run:

```bash
cp tests/lib.sh /tmp/lib.sh.bak && sed -i 's#brainstorming/\\ttests/test-vendored-brainstorming.sh#brainstorming/\\ttests/test-hook.sh#' tests/lib.sh && bash tests/test-ownership.sh; cp /tmp/lib.sh.bak tests/lib.sh
```

Expected: `FAIL: tests/test-hook.sh guards plugins/software-dev/hooks/payload.md, which '^plugins/software-dev/skills/brainstorming/' does not match; the row and its guard disagree about what is excluded`, exit 1 (the brainstorming row is checked before the hook row, so the binding fires before the distinctness check would). The row still names `payload.md` here; Task 2 renames it to `using-superpowers.md`. Then swap two guards so every row still has a distinct guard:

```bash
sed -i -e 's#adhd/\\ttests/test-vendored-adhd.sh#adhd/\\ttests/test-vendored-brainstorming.sh#' -e 's#brainstorming/\\ttests/test-vendored-brainstorming.sh#brainstorming/\\ttests/test-vendored-adhd.sh#' tests/lib.sh && bash tests/test-ownership.sh; cp /tmp/lib.sh.bak tests/lib.sh
```

Expected: `FAIL: tests/test-vendored-brainstorming.sh guards plugins/software-dev/skills/brainstorming/SKILL.md, which '^plugins/sensemaking/skills/adhd/' does not match; the row and its guard disagree about what is excluded`, exit 1. Both mutations that satisfied the old test are red. Confirm the restore with `bash tests/test-ownership.sh`.

- [ ] **Step 9: Run the drift tests that need no network, then the suite**

Run: `bash tests/test-hook.sh` (needs network) and `bash tests/run.sh`.
Expected: `hook: payload exact, envelope round-trips, wiring correct, control characters escaped`; the run ends `N passed, 0 failed, S skipped …` with the skips only for tools this machine lacks. `shellcheck -e SC1091 -e SC2016 tests/lib.sh tests/test-ownership.sh` exits 0; `shfmt -d -i 2 -ci -bn tests/lib.sh tests/test-ownership.sh tests/test-vendored-*.sh tests/test-hook.sh` prints nothing.

- [ ] **Step 10: Commit**

```bash
git add tests/lib.sh tests/test-ownership.sh tests/test-vendored-adhd.sh tests/test-vendored-brainstorming.sh tests/test-vendored-diagnosing-bugs.sh tests/test-vendored-scaffolder.sh tests/test-vendored-duplicates.sh tests/test-hook.sh
git commit -m "Bind every drift test to its row of one ownership table" -m "The two parallel arrays in tests/lib.sh become one (pattern, guard) table (names-and-surface spec §16, #61 M7). Each drift test calls guards() with the paths it holds to upstream, and tests/test-ownership.sh reads that line statically, so a guard can no longer be repointed at any test that happens to name the subject: the issue's own reproduction is red. The hook file is named at one site, its row, rather than three.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- tests/lib.sh tests/test-ownership.sh tests/test-vendored-adhd.sh tests/test-vendored-brainstorming.sh tests/test-vendored-diagnosing-bugs.sh tests/test-vendored-scaffolder.sh tests/test-vendored-duplicates.sh tests/test-hook.sh
```

### Task 2: The two hook files take their names from their content (§6)

**Files:**

- Rename: `plugins/software-dev/hooks/payload.md` → `plugins/software-dev/hooks/using-superpowers.md`; `plugins/software-dev/hooks/payload-rules.md` → `plugins/software-dev/hooks/working-rules.md`
- Modify: `plugins/software-dev/hooks/session-start` (lines 4, 12)
- Modify: `bin/bump-superpowers` (lines 5, 9, 33, 64–66, 70, 82, 86, 118–126, 162; it moves to `scripts/bump-superpowers` in Task 4)
- Modify: `bin/upstream-watch` (line 65; it moves to `scripts/upstream-watch` in Task 4)
- Modify: `tests/lib.sh` (the hook row), `tests/test-hook.sh` (whole file), `plugins/software-dev/README.md` (lines 38–43)
- Modify: `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` (the §4.2 heading) and every historical document naming the two files, the flag or the identifiers (146 lines; reviewed diff, P12)

**Interfaces:**

- Consumes: `guards` from Task 1.
- Produces: `scripts/bump-superpowers --emit-using-superpowers <clone-dir>` (the flag, under its Task 4 path) and the function `emit_using_superpowers`; the SessionStart output, byte-identical to today's.

- [ ] **Step 1: Record the hook's output before anything moves**

```bash
CLAUDE_PLUGIN_ROOT="$PWD/plugins/software-dev" plugins/software-dev/hooks/session-start >/tmp/hook-before.json && wc -c /tmp/hook-before.json
```

Expected: one JSON line; note the byte count.

- [ ] **Step 2: Rename the files and the row**

```bash
git mv plugins/software-dev/hooks/payload.md plugins/software-dev/hooks/using-superpowers.md
git mv plugins/software-dev/hooks/payload-rules.md plugins/software-dev/hooks/working-rules.md
sed -i 's#hooks/payload\\\\\.md#hooks/using-superpowers\\\\.md#' tests/lib.sh
grep -n 'using-superpowers' tests/lib.sh
```

Expected: the one row, `$'^plugins/software-dev/hooks/using-superpowers\\.md$\ttests/test-hook.sh'` (the file carries a doubled backslash inside the `$'…'` string, which the pattern above matches). If the `sed` defeats you, edit the row by hand; it is one line.

- [ ] **Step 3: The hook script**

In `plugins/software-dev/hooks/session-start`, line 4 becomes:

```bash
# Reads hooks/using-superpowers.md and hooks/working-rules.md (next to this script),
```

and line 12 becomes:

```bash
payload="$(cat "${SCRIPT_DIR}/using-superpowers.md" && printf '\n' && cat "${SCRIPT_DIR}/working-rules.md")"
```

The variable name changes in Task 5, with the word.

- [ ] **Step 4: The bump script**

In `bin/bump-superpowers` (`scripts/bump-superpowers` after Task 4): line 5 becomes `#   bin/bump-superpowers --emit-using-superpowers DIR print the payload for a clone at DIR`; line 9 becomes `#   regenerated   hooks/using-superpowers.md, skills/brainstorming/ (re-vendored)`; line 13's `payload.md` becomes `using-superpowers.md`; the function `emit_payload` (defined at line 33, called at lines 66 and 122) becomes `emit_using_superpowers`; the flag `--emit-payload` at lines 64, 65 and 70 becomes `--emit-using-superpowers`; `payload_tmp` at lines 82, 86, 121, 122, 123 and 124 becomes `using_superpowers_tmp`; line 120's `payload.md` and line 121's template become `using-superpowers.md` and `"$PLUGIN/hooks/using-superpowers.md.XXXXXX"`; line 123 becomes `mv "$using_superpowers_tmp" "$PLUGIN/hooks/using-superpowers.md" || die "could not replace using-superpowers.md"`; line 126 becomes `die "could not write using-superpowers.md"`; line 162 becomes `"plugins/software-dev/hooks/using-superpowers.md" \`. Then:

```bash
grep -n -E 'payload' bin/bump-superpowers
```

Expected: only lines 5, 27 and 118, the word in prose, which Task 5 takes (line 13's word was the file name and is renamed above).

- [ ] **Step 5: The watch's bump line and the plugin README**

`bin/upstream-watch` (`scripts/upstream-watch` after Task 4) line 65 becomes:

```bash
      report "  \`hooks/using-superpowers.md\` and \`skills/brainstorming/\` before merging."
```

`plugins/software-dev/README.md` lines 38–43 become:

```markdown
- `hooks/session-start`, Claude Code only: a SessionStart hook that injects
  `hooks/using-superpowers.md`, upstream's `using-superpowers` text with its one
  `superpowers:brainstorming` reference repointed at
  `software-dev:brainstorming`, followed by `hooks/working-rules.md`,
  this plugin's own working rules. The Claude manifest declares the hook as
  `hooks/claude-hooks.json`.
```

- [ ] **Step 6: Replace `tests/test-hook.sh`**

The §4.2 oracle goes (§6): `working-rules.md` is the desired state, so the diff against the hook design, the `extract_42` helper, the _specs move when the tree moves_ message and the comment calling the spec maintained are dropped, and the round-trip and `superpowers:<name>` checks stay against `working-rules.md` itself. The three shape checks the diff subsumed (one trailing newline, the worktree rule, no `superpowers:brainstorming`) return in plan B under #63 item 2 (§17); do not add them here. The file:

```bash
#!/usr/bin/env bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (1b) name only skills the superpowers
# subset entry lists in its working-rules file, (2) emit both files as the
# documented JSON envelope so that a JSON parser recovers the additional
# context byte-for-byte, (3) be wired by claude-hooks.json, (4) escape every
# C0 control character, not just the common five, and (5) fail rather than
# emit a rules-only envelope when using-superpowers.md is missing. Needs
# network access for (1).
. "$(dirname "$0")/lib.sh"

# fail() exits immediately, so temporaries have to be freed from a trap or a
# failing assertion leaks them.
cleanup() {
  [ -n "${expected:-}" ] && rm -f "$expected"
  [ -n "${T:-}" ] && rm -rf "$T"
  [ -n "${T2:-}" ] && rm -rf "$T2"
  return 0
}
trap cleanup EXIT

H="$REPO_ROOT/plugins/software-dev/hooks"
[ -f "$H/using-superpowers.md" ] || fail "missing $H/using-superpowers.md"
[ -f "$H/working-rules.md" ] || fail "missing $H/working-rules.md"
[ -f "$H/claude-hooks.json" ] || fail "missing $H/claude-hooks.json"
[ -x "$H/session-start" ] || fail "$H/session-start missing or not executable"
guards plugins/software-dev/hooks/using-superpowers.md

# (1) using-superpowers.md is the recipe's output, exactly. The frame is read
# from upstream's own hooks/session-start rather than transcribed here, and
# the recipe lives in bin/bump-superpowers so a bump and this test cannot
# diverge.
UP="$(fetch_upstream)"
src="$UP/skills/using-superpowers/SKILL.md"
[ "$(sed -n 30p "$src")" = '- "Let'"'"'s build X" → superpowers:brainstorming first, then implementation skills.' ] \
  || fail "upstream line 30 is not the expected superpowers:brainstorming line; re-audit the edit"
expected="$(mktemp)"
bash "$REPO_ROOT/bin/bump-superpowers" --emit-using-superpowers "$UP" >"$expected" \
  || fail "bin/bump-superpowers --emit-using-superpowers failed"
diff "$expected" "$H/using-superpowers.md" || fail "using-superpowers.md != the recipe's output for the pinned clone"
[ "$(grep -c 'software-dev:brainstorming' "$H/using-superpowers.md")" -eq 1 ] || fail "expected exactly one software-dev:brainstorming"
if grep -q 'superpowers:brainstorming' "$H/using-superpowers.md"; then fail "a superpowers:brainstorming reference survived"; fi

# (1b) the first-party rules file names only skills the subset entry lists:
# a working rule that points at a skill the marketplace does not ship is a
# dangling name in every session. Cross-checked against the marketplace,
# which no copy of the file could do.
[ -s "$H/working-rules.md" ] || fail "working-rules.md is empty"
curated="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  printf '%s\n' "$curated" | grep -qxF -- "$name" \
    || fail "working-rules.md names superpowers:$name, which the curated entry does not list"
done < <(grep -o 'superpowers:[a-z-]*' "$H/working-rules.md" | sed 's/^superpowers://' | sort -u)

# (2) envelope round-trip
# CLAUDE_PLUGIN_ROOT mirrors how claude-hooks.json invokes the script; session-start
# itself resolves using-superpowers.md via dirname "$0" and never reads the
# variable, so the ${CLAUDE_PLUGIN_ROOT} expansion asserted in section 3 is
# checked as a string and not exercised as an expansion.
out="$(CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/software-dev" "$H/session-start")"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  || fail "output is not the SessionStart envelope: $out"
[ "$(printf '%s' "$out" | jq 'keys | length')" -eq 1 ] || fail "envelope has extra top-level keys"
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') \
  <(
    cat "$H/using-superpowers.md"
    printf '\n'
    cat "$H/working-rules.md"
  ) \
  || fail "additionalContext does not round-trip to using-superpowers.md + blank line + working-rules.md"
len="$(printf '%s' "$out" | jq '.hookSpecificOutput.additionalContext | length')"
[ "$len" -lt 8000 ] || fail "additionalContext is $len code points; the tripwire is 8000"

# (3) wiring: the Claude manifest declares the hook file, and nothing sits at
# the path Codex loads by fallback when its manifest has no hooks key.
PLUGIN="$REPO_ROOT/plugins/software-dev"
HJ="$H/claude-hooks.json"
[ -z "$(find "$REPO_ROOT/plugins" -name hooks.json)" ] || fail "no plugins/**/hooks/hooks.json may exist: Codex loads that path by fallback"
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$HJ")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$HJ")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HJ")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$HJ")" = 'hooks' ] || fail "claude-hooks.json top level must contain only 'hooks'"
[ "$(jq -r '.hooks' "$PLUGIN/.claude-plugin/plugin.json")" = './hooks/claude-hooks.json' ] || fail "Claude manifest must declare hooks: ./hooks/claude-hooks.json"
[ "$(jq 'has("hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'false' ] || fail "Codex manifest must not declare hooks"
[ "$(jq '.interface.capabilities | index("Lifecycle hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'null' ] || fail "Codex manifest must not claim Lifecycle hooks"
# Scoped to the Codex manifest alone, never folded into the loop below: the
# Claude manifest's own description legitimately says "and its inspector" --
# consistency-audit's subagent ships there -- so a check spanning both files
# would fail on the true claim while catching the false one.
grep -qi 'inspector' "$PLUGIN/.codex-plugin/plugin.json" \
  && fail "Codex manifest advertises an inspector; a Codex plugin cannot ship a subagent"

for f in "$PLUGIN/.claude-plugin/plugin.json" "$PLUGIN/.codex-plugin/plugin.json" "$MARKETPLACE"; do
  if grep -q 'bridge rules' "$f"; then fail "$f still advertises bridge rules"; fi
  if grep -q 'Lifecycle hooks' "$f"; then fail "$f still advertises Lifecycle hooks"; fi
done

# (4) the encoder escapes control characters, not just the common five
T="$(mktemp -d)"
cp "$H/session-start" "$T/session-start"
sample=$'x\x01\x0c\x1b\x1fy "q" \\ end'
printf '%s' "$sample" >"$T/using-superpowers.md"
: >"$T/working-rules.md" # the script reads it; empty keeps the expectation the sample alone
out="$("$T/session-start")"
printf '%s' "$out" | jq -e . >/dev/null || fail "control characters produced invalid JSON"
[ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')" = "$sample" ] \
  || fail "control characters did not round-trip"

# (5) a missing using-superpowers.md must fail loudly: $(...) does not inherit
# -e, so `cat using-superpowers.md; printf '\n'; cat working-rules.md` would
# let a present working-rules.md's zero exit mask the missing file and
# silently emit a rules-only envelope. Assert the `&&`-joined form fails.
T2="$(mktemp -d)"
cp "$H/session-start" "$T2/session-start"
printf 'some rules\n' >"$T2/working-rules.md"
if "$T2/session-start" >/dev/null 2>&1; then
  fail "session-start must exit non-zero when using-superpowers.md is missing"
fi

echo "hook: using-superpowers exact, envelope round-trips, wiring correct, control characters escaped"
```

The `curated` variable and its message change in Task 6; `bin/bump-superpowers` becomes `scripts/bump-superpowers` in Task 4.

- [ ] **Step 7: The hook spec's heading, and the historical pass for the two names**

Line 49 of `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` becomes ``### 4.2 `hooks/working-rules.md`, in full``; the fenced block under it stays as the quotation it always was. Then the reviewed diff (P12) over every historical document, paths and identifiers everywhere, followed by the review:

```bash
sub_all() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 's{'"$re"'}{'"$rep"'}g' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_all '\bpayload-rules\.md\b' 'working-rules.md' $docs
sub_all '\bpayload\.md\b' 'using-superpowers.md' $docs
sub_all '--emit-payload\b' '--emit-using-superpowers' $docs
sub_all '\bemit_payload\b' 'emit_using_superpowers' $docs
sub_all '\bpayload_tmp\b' 'using_superpowers_tmp' $docs
git diff --stat -- docs/superpowers
```

Expected: eleven documents changed. Now review every hunk (`git diff -- docs/superpowers`) against §6's boundary and revert what stays, with `git checkout -p -- <file>` or by hand: inside a fenced block that reproduces tool output, a quoted manifest or a measurement, and inside quotation marks, the old name stays (a fence quoting `tests/run.sh`'s output at the time, a quoted `git diff --stat`, a `wc -c` measurement of `payload.md`); a fenced block that is a command to run, a code listing to write, a heading, and prose keep the new name. Expect most hunks to stand. Then:

```bash
git grep -n -E 'payload(-rules)?\.md|emit.payload|payload_tmp' -- docs/superpowers | wc -l
```

Expected: a small number, every one inside an output-reproducing fence or quotation; record it in the commit body.

- [ ] **Step 8: Prove the output is byte-identical, and the suite green**

```bash
CLAUDE_PLUGIN_ROOT="$PWD/plugins/software-dev" plugins/software-dev/hooks/session-start >/tmp/hook-after.json && cmp /tmp/hook-before.json /tmp/hook-after.json && echo identical
```

Expected: `identical`. Then `bash tests/test-hook.sh` (network), `bash tests/test-ownership.sh`, `shellcheck -e SC1091 -e SC2016 tests/test-hook.sh bin/bump-superpowers plugins/software-dev/hooks/session-start` and `shfmt -d -i 2 -ci -bn tests/test-hook.sh bin/bump-superpowers` (the bump script is `scripts/bump-superpowers` from Task 4 on), `prettier --check $(git ls-files 'docs/superpowers/*.md') plugins/software-dev/README.md`, and `bash tests/run.sh`.
Expected: `hook: using-superpowers exact, envelope round-trips, wiring correct, control characters escaped`; `ownership: 6 row(s), each bound to its guard; …`; every checker silent; the run green.

- [ ] **Step 9: Commit**

```bash
git add plugins/software-dev/hooks/using-superpowers.md plugins/software-dev/hooks/working-rules.md plugins/software-dev/hooks/session-start bin/bump-superpowers bin/upstream-watch tests/lib.sh tests/test-hook.sh plugins/software-dev/README.md docs/superpowers
git commit -m "Name the two hook files by their content: using-superpowers.md and working-rules.md" -m "The first is upstream superpowers' own session-start text, vendored and byte-pinned; the second already titled itself working rules (names-and-surface spec §6). The rename goes through the ownership table's one row. The hook design's §4.2 fence stops being an oracle: working-rules.md is the desired state, so tests/test-hook.sh drops the diff against the spec and keeps the round-trip and the subset-entry name check against the file itself; the three shape checks that diff subsumed return in plan B (#63). The SessionStart output is byte-identical. Historical documents carry the new names by reviewed diff; N old names stay inside quoted output.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- plugins/software-dev/hooks bin/bump-superpowers bin/upstream-watch tests/lib.sh tests/test-hook.sh plugins/software-dev/README.md docs/superpowers
```

Replace `N` with the count from Step 7.

### Task 3: `skills.json` moves to the root, and the silence fixture with it (§6)

**Files:**

- Rename: `upstream/skills.json` → `skills.json` (the directory `upstream/` goes with it)
- Modify: `bin/setup` (lines 11, 30), `bin/upstream-watch` (lines 14, 90; `scripts/upstream-watch` after Task 4), `plugins/sensemaking/README.md` (line 21)
- Modify: `tests/test-doctor-silence.sh` (lines 33, 36, 142, 149–150), `tests/test-doctor-faults.sh` (lines 141, 149, 188), `tests/test-setup-upgrade.sh` (line 76), `tests/test-skills-pin.sh` (lines 2, 11), `tests/test-vendored-diagnosing-bugs.sh` (lines 3, 18, 20, 71, 72), `tests/test-vendored-scaffolder.sh` (lines 203, 208, 219)
- Modify: every historical document naming the path (68 lines; reviewed diff)

**Interfaces:**

- Produces: `skills.json` at the repository root; `SKILLS_JSON="$REPO_ROOT/skills.json"` in `bin/setup` and the watch; the silence fixture's `scratch_repo` seeding `$r/skills.json`.

- [ ] **Step 1: Move the file**

```bash
git mv upstream/skills.json skills.json && [ ! -e upstream ] && echo "upstream/ gone"
```

Expected: `upstream/ gone` (the manifest is `skills.json` now). Then `bash tests/test-skills-pin.sh` fails with `FAIL: missing /…/upstream/skills.json` and `bash tests/test-doctor-silence.sh` fails at `could not copy skills.json`: the readers are red.

- [ ] **Step 2: The readers**

Every site is the literal `upstream/skills.json`; the replacement is `skills.json`, with one exception in the fixture. In `bin/setup` line 11 the header column becomes `#   skills.json                       the skills.sh set: repo, ref, names` (keep the column aligned with the marketplace line above it) and line 30 becomes `SKILLS_JSON="$REPO_ROOT/skills.json"`. In `bin/upstream-watch` (`scripts/upstream-watch` after Task 4) line 14 becomes `SKILLS_JSON="$REPO_ROOT/skills.json"` and the report line 90 names `skills.json`. In `plugins/sensemaking/README.md` line 21 names `skills.json`. In the four tests, `"$REPO_ROOT/upstream/skills.json"` becomes `"$REPO_ROOT/skills.json"` at every site, and the comments and failure texts that spell the path out name `skills.json`. In `tests/test-doctor-silence.sh` the fixture's layout changes with the file: `scratch_repo` at lines 31–38 becomes

```bash
scratch_repo() {
  local r="$T/$1"
  mkdir -p "$r/bin" "$r/.claude-plugin" || fail "could not seed $r"
  ln -s "$REPO_ROOT/bin/setup" "$r/bin/setup" || fail "could not link bin/setup into $r"
  cp "$MARKETPLACE" "$r/.claude-plugin/marketplace.json" || fail "could not copy the marketplace into $r"
  cp "$REPO_ROOT/skills.json" "$r/skills.json" || fail "could not copy skills.json into $r"
  printf '%s\n' "$r"
}
```

and fixture 8 (lines 142–150) reads `"$REPO_ROOT/skills.json"` and writes `"$R/skills.json"`. Then:

```bash
git grep -n 'upstream/skills' -- . ':(exclude)docs/superpowers'
```

Expected: nothing.

- [ ] **Step 3: The historical pass**

```bash
sub_all() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 's{'"$re"'}{'"$rep"'}g' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_all '\bupstream/skills\.json\b' 'skills.json' $docs
git diff -- docs/superpowers | grep -c '^[-+]'
```

Then review every hunk against §6's boundary and revert what stays: a fenced block that reproduces the file's own contents or a `git diff --stat`, a quoted failure line, and the four sentences whose subject is the old path (the spec's §6 bullet and §3 row; #26's quoted comment in the roster spec, if quoted). In this spec, the §22 row that measures `upstream/skills.json` (now `skills.json`) takes git's form, `1dd7362:upstream/skills.json` (P4). Then:

```bash
git grep -n 'upstream/skills\.json' -- docs/superpowers | wc -l
```

Expected: the kept sites only; record the count.

- [ ] **Step 4: Suite**

Run: `bash tests/test-skills-pin.sh` (network), `bash tests/test-doctor-silence.sh`, `bash tests/test-doctor-faults.sh`, `bash tests/test-vendored-diagnosing-bugs.sh` (network), `bash tests/test-vendored-scaffolder.sh` (network), `bash tests/test-setup-doctor.sh`, then `bash tests/run.sh`.
Expected: each prints its summary line; the run is green. `prettier --check skills.json plugins/sensemaking/README.md $(git ls-files 'docs/superpowers/*.md')` is silent.

- [ ] **Step 5: Commit**

```bash
git add skills.json bin/setup bin/upstream-watch plugins/sensemaking/README.md tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-upgrade.sh tests/test-skills-pin.sh tests/test-vendored-diagnosing-bugs.sh tests/test-vendored-scaffolder.sh docs/superpowers
git commit -m "Move the skills.sh manifest to the root as skills.json" -m "upstream/ held nothing else, and upstream is git's word for the repository you forked from; skills.json is a dependency manifest, and manifests sit at the root (names-and-surface spec §6). The silence fixture's layout follows. Historical documents carry the new path by reviewed diff; N old paths stay inside quoted output and the sentences that record the move.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- skills.json bin/setup bin/upstream-watch plugins/sensemaking/README.md tests docs/superpowers
```

### Task 4: `scripts/` for what CI and the maintainer run, and `AGENTS.md`'s two lines (§6)

**Files:**

- Rename: `bin/upstream-watch` → `scripts/upstream-watch`; `bin/bump-superpowers` → `scripts/bump-superpowers`; `bin/format` → `scripts/format`
- Modify: `cspell.config.yaml` (the override's `filename` list), `.github/workflows/upstream-watch.yml` (lines 37, 75), `AGENTS.md` (lines 39–41)
- Modify: `scripts/upstream-watch` (lines 4, 64), `scripts/bump-superpowers` (lines 4, 5, 70), `scripts/format` (line 12), `tests/lib.sh` (lines 2, 123, 126), `tests/test-hook.sh` (the recipe lines), `tests/test-setup-doctor.sh` (line 20), `tests/test-format-prettier.sh` (line 18), `tests/test-format-shell.sh` (lines 3, 11), `tests/test-lint-markdown.sh` (line 4), `.markdownlint-cli2.jsonc` (line 2), `.prettierrc.yaml` (line 1), `README.md` (line 107)
- Modify: every historical document naming the three paths (85 lines; reviewed diff)

**Interfaces:**

- Produces: `scripts/upstream-watch`, `scripts/bump-superpowers`, `scripts/format`, each run from the repository root as before; `cspell.config.yaml`'s override covers `scripts/*`.

- [ ] **Step 1: Reproduce the spelling regression the spec names**

```bash
mkdir -p scripts && git mv bin/upstream-watch scripts/upstream-watch && git mv bin/bump-superpowers scripts/bump-superpowers && git mv bin/format scripts/format && cspell --no-progress --config cspell.config.yaml scripts/upstream-watch scripts/bump-superpowers scripts/format | tail -n 1
```

Expected: `CSpell: Files checked: 3, Issues found: N in 3 files` with N around 20: with no override for `scripts/*`, cspell reads the three files whole rather than their `#` comments.

- [ ] **Step 2: The override**

In `cspell.config.yaml`, the `overrides:` `filename:` list gains one line after `- "bin/*"`:

```yaml
      - "scripts/*"
```

Re-run the cspell line from Step 1. Expected: `Issues found: 0`.

- [ ] **Step 3: Every reference**

Each site is a literal path; write the new one. `.github/workflows/upstream-watch.yml` line 37 becomes `bash scripts/upstream-watch > "$RUNNER_TEMP/report.md" 2>&1` and line 75 becomes `echo "scripts/upstream-watch could not complete; see the step log"`, each at its current indentation. `scripts/upstream-watch` line 4 names `scripts/bump-superpowers`, and line 64 becomes:

```bash
      report "- Bump with \`scripts/bump-superpowers $head_sha\`, then read the diff to"
```

`scripts/bump-superpowers` lines 4, 5 and 70 name `scripts/bump-superpowers`. `scripts/format` line 12 becomes `command -v "$t" >/dev/null 2>&1 || fail "scripts/format needs $t on PATH; the versions are in tests/tools.txt"`, indented as before. `tests/lib.sh` line 2 becomes `# Shared helpers for tests/test-*.sh and scripts/format. Source this file; do not execute it.`, and lines 123 and 126 name `scripts/format`. `tests/test-hook.sh`: the two lines that run `"$REPO_ROOT/bin/bump-superpowers"` and its failure text, and the comment above them, name `scripts/bump-superpowers`. `tests/test-setup-doctor.sh` line 20 runs `bash "$REPO_ROOT/scripts/upstream-watch" --newest-stable-tag`. `tests/test-format-prettier.sh` line 18, `tests/test-format-shell.sh` lines 3 and 11 and `tests/test-lint-markdown.sh` line 4 say `scripts/format`. `.markdownlint-cli2.jsonc` line 2 and `.prettierrc.yaml` line 1 say `scripts/format`. `README.md` line 107 says `scripts/format`. Then:

```bash
git grep -n -E 'bin/(upstream-watch|bump-superpowers|format)' -- . ':(exclude)docs/superpowers'
```

Expected: nothing.

- [ ] **Step 4: `AGENTS.md`'s two lines**

Lines 39–41 of `AGENTS.md` (under `### Security scanning`) become:

```markdown
`finding-discovery`) is explicit-invocation only. This repository ships
`bin/setup` and a SessionStart hook, so run a scan yourself on a diff that
touches `bin/`, `scripts/`, `plugins/software-dev/hooks/`, or a workflow.
```

Only the `## Codex only` section changes; `### Design discipline` and `### Task reports` are held byte-identical to the scaffolder's block by `tests/test-vendored-scaffolder.sh` and are not touched.

- [ ] **Step 5: The historical pass**

```bash
sub_all() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 's{'"$re"'}{'"$rep"'}g' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_all '\bbin/upstream-watch\b' 'scripts/upstream-watch' $docs
sub_all '\bbin/bump-superpowers\b' 'scripts/bump-superpowers' $docs
sub_all '\bbin/format\b' 'scripts/format' $docs
```

Review every hunk against §6's boundary and revert what stays: quoted output (`tests/run.sh`'s summary lines, `git diff --stat`), the spec's §3 row and §6 bullet, and #26's quoted audience table if it is quoted. In this spec, §21's bullet (the one keeping `bin/format` in `bin/`) gains its successor, `scripts/format`, in the words `; it is scripts/format now` before its full stop, and the §22 row that reduced `bin/format` to `exit 0` takes git's form, `1dd7362:bin/format` (P4). Then `git grep -n -E 'bin/(upstream-watch|bump-superpowers|format)' -- docs/superpowers | wc -l` and record the count.

- [ ] **Step 6: Suite**

Run: `bash tests/test-spelling.sh`, `bash tests/test-setup-doctor.sh`, `bash tests/test-hook.sh` (network), `bash tests/test-workflows.sh`, `bash tests/test-ownership.sh`, then `bash tests/run.sh`.
Expected: `spelling: … shell …` counts the same 37 shell files, since `checked_shell()` selects by shebang; `ownership: … 37 of them shell`; everything green. `prettier --check cspell.config.yaml .github/workflows/upstream-watch.yml README.md AGENTS.md $(git ls-files 'docs/superpowers/*.md')` is silent.

- [ ] **Step 7: Commit**

```bash
git add scripts/upstream-watch scripts/bump-superpowers scripts/format cspell.config.yaml .github/workflows/upstream-watch.yml AGENTS.md tests/lib.sh tests/test-hook.sh tests/test-setup-doctor.sh tests/test-format-prettier.sh tests/test-format-shell.sh tests/test-lint-markdown.sh .markdownlint-cli2.jsonc .prettierrc.yaml README.md docs/superpowers
git commit -m "Split bin/ by audience: setup and doctor stay, the maintainer's three scripts move to scripts/" -m "bin/ is what a user is told to run; the watch, the bump and the formatter are run by CI or by the maintainer (names-and-surface spec §6, #26). cspell's comment-only override gains scripts/* in the same change, or spelling goes red on the three files whole. AGENTS.md's scan note names bin/setup and the hook, and scripts/ joins the surfaces a Codex scan covers. Historical documents carry the new paths by reviewed diff; N old paths stay inside quoted output and the sentences that record the move.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- scripts cspell.config.yaml .github/workflows/upstream-watch.yml AGENTS.md tests .markdownlint-cli2.jsonc .prettierrc.yaml README.md docs/superpowers
```

### Task 5: `additional context` replaces the largest retired word (§5.1)

**Files:**

- Modify: `plugins/software-dev/hooks/session-start` (lines 12, 38), `scripts/bump-superpowers` (lines 5, 13, 27, 118)
- Modify: every historical document carrying the word (148 lines, 79 of them in prose; reviewed diff)

**Interfaces:**

- Consumes: the file names from Task 2 (so `payload-rules.md` and `payload.md` no longer appear in prose, and a word-boundary substitution cannot mangle them).
- Produces: no `payload` or `payloads` in any checked file outside `docs/superpowers/`. Task 15's test enforces it.

- [ ] **Step 1: The durable sites**

Run `git grep -n -i -w -E 'payloads?' -- . ':(exclude)docs/superpowers'`. Expected: five lines, all of which change:

- `plugins/software-dev/hooks/session-start` line 12: the variable `payload` becomes `context`, so the line reads `context="$(cat "${SCRIPT_DIR}/using-superpowers.md" && printf '\n' && cat "${SCRIPT_DIR}/working-rules.md")"`, and line 38 reads `"$(escape_for_json "$context")"`, indented as before.
- `scripts/bump-superpowers` line 5: `print the additional context for a clone at DIR`; line 13: `and using-superpowers.md,` (the word was already the file name; if the line still says `payload.md`, that is a Task 2 miss); line 27: `# The one copy of the additional-context recipe. $1 is a checkout of obra/superpowers.`; line 118: `# 2. regenerated: the additional context, then the vendored brainstorming tree. Written`.

Re-run the grep. Expected: nothing.

- [ ] **Step 2: The historical pass**

Terms are substituted outside fences only (P12), then reviewed. The helper tracks a fence the way the scanner does: a run of three or more backticks or tildes opens one, and only a run of the same character at least as long closes it, because two historical plans (the setup-and-drift plan and the suite-and-ci plan) quote three-backtick fences inside four-backtick ones; its state resets at each file's end.

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])Payload(?![\w.-])' 'Additional context' $docs
sub_prose '(?<![\w.-])payloads(?![\w.-])' 'additional contexts' $docs
sub_prose '(?<![\w.-])payload(?![\w.-])' 'additional context' $docs
git diff --stat -- docs/superpowers
```

Review every hunk against §6's boundary and revert what stays: the word inside quotation marks (a quoted issue title, a quoted comment); a sentence whose subject is the word itself (this spec's §5.1 table row and §5.5 entry, #26's quoted table, the hook spec's title `SessionStart hook payload` is a title and is kept); and any line where the substitution produced a phrase that no longer parses (`the additional context recipe` reads; `hook additional context` reads; `Additional context base` in a table's first column reads). Fenced blocks were not touched. Then:

```bash
git grep -n -i -w -E 'payloads?' -- docs/superpowers | wc -l
```

Expected: the kept sites plus every fenced site; record the two numbers in the commit body (`git grep -n -i -w payload -- docs/superpowers | awk -F: '…'` is not needed; count by eye from the list, which is short once the prose is done).

- [ ] **Step 3: Suite and commit**

Run `bash tests/test-hook.sh` (network), `shellcheck -e SC1091 -e SC2016 plugins/software-dev/hooks/session-start scripts/bump-superpowers`, `prettier --check $(git ls-files 'docs/superpowers/*.md')`, then `bash tests/run.sh`. Expected: green, silent, green. The hook's output is unchanged (the variable name is not in it).

```bash
git add plugins/software-dev/hooks/session-start scripts/bump-superpowers docs/superpowers
git commit -m "Say additional context, Claude Code's own name for what the hook prints" -m "The old word means the JSON a CLI passes into a hook, the opposite of how this repository used it (names-and-surface spec §5.1, #26). Durable sites: the hook script's variable and the bump script's comments. Historical documents by reviewed diff: N prose sites kept where the word is quoted or is the sentence's subject; fenced blocks untouched.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- plugins/software-dev/hooks/session-start scripts/bump-superpowers docs/superpowers
```

### Task 6: `subset entry` replaces `curated`, in the engine's report text, the manifests and a test's name (§5.1)

**Files:**

- Rename: `tests/test-curated-writing-clearly-and-concisely.sh` → `tests/test-subset-writing-clearly-and-concisely.sh`
- Modify: `bin/setup` (lines 9, 35, 178–181, 209, 216, 268–269, 283–302, 306, 314, 482, 493, 516, 736), `tests/test-doctor-silence.sh` (lines 69–83, 97, 111, 163), `tests/test-doctor-duplicates.sh` (line 40), `tests/test-doctor-faults.sh` (line 28), `tests/test-setup-upgrade.sh` (line 43), `tests/test-upstream-pin.sh` (line 2), `tests/test-plugin-skills.sh` (lines 10, 18, 43–44), `tests/test-hook.sh` (the `curated` variable and its message), `scripts/upstream-watch` (lines 48, 67), `README.md` (lines 8, 38, 62), `plugins/software-dev/README.md` (lines 53, 60, 135), `.claude-plugin/marketplace.json` (lines 21, 50), `plugins/software-dev/.codex-plugin/plugin.json` (line 13)
- Modify: every historical document carrying the word (129 lines; reviewed diff)

**Interfaces:**

- Produces: `subset_entries()` in `bin/setup`; the report strings below, which `tests/test-doctor-silence.sh` asserts; the watch's bump template naming `tests/test-subset-$name.sh`.

- [ ] **Step 1: The engine and the silence test, one edit**

In `bin/setup`, the function `curated_entries` (line 180, called at lines 268 and 516) becomes `subset_entries`, and these strings change, each with its assertion in `tests/test-doctor-silence.sh`:

| `bin/setup` line | Before                                                              | After                                                                  |
| ---------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 209              | `the curated entries cannot be read, so no pinned clone is checked` | `the subset entries cannot be read, so no pinned clone is checked`     |
| 216, 493         | `a curated entry is malformed: name=…`                              | `a subset entry is malformed: name=…`                                  |
| 269              | `no curated (git-subdir) entry could be read from $MARKETPLACE`     | `no subset (git-subdir) entry could be read from $MARKETPLACE`         |
| 285              | `the curated skill list cannot be read, so no link is checked`      | `the subset entries' skill list cannot be read, so no link is checked` |
| 298              | `the curated skill list could not be read from $MARKETPLACE`        | `the subset entries' skill list could not be read from $MARKETPLACE`   |
| 302              | `no curated skill is declared in $MARKETPLACE`                      | `no subset entry declares a skill in $MARKETPLACE`                     |
| 314              | `a curated skill line is malformed: entry=…`                        | `a subset entry's skill line is malformed: entry=…`                    |

The comments at lines 9, 35, 178, 283, 288, 306, 482 and 736 say `subset entry` (`every subset (git-subdir) entry`, `One pinned clone per subset (git-subdir) marketplace entry`, `the thirteen subset-entry links into the pinned clone`). In `tests/test-doctor-silence.sh`, the `saw` patterns at lines 69, 71, 80, 82, 97, 111 and 163 take the new strings verbatim; the labels `no curated entries` at lines 79, 81 and 83 become `no subset entries`; the comments at lines 74–75 say `zero subset entries`. `tests/test-doctor-duplicates.sh` line 40's skill body says `epsilon from the subset entry`. Comments in `tests/test-doctor-faults.sh` line 28, `tests/test-setup-upgrade.sh` line 43 and `tests/test-upstream-pin.sh` line 2 say `subset entry` (`Every other subset entry`, `The superpowers subset entry`).

- [ ] **Step 2: The two tests that read the entry's skill list, and the watch**

`tests/test-plugin-skills.sh`: line 10's comment says `subset entry excludes`; the variable `curated` (lines 18 and 43) becomes `subset`; line 44's message becomes `which the superpowers subset entry does not list`. `tests/test-hook.sh`: the variable `curated` becomes `subset` and its message `which the subset entry does not list`. `scripts/upstream-watch`: line 48's comment says `Each subset entry`, and line 67's template becomes:

```bash
      report "- Bump by editing \`.claude-plugin/marketplace.json\`: move \`sha\` and \`version\` together, then update the pinned pair in \`tests/test-subset-$name.sh\`."
```

Then the file:

```bash
git mv tests/test-curated-writing-clearly-and-concisely.sh tests/test-subset-writing-clearly-and-concisely.sh
```

and inside it, line 2 becomes `# The writing-clearly-and-concisely subset entry points at a real` and the summary line 45 begins `subset-writing:`.

- [ ] **Step 3: The READMEs and the manifests**

`README.md` line 8: `a curated upstream` becomes `a subset entry taken from an upstream at a pinned commit`; line 38: `curated at a pinned commit from upstream's published plugin` becomes `a subset entry at a pinned commit, taken from upstream's published plugin` (the whole section is rewritten in Task 13; the word goes now); line 62: `a pinned clone per curated entry` becomes `a pinned clone per subset entry`. `plugins/software-dev/README.md` line 53: `curated at a pinned commit` becomes `a subset entry at a pinned commit`; line 60: `the fourteen curated symlinks` becomes `the fourteen subset-entry symlinks`; line 135: `pins both curated entries` becomes `pins both subset entries`. `.claude-plugin/marketplace.json` line 21 becomes `"description": "obra/superpowers, a subset entry: the process spine without brainstorming.",` and line 50 `"description": "softaworks/agent-toolkit, a subset entry: one skill, Strunk's rules for prose humans read.",`. `plugins/software-dev/.codex-plugin/plugin.json` line 13 becomes `"shortDescription": "Software-development skills for Claude Code and Codex",` (P9). Then:

```bash
git grep -n -i -E 'curated|curation' -- . ':(exclude)docs/superpowers'
```

Expected: nothing.

- [ ] **Step 4: The historical pass**

The word is not a drop-in, so the scripted pass takes the phrases that are, and the rest is edited from the list:

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])curated \(git-subdir\) entr(y|ies)(?![\w.-])' 'subset (git-subdir) entr$1' $docs
sub_prose '(?<![\w.-])curated entr(y|ies)(?![\w.-])' 'subset entr$1' $docs
sub_prose '(?<![\w.-])Curated entr(y|ies)(?![\w.-])' 'Subset entr$1' $docs
sub_prose '(?<![\w.-])curated_entries(?![\w.-])' 'subset_entries' $docs
sub_prose '(?<![\w.-])test-curated-' 'test-subset-' $docs
git grep -n -i -E 'curated|curation' -- docs/superpowers
```

Edit each remaining prose site by hand: `curated skill(s)` and `curated link(s)` become `subset-entry skill(s)` and `subset-entry link(s)`; `obra/superpowers, curated` becomes `obra/superpowers, a subset entry`; `curated at a pinned commit` becomes `a subset entry at a pinned commit`; `the curation` becomes `the subset entry`; a report string quoted inline (`` `no curated (git-subdir) entry could be read` ``) takes the new string, since a current reader running the doctor sees it. Then review every hunk against §6's boundary and revert what stays: the word in quotation marks, in a fenced block (the scripted pass skipped these; the hand edits must too), and in a sentence whose subject is the word (this spec's §5.1 row and §5.5 entry, #26's quoted table row `"Curated" reads as editorial praise`). `git grep -n -i -E 'curated|curation' -- docs/superpowers | wc -l` and record the count.

- [ ] **Step 5: Suite and commit**

Run `bash tests/test-doctor-silence.sh`, `bash tests/test-doctor-duplicates.sh`, `bash tests/test-doctor-faults.sh`, `bash tests/test-plugin-skills.sh`, `bash tests/test-subset-writing-clearly-and-concisely.sh` (network), `bash tests/test-hook.sh` (network), `bash tests/test-setup-doctor.sh`, `bash tests/test-json-wellformed.sh`, `bash tests/test-references-resolve.sh`, then `shellcheck -e SC1091 -e SC2016 bin/setup scripts/upstream-watch tests/test-*.sh`, `prettier --check .claude-plugin/marketplace.json plugins/software-dev/.codex-plugin/plugin.json README.md plugins/software-dev/README.md $(git ls-files 'docs/superpowers/*.md')`, and `bash tests/run.sh`. Expected: `doctor-silence: 10 unreadable machines, none reported clean`; `subset-writing: dist == source at 3027f20f…`; everything green and silent.

```bash
git add bin/setup tests/test-doctor-silence.sh tests/test-doctor-duplicates.sh tests/test-doctor-faults.sh tests/test-setup-upgrade.sh tests/test-upstream-pin.sh tests/test-plugin-skills.sh tests/test-hook.sh tests/test-subset-writing-clearly-and-concisely.sh scripts/upstream-watch README.md plugins/software-dev/README.md .claude-plugin/marketplace.json plugins/software-dev/.codex-plugin/plugin.json docs/superpowers
git commit -m "Say subset entry for a marketplace entry that takes part of an upstream" -m "The old word read as editorial praise; the operation is a subtraction (names-and-surface spec §5.1, #26). The engine's function and report strings, the silence test's assertions, the two manifests, the READMEs, the watch's bump template and the test it names change together. Historical documents by reviewed diff: N sites kept where the word is quoted or is the sentence's subject.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- bin/setup tests scripts/upstream-watch README.md plugins/software-dev/README.md .claude-plugin/marketplace.json plugins/software-dev/.codex-plugin/plugin.json docs/superpowers
```

### Task 7: `desired state` replaces `declaration` (§5.1)

**Files:**

- Modify: `bin/setup` (lines 7, 17, 46, 64, 102, 144, 871, 872), `README.md` (lines 54, 76), `.github/workflows/validate.yml` (line 127), `tests/test-doctor-silence.sh` (lines 5, 29, 56, 70, 72, 75, 116, 169)
- Modify: every historical document carrying the word (25 lines; reviewed diff)

**Interfaces:**

- Produces: `usage()` in `bin/setup` saying `Both read the desired state from the checkout the script lives in`; the README's Install prose saying the same, since `tests/test-setup-doctor.sh` holds only the fenced blocks equal and this is prose.

- [ ] **Step 1: The durable sites**

Run `git grep -n -i -w -E 'declarations?' -- . ':(exclude)docs/superpowers'`. Expected: nineteen lines, all of which change. `bin/setup`: line 7 becomes `# The desired state is read from the checkout this script lives in, never from the`; line 17 `# exits early, with status 2.` keeps its shape with `a missing desired-state file` in place of `a missing declaration`; line 46 `# main and test the wrong desired state.`; line 64 `# missing reader of the desired state is a different kind of absence -- nothing`; line 102 `# the desired state malformed, then iterates an empty skill list and an empty`; line 144 `Both read the desired state from the checkout the script lives in, and reach`; lines 871–872 `die "no desired state beside this script: $MARKETPLACE is missing"` and the same for `$SKILLS_JSON`. `README.md` line 54: `and reads the desired state from it`; line 76: `The marketplace clone carries both the new desired state and the new copy of the`. `.github/workflows/validate.yml` line 127: `# would clone origin main and the run would test the wrong desired state.` `tests/test-doctor-silence.sh`: line 5 `beside a corrupted desired-state file`; line 29 `intact copies of both desired-state files`; line 56 `reaches the desired state it reads`; lines 70 and 72 `did not report the unreadable desired state`; line 75 `is a desired-state defect, not a clean machine`; line 116 `repository's own desired state`; line 169 `no desired-state shape is silent any more`. Re-run the grep. Expected: nothing.

- [ ] **Step 2: The historical pass**

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])Declarations?(?![\w.-])' 'Desired state' $docs
sub_prose '(?<![\w.-])declarations?(?![\w.-])' 'desired state' $docs
git grep -n -i -w -E 'declarations?' -- docs/superpowers
```

Review every hunk against §6's boundary and revert what stays: the word in quotation marks, in a sentence whose subject is the word (this spec's §5.1 row and §5.5 entry, #26's quoted table), and any site where `desired state` no longer parses (`both desired state` becomes `both desired-state files`; `a declaration defect` was covered above). The verb `declare` and the adjective `declared` are different words and were not matched. `git grep -n -i -w -E 'declarations?' -- docs/superpowers | wc -l` and record the count.

- [ ] **Step 3: Suite and commit**

Run `bash tests/test-setup-doctor.sh`, `bash tests/test-doctor-silence.sh`, `bash tests/test-workflows.sh`, `shellcheck -e SC1091 -e SC2016 bin/setup tests/test-doctor-silence.sh`, `prettier --check README.md .github/workflows/validate.yml $(git ls-files 'docs/superpowers/*.md')`, then `bash tests/run.sh`. Expected: green and silent.

```bash
git add bin/setup README.md .github/workflows/validate.yml tests/test-doctor-silence.sh docs/superpowers
git commit -m "Say desired state for what the manifests declare and bin/setup converges to" -m "Configuration management's term, which names the engine's whole shape; the verb declare stays (names-and-surface spec §5.1, #26). Historical documents by reviewed diff: N sites kept where the word is quoted or is the sentence's subject.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- bin/setup README.md .github/workflows/validate.yml tests/test-doctor-silence.sh docs/superpowers
```

### Task 8: `first-party` replaces `authored` (§5.1, §5.3)

**Files:**

- Modify: `README.md` (line 27), `plugins/software-dev/README.md` (lines 6, 24), `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md` (line 9) with `tests/test-vendored-duplicates.sh` (lines 5, 49), `tests/lib.sh` (the table comment, if the word is still there), `tests/test-codex-validate.sh` (line 44), `tests/test-hook.sh` (the (1b) comment, if the word is still there), `tests/test-plugin-skills.sh` (line 3), `tests/test-spelling.sh` (line 7)
- Modify: every historical document carrying the word (50 lines; reviewed diff)

**Interfaces:**

- Produces: the provenance header line in `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md` and the `expected_header` line in `tests/test-vendored-duplicates.sh`, byte-identical:

```text
     scripts/find-duplicates-prompt.md are upstream's, byte for byte; everything else is first-party.
```

- [ ] **Step 1: The coupled pair, then the rest**

Run `git grep -n -i -w authored -- . ':(exclude)docs/superpowers'`. Expected: the eleven lines below at most (Tasks 1 and 2 rewrote two of them). Line 9 of `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md` and line 49 of `tests/test-vendored-duplicates.sh` both end `everything else is first-party.` in place of `everything else is authored here.`; line 5 of the test says `The rest is first-party and is checked for shape, not`. `README.md` line 27: ``the first-party `consistency-audit` with its inspector agent``. `plugins/software-dev/README.md` line 6: `a first-party skill and agent, each with its own provenance below.`; line 24: `a first-party audit, user-invoked, that reads a repository whole for` (Task 9 changes `user-invoked`). `tests/test-codex-validate.sh` line 44: `policy Codex reads: the vendored scaffolder, the first-party consistency`. `tests/test-plugin-skills.sh` line 3: `# first-party assets that have no upstream to drift from.` `tests/test-spelling.sh` line 7: `# spelling inside a first-party SKILL.md is an edit to the skill and goes`. Re-run the grep. Expected: nothing.

- [ ] **Step 2: The historical pass**

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])authored here(?![\w.-])' 'first-party' $docs
sub_prose '(?<![\w.-])Authored(?![\w.-])' 'First-party' $docs
sub_prose '(?<![\w.-])authored(?![\w.-])' 'first-party' $docs
git grep -n -i -w authored -- docs/superpowers
```

Review every hunk against §6's boundary and revert what stays: the verb (`the maintainer authored`, `a spec authored on`, rare), the word in quotation marks or inside a fence, and a sentence whose subject is the word (this spec's §5.1 row and §5.5 entry, #26's table). Where the substitution left `is first-party` for `is authored here` it reads; where it left `an first-party` fix the article. `git grep -n -i -w authored -- docs/superpowers | wc -l` and record the count.

- [ ] **Step 3: Suite and commit**

Run `bash tests/test-vendored-duplicates.sh` (network, needs `python3`), `bash tests/test-plugin-skills.sh`, `bash tests/test-codex-validate.sh` (needs the validator; skipped otherwise), `prettier --check README.md plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/SKILL.md $(git ls-files 'docs/superpowers/*.md')`, then `bash tests/run.sh`. Expected: `vendored-duplicates: two templates match obra/superpowers-lab 51111f7…`; green and silent.

```bash
git add README.md plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/SKILL.md tests/test-vendored-duplicates.sh tests/test-codex-validate.sh tests/test-plugin-skills.sh tests/test-spelling.sh docs/superpowers
git commit -m "Say first-party for what is written here" -m "Its opposite is third-party, which is exactly the distinction (names-and-surface spec §5.1, #26). The fork's provenance header and the drift test that pins it change in one commit. Historical documents by reviewed diff: N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- README.md plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/SKILL.md tests docs/superpowers
```

### Task 9: `user-invocable only` replaces `gated` as a skill property, and the word leaves its other senses (§5.1)

**Files:**

- Modify: `tests/test-plugin-skills.sh` (lines 5, 29–34, 68), `tests/test-codex-validate.sh` (lines 3, 38, 43), `tests/test-vendored-adhd.sh` (line 6), `tests/test-vendored-diagnosing-bugs.sh` (lines 6, 65, 67, 68), `tests/test-vendored-scaffolder.sh` (line 59), `bin/setup` (line 800), `tests/test-doctor-duplicates.sh` (line 91), `tests/test-setup-doctor.sh` (lines 5, 31, 78), `plugins/software-dev/skills/consistency-audit/SKILL.md` (line 141), `plugins/software-dev/README.md` (lines 20, 24), `plugins/sensemaking/README.md` (line 41)
- Modify: every historical document carrying the word (56 lines; reviewed diff)

**Interfaces:**

- Produces: `claude_user_invocable` and `codex_user_invocable` in `tests/test-plugin-skills.sh`; the message `is user-invocable only on one CLI (Claude …, Codex …); each such skill carries both gates`.

- [ ] **Step 1: The skill sense**

Run `git grep -n -i -w gated -- . ':(exclude)docs/superpowers'`. Expected: the twenty-two lines this task covers. The skill sense: `tests/test-plugin-skills.sh` line 5 becomes `#   - a user-invocable-only skill carries both gates, the field Claude reads and the yaml`; the variables `claude_gated` and `codex_gated` (lines 29–34) become `claude_user_invocable` and `codex_user_invocable`; line 34's message becomes `"$plugin:$name is user-invocable only on one CLI (Claude $claude_user_invocable, Codex $codex_user_invocable); each such skill carries both gates"`; line 68's message becomes `"consistency-audit must be user-invocable only on Claude Code"`. `tests/test-codex-validate.sh` lines 3, 38 and 43: `each user-invocable-only skill`, `Every user-invocable-only skill keeps`, `Three user-invocable-only skills`. `tests/test-vendored-adhd.sh` line 6: `# User-invocable only on both Claude Code and Codex because its cost is the operator's call (spec`. `tests/test-vendored-diagnosing-bugs.sh` line 6: `It must not be user-invocable only, and it must`; line 65: `# Not user-invocable only, on either CLI: an agent reaches for it unprompted when a bug`; lines 67–68: `must not be user-invocable only on Claude Code` and `on Codex`. `tests/test-vendored-scaffolder.sh` line 59: `# a pair on all 21 of its user-invocable-only skills.` (Task 11 changes line 56's `harnesses`.)

- [ ] **Step 2: The other senses, and `user-invoked` (P10)**

`bin/setup` line 800 becomes ``# Conditional on the pool being complete, not on `have codex`: with codex present``; `tests/test-doctor-duplicates.sh` line 91 becomes `# The Codex all-clear is conditional on the pool being complete, not on codex being`; `tests/test-setup-doctor.sh` line 5 becomes `# conditional halves reporting their own absence; the report-only checks; and the`, line 31 `# Prerequisites: fatal for setup, conditional for the doctor. An empty PATH removes`, and line 78 `# The Codex half is conditional the same way, and says so.` In `plugins/software-dev/skills/consistency-audit/SKILL.md` line 141, `deleted rather than guarded` replaces `deleted rather than gated`. Then the third word for the same property: `plugins/software-dev/README.md` line 20 becomes `User-invocable only.` and line 24 `a first-party audit, user-invocable only, that reads a repository whole for`; in `plugins/sensemaking/README.md` line 41, `user-invoked on both harnesses` becomes `user-invocable only, on Claude Code and Codex alike` (Task 11 would otherwise take the `harnesses` on this line; it goes now). Re-run the grep, and `git grep -n 'user-invoked' -- . ':(exclude)docs/superpowers'`. Expected: nothing, twice.

- [ ] **Step 3: The historical pass**

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])gated skills?(?![\w.-])' 'user-invocable-only skill' $docs
sub_prose '(?<![\w.-])is gated(?![\w.-])' 'is user-invocable only' $docs
sub_prose '(?<![\w.-])not gated(?![\w.-])' 'not user-invocable only' $docs
sub_prose '(?<![\w.-])claude_gated(?![\w.-])' 'claude_user_invocable' $docs
sub_prose '(?<![\w.-])codex_gated(?![\w.-])' 'codex_user_invocable' $docs
git grep -n -i -w gated -- docs/superpowers
```

Edit each remaining prose site by hand: the skill sense becomes `user-invocable only`; the prerequisite sense (`gated on`, `gated halves`) becomes `conditional on`; `deleted rather than gated` becomes `deleted rather than guarded`. Review every hunk against §6's boundary and revert what stays: quotation marks, fences, and the sentences whose subject is the word (this spec's §5.1 row and §5.5 entry, #26's table). Where the plural substitution produced `skill` for `skills`, fix it. `git grep -n -i -w gated -- docs/superpowers | wc -l` and record the count.

- [ ] **Step 4: Suite and commit**

Run `bash tests/test-plugin-skills.sh`, `bash tests/test-vendored-adhd.sh` (network), `bash tests/test-vendored-diagnosing-bugs.sh` (network), `bash tests/test-doctor-duplicates.sh`, `bash tests/test-setup-doctor.sh`, `shellcheck -e SC1091 -e SC2016 bin/setup tests/test-plugin-skills.sh`, `prettier --check plugins/software-dev/README.md plugins/sensemaking/README.md plugins/software-dev/skills/consistency-audit/SKILL.md $(git ls-files 'docs/superpowers/*.md')`, then `bash tests/run.sh`. Expected: `plugin-skills: … skills checked; gates paired, …`; green and silent.

```bash
git add tests/test-plugin-skills.sh tests/test-codex-validate.sh tests/test-vendored-adhd.sh tests/test-vendored-diagnosing-bugs.sh tests/test-vendored-scaffolder.sh bin/setup tests/test-doctor-duplicates.sh tests/test-setup-doctor.sh plugins/software-dev/skills/consistency-audit/SKILL.md plugins/software-dev/README.md plugins/sensemaking/README.md docs/superpowers
git commit -m "Say user-invocable only, Claude Code's own name for a skill the model never selects" -m "The word leaves its other senses too, so the vocabulary test needs no sense exception: a check conditional on a pool, halves conditional on a CLI, a drift class deleted rather than guarded (names-and-surface spec §5.1). user-invoked, a third word for the same property, goes with it. Historical documents by reviewed diff: N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- tests bin/setup plugins/software-dev/skills/consistency-audit/SKILL.md plugins/software-dev/README.md plugins/sensemaking/README.md docs/superpowers
```

### Task 10: The three small rows: `user`, `instruction file`, `skill selection` (§5.1, §5.3)

One commit per row. The `harness` row is Task 11, and `historical artifact` lands with the reference check in Task 12, where its one durable site is rewritten.

**Files:**

- Modify: `README.md` (line 9), `plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md` (line 50); `plugins/software-dev/skills/setup-repository/SKILL.md` (line 100) with `tests/test-vendored-scaffolder.sh` (lines 144, 165)
- Modify: every historical document carrying the three words (15, 15 and 17 lines; reviewed diff)

**Interfaces:**

- Produces: the sentence ``Never leave the block in `CLAUDE.md` alone: a Claude-only instruction file leaves Codex reading nothing.`` in the scaffolder's `SKILL.md`, and the same string at both delimiter sites in its drift test.

- [ ] **Step 1: `user`, or no noun**

Run `git grep -n -i -w -E 'installers?' -- . ':(exclude)docs/superpowers'`. Expected: two lines (Task 4 took `AGENTS.md`'s). `README.md` line 9: `a separate installer with its own lockfile` becomes `` `skills.sh` with its own lockfile `` (the backticks are in the README), the spec's own wording (§5.4). `PROVENANCE.md` line 50: `rule of holding what no installer reproduces` becomes `rule of holding what no tool reproduces`. Then the historical pass, by hand from the list (fifteen lines): a person becomes `user` (`true for every installer` becomes `true for every user`; `wherever this plugin is installed` where no noun is needed), a program is named (`the skills.sh installer` becomes `skills.sh`; `bin/setup` where it is meant). Review against §6's boundary: this spec's §5.1 row and §5.5 entry, #26's quoted collisions and table, and the hook spec's admission-test quotation stay. Run the suite (`bash tests/run.sh`), then:

```bash
git add README.md plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md docs/superpowers
git commit -m "Say user for whoever runs bin/setup, and name the tool that installs skills" -m "One word meant a person and a program in the same document set (names-and-surface spec §5.1, #26). Historical documents by reviewed diff: N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- README.md plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md docs/superpowers
```

- [ ] **Step 2: `instruction file`, the coupled pair**

Line 100 of `plugins/software-dev/skills/setup-repository/SKILL.md` becomes:

```markdown
Never leave the block in `CLAUDE.md` alone: a Claude-only instruction file leaves Codex reading nothing.
```

and lines 144 and 165 of `tests/test-vendored-scaffolder.sh` carry the identical string as the region delimiter. That file is vendored (its row in the table), so the drift test is what holds the edit: run `bash tests/test-vendored-scaffolder.sh` (network) and expect `vendored-scaffolder: matches mattpocock/skills v1.2.3 except header + declared regions; N skill name(s) resolve`. Then the historical pass:

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])carriers(?![\w.-])' 'instruction files' $docs
sub_prose '(?<![\w.-])carrier(?![\w.-])' 'instruction file' $docs
git grep -n -i -w -E 'carriers?' -- docs/superpowers
```

Review against §6's boundary (this spec's rows and entries, #26's table, quoted text) and record the count. Run the suite, then:

```bash
git add plugins/software-dev/skills/setup-repository/SKILL.md tests/test-vendored-scaffolder.sh docs/superpowers
git commit -m "Say instruction file for CLAUDE.md and AGENTS.md" -m "What both CLIs call them (names-and-surface spec §5.1). The scaffolder's sentence and the region delimiter its drift test uses change in one commit (§5.3). Historical documents by reviewed diff: N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- plugins/software-dev/skills/setup-repository/SKILL.md tests/test-vendored-scaffolder.sh docs/superpowers
```

- [ ] **Step 3: `skill selection`, historical documents only**

`git grep -n -i -w routing -- . ':(exclude)docs/superpowers'` prints nothing at HEAD; confirm. Then:

```bash
sub_prose() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 'BEGIN { $f = "" }
    if (/^(`{3,}|~{3,})/) {
      my $r = $1;
      if ($f eq "") { $f = $r }
      elsif (substr($r, 0, 1) eq substr($f, 0, 1) && length($r) >= length($f)) { $f = "" }
    } elsif ($f eq "") { s{'"$re"'}{'"$rep"'}g }
    $f = "" if eof;' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_prose '(?<![\w.-])Routing(?![\w.-])' 'Skill selection' $docs
sub_prose '(?<![\w.-])routing(?![\w.-])' 'skill selection' $docs
git grep -n -i -w routing -- docs/superpowers
```

Review against §6's boundary (this spec's row and entry, #26's table, quoted text; `routing failure` reads as `skill-selection failure`, hyphenate it) and record the count. `prettier --check $(git ls-files 'docs/superpowers/*.md')`, then:

```bash
git add docs/superpowers
git commit -m "Say skill selection for how an agent picks a skill" -m "No dispatch connotation (names-and-surface spec §5.1). Historical documents only; no durable file carried the word. N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- docs/superpowers
```

### Task 11: Name the CLI, or say `agent CLI` where the sentence is generic (§5.2)

**Files:**

- Modify: `README.md` (lines 9, 61), `bin/setup` (lines 63, 731–749, 822–849), `tests/test-doctor-duplicates.sh` (lines 3, 6, 35), `tests/test-doctor-silence.sh` (lines 7, 114), `tests/test-plugin-skills.sh` (line 34, if `harness` is still there), `tests/test-vendored-adhd.sh` (line 6, if still there), `tests/test-vendored-diagnosing-bugs.sh` (line 65, if still there), `tests/test-vendored-scaffolder.sh` (line 56), `plugins/software-dev/skills/setup-repository/SKILL.md` (line 94, inside a region the drift test strips)
- Modify: every historical document carrying the word (62 lines; by hand)

**Interfaces:**

- Produces: `report_pool`'s first parameter named `cli`; the report lines `Claude: …` and `Codex: …` unchanged.

- [ ] **Step 1: Re-measure the durable set**

Run `git grep -n -i -E 'harness' -- . ':(exclude)docs/superpowers'`. Expected: the sites below, plus `harness-backup` in `PROVENANCE.md`, `knowledge-harness` in `tests/test-skills-pin.sh`, and upstream's text in the three vendored files (`skills/brainstorming/scripts/start-server.sh`, `skills/brainstorming/visual-companion.md`, `skills/diagnosing-bugs/SKILL.md`) and in `hooks/using-superpowers.md`, all of which stay (§5.2: a repository's name; upstream's byte-locked text until #21).

- [ ] **Step 2: The generic sites take `agent CLI`; every other site names the CLI**

`README.md` line 9: `Two harnesses consume` becomes `The two agent CLIs consume`; line 61: `on each harness present` becomes `on each agent CLI present`. `bin/setup` line 63: `a machine with neither agent CLI can still be clean`; lines 731–732: `on one agent CLI. Derived` and `from every route that CLI loads a skill by`; lines 740–741: `Per agent CLI, because the` and `the two CLIs`; line 749: `# CLI, and a guard placed there would print this SKIP twice. The`; line 822: `# $1 the agent CLI's name, then every skill directory that CLI can load.`; line 826: `local cli="$1" dir name h found=0 hashed=0`; lines 847 and 849: `"$cli: skill $name …"` and `"$cli: $hashed skill tree(s) hashed; …"`. `tests/test-doctor-duplicates.sh` line 3: `# agent CLI, and a Claude plugin cache …`; line 6: `# name differing only across the two CLIs.`; line 35: `# delta: differs only across the two CLIs. Not a finding on either.` `tests/test-doctor-silence.sh` line 7: `so both CLI halves report`; line 114: `# 5. jq off PATH. jq is not an optional agent CLI like claude or codex, whose`. `tests/test-vendored-scaffolder.sh` line 56: `Claude Code and Codex gate` in place of `The two harnesses gate`. `plugins/software-dev/skills/setup-repository/SKILL.md` line 94: `serves both Claude Code and Codex.` (the line sits inside the file-pick region the drift test strips on our side; the test's delimiters are lines 143–144 of the test and are untouched). Re-run the grep from Step 1. Expected: only the repository names and the four upstream files.

- [ ] **Step 3: The historical pass, by hand**

`git grep -n -i -E '(^|[^[:alnum:]-])harness(es)?([^[:alnum:]-]|$)' -- docs/superpowers` lists 62 lines. For each prose site, name the CLI the sentence means (`Claude Code`, `Codex`, `both`, `the two CLIs`); write `agent CLI` only where the sentence is generic. Leave: `harness-backup` and `knowledge-harness` (names), quotation marks, fenced blocks, and the sentences whose subject is the word (this spec's §3 row, §5.1, §5.2, §5.5 entry; #26's table). `prettier --check $(git ls-files 'docs/superpowers/*.md')`; record the kept count.

- [ ] **Step 4: Suite and commit**

Run `bash tests/test-doctor-duplicates.sh`, `bash tests/test-doctor-silence.sh`, `bash tests/test-vendored-scaffolder.sh` (network), `shellcheck -e SC1091 -e SC2016 bin/setup`, then `bash tests/run.sh`. Expected: `doctor-duplicates: one Claude duplicate and one residue reported; …`; green.

```bash
git add README.md bin/setup tests/test-doctor-duplicates.sh tests/test-doctor-silence.sh tests/test-vendored-scaffolder.sh plugins/software-dev/skills/setup-repository/SKILL.md docs/superpowers
git commit -m "Name Claude Code or Codex where a sentence means one, agent CLI where it means either" -m "The old word reads as a test harness (names-and-surface spec §5.2, #26). The generic survives at the durable sites the spec lists and nowhere else; a repository's name and upstream's byte-locked text keep it. Historical documents by hand: N sites kept.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- README.md bin/setup tests plugins/software-dev/skills/setup-repository/SKILL.md docs/superpowers
```

### Task 12: The reference check over every path in backticks (§8, #59)

**Files:**

- Modify: `tests/test-links-resolve.sh` (whole file), `.gitignore` (three lines), `.github/workflows/validate.yml` (the `validate` job's checkout), `cspell.config.yaml` (one word)
- Modify: `plugins/software-dev/README.md` (line 109), `plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md` (line 13)
- Modify: every historical document in the residue table below, and this spec's four P4 sites

**Interfaces:**

- Consumes: `checked '*.md'`; git history (full, not shallow).
- Produces: `tests/test-links-resolve.sh` green over 100 documents (88 checked at HEAD, plus this plan; the count is whatever `checked '*.md'` lists), its summary line naming every class's count; `DECLARED_ABSENT` in that file, which Task 15 and plan B each edit once.

- [ ] **Step 1: Write the test**

Replace `tests/test-links-resolve.sh` with the file below. It is the scanner the counts in _What was verified_ were measured with; shellcheck, shfmt and cspell are clean on it.

````bash
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
# and a word that is not shaped like a path is command syntax, counted.
#
# What does not resolve is one of eight classes, each counted and printed so
# a zero is visible, or it fails naming the file, line and token:
#   1. a URL;
#   2. a name that is not a working-tree path by its shape: ~ (home), $
#      anywhere (a variable), / (absolute), " (quoted syntax), an elision (.../, …/, or
#      ending in ... or …), :( (git's own path syntax), refs/ (a git ref),
#      repos/ (a GitHub API route);
#   3. a placeholder or glob: <, *, ?, {, [, |;
#   4. an owner/repo slug, with an optional #ref or @ref: two segments whose
#      first is not a directory at any root, so a misspelled two-segment
#      path is still checked;
#   5. a namespaced path: owner/repo:path or owner/repo@ref:path, the
#      other-repository convention CONTEXT.md sets, and the same shape with a
#      bare name before the colon (rev:path, plugin@marketplace:key);
#   6. a path git check-ignore accepts: runtime-only, classified by the file
#      that ignores it;
#   7. a path declared absent by decision, in DECLARED_ABSENT below;
#   8. under docs/superpowers/ only, the history tier: a path git shows
#      deleted passes, since git history is the archive; a renamed path fails
#      naming its successor at HEAD, followed through later renames; a path
#      with no history is a typo and fails.
. "$(dirname "$0")/lib.sh"

cd "$REPO_ROOT" || fail "could not cd to the repository root"
[ "$(git rev-parse --is-shallow-repository)" = false ] \
  || fail "the history tier reads every commit and this clone is shallow; fetch the history (actions/checkout: fetch-depth: 0)"

# Paths named because they must not exist, or absent by a recorded decision.
DECLARED_ABSENT=(
  'hooks/hooks.json'           # the path Codex loads by fallback: named so nothing sits there
  'docs/adr/'                  # docs/agents/domain.md names it; this repository keeps no ADRs (#26, #37)
  '.github/actionlint.yaml'    # the runner-label override ubuntu-latest makes unnecessary (names-and-surface spec §14)
  'bin/setpu'                  # the names-and-surface spec's example of a typo this test must catch
  'plugins/ghost/'             # the suite-and-ci spec's mutation, created and removed inside the mutation
  'tests/test-format-apply.sh' # named by the names-and-surface spec §18; plan B creates it and drops this line
  'tests/test-vocabulary.sh'   # named by the names-and-surface spec §5.4; Task 15 of plan A creates it and drops this line
  '.claude/settings.json'      # the project-scope file `claude plugin install --scope project` would write; named so it is never written
)

docs="$(checked '*.md')"
[ -n "$docs" ] || fail "checked '*.md' listed nothing; the ownership derivation went vacuous"

# ---- paths in backticks ----------------------------------------------------
# The roots a token resolves at, for a document in $1: its directory, the
# repository root, each plugin root.
roots_for() {
  printf '%s\n' "$1" .
  local p
  for p in plugins/*/; do printf '%s\n' "${p%/}"; done
}

# The history tier for $1, a path relative to the repository root. Prints
# `deleted`, `renamed <successor>`, or nothing when git has no commit for it.
# A rename is read from the commit's own --name-status, never from a log over
# the old path, which reports a rename as a deletion (spec §22); a directory
# is read through the files under it. The chain is followed until a
# successor exists at HEAD or the file was deleted.
declare -A TIER=()
history_tier() {
  local p="$1" c line st new
  case "$p" in ../*) return 0 ;; esac # outside the repository: git has nothing to say
  if [ -n "${TIER[$p]+set}" ]; then
    printf '%s' "${TIER[$p]}"
    return 0
  fi
  TIER[$p]="$(history_tier_walk "$p")"
  printf '%s' "${TIER[$p]}"
}
history_tier_walk() {
  local p="$1" c line st new
  while :; do
    c="$(git log --all -1 --format=%h -- "$p")"
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
  local doc="$1" n="$2" raw="$3" tok="$4" r first isdir verdict
  case "$tok" in
    *://* | mailto:*)
      n_url=$((n_url + 1))
      return
      ;;
    '~'* | *'$'* | /* | '"'* | .../* | …/* | *... | *… | ':('* | refs/* | repos/*)
      n_shape=$((n_shape + 1))
      return
      ;;
    *'<'* | *'*'* | *'?'* | *'{'* | *'['* | *'|'*)
      n_glob=$((n_glob + 1))
      return
      ;;
  esac
  if printf '%s' "$tok" | grep -qE '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)?(@[^:]+)?:.+'; then
    n_ns=$((n_ns + 1))
    return
  fi
  tok="${tok#./}"
  if printf '%s' "$tok" | grep -qE '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+([#@][^/]+)?$'; then
    first="${tok%%/*}"
    isdir=0
    while IFS= read -r r; do [ -d "$r/$first" ] && isdir=1; done < <(roots_for "$(dirname "$doc")")
    if [ "$isdir" -eq 0 ]; then
      n_slug=$((n_slug + 1))
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
        if [ "$r" = . ]; then verdict="$(history_tier "$tok")"; else verdict="$(history_tier "$r/$tok")"; fi
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
            word="${word#*=}"
            word="$(printf '%s' "$word" | sed -E "s/^[\"'(]+//; s/[\"'),;:]+\$//; s/([^.])\.\$/\\1/; s/:[0-9]+([-,][0-9]+)*\$//")"
            if printf '%s' "$word" | grep -qE '^[A-Za-z0-9_.@#~$-]+(/[A-Za-z0-9_.@#~$-]*)+$'; then
              classify "$doc" "$n" "$span" "$word"
            else
              n_syntax=$((n_syntax + 1))
            fi
          done
          ;;
        *)
          word="${span#*=}"
          classify "$doc" "$n" "$span" "$(printf '%s' "$word" | sed -E "s/^[\"'(]+//; s/[\"'),;:]+\$//; s/([^.])\.\$/\\1/; s/:[0-9]+([-,][0-9]+)*\$//")"
          ;;
      esac
    done < <(grep -o '`[^`]*`' <<<"$line")
  done <"$f"
done

[ -z "$failures" ] || fail "these references do not resolve:$failures"
printf 'links-resolve: %s link(s) and %s backticked path(s) resolve across %s document(s); skipped %s URL(s), %s by shape, %s placeholder(s), %s slug(s), %s namespaced, %s ignored, %s declared absent, %s deleted in history, %s renamed beside the successor, %s command word(s)\n' \
  "$links" "$n_ok" "$scanned" "$n_url" "$n_shape" "$n_glob" "$n_slug" "$n_ns" "$n_ignored" "$n_declared" "$n_history" "$n_renamed" "$n_syntax"
````

- [ ] **Step 2: Run it and read the residue**

Run: `bash tests/test-links-resolve.sh 2>&1 | tail -n 40`
Expected: `FAIL: these references do not resolve:` followed by one line per token, exit 1; about 150 lines after Tasks 2–11 (267 in the dry run before them; the moved paths are gone, the renamed plugin name is not). The first lines outside `docs/superpowers/` are the working-rules file's `.worktrees/` and `worktrees/`. Save the list: `bash tests/test-links-resolve.sh >/tmp/residue.txt 2>&1 || true`.

- [ ] **Step 3: Class 6, and the history the tier needs**

`.gitignore` gains, after the `.claude/worktrees/` block:

```gitignore

# The two directories superpowers' finishing-a-development-branch recognizes
# as its own, named by plugins/software-dev/hooks/working-rules.md, which
# tests/test-hook.sh round-trips byte for byte; and Kilo's worktree directory,
# named by the suite-and-ci spec. None is ever tracked, and the reference
# check classifies a path by the file that ignores it.
.worktrees/
worktrees/
.kilo/
```

`.github/workflows/validate.yml`: the `validate` job's checkout step (line 16) gains `fetch-depth: 0` under `with:`, beside `persist-credentials: false`, with the comment `# The reference check's history tier reads every commit; a depth-1 clone would call a deleted file a typo.` The `setup-e2e` job's checkout is untouched. `cspell.config.yaml`'s word list gains `pathspec` in alphabetical order (the test's header does not use the word; the older spec and plan do, and `pathspecs` was already listed; add it now so the singular can be used).

- [ ] **Step 4: The two convention sites in durable files, and the retired plugin name**

`plugins/software-dev/README.md` line 109 names archify's update checker by its bare path, scripts/check-update.mjs, which stops being a slug once `scripts/` exists here; it becomes `tt-a1i/archify:scripts/check-update.mjs`. `PROVENANCE.md` line 13 names the fork's upstream path bare, skills/finding-duplicate-functions, which resolved at a plugin root by accident; it becomes `obra/superpowers-lab:skills/finding-duplicate-functions`. The convention says what both mean. Then the retired plugin name, everywhere in the historical documents, the spec's file name excluded (P11):

```bash
sub_all() {
  local re="$1" rep="$2"
  shift 2
  perl -i -pe 's{'"$re"'}{'"$rep"'}g' "$@"
}
docs="$(git ls-files 'docs/superpowers/*.md')"
sub_all 'software-development(?!-layout-and-tracer)' 'software-dev' $docs
git grep -n 'software-development' -- docs/superpowers | grep -v 'software-development-layout-and-tracer' | wc -l
```

Expected: 0. Review every hunk against §6's boundary and revert what stays: a quoted manifest (`"name": "software-development"` inside a fenced JSON block reproduced from the tree at the time), a fenced block reproducing output, the Codex hook-state key `software-development@eranroseman:…` inside quotation marks, and the sentences whose subject is the old name (the rename commit `a3c797f`'s description in the spec's §22, if it names the old path outside a `rev:path` form, takes that form). Prose, headings, inline commands and code listings keep the new name. Record the kept count.

- [ ] **Step 5: The residue, by disposition**

Work through `/tmp/residue.txt`. Every token below was measured; a token not in the table is new and gets one of the same dispositions, or a line in `DECLARED_ABSENT` with its reason.

```text
| Token(s) as written                                                                                                                                                                                       | Sites                                                                                                                                        | Disposition                                                                                                                                                                                                                                                                                                                         |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `plugins/software-development/…` (70 lines)                                                                                                                                                               | every plan and spec of 2026-09-04 and 2026-09-05, the review plan, this spec's §22                                                           | Step 4's substitution made them current; the §22 row takes `a3c797f:plugins/software-development/README.md` (P4)                                                                                                                                                                                                                    |
| `scripts/` (11)                                                                                                                                                                                           | the 2026-09-04 layout spec and later                                                                                                         | resolves once Task 4 has run; nothing to edit                                                                                                                                                                                                                                                                                       |
| `agents/openai.yaml` (11), `adhd/agents/openai.yaml`, `./agents/openai.yaml`, `./SKILL.md`, `./scripts/hitl-loop.template.sh`, `scripts/server.cjs`                                                       | the roster and setup-and-drift documents                                                                                                     | the plugin-relative path of the skill the sentence is about: `skills/adhd/agents/openai.yaml`, `skills/setup-repository/agents/openai.yaml`, `skills/diagnosing-bugs/SKILL.md`, `skills/diagnosing-bugs/scripts/hitl-loop.template.sh`, `skills/brainstorming/scripts/server.cjs` (§8: specs and plans write plugin-relative paths) |
| `codex-rs/…` (18 tokens, eleven files)                                                                                                                                                                    | the hook spec's claims table, the layout spec and plan, the setup-and-drift spec and plan                                                    | `openai/codex:codex-rs/…`, keeping any `:N` line suffix after the path                                                                                                                                                                                                                                                              |
| `skills/using-superpowers/SKILL.md` (4)                                                                                                                                                                   | the hook spec, the layout spec and plan                                                                                                      | `obra/superpowers:skills/using-superpowers/SKILL.md`                                                                                                                                                                                                                                                                                |
| `../requesting-code-review/code-reviewer.md`                                                                                                                                                              | the layout spec line 134                                                                                                                     | `obra/superpowers:skills/requesting-code-review/code-reviewer.md`                                                                                                                                                                                                                                                                   |
| `harness-backup/bin/harness-drift-check.py` (3), `bin/harness-drift-check.py`, `harness-backup/claude/CLAUDE.md`, `harness-backup/codex/AGENTS.md`                                                        | the setup-and-drift spec and plan, the roster spec                                                                                           | `eranroseman/harness-backup:bin/harness-drift-check.py` and the same form for the other two                                                                                                                                                                                                                                         |
| `working-with-claude-code/references/hooks.md` (2), `working-with-claude-code/references/plugins-reference.md`                                                                                            | the hook spec's and the layout spec's claims tables                                                                                          | `obra/superpowers-developing-for-claude-code:skills/working-with-claude-code/references/hooks.md` (the source `skills.json` declares; the lockfile's `skillPath` confirms the `skills/` prefix)                                                                                                                                     |
| `dist/`, `dist/plugins/writing-clearly-and-concisely`, `dist/plugins/writing-clearly-and-concisely/skills/writing-clearly-and-concisely`, `skills/writing-clearly-and-concisely`                          | the roster plan lines 50 and 1354                                                                                                            | `softaworks/agent-toolkit:dist/…` and `softaworks/agent-toolkit:skills/writing-clearly-and-concisely`                                                                                                                                                                                                                               |
| `skills/engineering/`, `skills/productivity/`                                                                                                                                                             | the setup-and-drift spec line 300                                                                                                            | `mattpocock/skills:skills/engineering/`, `mattpocock/skills:skills/productivity/`                                                                                                                                                                                                                                                   |
| `bench/`                                                                                                                                                                                                  | the roster spec line 134                                                                                                                     | `UditAkhourii/adhd:bench/`; `src/engine.ts` and `src/llm.ts` on the same line passed as slugs by accident and take the same form                                                                                                                                                                                                    |
| `assets/`, `test/`                                                                                                                                                                                        | the roster spec line 169                                                                                                                     | `tt-a1i/archify:assets/`, `tt-a1i/archify:test/`; the line's `bin/` and `scripts/` resolved here by accident and take the same form                                                                                                                                                                                                 |
| `research-vault/docs/superpowers/reqs/`                                                                                                                                                                   | the roster spec line 235                                                                                                                     | `eranroseman/research-vault:docs/superpowers/reqs/`                                                                                                                                                                                                                                                                                 |
| `scripts/check-update.mjs`                                                                                                                                                                                | the roster plan line 1294                                                                                                                    | `tt-a1i/archify:scripts/check-update.mjs`                                                                                                                                                                                                                                                                                           |
| `agents/.skill-lock.json`                                                                                                                                                                                 | the roster spec line 297                                                                                                                     | `~/.agents/.skill-lock.json`                                                                                                                                                                                                                                                                                                        |
| `cache/eranroseman/`, `cache/eranroseman/writing-clearly-and-concisely/0.1.0/skills/writing-clearly-and-concisely/`, `eranroseman/superpowers/6.3.0`                                                      | the roster plan lines 42 and 44, the hook spec line 197                                                                                      | `~/.claude/plugins/cache/…`, the path on the machine                                                                                                                                                                                                                                                                                |
| `plans/` (2)                                                                                                                                                                                              | the suite-and-ci spec lines 237 and 256                                                                                                      | `docs/superpowers/plans/`                                                                                                                                                                                                                                                                                                           |
| `tests/codex/test-marketplace-manifest.sh` (2)                                                                                                                                                            | the layout plan line 30, the layout spec line 422                                                                                            | `tests/test-codex-marketplace.sh`, the test as it stands                                                                                                                                                                                                                                                                            |
| `.claude/settings.json` (3)                                                                                                                                                                               | the setup-and-drift spec and plan                                                                                                            | declared absent (the file `--scope project` would write; named so it never is)                                                                                                                                                                                                                                                      |
| `FAIL: docs/superpowers/plans/2026-09-04-session-start-hook.md links […] (looked at …)`                                                                                                                   | the suite-and-ci plan line 361                                                                                                               | the span quotes a failure naming a path that never existed: move it into a `text` fence, content unchanged (P5)                                                                                                                                                                                                                     |
| `FAIL: software-development: plugins/software-development has no .claude-plugin/plugin.json`                                                                                                              | the suite-and-ci plan                                                                                                                        | Step 4 made it current                                                                                                                                                                                                                                                                                                              |
| `.worktrees/`, `worktrees/`, `.kilo/worktrees/brass-settee`                                                                                                                                               | the working-rules file, this spec's §8, the suite-and-ci spec's claims table                                                                 | Step 3's `.gitignore` lines                                                                                                                                                                                                                                                                                                         |
| `tests/test-vocabulary.sh`, `tests/test-format-apply.sh`, `bin/setpu`, `plugins/ghost/`, `hooks/hooks.json`, `docs/adr/`, `.github/actionlint.yaml`                                                       | this spec, the suite-and-ci spec and plan, the software-dev README, `docs/agents/domain.md`, and every document naming Codex's fallback path | `DECLARED_ABSENT` in the test                                                                                                                                                                                                                                                                                                       |
| `plugins/software-dev/hooks/using-superpowers.md`, `tests/test-subset-writing-clearly-and-concisely.sh`                                                                                                   | this spec                                                                                                                                    | exist since Tasks 2 and 6                                                                                                                                                                                                                                                                                                           |
| `bin/format` in §21, `upstream/skills.json` and `bin/format` in §22                                                                                                                                       | this spec                                                                                                                                    | P4: the §21 bullet reads `it fails the audience rule it postdates; it is scripts/format now`; the §22 rows read `1dd7362:upstream/skills.json` and `1dd7362:bin/format`                                                                                                                                                             |
| `2825752:docs/superpowers/specs/2026-09-06-repository-quality-gates-design.md`, `7b8c09b:docs/archive/2026-08-08-harness-update-design.md`, `software-dev@eranroseman:hooks/hooks.json:session_start:0:0` | the suite-and-ci plan, the roster spec, the layout spec                                                                                      | class 5; nothing to edit                                                                                                                                                                                                                                                                                                            |
```

Edit each site as the table says; `prettier --check $(git ls-files 'docs/superpowers/*.md') plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md` after (a table cell that grew may need `scripts/format`). Then run the test again and repeat until:

```bash
bash tests/test-links-resolve.sh
```

Expected: one line, `links-resolve: L link(s) and P path(s) in backticks resolve across D document(s); skipped U URL(s), S by shape, G placeholder(s), N slug(s), M namespaced, I ignored, A declared absent, H deleted in history, R renamed beside the successor, C command word(s)`, exit 0, with `A` at least 40 (`hooks/hooks.json` alone is 28), `H` about 10, `R` about 15, and every count non-zero except possibly `I` if no document names an ignored path outside the working-rules file. The run takes a few seconds.

- [ ] **Step 6: Prove the guard by mutation, three ways**

A scratch git clone, since `checked()` reads `git ls-files`:

```bash
rm -rf /tmp/ref-mutant && git clone -q --local . /tmp/ref-mutant && cd /tmp/ref-mutant \
  && printf '\nSee `tests/nosuch/file.sh`.\n' >> README.md \
  && printf '\nSee `tests/nosuch/other.sh` and `upstream/skills.json`.\n' >> docs/superpowers/plans/2026-09-17-suite-and-ci.md \
  && bash tests/test-links-resolve.sh; cd - >/dev/null
```

Expected: `FAIL: these references do not resolve:` with three lines: the README line, with its line number and the seeded token, ending `does not resolve at the document's directory, the repository root or any plugin root`; the plan's second seeded token the same way (no history: a typo); and the old manifest path ending `names a file that was renamed; it is now skills.json` (renamed, with no successor on its line). Exit 1. Then the shallow refusal: `git clone -q --depth 1 file://$PWD /tmp/ref-shallow && bash /tmp/ref-shallow/tests/test-links-resolve.sh` prints `FAIL: the history tier reads every commit and this clone is shallow; fetch the history (actions/checkout: fetch-depth: 0)`, exit 1. Remove both clones.

- [ ] **Step 7: Suite and commit**

Run `bash tests/test-workflows.sh`, `bash tests/test-spelling.sh`, `bash tests/test-hook.sh` (network; the working-rules file is unchanged, the round-trip holds), `shellcheck -e SC1091 -e SC2016 tests/test-links-resolve.sh`, `shfmt -d -i 2 -ci -bn tests/test-links-resolve.sh`, then `bash tests/run.sh`. Expected: green and silent. The old word `maintained record` left the tree with the old test's header; `git grep -n -i -E 'maintained record|working paper' -- . ':(exclude)docs/superpowers'` prints nothing. In the historical documents the two phrases state the rule that was then in force and stay (content).

```bash
git add tests/test-links-resolve.sh .gitignore .github/workflows/validate.yml cspell.config.yaml plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md docs/superpowers
git commit -m "Resolve every path in backticks, with a history tier for the historical documents" -m "tests/test-links-resolve.sh checked markdown links, of which the owned documents carry almost none; the repository refers to files in backticks (names-and-surface spec §8, #59). The backticked half resolves at the document's directory, the repository root and each plugin root; eight classes of token are excluded, each with its count printed; under docs/superpowers/ a deleted file may keep its name and a renamed one may not, unless its successor is named on the same line. A span with whitespace is a command and is classified word by word. The runner's checkout fetches the full history, which the tier reads. The retired plugin name and about thirty other-repository paths are written current by reviewed diff; the residue and its dispositions are in plan A, Task 12. N old names stay inside quoted output.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- tests/test-links-resolve.sh .gitignore .github/workflows/validate.yml cspell.config.yaml plugins/software-dev/README.md plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md docs/superpowers
```

### Task 13: The root README names no skill, the manifests say one thing, and the residuals (§7, #37, #22, #58)

**Files:**

- Modify: `README.md` (lines 21–40, 70–72, 81, and a new `## Layout` section after `## Checks`), `.claude-plugin/marketplace.json` (lines 2, 5), `plugins/software-dev/README.md` (lines 78–79), `bin/setup` (`usage()` line 155, `ensure_codex` line 553), `tests/test-spelling.sh` (the file list and summary), `cspell.config.yaml` (one word)

**Interfaces:**

- Produces: `README.md`'s tagline and the marketplace's top-level `description` as one string; the Update block and `usage()` both saying `codex plugin marketplace upgrade eranroseman`; `tests/test-spelling.sh` spelling every checked JSON file whole.

- [ ] **Step 1: `## What it ships`, four entries at one line each, naming no skill (item 1)**

Replace lines 21–40 of `README.md` with:

```markdown
## What it ships

Four marketplace entries:

- `software-dev`: the glue plugin, for anyone building software with an agent; its README names every skill, hook and agent it ships and where each came from. Depends on the three entries below.
- `sensemaking`: skills for thinking work that is not code, shared with `research-vault`; its README says which plugin holds a skill, and why.
- `superpowers`: obra/superpowers at a pinned commit, a subset entry, Claude Code only; Codex reaches the same skills by symlink, created by `bin/setup` as described in Install below.
- `writing-clearly-and-concisely`: softaworks/agent-toolkit's one skill of that name, a subset entry at a pinned commit, Claude Code only, with the same Codex symlink.
```

Then `grep -noE '`[a-z-]+`' README.md | grep -E 'brainstorming|diagnosing-bugs|adhd|consistency-audit|rethink-audit|finding-duplicate'` prints nothing: the inventory lives in the per-plugin READMEs and the manifests, and no guard is added (§7: a returning skill name is a review finding).

- [ ] **Step 2: One string for the tagline and the marketplace (item 2), and the schema URL (#58)**

`README.md` lines 3–4 stay as they are: `One command puts the same agent skills on Claude Code and Codex, and one script tells you when a machine has drifted from them.` `.claude-plugin/marketplace.json` line 5 becomes exactly that sentence: `"description": "One command puts the same agent skills on Claude Code and Codex, and one script tells you when a machine has drifted from them.",`. Line 2 becomes `"$schema": "https://json.schemastore.org/claude-code-marketplace.json",` (the URL that returns 200; `claude plugin validate --strict` never fetches it, §7). The Codex `shortDescription` was rewritten in Task 6 (P9).

- [ ] **Step 3: The software-dev README's pointer (item 3), and the doctor sentence**

In `plugins/software-dev/README.md`, delete the sentence `The design spec in the repository records the evidence.` at the end of the paragraph on lines 73–79, so the paragraph ends `…that keeps its documented fallback path and manifest order.` The evidence is inline in the same paragraph. In `README.md` lines 70–72, the sentence `` `bin/doctor` reports the state of the first two; the plugin README covers the third by instruction alone, for now. `` becomes `` `bin/doctor` reports the operator decisions it never makes for you. `` (count-free, so plan B's #50 does not rewrite it).

- [ ] **Step 4: `## Layout` (item 4)**

After the `## Checks` section (after line 110), append:

````markdown

## Layout

```text
bin/               the two commands a user runs: setup, and doctor, its check mode
scripts/           what CI and the maintainer run: the upstream watch, the superpowers bump, the formatter
plugins/           the two plugins, software-dev and sensemaking, each with its own README
skills.json        the desired state for skills.sh: sources, refs, skill names
tests/             every check; tests/run.sh runs them and tests/tools.txt pins the tools
docs/agents/       the conventions the agents read: issue tracker, triage labels, domain docs
docs/Professional-Editorial-Standards-2024.md   the editorial reference
docs/superpowers/  historical artifacts: specs and plans as executed; vocabulary and paths current, content frozen
CONTEXT.md         the vocabulary: contested terms with their retired forms, and the leading words
AGENTS.md          the agents' instruction file; CLAUDE.md imports it
```
````

Plan B adds the `vendored.json` line when it creates the file (§14).

- [ ] **Step 5: The named upgrade at the three live sites (#22)**

`README.md` line 81 (inside the Update fence) becomes `codex plugin marketplace upgrade eranroseman`; `bin/setup`'s `usage()` line 155 becomes the same, so `tests/test-setup-doctor.sh` keeps README and usage equal; `bin/setup` line 553's `codex plugin marketplace upgrade >/dev/null 2>&1` becomes `codex plugin marketplace upgrade eranroseman >/dev/null 2>&1`, its trailing continuation unchanged. The fourth site, the 2026-09-05 spec's §9 step 1, is frozen content and keeps the bare form (§7). `bash tests/test-setup-doctor.sh` prints `setup-doctor: two entry points, prerequisites split as documented, recipes match the usage text`.

- [ ] **Step 6: JSON joins the spelling check (item 5)**

In `tests/test-spelling.sh`, after the YAML list and its guard, add:

```bash
json="$(checked '*.json')"
[ -n "$json" ] || fail "checked '*.json' listed nothing"
```

and the cspell call and the summary take it: `cspell --no-progress $md $shell $yaml $json` and `printf 'spelling: %s markdown, %s shell, %s YAML and %s JSON file(s) spelled\n'` with the fourth count `"$(printf '%s\n' "$json" | grep -c .)"`; the header comment gains `, and every JSON file whole (thirteen user-facing strings)`. `cspell.config.yaml`'s word list gains `Strunk` in alphabetical order. `bash tests/test-spelling.sh` prints `spelling: … markdown, 37 shell, … YAML and 8 JSON file(s) spelled` (`skills.json` moved but is still counted).

- [ ] **Step 7: Suite and commit**

Run `scripts/format`, then `bash tests/test-setup-doctor.sh`, `bash tests/test-spelling.sh`, `bash tests/test-claude-validate.sh` (needs `claude`), `bash tests/test-references-resolve.sh`, `bash tests/test-json-wellformed.sh`, `bash tests/test-links-resolve.sh`, `bash tests/test-lint-markdown.sh`, then `bash tests/run.sh`. Expected: green; `git status --short` shows only the files named above (the formatter changed nothing else).

```bash
git add README.md .claude-plugin/marketplace.json plugins/software-dev/README.md bin/setup tests/test-spelling.sh cspell.config.yaml
git commit -m "Root README: four entries naming no skill, one string with the marketplace, a layout, and the residuals" -m "The inventory lives in the per-plugin READMEs and the manifests, so the root README has nothing to go stale (names-and-surface spec §7, #37). The tagline is the marketplace description, since that string is what /plugin renders. The plugin README's pointer at a spec goes; the evidence was already inline. A Layout section says where the historical documents stand. The Codex upgrade names the marketplace at the three live sites (#22); the schema URL is SchemaStore's (#58); cspell reads every JSON file whole (#37 item 5).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- README.md .claude-plugin/marketplace.json plugins/software-dev/README.md bin/setup tests/test-spelling.sh cspell.config.yaml
```

### Task 14: `CONTEXT.md`, the output of the renames (§5.5)

**Files:**

- Modify: `CONTEXT.md` (whole file; one placeholder line today)

**Interfaces:**

- Produces: `CONTEXT.md` in the reference implementation's shape; every `_Avoid_:` line ends in a comma-separated list of bare surface forms and nothing else, which Task 15 reads.

- [ ] **Step 1: Audit the leading words on the tree as it now stands**

```bash
for w in ladder rung gate drift spine 'front door' admission 'tracer bullet'; do printf '%-14s %s\n' "$w" "$(git grep -n -i -w -E "${w}s?" -- AGENTS.md README.md plugins/software-dev/README.md plugins/sensemaking/README.md plugins/software-dev/hooks/working-rules.md bin scripts tests .claude-plugin .agents plugins/software-dev/.codex-plugin plugins/software-dev/.claude-plugin | wc -l)"; done
```

Expected, as measured at HEAD: `ladder` 3, `rung` 3, `gate` about 24, `drift` about 17, `spine` 4, `front door` 3, `admission` 0, `tracer bullet` 0. Read the `gate` lines: the runner's hard gate, a skill's invocation gate, the `claude` and `codex` gates in `bin/setup`, the complete-pool gate, a milestone's gate. One sense, a precondition, every time. `admission` and `tracer bullet` appear in no durable file and are dropped from the list; the file below records both findings.

- [ ] **Step 2: Write the file**

```markdown
# agent-plugins

One repository states the skills a machine should have on Claude Code and Codex, converges a machine to that state, reports where a machine differs from it, and watches the upstreams it takes skills from. The words below are the ones its files use for that. A contested entry names the winner and lists the retired forms under _Avoid_; a leading word is pinned so it reads the same in every file.

## Language

**additional context**:
What the SessionStart hook prints into a session; Claude Code's own name for it.
_Avoid_: payload, payloads

**user**:
Whoever runs `bin/setup`, or no noun at all. The tool that installs skills is named: `skills.sh`.
_Avoid_: installer, installers

**instruction file**:
`CLAUDE.md` and `AGENTS.md`, what both CLIs call the file they read at the start of a session.
_Avoid_: carrier

**desired state**:
What `skills.json` and the marketplace manifest declare and `bin/setup` converges a machine to. The verb _declare_ is a different word and stays.
_Avoid_: declaration, declarations

**first-party**:
A skill, agent or file written in this repository, as opposed to third-party.
_Avoid_: authored

**user-invocable only**:
A skill the user invokes and the model never selects on its own; Claude Code's own `skillOverrides` value. On Claude Code it is `disable-model-invocation: true`, on Codex `allow_implicit_invocation: false`.
_Avoid_: gated

**subset entry**:
A marketplace entry that takes part of an upstream repository at a pinned commit: `superpowers` and `writing-clearly-and-concisely`.
_Avoid_: curated, curation

**skill selection**:
How an agent picks a skill for the task in front of it.
_Avoid_: routing

**Claude Code, Codex, agent CLI**:
The two, or the generic. A sentence that means one names it; _agent CLI_ appears only where a sentence means either.
_Avoid_: harness, harnesses

**historical artifact**:
A spec once every plan written from it has run, and a plan once it has executed. Its vocabulary and paths are kept current so a reader today can follow it; its content is frozen.
_Avoid_: maintained record, working paper

**vendored**:
A tree that is upstream's at a pinned commit, held byte-identical by a drift test except for enumerated regions, and updated by re-vendoring. Edits flow in from upstream.

**forked**:
A tree that is first-party and holds named fragments to upstream under a drift test, updated by editing here. Edits flow out from here. _Trees with a drift test_ is the superset of both, and is the formatter's exclusion class.

### Leading words

Pinned so they read identically in every file; each recruits a meaning the reader already has.

- **ladder** and **rung**: eliminate the problem, add a mechanism, add a rule, then prose; climb from the top and stop at the first rung that holds.
- **gate**: a condition that must hold before the next thing runs: the runner's hard gate, a skill's invocation gate, the `claude` and `codex` gates in `bin/setup`, and a milestone's gate.
- **drift**: an upstream moved past a pin, or a machine differs from the desired state.
- **spine**: the superpowers process skills, brainstorm to finish.
- **front door**: `brainstorming`, where a build request enters the spine.

## Relationships

- `bin/` holds what a user runs; `scripts/` holds what CI and the maintainer run.
- A path in another repository is written `owner/repo:path`, or `owner/repo@ref:path` when the ref matters, so the reference check can tell it from a path here.
- The desired state lives in two files: `.claude-plugin/marketplace.json` for the plugins and the subset entries, `skills.json` for what `skills.sh` installs. `bin/setup` converges a machine to both; `bin/doctor` is the same engine in check mode.

## Flagged ambiguities

- "installer" meant both a person and a program. Resolved: the person is the **user**; the program is named, `bin/setup` or `skills.sh`.
- "payload" meant the hook's output here and the hook's input everywhere else. Resolved: **additional context**, the CLI's own word.
- "vendored" and "forked" were used as if defined. Resolved by the direction edits flow, above.
- "curated" read as editorial praise for what is a subtraction. Resolved: **subset entry**.
- The `upstream` directory read as a copy of an upstream repository and held this repository's own dependency manifest. Resolved: `skills.json` at the root.
- "gate" was audited for divergent senses on 2026-09-23 and carries one, a precondition, in each of its uses.
- "admission" and "tracer bullet" were candidates for the leading words and appear in no durable file; dropped.
```

Check the shape: `grep -n '_Avoid_:' CONTEXT.md` prints ten lines, each ending in a bare form with no full stop; `prettier --check CONTEXT.md` and `markdownlint-cli2 CONTEXT.md` are silent (run `scripts/format` if not); `cspell --no-progress CONTEXT.md` reports nothing. `bash tests/test-links-resolve.sh` is green: every path in the file resolves and the two convention forms are class 5.

- [ ] **Step 3: Suite and commit**

Run `bash tests/test-spelling.sh`, `bash tests/test-links-resolve.sh`, `bash tests/test-lint-markdown.sh`, `bash tests/test-format-prettier.sh`, then `bash tests/run.sh`. Expected: green.

```bash
git add CONTEXT.md
git commit -m "Write CONTEXT.md as the output of the renames" -m "In the shape of the reference implementation: what the repository is, the contested terms with the winner named and the losers under _Avoid_, the leading words pinned, the relationships, and the ambiguities as they were resolved (names-and-surface spec §5.5, #26). The leading-word audit found gate carrying one sense in every use, and admission and tracer bullet in no durable file.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- CONTEXT.md
```

### Task 15: `tests/test-vocabulary.sh`, red on a seeded mutant, green on the tree (§5.4)

**Files:**

- Create: `tests/test-vocabulary.sh`
- Modify: `tests/test-links-resolve.sh` (drop the `tests/test-vocabulary.sh` line from `DECLARED_ABSENT`)

**Interfaces:**

- Consumes: `checked()`; the `_Avoid_:` lines of `CONTEXT.md`.
- Produces: a test that fails naming file, line and form for every retired form in a checked shell, JSON, YAML, markdown or other owned file outside `CONTEXT.md` and `docs/superpowers/`.

- [ ] **Step 1: Write the test**

The file must not carry any `_Avoid_` form in its own comments; it reads them from `CONTEXT.md`.

```bash
#!/usr/bin/env bash
# Every retired form is gone from the files this repository owns (spec §5.4).
# CONTEXT.md lists, on each `_Avoid_:` line, the bare surface forms a winning
# term retired; this test reads those lists and greps every checked file for
# each form, whole word, case-insensitive, so the list is a mechanism rather
# than a rule. `_` is not a word character to the pattern, so an identifier
# carrying a retired form is a hit; `-` is, so a repository name joined by a
# hyphen is not, and there is no exception list. Outside the scan: CONTEXT.md,
# whose subject is the retired forms, and docs/superpowers/, where a spec's
# substitution table and an older plan's quoted output keep them (spec §5.4
# says which higher rungs were tried there).
. "$(dirname "$0")/lib.sh"

CONTEXT="$REPO_ROOT/CONTEXT.md"
[ -f "$CONTEXT" ] || fail "missing $CONTEXT"

forms="$(sed -n 's/.*_Avoid_: *//p' "$CONTEXT" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . || true)"
[ -n "$forms" ] || fail "CONTEXT.md carries no _Avoid_ line; nothing to enforce"
odd="$(printf '%s\n' "$forms" | grep -vE '^[a-z]+( [a-z]+)*$' || true)"
[ -z "$odd" ] || fail "an _Avoid_ list in CONTEXT.md carries something other than a bare lower-case form:"$'\n'"$odd"

files="$(checked ':(exclude)CONTEXT.md' ':(exclude)docs/superpowers')"
[ -n "$files" ] || fail "checked() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"

hits=""
n=0
while IFS= read -r form; do
  n=$((n + 1))
  # shellcheck disable=SC2086  # one path per word -- no whitespace, a glob character, or a quoted path, asserted by tests/test-ownership.sh
  found="$(grep -n -i -E "(^|[^[:alnum:]-])$form([^[:alnum:]-]|$)" -- $files || true)"
  [ -z "$found" ] || hits="$hits"$'\n'"$(printf '%s\n' "$found" | sed "s/\$/  [$form]/")"
done <<<"$forms"
[ -z "$hits" ] || fail "a retired form survives in an owned file (file:line:text [form]):$hits"
printf 'vocabulary: %s retired form(s) absent from %s owned file(s)\n' "$n" "$(printf '%s\n' "$files" | grep -c .)"
```

`shellcheck -e SC1091 -e SC2016 tests/test-vocabulary.sh` exits 0; `shfmt -d -i 2 -ci -bn tests/test-vocabulary.sh` prints nothing; `cspell --no-progress tests/test-vocabulary.sh` reports nothing.

- [ ] **Step 2: Red first, on a seeded mutant**

A scratch git clone, since `checked()` reads `git ls-files`; the seeded word is the first `_Avoid_` form, appended to a tracked file:

```bash
rm -rf /tmp/vocab-mutant && git clone -q --local . /tmp/vocab-mutant && cp tests/test-vocabulary.sh /tmp/vocab-mutant/tests/ && cd /tmp/vocab-mutant \
  && printf '\nThe hook prints its payload.\n' >> README.md \
  && bash tests/test-vocabulary.sh; cd - >/dev/null
```

Expected: `FAIL: a retired form survives in an owned file (file:line:text [form]):` then `README.md:N:The hook prints its payload.  [payload]`, exit 1. Then a hyphen-joined name is not a hit and an underscore-joined identifier is:

```bash
cd /tmp/vocab-mutant && git checkout -q -- README.md && printf '\nSee harness-backup, and payload_tmp.\n' >> README.md && bash tests/test-vocabulary.sh; cd - >/dev/null; rm -rf /tmp/vocab-mutant
```

Expected: one hit, `[payload]`, on that line; `harness-backup` is not reported.

- [ ] **Step 3: Green on the tree, and the declared entry goes**

Run: `bash tests/test-vocabulary.sh`
Expected: `vocabulary: 16 retired form(s) absent from 76 owned file(s)` (the file count is `checked()` minus `CONTEXT.md` and the historical directory, the new test included once it is staged; 75 before that). If a form is reported, a rename task missed a site: fix it in this commit and say so in the body. Then remove the line `'tests/test-vocabulary.sh'   # named by …` from `DECLARED_ABSENT` in `tests/test-links-resolve.sh`, stage the new test so the reference check resolves the spec's mention of it, and run `bash tests/test-links-resolve.sh`: green, with the declared count one lower.

- [ ] **Step 4: Suite and commit**

Run `bash tests/run.sh`. Expected: green, `tests/test-vocabulary.sh` among the PASS lines.

```bash
git add tests/test-vocabulary.sh tests/test-links-resolve.sh
git commit -m "Enforce CONTEXT.md's retired forms with a test" -m "Each _Avoid_ line is a list of bare surface forms, and every checked file outside CONTEXT.md and the historical directory is grepped for each, whole word (names-and-surface spec §5.4). Red first on a seeded mutant; an underscore-joined identifier is a hit and a hyphen-joined repository name is not, so there is no exception list. The reference check's temporary declared entry for this file goes.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>" -- tests/test-vocabulary.sh tests/test-links-resolve.sh
```

### Task 16: Gate 1 (§9)

**Files:**

- None edited unless a check is red.

- [ ] **Step 1: The full suite, cited**

Run: `bash tests/run.sh` then `head -n 1 tests/results.tsv && grep -c PASS tests/results.tsv && grep -vE 'PASS' tests/results.tsv`
Expected: the header names the branch's HEAD without `dirty`; every row `PASS`, with `SKIP` only for a tool this machine lacks, named in the summary's `for want of:`. Cite the file's header line in the plan's execution notes; do not paste the output.

- [ ] **Step 2: This plan's own paths, formatting and spelling**

This file is a checked document. Run `scripts/format`, then `bash tests/test-lint-markdown.sh`, `bash tests/test-format-prettier.sh`, `bash tests/test-links-resolve.sh`. Expected: silent, green, green: every path this plan names is current or sits beside its successor. If the reference check names a line of this plan, edit that line (the ruling permits it) and commit with the message `Keep plan A's own paths current`.

- [ ] **Step 3: Push and watch CI**

```bash
git push -u origin names-and-surface && gh run list --branch names-and-surface --limit 2
```

Then `gh run watch` on the `validate` run. Expected: both jobs green, `validate` running `tests/run.sh --no-skip` with nothing skipped (the runner installs every tool, and the checkout now fetches the full history), and `setup-e2e` converging a scratch HOME under the moved `skills.json`. A red job is fixed on the branch and the gate re-run; no force-push.

- [ ] **Step 4: What plan B inherits**

Record in the branch, as the body of an empty commit, so plan B's author reads it from `git log`:

```bash
git commit --allow-empty -m "Gate 1 of names-and-surface: milestone 3 lands" -m "Suite green (tests/results.tsv header: <paste the header line>); CI green on names-and-surface. Plan B is written against this tree. It inherits: the temporary DECLARED_ABSENT entry for tests/test-format-apply.sh in tests/test-links-resolve.sh, dropped when §18 creates the file; the Layout section's vendored.json line, added when §14 creates the file; the three shape checks tests/test-hook.sh lost with the §4.2 oracle, returned by #63 item 2; M4's checked_shell() half and M8's remaining sites in tests/test-ownership.sh; and every issue disposition, #57 included, since none was closed here.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git push
```

Replace the placeholder with the actual header line. Plan A ends here; plan B (milestone 4) is the next writing-plans run, against this tree.
