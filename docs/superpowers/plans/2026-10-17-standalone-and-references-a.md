# software-dev carries what it changes — Implementation Plan A (constraints 1 to 9)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the branch `standalone-and-references` from `main` through §18's constraints 1 to 9: the watch rewritten and tested offline, the forks and the `brainstorming` copy out of the drift exclusion, the hook gone, the reference scan widened, the records in `vendored.json`, one upstream test and one LICENSE grammar, and a CI install job green before anything of `bin/setup` is deleted.

**Architecture:** Every guard lands red first, by the mutation the spec names. The watch comes first, since later tasks extend its offline test. The reference check learns to skip historical artifacts before any path is renamed, so the plans themselves stop being checked at their own commit. Then the three trees that leave the drift exclusion (the two forks and the copy), the widened scan, the records, the one upstream test with the LICENSE sections it reads, and the install job beside the still-present `setup-e2e`. Nothing that `bin/setup` reads changes in this plan; plan B retires it.

**Tech Stack:** bash 4.4+ (`set -euo pipefail` in tests), git, jq, GitHub Actions, Claude Code (`claude plugin`), codex-cli (`codex plugin`, `codex debug prompt-input`), shellcheck 0.9.0, shfmt 3.14.1, prettier 3.9.6, markdownlint-cli2 0.23.2, cspell 10.2.2, actionlint 1.7.12, python3 with pyyaml.

**Spec:** `docs/superpowers/specs/2026-09-27-standalone-and-references-design.md`. Section numbers below refer to it; Q and T numbers are its §3 rows. Plan B, `2026-10-17-standalone-and-references-b.md` beside this file, takes constraints 10 to 20.

**This is plan A of two, one branch.** Written against `main` at `bb596b0` on 2026-10-17. Plans name functions, sections and anchors, never line numbers (§18); where a number appears it is a locator, and the quoted text beside it binds.

## What was verified while planning (2026-10-17, tree at `bb596b0`)

Each item was measured in this checkout, in scratch clones, or against the live services; where it refines the spec, the plan says so.

- **The upstream refs match the spec.** `mattpocock/skills`: `v1.3.1` is the newest stable tag and peels to `24fe0ef7737efae15c87225755e9f6f5965e4888`; `v1.2.3` peels to `6acc160e4e0cd062dbbbd7a1b26ae92855edf07e` (its tag object is `835450ef`); `main` is `49dd158d`. `UditAkhourii/adhd` `main` is `7b91ce601ed951c1a9658c63f6f9550d2486525b`, its one tag `v0.1.4`, and `skills/adhd` there is byte-identical to the pin `16dc239f`. `softaworks/agent-toolkit` `main` is the pin `3027f20f`. `obra/superpowers-lab` `main` is the pin `51111f74`. `obra/superpowers` `main` is `bb92a777`, newest tag `v7.0.0`. The former superpowers pin `b36e0829` holds fourteen skill directories, `brainstorming` among them, at version 6.3.0.
- **Upstream LICENSE copyright lines at the pins:** `Copyright (c) 2026 Matt Pocock`; `Copyright (c) 2026 ADHD contributors`; `Copyright (c) 2025 Jesse Vincent` (superpowers-lab, and the former superpowers pin); `Copyright (c) 2026 Leonardo Flores` (softaworks, credited by no section, since nothing of it is copied).
- **mattpocock at `v1.3.1`:** 37 skill directories hold a `SKILL.md` under `skills/engineering`, `skills/productivity`, `skills/in-progress` and `skills/misc` (`skills/deprecated` holds only a README); no plugin manifest and no `hooks/hooks.json` under `skills`; the root manifest is `mattpocock-skills` at 1.3.1. Every file of `diagnosing-bugs` and of `setup-matt-pocock-skills` there is mode 100644. `diagnosing-bugs`' description is unchanged from `v1.2.3`: `description: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.` Its body changes by the `GLOSSARY.md` rename, punctuation, and one more thing the spec does not record: Phase 6 loses its post-mortem paragraph and its `/improve-codebase-architecture` handoff. Harmless to the copy; recorded here. The eight gated skills pair `disable-model-invocation: true` with `allow_implicit_invocation: false`: `handoff`, `teach`, `to-questionnaire`, `wait-what`, `wayfinder`, `grill-with-docs`, `improve-codebase-architecture`, `triage`; the other seven listed skills carry neither.
- **The sibling-name check (T44) over every markdown file of the fifteen listed skills, the copy and upstream's `setup-matt-pocock-skills` at `v1.3.1`:** three undelivered names, all in the scaffolder: `to-spec` and `to-tickets` in its `SKILL.md` explainer (which this repository's fork already replaced), and `pr` in `issue-tracker-gitlab.md` (`` `mr` in place of `pr` ``), which the fork still carries. Over `SKILL.md` alone, only the first two. Plan B's Task 1 rewords the gitlab line. `handoff` does not name `claude-handoff`.
- **The reference scan's file set today** (`git ls-files 'plugins/*/skills/**/*.md' 'plugins/*/agents/*.md' 'plugins/*/skills/*/agents/openai.yaml'`): 23 files, 20 once the `brainstorming` copy leaves. Its `<p>:<s>` tokens outside the copy: `software-dev:consistency-audit-inspector` (twice), `superpowers:writing-plans` and `software-dev:brainstorming` in `rethink-audit`, and the idioms `file:line` (twice), `bug:triage`, `wayfinder:map` (four times); `superpowers-lab:skills` in `PROVENANCE.md` is preceded by `/` and skipped by shape. The exceptions §10.2 names are exactly the three idioms.
- **The two forks, linted in a scratch clone with their exclusion rows removed:** prettier reformats 2 files (`setup-repository/SKILL.md`, `find-duplicates-prompt.md`); markdownlint reports 13 (MD040 in `domain.md` twice, `categorize-prompt.md` once and `find-duplicates-prompt.md` twice; MD031 twice, MD029 five times and MD032 once in `find-duplicates-prompt.md`'s Usage list); cspell 10 (`glab` seven times, `unlabel` twice, `Summarise` once); the vocabulary scan 0 (the hook file carried the one hit); the reference check 6 lines: `./extract-functions.sh src/ -o catalog.json` in `categorize-prompt.md` (two words), `.scratch/` three times and `src/` once in the scaffolder. §8's counts included the hook file.
- **The CLIs' output shapes the install job parses.** `claude plugin details <p>@<m>` prints, indented by two spaces, `Skills (N)` and `Agents (N)` followed by two spaces and the comma-separated names on one line each, `Agents (0)` with nothing after it. `claude plugin list` prints each plugin on its own line as the glyph `❯` and `name@marketplace`, indented by two spaces. `codex debug prompt-input` prints one JSON array; the catalogue is the `text` of a developer message, a `<skills_instructions>` block whose entries are `- <name>: <description> (file: rN/...)`, qualified names as `plugin:skill`, bare names for `~/.agents/skills` and `~/.codex/skills`. `codex plugin list --json` carries no skill list.
- **npm dist-tags on 2026-10-17:** `@anthropic-ai/claude-code` `stable` 2.1.292, `latest` 2.1.302; `@openai/codex` `latest` 0.163.0 and no `stable`. The current action releases are `actions/checkout@v7.0.1` (pinned), `actions/setup-node@v7.1.0` and `actions/upload-artifact@v7.0.2` (both past the pins), `actions/setup-python@v7.0.0` (pinned): Dependabot's to move, not this branch's.
- **Local tools:** Claude Code 2.1.273, codex-cli 0.147.0, and every registry tool at its pinned version. `gh` is logged in as `eranroseman`. Private vulnerability reporting is `enabled: false`.
- **The tests that read the copy or the hook** (constraint 3 asked the plan to read `bin/setup`'s tests): none. `tests/test-setup-upgrade.sh` calls `fetch_upstream`, the superpowers clone, which stays until plan B; `test-doctor-*.sh` and `test-setup-*.sh` name neither `brainstorming` nor `hooks/`.
- **`setup-matt-pocock-skills` has no history as a path under `plugins/software-dev`:** `d7ddf27` renamed it under the old `plugins/software-development/`. The reference check's history tier would not rescue a slashed mention of the new path before the rename lands, which is why Task 2 (the skip of `docs/superpowers`) precedes Task 4 (the rename).
- **`.agents/plugins/marketplace.json`'s only reader in the tests** is `tests/test-codex-marketplace.sh`.
- **The ownership table's six rows** name `tests/test-vendored-adhd.sh`, `tests/test-vendored-brainstorming.sh`, `tests/test-vendored-diagnosing-bugs.sh`, `tests/test-vendored-scaffolder.sh`, `tests/test-vendored-duplicates.sh` and `tests/test-hook.sh`; `guards` is called by exactly those six.

## Deviations decided while planning

Visible choices, each with a veto line.

- **P1. Two plans, split at constraints 9 and 10.** Constraint 10 is the first commit that deletes what `bin/setup` reads; everything before it leaves the engine and its nine tests intact, so plan A ends at a gate where the suite and both CI jobs are green and nothing has merged. Veto: one plan.
- **P2. The reference check's skip of `docs/superpowers` lands second, before any rename, and the plans are committed right after it.** Q18's change is unordered in §18; landing it before Task 4 means no commit checks the plans' own text, whose Files lists name new paths with slashes, and no renamed path has to be written beside its successor. Veto: land it with constraint 10 and commit the plans with every new path declared absent.
- **P3. `tests/test-format-apply.sh`, the runner test's leftovers and `tests/test-references-resolve.sh`'s trims land in Task 2.** All are unordered in §18 and the first two read `skills.json` or `tests/tools.txt` in ways plan B would otherwise have to touch. Veto: a leftovers task in plan B.
- **P4. The sibling-name check (T44) runs for a record whose pin is its entry's, over every markdown file of the listed skills, the copy and the fork.** §7.3 lists it under the records and T44 names the entry's skills; before the mattpocock entry lands no record pairs with an entry, so the check is vacuous and its summary count says so, and from plan B's Task 1 it holds. Every markdown file, as §10.2's scan reads them, not `SKILL.md` alone: the one extra name it catches, `pr` in the gitlab template, is a real pointer at a skill the entry excludes. Veto: `SKILL.md` only, or a separate check added in plan B.
- **P5. The complement check runs under each entry's `path` for every entry, softaworks included.** §7.3's complement is "the basenames of the directories under `path` that hold a `SKILL.md`"; under softaworks' `path` that is one directory, its one listed skill, so the check holds there with zero exclusions and no special case. The reason §7.3 gives for keeping no softaworks complement, the 43 skills shipped twice, concerns a complement over the whole repository, and the comment records it. Veto: skip softaworks by name.
- **P6. Codex's hidden skills in an entry are read from the installed cache's policy files**, located as the one directory under `$CODEX_HOME/plugins/cache/eranroseman/<entry>/`, since Codex names that directory by `version` and the job should not depend on the naming. Veto: build the path from `version`.
- **P7. The interim README.** Task 9 adds the marked install and update blocks and keeps the `bin/setup` prose and its two unmarked blocks beside them until plan B's Task 1 rewrites Install and Update, as constraint 9 requires. Nothing on the branch is published before plan B's gate. Veto: rewrite Install and Update in Task 9 and let `tests/test-setup-doctor.sh`'s bash-floor grep read the Checks section, where the sentence already is.
- **P8. The watch is rewritten in Task 1 with the record loop still reading today's per-tree `vendored.json`;** Task 7 moves it to the records' shape with the fixture. Constraint 1 wants the offline test first and constraint 4 the records later, so the loop is touched twice, each time small. Veto: land the records first.
- **P9. The adhd record is written at `16dc239f`, today's pin;** plan B bumps it to `main`'s tip re-read then (§9), since the copy's bytes do not change and nothing in this plan needs the move. Veto: bump here.
- **P11. The superpowers-lab LICENSE section keeps `PROVENANCE.md`'s date and drops its sha.** §7.4 folds the file's "compared against `51111f7` on 2026-08-29" into the section, and Q1 says no section names a sha; the date carries the fact, and the record carries the pin. Veto: write the sha.
- **P10. The test cache directories** keep the `${TMPDIR:-/tmp}/software-dev-upstream-<owner>-<repo>` naming, one per repository, so a second test run reuses the fetch. Veto: `mktemp -d` per run.

## Global Constraints

Copied from the spec unless marked; every task's requirements implicitly include this section.

- **Branch:** `standalone-and-references` from `main`, checked out in the worktree `.claude/worktrees/standalone-and-references`. Every commit of both plans lands there. Nothing merges in plan A.
- **Red first:** every new check is added red, by the mutation its issue or the spec names (§15.3, T31), made in a scratch copy or in the working tree and reverted; each task names its mutation.
- **Evidence:** each green cites `tests/results.tsv` (gitignored, rewritten by every `tests/run.sh` run) rather than pasted output; a CI run is cited by its run id, since it writes no row.
- **Names, not line numbers** (§18): anchors are quoted text, functions and sections.
- **The plans are committed after Task 2** (P2), on the branch, in one commit; until then they are untracked files in the main checkout.
- **No sha in any header, LICENSE or `PROVENANCE.md`** (Q1): a pin is written once, in `vendored.json` or in its subset entry.
- **A copy is upstream's bytes and modes** except its declared changes, each a row in `test-upstream.sh` with a reason (§7.1); a fork is first-party, linted, and held by nothing (§8).
- **Comments and sentences that go false** are made true or count-free in the commit that makes the change (§17, #37's rule); no count where a count would go stale.
- **The suite rule** (§15.1): a test holds upstream drift or installability; beside them the linters, the skill-reference scan, the watch's tests and the runner's tests. Nothing holds this repository's own wording, literals, counts or headers.
- **`strict: false` on every subset entry**, its reason in `test-upstream.sh`'s comment (§6.4).
- **The spelling test's rule:** a typo is fixed, a term joins `cspell.config.yaml`'s word list; a British spelling becomes the US one.
- **Versions:** `software-dev` stays at 0.8.0 and `sensemaking` at 0.2.2 through plan A; plan B bumps `software-dev` once (T43).
- **Caveman mode does not apply to anything persisted.** Files, commits and comments are written in normal prose.

## Names used across tasks

A task's implementer sees only their own task; these are the names neighboring tasks rely on, defined where the Interfaces block says.

| Name                                                  | Where                    | Defined in | Shape                                                                                                                                              |
| ----------------------------------------------------- | ------------------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VENDORED_JSON`                                       | `tests/lib.sh`           | Task 7     | `"$REPO_ROOT/vendored.json"`                                                                                                                       |
| `entry_rows`                                          | `tests/lib.sh`           | Task 6     | prints `name<TAB>url<TAB>path<TAB>ref<TAB>sha<TAB>version` per `git-subdir` entry                                                                  |
| `entry_skills <name>`                                 | `tests/lib.sh`           | Task 6     | prints the last segment of each path the entry lists, one per line                                                                                 |
| `upstream_sha <owner/repo>`                           | `tests/lib.sh`           | Task 7     | the `sha` of the one `git-subdir` entry whose `source.url` is `https://github.com/<owner/repo>.git`; fails on none or more than one                |
| `upstream_ref <owner/repo>`                           | `tests/lib.sh`           | Task 7     | the same entry's `ref`                                                                                                                             |
| `record_rows`                                         | `tests/lib.sh`           | Task 7     | prints `repo<TAB>ref<TAB>sha` per record, the pin resolved through the entry when the record carries neither (T24); fails on one without the other |
| `record_map <trees\|forks> <owner/repo>`              | `tests/lib.sh`           | Task 7     | prints `local<TAB>upstream` per pair of that map                                                                                                   |
| `tree_keys`, `fork_keys`                              | `tests/lib.sh`           | Task 7     | every `trees` key, every `forks` key, one per line, across records                                                                                 |
| `EXCLUDED`                                            | `tests/lib.sh`           | Task 7     | an extended regex, every `trees` key as `^<key>/`, joined by `\|`; `^$` when none                                                                  |
| `shipped_texts`                                       | `tests/lib.sh`           | Task 6     | `git ls-files 'plugins/*/skills/**/*.md' 'plugins/*/agents/*.md' 'plugins/*/skills/*/agents/openai.yaml'`                                          |
| `skill_name_matches <dir> [label]`                    | `tests/lib.sh`           | Task 6     | fails unless `<dir>/SKILL.md`'s frontmatter `name` equals the directory's basename                                                                 |
| `peel_tag <url> <tag>`                                | `tests/lib.sh`           | Task 8     | the commit the tag names: `refs/tags/<tag>^{}`, else the bare tag; empty when no such tag                                                          |
| `fetch_pinned <url> <sha> <dir>`                      | `tests/lib.sh`           | exists     | Task 8 adds the assertion that the checkout's HEAD equals `<sha>`                                                                                  |
| `fetch_upstream`                                      | `tests/lib.sh`           | exists     | obra/superpowers at its entry's pin; from Task 7 it calls `upstream_sha obra/superpowers`; plan B deletes it with `tests/test-setup-upgrade.sh`    |
| `resolve_ref <url> <ref>`                             | `scripts/upstream-watch` | Task 1     | prints `branch<TAB>sha` or `tag<TAB>sha`; `die` (exit 2) on both or neither (T39)                                                                  |
| `newest_stable_tag`                                   | `scripts/upstream-watch` | exists     | filters tag names on stdin to the newest stable one                                                                                                |
| `readme_block <name>`                                 | `tests/install-check.sh` | Task 9     | the lines of the fenced block of `README.md` whose info string's second word is `<name>` (T13)                                                     |
| `details_names <plugin@marketplace> <Skills\|Agents>` | `tests/install-check.sh` | Task 9     | the names on that line of `claude plugin details`, sorted, one per line                                                                            |
| `codex_catalogue`                                     | `tests/install-check.sh` | Task 9     | every skill name in `codex debug prompt-input`'s catalogue, qualified as the catalogue shows it, one per line                                      |
| `DECLARED` (array)                                    | `tests/test-upstream.sh` | Task 8     | one row per declared change: `local path<TAB>kind<TAB>anchor<TAB>reason`, kind `line` or `added`, anchor `<file>` for a whole added file           |
| `EXCLUSIONS` (associative array)                      | `tests/test-upstream.sh` | Task 8     | per entry name, lines of `skill<TAB>reason`                                                                                                        |
| README block markers                                  | `README.md`              | Task 9     | fenced blocks `sh install-claude`, `sh install-codex`, `sh update-claude`, `sh update-codex`; plan B adds `sh cleanup`                             |

---

### Task 1: The branch, the watch's one ref resolution, and its offline test (§12, constraint 1; #69, T39, T50, Q66)

**Files:**

- Create: `tests/test-upstream-watch.sh` (named `test-upstream-watch.sh` in prose until Task 2)
- Create: `.github/dependabot.yml` (named `dependabot.yml`)
- Modify: `scripts/upstream-watch` (rewritten whole)
- Modify: `tests/test-workflows.sh` (the watch cases after `# The watch reads the same pins`)
- Modify: `tests/test-setup-doctor.sh` (the six lines under `# upstream-watch's tag filter, with no network`)
- Modify: `cspell.config.yaml` (word list)

**Interfaces:**

- Produces: `resolve_ref <url> <ref>` inside the watch, printing `branch<TAB>sha` or `tag<TAB>sha`, exit 2 on both or neither; the watch's report sections `### subset entries`, `### vendored and forked trees`, `### skills.sh sources` (the last goes in plan B); the offline test's fixture layout, which Task 7 extends: a scratch root holding `scripts/upstream-watch`, `.claude-plugin/marketplace.json`, `vendored.json`, `skills.json`, and a `bin/git` stub answering `ls-remote` from a tab-separated table `answers.tsv` (`url<TAB>refname<TAB>sha`).
- Consumes: nothing new.

- [ ] **Step 1: The branch, and where the plans live**

The branch `standalone-and-references` exists, checked out in the worktree `.claude/worktrees/standalone-and-references` at `main`'s `bb596b0`; every path in this plan is relative to that worktree, and the main checkout stays on `main`. The two plan files sit untracked in the main checkout, `docs/superpowers/plans/`, until Task 2 lands: committed at `bb596b0` they turn the reference check red on the slashed new paths in their own Files lists, so they are copied into the worktree and committed in one commit right after Task 2's, once documents under `docs/superpowers` are no longer scanned. Spelling, markdownlint and prettier pass with them tracked.

Run `bash tests/run.sh` once in the worktree before changing anything. Expected: green but for the tests this machine skips for want of a tool, and `tests/test-codex-validate.sh` red when `~/.codex`'s validator copy is not the pinned one (Task 3 fixes that); cited in `tests/results.tsv`.

- [ ] **Step 2: Write the offline watch test, red**

Create `tests/test-upstream-watch.sh`:

```bash
#!/usr/bin/env bash
# The watch, run whole and offline (spec §12.4). A PATH stub stands in for the
# network: a `git` whose `ls-remote` answers come from a table in this test,
# so the cases exercise the call sites the scheduled run uses, not a mode.
# The watch is copied into a scratch root beside a fixture marketplace with
# two git-subdir entries, one on a tag and one on a branch, a fixture
# vendored.json and a fixture skills.json. The cases:
#   1. the stable-tag filter: a tag entry pinned at the newest stable tag is
#      current, and prereleases, -dev builds and a parallel tag series never
#      count (Q66);
#   2. tag and branch pins (Q29, T1, T39): a tag entry behind its newest
#      stable tag, a branch entry behind its tip, and a branch tree behind its
#      tip each exit 1 and are named; all current exit 0.
# Needs no network.
. "$(dirname "$0")/lib.sh"

W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/scripts" "$W/.claude-plugin" "$W/bin" || fail "could not seed $W"
cp "$REPO_ROOT/scripts/upstream-watch" "$W/scripts/" || fail "could not copy the watch"

TAG_URL="https://example.invalid/tag-upstream.git"
BRANCH_URL="https://example.invalid/branch-upstream.git"
TREE_URL="https://github.com/example/tree-upstream.git"
SKILLS_URL="https://github.com/example/skills-upstream.git"
TAG_SHA="1111111111111111111111111111111111111111"
BRANCH_SHA="2222222222222222222222222222222222222222"
TREE_SHA="3333333333333333333333333333333333333333"
NEWER="4444444444444444444444444444444444444444"

# The fixture desired state. The tag entry's version is upstream's, the
# branch entry's is this repository's; neither matters to the watch.
write_marketplace() { # $1 the tag entry's ref, $2 its sha, $3 the branch entry's sha
  cat >"$W/.claude-plugin/marketplace.json" <<JSON
{
  "name": "fixture",
  "plugins": [
    {
      "name": "tagged",
      "source": { "source": "git-subdir", "url": "$TAG_URL", "path": "skills", "ref": "$1", "sha": "$2" },
      "version": "2.16.0",
      "strict": false,
      "skills": ["./one"]
    },
    {
      "name": "branched",
      "source": { "source": "git-subdir", "url": "$BRANCH_URL", "path": "dist", "ref": "main", "sha": "$3" },
      "version": "0.1.0",
      "strict": false,
      "skills": ["./skills/two"]
    }
  ]
}
JSON
}
write_vendored() { # $1 the tree's sha
  cat >"$W/vendored.json" <<JSON
{
  "\$comment": "fixture",
  "plugins/p/skills/three": {
    "repo": "example/tree-upstream",
    "branch": "main",
    "sha": "$1",
    "upstream_path": "skills/three",
    "kind": "vendored"
  }
}
JSON
}
printf '{"sources":[{"repo":"example/skills-upstream","ref":"v1.0.0","skills":["four"],"not_adopted":[],"via_subset_entry":[]}]}\n' >"$W/skills.json" \
  || fail "could not write the fixture skills.json"

# The git stub: `ls-remote` answered from answers.tsv (url, refname, sha);
# with no refspec it lists the tags of the url, as `--tags --refs` does. Any
# other verb is exit 99, so the watch cannot reach a real remote from here.
cat >"$W/bin/git" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = ls-remote ] || exit 99
shift
while [ "$#" -gt 0 ]; do
  case "$1" in --*) shift ;; *) break ;; esac
done
url="$1"
shift
if [ "$#" -eq 0 ]; then
  awk -F'\t' -v u="$url" '$1 == u && $2 ~ /^refs\/tags\// && $2 !~ /\^\{\}$/ { print $3 "\t" $2 }' "$ANSWERS"
else
  for spec in "$@"; do
    awk -F'\t' -v u="$url" -v s="$spec" '$1 == u && $2 == s { print $3 "\t" $2 }' "$ANSWERS"
  done
fi
STUB
chmod +x "$W/bin/git" || fail "could not make the git stub executable"
export ANSWERS="$W/answers.tsv"

# $1 the tag entry's newest tag set, one sha for every tag listed; $2 the
# branch tip; $3 the tree tip. The tag entry's tags: a stable release, a
# newer stable release, prereleases, a -dev build and a parallel series.
write_answers() { # $1 newest stable tag name, $2 its sha, $3 branch tip, $4 tree tip
  {
    for t in archify-dsh-v0.1.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 v2.16.0 "$1"; do
      printf '%s\trefs/tags/%s\t%s\n' "$TAG_URL" "$t" "$TAG_SHA"
    done
    printf '%s\trefs/tags/%s\t%s\n' "$TAG_URL" "$1" "$2"
    printf '%s\trefs/tags/v2.16.0\t%s\n' "$TAG_URL" "$TAG_SHA"
    printf '%s\trefs/heads/main\t%s\n' "$BRANCH_URL" "$3"
    printf '%s\trefs/heads/main\t%s\n' "$TREE_URL" "$4"
    printf '%s\trefs/tags/v1.0.0\t%s\n' "$SKILLS_URL" "$TREE_SHA"
  } | sort -u >"$ANSWERS"
}

run_watch() { # prints the report; status in $status
  status=0
  out="$(cd "$W" && PATH="$W/bin:$PATH" bash scripts/upstream-watch 2>&1)" || status=$?
}

# 1. The stable-tag filter. Everything current: the tag entry at v2.16.0,
# which is the newest stable tag; exit 0 and the entry's current line.
write_marketplace v2.16.0 "$TAG_SHA" "$BRANCH_SHA"
write_vendored "$TREE_SHA"
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 0 ] || fail "with every pin current the watch exited $status, not 0:"$'\n'"$out"
grep -qF -- '`v2.16.0`' <<<"$out" || fail "the current tag entry's line does not name its tag:"$'\n'"$out"
grep -qF 'Everything matches' <<<"$out" || fail "a clean run must say so:"$'\n'"$out"
# Pinned one stable release back: exit 1, and the line names v2.16.0, never a
# prerelease or the parallel series.
write_marketplace v2.15.0 "$TAG_SHA" "$BRANCH_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a tag entry behind the newest stable tag must exit 1, got $status:"$'\n'"$out"
grep -qF -- 'the newest stable tag is `v2.16.0`' <<<"$out" || fail "the drifted tag entry does not name v2.16.0:"$'\n'"$out"
grep -qE 'v2\.17\.0-dev|v2\.16\.1-rc|v2\.16\.0-beta|archify-dsh' <<<"$out" \
  && fail "a prerelease or a parallel tag series was reported as the newest stable tag:"$'\n'"$out"

# 2. Tag and branch pins. A newer stable tag appears: the tag entry drifts.
write_marketplace v2.16.0 "$TAG_SHA" "$BRANCH_SHA"
write_answers v2.17.0 "$NEWER" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a tag entry behind a new stable tag must exit 1, got $status:"$'\n'"$out"
grep -qF -- 'the newest stable tag is `v2.17.0`' <<<"$out" || fail "the new tag was not named:"$'\n'"$out"
grep -qF 'tagged' <<<"$out" || fail "the drifted entry was not named:"$'\n'"$out"
# The branch entry behind its tip.
write_answers v2.16.0 "$TAG_SHA" "$NEWER" "$TREE_SHA"
run_watch
[ "$status" -eq 1 ] || fail "a branch entry behind its tip must exit 1, got $status:"$'\n'"$out"
grep -qF -- "main is \`$NEWER\`" <<<"$out" || fail "the branch entry's drift does not name the tip:"$'\n'"$out"
grep -qF 'branched' <<<"$out" || fail "the drifted branch entry was not named:"$'\n'"$out"
# The tree behind its tip.
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$NEWER"
run_watch
[ "$status" -eq 1 ] || fail "a tree behind its tip must exit 1, got $status:"$'\n'"$out"
grep -qF 'plugins/p/skills/three' <<<"$out" || fail "the drifted tree was not named:"$'\n'"$out"
# All current again: exit 0.
write_answers v2.16.0 "$TAG_SHA" "$BRANCH_SHA" "$TREE_SHA"
run_watch
[ "$status" -eq 0 ] || fail "with every pin current again the watch exited $status:"$'\n'"$out"

# A ref that is both a branch and a tag is the watch's own failure, exit 2.
printf '%s\trefs/heads/v2.16.0\t%s\n' "$TAG_URL" "$NEWER" >>"$ANSWERS"
run_watch
[ "$status" -eq 2 ] || fail "a ref that is both a branch and a tag must exit 2, got $status:"$'\n'"$out"
grep -qF 'both a branch and a tag' <<<"$out" || fail "the double ref was not named:"$'\n'"$out"

printf 'upstream-watch: offline, the stable-tag filter holds and tag, branch and tree pins each report drift and clean\n'
```

- [ ] **Step 3: Run it to see it fail**

Run: `bash tests/test-upstream-watch.sh`
Expected: FAIL. Today's watch resolves a tag entry through `refs/heads/<ref>` only and dies `could not resolve ... v2.16.0`, exit 2, where case 1 expects 0.

- [ ] **Step 4: Rewrite the watch**

Replace `scripts/upstream-watch` whole:

```bash
#!/usr/bin/env bash
# Compare this repository's declared pins against their upstreams and print a
# markdown report. Never bumps a pin: a bump is a manual edit of the file that
# declares it, a hand copy of upstream's changes, and test-upstream.sh saying
# whether the copy is right (spec §12).
#
#   exit 0   everything matches
#   exit 1   something upstream moved; the report says what
#   exit 2   the run itself failed, which must be loud: a dead detector looks
#            exactly like a healthy repository
#
# One ref resolution serves every pin (T39): a ref is a branch when
# refs/heads/<ref> resolves, else a tag when refs/tags/<ref>^{} or the bare
# tag does. A branch pin is compared with its branch's tip; a tag pin with its
# repository's newest stable tag. A ref that is both or neither is exit 2.
# The action pins are Dependabot's (.github/dependabot.yml), not the watch's.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
SKILLS_JSON="$REPO_ROOT/skills.json"
VENDORED_JSON="$REPO_ROOT/vendored.json"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}
DRIFT=0
report() { printf '%s\n' "$*"; }

# Stable release tags only, from tag names on stdin: v1.2.3 or 1.2.3 with
# nothing after the digits. Two different reasons, not one: -alpha, -beta,
# -rc and -dev.N suffixes are excluded because `sort -V` would otherwise rank
# an upcoming version's prerelease above the newest stable release and report
# it as drift indefinitely; a parallel tag series with its own prefix (archify
# published archify-dsh-v0.1.0 beside its releases) sorts below a real release
# regardless -- `printf 'archify-dsh-v9.9.9\nv2.16.0\n' | sort -V` puts
# v2.16.0 last -- and is excluded because the anchor admits nothing before the
# version, not because of how it would sort.
newest_stable_tag() { grep -E '^v?[0-9]+(\.[0-9]+)+$' | sort -V | tail -1; }

# $1 a URL, $2 a ref. Prints `branch<TAB>sha` or `tag<TAB>sha`; dies when the
# ref is both or neither. For a tag, the sha is the commit it names: the
# peeled object of an annotated tag, the tag itself for a lightweight one.
resolve_ref() {
  local url="$1" ref="$2" head tag
  head="$(git ls-remote "$url" "refs/heads/$ref" | cut -f1)"
  tag="$(git ls-remote --tags "$url" "refs/tags/$ref^{}" | cut -f1)"
  [ -n "$tag" ] || tag="$(git ls-remote --tags "$url" "refs/tags/$ref" | cut -f1)"
  if [ -n "$head" ] && [ -n "$tag" ]; then die "$url: $ref is both a branch and a tag"; fi
  if [ -z "$head" ] && [ -z "$tag" ]; then die "could not resolve $url $ref as a branch or a tag"; fi
  if [ -n "$head" ]; then printf 'branch\t%s\n' "$head"; else printf 'tag\t%s\n' "$tag"; fi
}

# $1 a URL. The newest stable tag there, or exit 2.
newest_tag_of() {
  local t
  t="$(git ls-remote --tags --refs "$1" | awk -F/ '{print $NF}' | newest_stable_tag)"
  [ -n "$t" ] || die "could not resolve the newest stable tag of $1"
  printf '%s\n' "$t"
}

# One pin's line. $1 what is pinned, in backticks already; $2 URL; $3 ref;
# $4 sha; $5 the bump advice for a drifted pin, one sentence. A branch pin
# is current when the branch's tip is the sha; a tag pin when the tag is the
# repository's newest stable tag.
compare_pin() {
  local what="$1" url="$2" ref="$3" sha="$4" advice="$5" resolved kind tip newest
  [ "${#sha}" -eq 40 ] || die "no 40-character sha for $what"
  resolved="$(resolve_ref "$url" "$ref")" || exit 2
  kind="${resolved%%$'\t'*}"
  tip="${resolved#*$'\t'}"
  case "$kind" in
    branch)
      if [ "$tip" = "$sha" ]; then
        report "- $what pinned at \`$sha\`, which is \`$ref\`'s tip. Nothing to do."
      else
        report "- $what pinned at \`$sha\`; $ref is \`$tip\`. $advice"
        DRIFT=1
      fi
      ;;
    tag)
      newest="$(newest_tag_of "$url")" || exit 2
      if [ "$ref" = "$newest" ]; then
        report "- $what pinned at tag \`$ref\` (\`$sha\`), the newest stable tag. Nothing to do."
      else
        report "- $what pinned at tag \`$ref\`; the newest stable tag is \`$newest\`. $advice"
        DRIFT=1
      fi
      ;;
  esac
}

[ -f "$MARKETPLACE" ] || die "missing $MARKETPLACE"
[ -f "$SKILLS_JSON" ] || die "missing $SKILLS_JSON"
[ -f "$VENDORED_JSON" ] || die "missing $VENDORED_JSON"

report "## Upstream watch"
report ""
report "Generated $(date -u '+%Y-%m-%d %H:%M UTC'). This issue is updated in place."
report ""

# 1. Each subset entry, by its ref. A bump edits .claude-plugin/marketplace.json
# and moves ref, sha and version together (spec §12.3).
report "### subset entries"
report ""
subset_rows="$(jq -r '.plugins[] | select(.source.source? == "git-subdir")
                      | [.name, .source.url, .source.ref, .source.sha] | @tsv' "$MARKETPLACE")" \
  || die "could not read subset entries from $MARKETPLACE"
[ -n "$subset_rows" ] || die "no subset entry could be read from $MARKETPLACE"
while IFS="$(printf '\t')" read -r name url ref sha; do
  [ -n "$name" ] || continue
  compare_pin "\`$name\` ($url)" "$url" "$ref" "$sha" \
    "Bump by editing \`.claude-plugin/marketplace.json\`: move \`ref\`, \`sha\` and \`version\` together, \`version\` from upstream's manifest at the new pin where it has one and by hand otherwise; then run test-upstream.sh, which names each new upstream skill to list or exclude."
done <<<"$subset_rows"
report ""

# 1b. Each vendored or forked tree: the pinned sha against the tip of its
# declared branch (vendored.json). A bump is a human decision: edit
# vendored.json, re-copy or re-diff the tree, and run test-upstream.sh.
report "### vendored and forked trees"
report ""
tree_rows="$(jq -r 'to_entries[] | select(.key != "$comment") | [.key, .value.repo, .value.branch, .value.sha, .value.kind] | @tsv' "$VENDORED_JSON")" \
  || die "could not read vendored or forked trees from $VENDORED_JSON"
[ -n "$tree_rows" ] || die "no vendored or forked tree could be read from $VENDORED_JSON"
while IFS="$(printf '\t')" read -r tree repo branch sha kind; do
  [ -n "$tree" ] || continue
  compare_pin "\`$tree\` ($kind from \`$repo\`)" "https://github.com/$repo.git" "$branch" "$sha" \
    "Bump by editing \`vendored.json\`, then re-copy the tree from the new pin (a forked tree: read its upstream diff and port what is worth it)."
done <<<"$tree_rows"
report ""

# 2. Each skills.sh source: the declared ref against the newest stable tag.
report "### skills.sh sources"
report ""
source_rows="$(jq -r '.sources[] | [.repo, .ref] | @tsv' "$SKILLS_JSON")" \
  || die "could not read skills.sh sources from $SKILLS_JSON"
[ -n "$source_rows" ] || die "no skills.sh source could be read from $SKILLS_JSON"
while IFS="$(printf '\t')" read -r repo ref; do
  [ -n "$repo" ] || continue
  newest="$(newest_tag_of "https://github.com/$repo.git")" || exit 2
  if [ "$newest" = "$ref" ]; then
    report "- \`$repo\` pinned at \`$ref\`, the newest tag."
  else
    report "- \`$repo\` pinned at \`$ref\`; newest tag is \`$newest\`. Bump by editing \`skills.json\`."
    DRIFT=1
  fi
done <<<"$source_rows"
report ""

if [ "$DRIFT" -eq 0 ]; then
  report "Everything matches. No action."
  exit 0
fi
report "One or more pins moved. Bumping is a human decision, made on a branch."
exit 1
```

What left with it: the `--newest-stable-tag` and `--workflow-pins` modes, `workflow_pins`, the `### openai/codex constants` section and its two `curl` fetches (#69's pipe with them, unfixed), and the `### action pins` section (T50). The superpowers-only _Latest upstream tag_ line goes with the branch (Q11; it would have gone with the entry anyway).

- [ ] **Step 5: Run the offline test to see it pass**

Run: `bash tests/test-upstream-watch.sh`
Expected: PASS, printing the `upstream-watch: offline, ...` line.

- [ ] **Step 6: Point Dependabot at the action pins**

Create `.github/dependabot.yml`:

```yaml
# Dependabot watches the Actions pins (spec §12.2, T50): it moves a sha-pinned
# `uses:` line to the action's newest release together with the version
# comment beside it, and moves a sha with no tag to the latest commit. Daily,
# the watch's own cadence. tests/test-workflows.sh still holds that every
# `uses:` is pinned by sha.
version: 2
updates:
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: daily
```

Add `Dependabot` to the word list in `cspell.config.yaml`, in alphabetical order after `custodied`.

- [ ] **Step 7: Trim the tests that drove the deleted modes**

In `tests/test-setup-doctor.sh`, delete the six lines from the comment `# upstream-watch's tag filter, with no network: the newest stable release` through `[ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"` and the blank line after them. The case lives in `tests/test-upstream-watch.sh` now.

In `tests/test-workflows.sh`, replace everything from the comment `# The watch reads the same pins the guard above checks` to the line before the final `printf 'workflows: ...'` with:

```bash
# A broken desired-state file must fail the watch before it reads any upstream:
# exit 2, the file named, and the git stub's log empty. The stub records every
# call and answers nothing, so a watch that reached for a remote shows here.
W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/scripts" "$W/.claude-plugin" "$W/bin" || fail "could not seed $W"
cp "$REPO_ROOT/scripts/upstream-watch" "$W/scripts/" || fail "could not copy the watch"
cp "$REPO_ROOT/skills.json" "$REPO_ROOT/vendored.json" "$W/" \
  || fail "could not copy the watch's desired state"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"%s"\nexit 99\n' "$W/git.log" >"$W/bin/git" \
  || fail "could not write the git stub"
chmod +x "$W/bin/git" || fail "could not make the git stub executable"
printf '{\n' >"$W/.claude-plugin/marketplace.json" || fail "could not break marketplace.json"
status=0
out="$(PATH="$W/bin:$PATH" bash "$W/scripts/upstream-watch" 2>&1)" || status=$?
[ "$status" -eq 2 ] || fail "with a broken marketplace, upstream-watch exited $status, not 2:"$'\n'"$out"
grep -qF "$W/.claude-plugin/marketplace.json" <<<"$out" \
  || fail "the broken marketplace was not named:"$'\n'"$out"
[ ! -s "$W/git.log" ] || fail "the watch read an upstream before rejecting the broken marketplace:"$'\n'"$(cat "$W/git.log")"
# A marketplace with no subset entry is the case the old process substitution
# turned into a clean verdict: zero rows, zero iterations, DRIFT still 0.
printf '{"plugins":[]}\n' >"$W/.claude-plugin/marketplace.json" || fail "could not empty marketplace.json"
status=0
out="$(PATH="$W/bin:$PATH" bash "$W/scripts/upstream-watch" 2>&1)" || status=$?
[ "$status" -eq 2 ] || fail "with no subset entry, upstream-watch exited $status, not 2:"$'\n'"$out"
grep -qF "$W/.claude-plugin/marketplace.json" <<<"$out" \
  || fail "a marketplace with no subset entry was not named:"$'\n'"$out"
[ ! -s "$W/git.log" ] || fail "the watch read an upstream with no subset entry to compare:"$'\n'"$(cat "$W/git.log")"
```

Red first for the recording stub: point the fixture at a readable marketplace with one entry and a `git` stub that exits 99 after logging; the test must fail on `git.log` not being empty. Make that change in the working tree, run `bash tests/test-workflows.sh` (expected FAIL naming the log), revert.

Delete the header comment's sentence that the watch "reads the same pins"; the header now ends at `greps are not redundant with it.`

- [ ] **Step 8: Run the suite**

Run: `bash tests/run.sh`
Expected: every test PASS or SKIP for want of a tool; `tests/test-upstream-watch.sh`, `tests/test-workflows.sh` (needs actionlint and shellcheck) and `tests/test-setup-doctor.sh` PASS; the spelling test passes with `Dependabot` listed. Cite `tests/results.tsv`.

- [ ] **Step 9: Commit**

```bash
git add scripts/upstream-watch tests/test-upstream-watch.sh tests/test-workflows.sh tests/test-setup-doctor.sh .github/dependabot.yml cspell.config.yaml
git commit -m "Resolve every pin as a branch or a tag, test the watch offline, and leave the action pins to Dependabot"
```

### Task 2: The reference check skips historical artifacts, and three suite leftovers (Q18, T18; §15.2; §16.1)

**Files:**

- Modify: `tests/test-links-resolve.sh` (header, `DECLARED_ABSENT`, `checked_markdown` call, `classify`'s class 8 branch, `names_successor`, the summary line)
- Modify: `tests/test-references-resolve.sh` (check B's floor, check C's projection and comment)
- Modify: `tests/test-runner.sh` (the registry fixture, the result-file assertion, three assertions on names)
- Delete: `tests/test-format-apply.sh`

**Interfaces:**

- Produces: nothing other tasks call. After this task the reference check reads no document under `docs/superpowers`, so the plans and specs are checked only at commits before this one.
- Consumes: nothing new.

- [ ] **Step 1: The reference check stops reading `docs/superpowers`**

In `tests/test-links-resolve.sh`:

Replace the header's class 8 sentence, from `#   8. under docs/superpowers/ only, the history tier:` to `#      through later renames; a path with no history is a typo and fails.`, with:

```bash
# Documents under docs/superpowers are not scanned: a spec or a plan is a
# historical artifact, read as of its commit (Q18), and git history is its
# archive. The history tier below still serves class 4: a two-segment path
# a move removed is this repository's, not an owner/repo slug.
```

and renumber the list so it ends at class 7. Replace the `DECLARED_ABSENT` array with:

```bash
# Paths named because they must not exist, or absent by a recorded decision.
# An entry whose only referents sit under docs/superpowers has no reader left
# and goes (T18).
DECLARED_ABSENT=(
  'hooks/hooks.json' # the path Codex loads by fallback: named so nothing sits there (Task 5 deletes its last reader, the plugin README's paragraph, and this line with it)
  'docs/adr/'        # docs/agents/domain.md names it; this repository keeps no ADRs (#26, #37)
)
```

Replace `docs="$(checked_markdown)"` with `docs="$(checked_markdown ':(exclude)docs/superpowers')"`.

Delete the `names_successor` function whole, with its comment, and the `n_history=0 n_renamed=0` counters from the `n_ok=0 ...` line. In `classify`, delete the whole `case "$doc" in docs/superpowers/*) ... esac` block between the `DECLARED_ABSENT` loop and the final `failures=...` line. Replace the summary `printf` with:

```bash
printf 'links-resolve: %s link(s) and %s backticked path(s) resolve across %s document(s); skipped %s URL(s), %s by shape, %s placeholder(s), %s slug(s), %s namespaced, %s ignored, %s declared absent, %s command word(s)\n' \
  "$links" "$n_ok" "$scanned" "$n_url" "$n_shape" "$n_glob" "$n_slug" "$n_ns" "$n_ignored" "$n_declared" "$n_syntax"
```

`history_tier` and `history_tier_walk` stay: class 4 calls them for every document, and they are what keeps a deleted two-segment path such as `bin/setup` from passing as a slug (measured; spec §15.3), so the shallow-clone refusal and `validate.yml`'s `fetch-depth: 0` stay too.

Four of today's six declared-absent entries go (T18): `.github/actionlint.yaml`, `bin/setpu` and `plugins/ghost/` are named only under `docs/superpowers`, and `.claude/settings.json`'s one live mention, in the plugin README, is `~/.claude/settings.json`, which the shape class skips before the list is read. `hooks/hooks.json` stays until Task 5 deletes the plugin README paragraph that names it.

Red first: add a line `` `docs/superpowers/plans/no-such-plan.md` `` to `README.md` in the working tree; the test must still fail on it (the skip is of documents under that directory, not of mentions of it). Then add `` `bin/setpu` `` to `docs/superpowers/specs/2026-09-27-standalone-and-references-design.md` in the working tree; the test must pass. Revert both.

Run: `bash tests/test-links-resolve.sh`
Expected: PASS, the summary without `deleted in history` and `renamed beside the successor`.

- [ ] **Step 2: `tests/test-references-resolve.sh` compares what installs**

Replace check B's floor line `[ "$depcount" -gt 0 ] || fail "no dependencies found"` with:

```bash
[ "$depcount" -ge 1 ] || fail "no plugin declares a dependency; software-dev depends on its subset entries"
```

Replace check C's comment and projection, from `# Check C: the two manifests of each plugin agree` through `proj='{name, version, author, homepage, repository, license, keywords}'`, with:

```bash
# Check C: the two manifests of each plugin agree on name and version, the
# install id and the update gate (#1), compared as one projected object under
# jq -S. Display metadata is each manifest's own: the descriptions differ by
# design, the Claude side naming the inspector that ships only there. The
# Codex manifest's skills pointer must resolve to a directory.
pairs=0
proj='{name, version}'
```

Run: `bash tests/test-references-resolve.sh`
Expected: PASS.

- [ ] **Step 3: `tests/test-runner.sh` writes its own registry and asserts the file it checks**

In `tests/test-runner.sh`, replace `cp "$REPO_ROOT/tests/tools.txt" "$R/tests/tools.txt" || fail "could not copy tools.txt"` with a registry the fixture writes, so `shfmt 3.14.1` and `row 8` below are the fixture's and not the live file's:

```bash
cat >"$R/tests/tools.txt" <<'REGISTRY' || fail "could not write the fixture registry"
# tool  version  sha256 of the linux-amd64 release asset (- for npm packages)
shellcheck         0.9.0    700324c6dd0ebea0117591c6cc9d7350d9c7c5c287acbad7630fa17b1d4d9e2f
actionlint         1.7.12   8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
shfmt              3.14.1   76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
prettier           3.9.6    -
markdownlint-cli2  0.23.2   -
cspell             10.2.2   -
REGISTRY
```

In fixture 4 (`# 4. A dirty tree is named as such.`), the result file was written last by that fixture's own run; the comment above fixture 2's `RES="$R/tests/results.tsv"` stays, and before the dirty-tree assertion add:

```bash
[ -f "$RES" ] || fail "fixture 4's run wrote no $RES"
```

so the header check after it cannot pass vacuously on a missing file (#68). Then make the three assertions that read a sentence read the name instead: fixture 5's `grep -q 'tests/test-e-unknown.sh declares a need no probe knows: nosuchtool'` becomes `grep -qE 'tests/test-e-unknown\.sh.*nosuchtool'`; fixture 7's `grep -q 'declares a tool twice: shfmt'` becomes `grep -qE 'twice.*shfmt'`; fixture 7's `grep -q "row 8 is not 'tool version sha256-or-dash'"` becomes `grep -q 'row 8'`.

Run: `bash tests/test-runner.sh`
Expected: PASS.

- [ ] **Step 4: Delete `tests/test-format-apply.sh`**

```bash
git rm -q tests/test-format-apply.sh
```

`tests/test-format-prettier.sh` and `tests/test-format-shell.sh` name `scripts/format` when they fail and `tests/test-lint-markdown.sh` prints its findings, so a broken formatter shows the first time it runs (§15.2). Its mention in `.gitignore` does not exist; nothing else names it.

- [ ] **Step 5: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips; cite `tests/results.tsv`.

```bash
git add tests/test-links-resolve.sh tests/test-references-resolve.sh tests/test-runner.sh
git commit -m "Read historical artifacts as of their commit, and trim three tests to what the suite holds"
```

### Task 3: The Codex validator fetches its own pin, and derives its exceptions (Q69, §15.2)

**Files:**

- Modify: `tests/test-codex-validate.sh` (rewritten whole)
- Modify: `tests/run.sh` (the `codex-validator` probe and the header's example)
- Modify: `.github/workflows/validate.yml` (the _Fetch the Codex plugin validator_ step)
- Modify: `README.md` (one sentence in `## Checks`)

**Interfaces:**

- Produces: the test's `# needs: python3 pyyaml` line, the only needs line the runner has to probe for it; `CODEX_PLUGIN_VALIDATOR` still names a copy in place of the fetch.
- Consumes: nothing new.

- [ ] **Step 1: Rewrite the test**

Replace `tests/test-codex-validate.sh` whole:

```bash
#!/usr/bin/env bash
# Run Codex's own plugin validator on every local plugin. Each must pass
# cleanly, except for one recorded bullet on each user-invocable-only skill:
# validate_plugin.py requires Claude's disable-model-invocation to be false or
# absent, and every such skill keeps `true` because that is the field Claude
# reads, while Codex reads policy.allow_implicit_invocation in
# agents/openai.yaml, set to false; tests/test-plugin-skills.sh holds the pair.
# The exceptions are derived from the policy files, so a skill gaining the gate
# needs no edit here, and any other bullet fails the test.
#
# The validator is two files from openai/codex at a pinned sha (Q69), fetched
# here blobless and checked against their sha256: codex-cli no longer ships
# them, since 0.159 rewrites ~/.codex/skills/.system at startup without
# plugin-creator. CODEX_PLUGIN_VALIDATOR names a copy in place of the fetch.
# Offline, this fails rather than skips, as test-upstream.sh does.
# needs: python3 pyyaml
. "$(dirname "$0")/lib.sh"

PIN=f3f6922519fa38487c8250c2b8a670a39a2cf9ff
UPSTREAM_DIR=codex-rs/skills/src/assets/samples/plugin-creator/scripts
declare -A WANT=(
  [validate_plugin.py]=f4eeadb733b28b0c3e714de263a76d6542866a672f3e99bdffcf4dbcdf85e944
  [identifier_validation.py]=a6d51ce4a9a7e8f85626ff5808a467a67574e7f8cdf1167ffb467c5f67e57223
)

# True when both files under $1 hash to the pins.
pinned_copy() {
  local f got
  for f in "${!WANT[@]}"; do
    [ -f "$1/$f" ] || return 1
    got="$(sha256sum "$1/$f")" || return 1
    [ "${got%% *}" = "${WANT[$f]}" ] || return 1
  done
}

if [ -n "${CODEX_PLUGIN_VALIDATOR:-}" ]; then
  VALIDATOR="$(readlink -f "$CODEX_PLUGIN_VALIDATOR")" || fail "could not resolve $CODEX_PLUGIN_VALIDATOR"
  VDIR="${VALIDATOR%/*}"
else
  # A depth-1 blobless fetch and a checkout of the two paths: 2 seconds and
  # 464 KB (measured 2026-10-01). Reused while both files still match.
  CACHE="${TMPDIR:-/tmp}/software-dev-codex-validator-${PIN:0:7}"
  VDIR="$CACHE/$UPSTREAM_DIR"
  if ! pinned_copy "$VDIR"; then
    rm -rf "$CACHE"
    mkdir -p "$CACHE" || fail "could not create $CACHE"
    git -C "$CACHE" init -q || fail "git init failed in $CACHE"
    git -C "$CACHE" remote add origin https://github.com/openai/codex.git || fail "git remote add failed in $CACHE"
    git -C "$CACHE" fetch -q --depth 1 --filter=blob:none origin "$PIN" \
      || fail "could not fetch openai/codex at $PIN (no network, or the pinned sha is gone)"
    git -C "$CACHE" checkout -q FETCH_HEAD -- "$UPSTREAM_DIR/validate_plugin.py" "$UPSTREAM_DIR/identifier_validation.py" \
      || fail "could not check out the validator's two files at $PIN"
  fi
  VALIDATOR="$VDIR/validate_plugin.py"
fi
for f in "${!WANT[@]}"; do
  [ -f "$VDIR/$f" ] || fail "$f is missing beside $VALIDATOR; the validator is two files"
  got="$(sha256sum "$VDIR/$f")" || fail "could not hash $VDIR/$f"
  [ "${got%% *}" = "${WANT[$f]}" ] \
    || fail "$f at $VDIR is not openai/codex@${PIN:0:7}'s; re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a pinned copy"
done

# The exceptions, derived: one bullet per skill whose Codex policy file sets
# allow_implicit_invocation: false.
known="$(for y in "$REPO_ROOT"/plugins/*/skills/*/agents/openai.yaml; do
  grep -qx '  allow_implicit_invocation: false' "$y" || continue
  s="$(basename "$(dirname "$(dirname "$y")")")"
  printf -- '- skill `%s` frontmatter field `disable-model-invocation` must be false\n' "$s"
done)"

found=0
for p in "$REPO_ROOT"/plugins/*/; do
  [ -f "$p/.codex-plugin/plugin.json" ] || fail "$p has no .codex-plugin/plugin.json"
  if ! out="$(python3 "$VALIDATOR" "$p" 2>&1)"; then
    # A non-zero exit with no `- ` bullet at all -- a traceback, a missing
    # dependency, a message-format change -- is not a recorded exception and
    # must fail loudly rather than fall through the filter below.
    printf '%s\n' "$out" | grep -q '^- ' || fail "Codex validator failed on $p with no bullets:
$out"
    # -f with a process substitution, not -e: more than one pattern, each
    # beginning with a dash. `|| true` because the inverting grep exits 1
    # when every bullet is a known one, the case that must pass.
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -f <(printf '%s\n' "$known") || true)"
    [ -z "$others" ] || fail "Codex validator rejected $p:
$others"
  fi
  found=$((found + 1))
done
[ "$found" -gt 0 ] || fail "no plugins under plugins/"
printf 'codex-validate: %s plugin(s) validated against openai/codex@%s; %s gated skill(s) excepted\n' \
  "$found" "${PIN:0:7}" "$(printf '%s\n' "$known" | grep -c .)"
```

Red first for the derivation: drop the `allow_implicit_invocation: false` line from `plugins/sensemaking/skills/adhd/agents/openai.yaml` in the working tree; the test must fail on adhd's bullet as an unknown one. Revert.

Run: `bash tests/test-codex-validate.sh` (with `CODEX_PLUGIN_VALIDATOR` unset, so the fetch runs)
Expected: PASS; a second run reuses the cache and finishes in under a second.

- [ ] **Step 2: The runner loses the probe**

In `tests/run.sh`, delete the `codex-validator)` case (three lines) from `probe()`. In the header comment, change `` `# needs: claude` or `# needs: python3 pyyaml codex-validator` `` to `` `# needs: claude` or `# needs: python3 pyyaml` ``. In `probe()`'s comment, change `the other four are probed by presence` to `the other three are probed by presence`.

Run: `bash tests/test-runner.sh`
Expected: PASS.

- [ ] **Step 3: CI stops fetching the validator**

In `.github/workflows/validate.yml`, replace the whole `- name: Fetch the Codex plugin validator` step and its comment with:

```yaml
      # tests/test-codex-validate.sh fetches its own pinned validator from
      # openai/codex (Q69); it still needs pyyaml.
      - name: Install pyyaml
        run: pip install pyyaml==6.0.3
```

- [ ] **Step 4: The README's Checks sentence**

In `README.md`, under `## Checks`, replace the sentence from `The Codex manifest check needs` to `named by` `` `CODEX_PLUGIN_VALIDATOR`. `` with:

```text
The Codex manifest check needs `python3` with `pyyaml` and fetches Codex's
validator from GitHub at a pinned commit, as the pin and drift checks fetch
their upstreams; offline, they fail rather than skip.
```

and delete the sentence that follows it, `The pin and drift checks fetch from GitHub; offline, they fail rather than skip.`, which the new one absorbs.

- [ ] **Step 5: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: `tests/test-codex-validate.sh` PASS rather than skipped; the rest as before. Cite `tests/results.tsv`.

```bash
git add tests/test-codex-validate.sh tests/run.sh .github/workflows/validate.yml README.md
git commit -m "Fetch the Codex validator at its pin inside the test, and derive its gated-skill exceptions"
```

### Task 4: The two forks leave the drift exclusion (§8, constraint 2; Q81, Q30, Q31, T9, T32, Q37)

**Files:**

- Rename: `plugins/software-dev/skills/setup-repository/` to the directory `setup-matt-pocock-skills` beside it (every file moves)
- Modify: the fork's `SKILL.md`, `agents/openai.yaml`, `domain.md`, `issue-tracker-local.md` (content), `issue-tracker-gitlab.md` (formatting only)
- Modify: `plugins/software-dev/skills/finding-duplicate-functions/scripts/categorize-prompt.md`, `scripts/find-duplicates-prompt.md`
- Delete: `tests/test-vendored-scaffolder.sh`, `tests/test-vendored-duplicates.sh`
- Modify: `tests/lib.sh` (two `GUARDED` rows), `.gitignore`, `.prettierrc.yaml`, `cspell.config.yaml`, `plugins/software-dev/README.md`, `AGENTS.md`

**Interfaces:**

- Produces: the fork directory name `setup-matt-pocock-skills`, which Task 7's record, Task 8's LICENSE section and plan B's entry exclusion name; the fork's frontmatter `name: setup-matt-pocock-skills` and display name `Setup Matt Pocock Skills`.
- Consumes: Task 3's derived exceptions in `tests/test-codex-validate.sh`, which follow the rename without an edit.

- [ ] **Step 1: Rename the fork and its names**

```bash
cd /home/eranr/agent-plugins
git mv plugins/software-dev/skills/setup-repository plugins/software-dev/skills/setup-matt-pocock-skills
```

In the moved `SKILL.md`: line 2 becomes `name: setup-matt-pocock-skills`; the title `# Setup Repository` becomes `# Setup Matt Pocock Skills`. In its `agents/openai.yaml`, the `display_name` value `Setup Repository` becomes `Setup Matt Pocock Skills`. The description stays ours: the fork is first-party (§11.2).

Run: `bash tests/test-codex-validate.sh`
Expected: PASS: the derived exception follows the directory name.

- [ ] **Step 2: Delete the two drift tests and their rows**

```bash
git rm -q tests/test-vendored-scaffolder.sh tests/test-vendored-duplicates.sh
```

In `tests/lib.sh`'s `GUARDED` array, delete the two rows:

```bash
  $'^plugins/software-dev/skills/setup-repository/\ttests/test-vendored-scaffolder.sh'
  $'^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\\.md$\ttests/test-vendored-duplicates.sh'
```

Run: `bash tests/test-ownership.sh`
Expected: PASS with four rows.

- [ ] **Step 3: See the linters go red on the forks**

Run: `bash tests/test-format-prettier.sh; bash tests/test-lint-markdown.sh; bash tests/test-spelling.sh; bash tests/test-links-resolve.sh`
Expected: each FAIL, naming the fork files: prettier on the scaffolder's `SKILL.md` and `find-duplicates-prompt.md`; markdownlint's MD040, MD031, MD029 and MD032 findings; cspell's `glab`, `unlabel`, `Summarise`; the reference check's `./extract-functions.sh src/ -o catalog.json`, `.scratch/` and `src/` lines.

- [ ] **Step 4: The mechanical fixes**

Spelling: add `glab` and `unlabel` to `cspell.config.yaml`'s word list, in alphabetical order; in the scaffolder's `SKILL.md`, `Summarise what's present` becomes `Summarize what's present`.

The reference check (T9): in the scaffolder's `SKILL.md`, the three spans `` `.scratch/` `` (two of them) and `` `src/` `` lose their trailing slash, as does `` `.scratch/` `` in `issue-tracker-local.md`'s opening line; the four name directories of the repository being scaffolded, not this one. `docs/adr/` stays declared absent.

The reference check (T32): in `categorize-prompt.md`'s `## Usage`, the line

```text
1. Run extraction: `./extract-functions.sh src/ -o catalog.json`
```

becomes

```text
1. Run extraction: `python3 ./extract-functions.py <SOURCE_DIR> -o catalog.json`
```

The relative path resolves at the prompt's own directory, where the fork ships the script; `<SOURCE_DIR>` is a placeholder by shape.

Markdownlint: in the scaffolder's `domain.md`, both bare ` ``` ` fences that open a tree diagram become ` ```text `; in `categorize-prompt.md`, the fence that opens the prompt template becomes ` ```text `; in `find-duplicates-prompt.md`, the fence that opens the prompt template becomes ` ```text `, and its `## Usage` list, whose fenced `jq` command splits the numbered list, becomes:

````markdown
## Usage

1. First run categorization (see categorize-prompt.md)
2. Filter categorized.json to get functions for one category, with the `jq` command below
3. Replace `{CATEGORY}` with the category name
4. Replace `<INSERT_CATEGORY_FUNCTIONS_HERE>` with the filtered JSON
5. Dispatch opus subagent with the prompt
6. Repeat for each category with 3+ functions
7. Combine outputs into final report

The filter for one category:

```bash
jq '[.[] | select(.category == "validation")]' categorized.json > validation-functions.json
```
````

Then `bash scripts/format`, which writes prettier's own changes (a blank line after the scaffolder's frontmatter; the prompt template's fences may become four backticks where prettier reads a fence inside them).

Run: `bash tests/test-format-prettier.sh && bash tests/test-lint-markdown.sh && bash tests/test-spelling.sh && bash tests/test-links-resolve.sh && bash tests/test-vocabulary.sh`
Expected: all PASS.

- [ ] **Step 5: #23's three defects (Q30, Q31)**

In the scaffolder's `SKILL.md`:

Defect 1, the six clauses that make Section B or its file conditional on `triage` being installed, each deleted or reworded so Section B always runs. Each pair below is the text as it stands, then the text that replaces it:

```text
(Section B when `triage` isn't installed, Section C when there's no monorepo)
(Section C when there's no monorepo)
```

```text
**Section B — Triage label vocabulary.** Skip this section entirely if the `triage` skill isn't installed (exploration told you) — an uninstalled skill needs no labels.
**Section B — Triage label vocabulary.** Section B always runs.
```

```text
If it is installed, ask exactly one question:
Ask exactly one question:
```

```text
and `docs/agents/triage-labels.md` (the last only when `triage` is installed)
and `docs/agents/triage-labels.md`
```

```text
Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when `triage` is installed and Section B ran. When it isn't, both are omitted. Omit `### Task reports` only when Section A recorded no tracker, since the rule points at one.
Omit `### Task reports` only when Section A recorded no tracker, since the rule points at one.
```

```text
- [triage-labels.md](./triage-labels.md) — label mapping (only if `triage` is installed)
- [triage-labels.md](./triage-labels.md) — label mapping
```

Defect 2: hard-wrap the `### Design discipline` paragraph in the block, and the same paragraph in `AGENTS.md`, so the two stay byte-identical and an agent told to write it verbatim has no long line to rewrap. Both become:

```markdown
### Design discipline

Eliminate the problem > add a mechanism > add a rule; prose is the last resort.

Climb from the top and stop at the first rung that holds. A rule nobody can
enforce is the weakest thing you can ship, and it goes stale silently. When
prose really is the last resort, **say which higher rungs you tried and why
they were unavailable** — an unexplained rule is indistinguishable from a lazy
one, and the next reader cannot tell whether to re-attempt the climb.
```

Defect 3: after the sentence that begins `Write` and tells the agent to write the Design discipline and Task reports sections verbatim, add:

```markdown
A rule the file already states outside the block is not written into it again.
This stays prose because the skill cannot know what counts as an equivalent
statement, so no check can hold it.
```

Run: `bash scripts/format && bash tests/run.sh`
Expected: green but for skips.

- [ ] **Step 6: Comments and sentences that named the two tests**

`.gitignore`: the comment `# __pycache__ or ruff cache under it breaks tests/test-vendored-duplicates.sh,` and its next line `# which asserts an exact file set against upstream.` become `# __pycache__ or ruff cache under it would be an untracked file in a tracked` and `# tree, which the reference check and the formatters would then read.`

`.prettierrc.yaml`: replace both comments. The first, above `proseWrap: preserve`:

```yaml
# The block the scaffolder setup-matt-pocock-skills writes and the two
# sections of AGENTS.md it copies are kept in step by hand (#21); a rewrap of
# one would make the next hand-sync a diff of line breaks.
```

The second, above `embeddedLanguageFormatting`:

```yaml
# Fenced blocks quote other files verbatim -- the AGENTS.md block in the
# scaffolder, the README's install blocks that the install job runs as
# written -- and quoted material must not be restyled by the document quoting
# it. Quoted: a bare `off` is YAML for false.
```

`plugins/software-dev/README.md`: the `skills/setup-repository/` bullet becomes:

```markdown
- `skills/setup-matt-pocock-skills/`: a fork of mattpocock/skills' repository
  scaffolder, first-party since the fork. It writes the `## Agent skills`
  block to `AGENTS.md` and leaves `CLAUDE.md` as a one-line `@AGENTS.md`
  import, so Codex reads the same rules Claude does; it asks which git
  convention the repo uses; and the block it writes carries that convention,
  the design ladder, and the task-reports rule. User-invocable only.
```

and the `skills/finding-duplicate-functions/` bullet loses `; only its two prompt templates are upstream's, and the drift test holds them there`, ending at the sentence that says its `PROVENANCE.md` records what changed (the file goes in Task 8). The `## License` paragraph's `skills/setup-repository/` becomes `skills/setup-matt-pocock-skills/`.

- [ ] **Step 7: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips; cite `tests/results.tsv`.

```bash
git add -A plugins/software-dev/skills/setup-matt-pocock-skills plugins/software-dev/skills/finding-duplicate-functions tests/lib.sh .gitignore .prettierrc.yaml cspell.config.yaml plugins/software-dev/README.md AGENTS.md
git commit -m "Fork the scaffolder under upstream's name and lint both forks: nothing holds a fork to upstream"
```

### Task 5: The `brainstorming` copy and the hook leave (Q78, constraint 3; Q86, T47's carve-out)

**Files:**

- Delete: `plugins/software-dev/skills/brainstorming/` (seven files), `plugins/software-dev/hooks/` (four files), `tests/test-hook.sh`, `tests/test-vendored-brainstorming.sh`, `scripts/bump-superpowers`
- Modify: `plugins/software-dev/.claude-plugin/plugin.json`, `plugins/software-dev/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json` (descriptions; the `hooks` key)
- Modify: `plugins/software-dev/LICENSE` (the `brainstorming` section)
- Modify: `tests/lib.sh` (two `GUARDED` rows; `checked_shell`'s comment), `tests/test-plugin-skills.sh`, `tests/test-links-resolve.sh` (`DECLARED_ABSENT`)
- Modify: `plugins/sensemaking/skills/rethink-audit/SKILL.md` (one token)
- Modify: `.gitignore`, `cspell.config.yaml`, `plugins/software-dev/README.md`, `README.md`, `AGENTS.md`

**Interfaces:**

- Produces: `tests/test-plugin-skills.sh` skips `superpowers:` tokens, with a comment naming `install-check.sh` as their holder; `rethink-audit` names `superpowers:brainstorming`.
- Consumes: nothing new.

- [ ] **Step 1: Delete the copy, the hook, their tests and the bump script**

```bash
cd /home/eranr/agent-plugins
git rm -rq plugins/software-dev/skills/brainstorming plugins/software-dev/hooks
git rm -q tests/test-hook.sh tests/test-vendored-brainstorming.sh scripts/bump-superpowers
```

- [ ] **Step 2: The manifests and the marketplace entry**

`plugins/software-dev/.claude-plugin/plugin.json`: delete the `"hooks": "./hooks/claude-hooks.json"` line and the comma that ended the `dependencies` array's closing bracket; the description becomes `The repository scaffolder, the consistency audit and its inspector, diagnosing-bugs and finding-duplicate-functions, for Claude Code and Codex.`

`plugins/software-dev/.codex-plugin/plugin.json`: the description becomes `The repository scaffolder, the consistency audit, diagnosing-bugs and finding-duplicate-functions, for Claude Code and Codex.`; `longDescription` becomes `The repository scaffolder for mattpocock's engineering skills, a refuted-before-reported consistency audit, a reproduction-first debugging loop, and a Python duplicate-function finder.`; `defaultPrompt` becomes `["Set up this repository for the engineering skills.", "Audit this repository for inconsistencies."]`.

`.claude-plugin/marketplace.json`: `software-dev`'s description becomes `The repository scaffolder, the consistency audit and its inspector, diagnosing-bugs and finding-duplicate-functions.`

Run: `bash tests/test-references-resolve.sh && bash tests/test-json-wellformed.sh`
Expected: PASS.

- [ ] **Step 3: The LICENSE, the exclusion rows, the carve-out**

`plugins/software-dev/LICENSE`: delete the `brainstorming` section, from the line of dashes before `skills/brainstorming/ is vendored from https://github.com/obra/superpowers` through the `SOFTWARE.` that closes its MIT text, keeping the line of dashes that opens the next section.

`tests/lib.sh`: delete the rows `$'^plugins/software-dev/skills/brainstorming/\ttests/test-vendored-brainstorming.sh'` and `$'^plugins/software-dev/hooks/using-superpowers\\.md$\ttests/test-hook.sh'` from `GUARDED`; in `checked_shell`'s comment, `the two commands under bin/, the three scripts and the hook have none` becomes `the two commands under bin/ and the two scripts have none`.

`tests/test-plugin-skills.sh`: delete the three lines from `# rethink-audit: the one repointed reference.` through `grep -q 'software-dev:brainstorming' "$RA" || ...`, and the `subset="$(jq ... superpowers ...)"` line. Replace the `superpowers)` case with:

```bash
      superpowers)
        # Carved out (Q87, T47): no entry here lists obra's skills. tests/install-check.sh
        # asserts each superpowers: token against the superpowers the README's blocks install.
        ;;
```

Replace the header's bullet `#   - every <plugin>:<skill> reference in a SKILL.md resolves ...` through `#     subset entry excludes);` with:

```bash
#   - every <plugin>:<skill> reference in a SKILL.md resolves to something an
#     install gets; superpowers: tokens are carved out for the install job;
```

(Task 6 rewrites this test whole.)

`plugins/sensemaking/skills/rethink-audit/SKILL.md`, in `## Boundaries`: `software-dev:brainstorming` becomes `superpowers:brainstorming`. Nothing else in the file changes (Q86: one dead pointer, inside the hold).

`tests/test-links-resolve.sh`: delete the `'hooks/hooks.json'` entry from `DECLARED_ABSENT`; its last reader goes in Step 4.

Run: `bash tests/test-plugin-skills.sh && bash tests/test-ownership.sh`
Expected: PASS (the ownership test with two rows).

- [ ] **Step 4: Sentences and comments that named them**

`.gitignore`: the comment above `/.worktrees/` becomes:

```text
# The two directories superpowers' finishing-a-development-branch recognizes
# as its own, and Kilo's worktree directory, named by the suite-and-ci spec.
# None is ever tracked, and the reference check classifies a path by the file
# that ignores it.
```

`cspell.config.yaml`: delete the override filename `"plugins/software-dev/hooks/session-start"`.

`AGENTS.md`, `### Security scanning`: the last sentence becomes:

```text
This repository ships `bin/setup` and the scripts the skills run, so run a scan yourself on a diff that touches `bin/`, `scripts/`, or a workflow.
```

`README.md`: in `## What it ships`, `its README names every skill, hook and agent it ships` becomes `its README names every skill and agent it ships`; in `## Layout`, the `scripts/` line becomes `scripts/           what CI and the maintainer run: the upstream watch and the formatter`.

`plugins/software-dev/README.md`: the opening paragraph becomes:

```text
Eran Roseman's glue plugin for software development. It carries a fork of
mattpocock/skills' repository scaffolder, a copy of its debugging loop, a
rewritten fork of obra/superpowers-lab's duplicate finder, and a first-party
audit with its agent, each with its provenance below.
```

Delete the `skills/brainstorming/` bullet and the `hooks/session-start` bullet; delete the paragraph that begins `Codex gets the skills and no hook, by design.` through its end at `manifest order.`; under `## Environment`, delete the opening two sentences (`Nothing here needs configuring to work.` and the one after it) and the four paragraphs on the Visual Companion and the telemetry variable, from `The brainstorming skill's Visual Companion` through `If you never accept it, the request never happens.`; in the `archify` paragraph, the phrase `in the same place as the telemetry variable above` becomes:

```text
in the `env` map of `~/.claude/settings.json` on Claude Code, or in `~/.profile` on Codex
```

In `## License`, delete the sentence on the vendored `skills/brainstorming/` being MIT, © 2025 Jesse Vincent, so the paragraph opens `MIT.` and then names `skills/setup-matt-pocock-skills/` and `skills/diagnosing-bugs/` as MIT, © 2026 Matt Pocock.

- [ ] **Step 5: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green but for skips; the links check passes with `hooks/hooks.json` no longer declared. Cite `tests/results.tsv`.

```bash
git add -A plugins/software-dev plugins/sensemaking/skills/rethink-audit/SKILL.md .claude-plugin/marketplace.json tests/lib.sh tests/test-plugin-skills.sh tests/test-links-resolve.sh .gitignore cspell.config.yaml README.md AGENTS.md
git commit -m "Drop the brainstorming copy and the SessionStart hook: upstream's come with obra's superpowers"
```

### Task 6: The widened reference scan and the new static checks (§10.2, §15.3; Q66, T47)

**Files:**

- Modify: `tests/lib.sh` (new helpers `entry_rows`, `entry_skills`, `shipped_texts`, `skill_name_matches`)
- Modify: `tests/test-plugin-skills.sh` (rewritten whole)

**Interfaces:**

- Produces: `entry_rows`, `entry_skills <name>`, `shipped_texts`, `skill_name_matches <dir> [label]` in `tests/lib.sh`, with the shapes the name table gives; `tests/test-plugin-skills.sh`'s exception list `EXCEPTIONS`.
- Consumes: nothing new.

- [ ] **Step 1: The helpers**

Append to `tests/lib.sh`, before the `# ---- Ownership` section:

```bash
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
# superpowers: references (T47). Tracked, not present, like checked().
shipped_texts() {
  git -C "$REPO_ROOT" ls-files 'plugins/*/skills/**/*.md' 'plugins/*/agents/*.md' 'plugins/*/skills/*/agents/openai.yaml'
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
```

- [ ] **Step 2: Rewrite the scan, red first by its permanent negative fixture**

Replace `tests/test-plugin-skills.sh` whole:

```bash
#!/usr/bin/env bash
# What the marketplace delivers, held statically (spec §10.2, §15.3):
#   - every qualified reference <p>:<s> in a shipped text resolves to a skill
#     or agent a marketplace entry delivers: the local plugin's skills/<s> or
#     agents/<s>.md, or a subset entry's listed skill; any other prefix fails.
#     A token after / is the tail of the house owner/repo:path form and one
#     after // a URL authority; both are skipped by shape. superpowers: tokens
#     are carved out: no entry here lists obra's skills, and
#     tests/install-check.sh asserts each against the superpowers the README's
#     blocks install (Q87, T47). The idioms left are in EXCEPTIONS below, one
#     comment each; an exception whose prefix is a marketplace entry fails, so
#     a dead reference with a known prefix can never be exempted, and one that
#     matches no token fails, so the list cannot rot;
#   - a permanent negative fixture: the same scan over a scratch copy carrying
#     nosuch:thing and software-dev:no-such-skill fails on both, by file, line
#     and token;
#   - every local skill's frontmatter name equals its directory, and every
#     local agent's its file stem;
#   - no skill name appears twice across the local plugins' skill directories
#     and the entries' listed skills: a bare call on Claude Code reaches one
#     skill only while its name is unique;
#   - every scripts/<file> a SKILL.md names ships under that skill;
#   - a user-invocable-only skill carries both gates, Claude's frontmatter
#     field and Codex's policy file, never one without the other;
#   - no shipped text names a local agent bare in backticks: the Agent tool
#     accepts only <plugin>:<name> (measured 2026-09-06).
# Needs no network.
. "$(dirname "$0")/lib.sh"

EXCEPTIONS=(
  'file:line'     # a report card's location field, in consistency-audit and finding-duplicate-functions
  'bug:triage'    # the scaffolder's example of a tracker's own label name
  'wayfinder:map' # the wayfinder label in the scaffolder's tracker templates
)

local_plugins="$(jq -r '.plugins[] | select(.source | type == "string") | .name' "$MARKETPLACE")"
[ -n "$local_plugins" ] || fail "no local plugin in $MARKETPLACE"
entries="$(entry_rows | cut -f1)"

# True when a marketplace entry delivers $2 under the prefix $1.
delivers() {
  local p="$1" s="$2"
  if grep -qxF -- "$p" <<<"$local_plugins"; then
    [ -f "$REPO_ROOT/plugins/$p/skills/$s/SKILL.md" ] || [ -f "$REPO_ROOT/plugins/$p/agents/$s.md" ]
  elif grep -qxF -- "$p" <<<"$entries"; then
    entry_skills "$p" | grep -qxF -- "$s"
  else
    return 1
  fi
}

# The scan over the shipped texts under the root $1. Sets SCANNED, RESOLVED,
# SKIPPED (superpowers: tokens), EXCEPTED, USED (the exceptions matched) and
# FAILURES, one line each.
scan() {
  local root="$1" f n raw tok p s
  SCANNED=0 RESOLVED=0 SKIPPED=0 EXCEPTED=0 USED="" FAILURES=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$root/$f" ] || fail "$f is tracked but absent under $root"
    SCANNED=$((SCANNED + 1))
    while IFS=: read -r n raw; do
      [ -n "$raw" ] || continue
      tok="$(sed -E 's#^[^a-z/]+##' <<<"$raw")"
      case "$tok" in /*) continue ;; esac # owner/repo:path or a URL authority
      p="${tok%%:*}"
      s="${tok#*:}"
      if [ "$p" = superpowers ]; then
        SKIPPED=$((SKIPPED + 1)) # held by tests/install-check.sh (T47)
        continue
      fi
      if printf '%s\n' "${EXCEPTIONS[@]}" | grep -qxF -- "$tok"; then
        EXCEPTED=$((EXCEPTED + 1))
        USED="$USED $tok"
        continue
      fi
      if delivers "$p" "$s"; then
        RESOLVED=$((RESOLVED + 1))
      else
        FAILURES="$FAILURES"$'\n'"$f:$n: $tok names nothing a marketplace entry delivers"
      fi
    done < <(grep -noE '(^|[^A-Za-z0-9_-])/{0,2}[a-z][a-z0-9-]*:[a-z][a-z0-9-]*' "$root/$f" || true)
  done < <(shipped_texts)
}

# The exceptions' own shape: no marketplace prefix.
for e in "${EXCEPTIONS[@]}"; do
  p="${e%%:*}"
  if grep -qxF -- "$p" <<<"$local_plugins" || grep -qxF -- "$p" <<<"$entries"; then
    fail "the exception $e carries a marketplace entry's prefix; a dead reference cannot be exempted"
  fi
done

scan "$REPO_ROOT"
[ -z "$FAILURES" ] || fail "these references resolve to nothing an install delivers:$FAILURES"
for e in "${EXCEPTIONS[@]}"; do
  case " $USED " in *" $e "*) ;; *) fail "the exception $e matches no token; drop it" ;; esac
done
scanned="$SCANNED" resolved="$RESOLVED" skipped="$SKIPPED" excepted="$EXCEPTED"

# The permanent negative fixture: a scratch copy of the shipped texts, two
# dead references injected, both caught by file, line and token.
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT
while IFS= read -r f; do
  mkdir -p "$T/$(dirname "$f")" && cp "$REPO_ROOT/$f" "$T/$f" || fail "could not copy $f into the fixture"
done < <(shipped_texts)
first="$(shipped_texts | grep '/SKILL.md$' | head -n 1)"
printf '\nSee nosuch:thing and software-dev:no-such-skill.\n' >>"$T/$first" || fail "could not inject the dead references"
line="$(grep -c . "$T/$first")"
scan "$T"
grep -qF -- "$first:$line: nosuch:thing names nothing" <<<"$FAILURES" \
  || fail "the scan did not fail on nosuch:thing by file, line and token:"$'\n'"$FAILURES"
grep -qF -- "$first:$line: software-dev:no-such-skill names nothing" <<<"$FAILURES" \
  || fail "the scan did not fail on software-dev:no-such-skill by file, line and token:"$'\n'"$FAILURES"

# Names: each local skill's frontmatter name is its directory, each agent's
# its stem; no skill name twice across the plugins and the entries.
names=""
checked=0
for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
  skill="${skill%/}"
  plugin="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$skill")"
  skill_name_matches "$skill" "$plugin:$name"
  names="$names"$'\n'"$name"
  checked=$((checked + 1))
  # Gates travel as a pair.
  claude_gate=false
  codex_gate=false
  grep -qx 'disable-model-invocation: true' "$skill/SKILL.md" && claude_gate=true
  [ -f "$skill/agents/openai.yaml" ] && grep -qx '  allow_implicit_invocation: false' "$skill/agents/openai.yaml" && codex_gate=true
  [ "$claude_gate" = "$codex_gate" ] \
    || fail "$plugin:$name is user-invocable only on one agent CLI (Claude $claude_gate, Codex $codex_gate); each such skill carries both gates"
  # Every scripts/<file> the SKILL.md names ships under the skill.
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    tok="${tok%.}"
    [ -e "$skill/$tok" ] || fail "$plugin:$name names $tok, which the skill does not ship"
  done < <(grep -oE 'scripts/[A-Za-z0-9_.-]+' "$skill/SKILL.md" | sort -u)
done
[ "$checked" -ge 1 ] || fail "no local skill under plugins/*/skills"
agents=""
for ag in "$REPO_ROOT"/plugins/*/agents/*.md; do
  [ -f "$ag" ] || continue
  stem="$(basename "$ag" .md)"
  [ "$(sed -n 2p "$ag")" = "name: $stem" ] || fail "$ag: line 2 is not 'name: $stem'"
  agents="$agents"$'\n'"$stem"
done
while IFS= read -r e; do
  [ -n "$e" ] || continue
  names="$names"$'\n'"$(entry_skills "$e")"
done <<<"$entries"
dup="$(printf '%s\n' "$names" | grep . | sort | uniq -d)"
[ -z "$dup" ] || fail "a skill name is delivered twice, by a local plugin or a subset entry; a bare call on Claude Code needs it unique: $dup"

# A bare agent name in a shipped text.
while IFS= read -r stem; do
  [ -n "$stem" ] || continue
  bare="$(shipped_texts | while IFS= read -r f; do grep -nF -- "\`$stem\`" "$REPO_ROOT/$f" | sed "s#^#$f:#"; done || true)"
  [ -z "$bare" ] || fail "a shipped text names the agent $stem bare; the Agent tool accepts only <plugin>:$stem:"$'\n'"$bare"
done <<<"$agents"

printf 'plugin-skills: %s file(s) scanned, %s reference(s) resolve, %s superpowers: token(s) left to the install job, %s exception(s) used; %s skill(s) named, gated and shipped whole\n' \
  "$scanned" "$resolved" "$skipped" "$excepted" "$checked"
```

Run: `bash tests/test-plugin-skills.sh`
Expected: PASS. The negative fixture is the permanent red case; it is exercised every run.

- [ ] **Step 3: The mutations (T31)**

Each in the working tree, each reverted after its run of `bash tests/test-plugin-skills.sh`:

1. Bare agent name: append `` `consistency-audit-inspector` `` to `plugins/software-dev/skills/consistency-audit/SKILL.md`. Expected FAIL naming the file and line.
2. Name helper: change `name: adhd` to `name: adhd-x` in `plugins/sensemaking/skills/adhd/SKILL.md`. Expected FAIL `sensemaking:adhd: frontmatter name 'adhd-x' ...`.
3. Uniqueness: `mkdir -p plugins/software-dev/skills/writing-clearly-and-concisely && printf -- '---\nname: writing-clearly-and-concisely\n---\n' > plugins/software-dev/skills/writing-clearly-and-concisely/SKILL.md`. Expected FAIL `a skill name is delivered twice ... writing-clearly-and-concisely`. Remove the directory.
4. Named scripts: `git mv plugins/software-dev/skills/finding-duplicate-functions/scripts/cluster.py plugins/software-dev/skills/finding-duplicate-functions/scripts/clusters.py`. Expected FAIL `software-dev:finding-duplicate-functions names scripts/cluster.py, which the skill does not ship`. Move it back.
5. Exceptions: add `'software-dev:nothing'` to `EXCEPTIONS`. Expected FAIL `carries a marketplace entry's prefix`. Add `'nosuch:idiom'` instead. Expected FAIL `matches no token`. Revert.

- [ ] **Step 4: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips; cite `tests/results.tsv`.

```bash
git add tests/lib.sh tests/test-plugin-skills.sh
git commit -m "Resolve every qualified skill reference through the marketplace, and hold names, gates and shipped scripts"
```

### Task 7: The records (§7.2, constraint 4; Q39, Q62, Q12, T7, T23, T24, T40)

**Files:**

- Modify: `vendored.json` (rewritten whole)
- Modify: `tests/lib.sh` (`VENDORED_JSON`; `upstream_sha`, `upstream_ref`, `record_rows`, `record_map`, `tree_keys`, `fork_keys`; `fetch_upstream`; the ownership section; `vendored_sha`, `GUARDED`, `guarded_pattern`, `guards` go)
- Modify: `tests/test-ownership.sh` (rewritten whole)
- Modify: `tests/test-vendored-adhd.sh`, `tests/test-vendored-diagnosing-bugs.sh` (the pin's source; the `guards` line)
- Modify: `scripts/upstream-watch` (the record loop; the entries' bump advice)
- Modify: `tests/test-upstream-watch.sh` (the fixture `vendored.json`; the tag entry's URL; two assertions)
- Modify: `README.md` (the `vendored.json` line of `## Layout`)

**Interfaces:**

- Produces: `VENDORED_JSON`, `upstream_sha <owner/repo>`, `upstream_ref <owner/repo>`, `record_rows`, `record_map <trees|forks> <owner/repo>`, `tree_keys`, `fork_keys`, and `EXCLUDED` derived from the `trees` keys, all in `tests/lib.sh` with the shapes the name table gives; the records' repositories `mattpocock/skills`, `UditAkhourii/adhd`, `obra/superpowers-lab`.
- Consumes: Task 4's fork directory name; Task 6's `entry_rows`.

- [ ] **Step 1: The three records**

Replace `vendored.json` whole:

```json
{
  "$comment": "One record per upstream repository this repository copies or forks from. trees maps each copy's path here to its path upstream: upstream's bytes at the pin, held there by tests/test-upstream.sh except for the declared changes that test lists, and excluded from the linters. forks maps each fork's path here to the upstream path it began from: first-party, linted, held by nothing, its upstream watched for changes worth porting. A record carries ref and sha, or neither and takes the pin of the one subset entry in .claude-plugin/marketplace.json whose source.url is its repository. Read by tests/lib.sh and scripts/upstream-watch.",
  "records": [
    {
      "repo": "mattpocock/skills",
      "ref": "v1.2.3",
      "sha": "6acc160e4e0cd062dbbbd7a1b26ae92855edf07e",
      "trees": {
        "plugins/software-dev/skills/diagnosing-bugs": "skills/engineering/diagnosing-bugs"
      },
      "forks": {
        "plugins/software-dev/skills/setup-matt-pocock-skills": "skills/engineering/setup-matt-pocock-skills"
      }
    },
    {
      "repo": "UditAkhourii/adhd",
      "ref": "main",
      "sha": "16dc239ff186b869372e75095cfa58fc0ee89927",
      "trees": {
        "plugins/sensemaking/skills/adhd": "skills/adhd"
      },
      "forks": {}
    },
    {
      "repo": "obra/superpowers-lab",
      "ref": "main",
      "sha": "51111f74f24058117752d9aa917cb19859f8ec86",
      "trees": {},
      "forks": {
        "plugins/software-dev/skills/finding-duplicate-functions": "skills/finding-duplicate-functions"
      }
    }
  ]
}
```

The mattpocock record carries its own tag pin until plan B's entry lands (T40); the adhd key moves under `software-dev` in plan B (§5.2) and its sha to `main`'s tip then (§9, P9).

- [ ] **Step 2: The record reader and the derived exclusion**

In `tests/lib.sh`:

Add `VENDORED_JSON="$REPO_ROOT/vendored.json"` after `MARKETPLACE=...`. Delete `upstream_sha` (the superpowers-only one), its comment, `vendored_sha` and its comment. In their place, after `fail()`:

```bash
# ---- Pins: the subset entries and the records (spec §6, §7.2) ---------------
# The one git-subdir entry whose source.url is the repository $1's, as
# https://github.com/<owner>/<repo>.git: its sha, or its ref. A record without a
# pin of its own takes its pin here (T24); no match, or more than one, fails.
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
# mistake is never skipped. Every record carries trees and forks, {} when
# empty.
record_rows() {
  local repo ref sha
  jq -e '.records | type == "array" and length > 0' "$VENDORED_JSON" >/dev/null 2>&1 \
    || fail "$VENDORED_JSON carries no records array"
  jq -e '[.records[] | (.trees | type == "object") and (.forks | type == "object")] | all' "$VENDORED_JSON" >/dev/null 2>&1 \
    || fail "a record in $VENDORED_JSON lacks a trees or forks object"
  while IFS=$'\t' read -r repo ref sha; do
    [ -n "$repo" ] || continue
    if [ -z "$ref" ] && [ -z "$sha" ]; then
      ref="$(upstream_ref "$repo")"
      sha="$(upstream_sha "$repo")"
    elif [ -z "$ref" ] || [ -z "$sha" ]; then
      fail "the $repo record carries one of ref and sha without the other"
    fi
    [ "${#sha}" -eq 40 ] || fail "$repo: the pinned sha is not 40 characters: '$sha'"
    printf '%s\t%s\t%s\n' "$repo" "$ref" "$sha"
  done < <(jq -r '.records[] | [.repo, (.ref // ""), (.sha // "")] | @tsv' "$VENDORED_JSON")
}

# The pairs of the $1 map (trees or forks) of the record $2: local path, then
# upstream path, tab-separated, one per line.
record_map() {
  jq -r --arg m "$1" --arg r "$2" '.records[] | select(.repo == $r) | .[$m] | to_entries[] | [.key, .value] | @tsv' "$VENDORED_JSON"
}
# Every copy's path, and every fork's, one per line, across every record.
tree_keys() { jq -r '.records[].trees | keys[]' "$VENDORED_JSON"; }
fork_keys() { jq -r '.records[].forks | keys[]' "$VENDORED_JSON"; }
```

In `fetch_upstream`, replace the two lines `sha="$(upstream_sha)" || fail "could not read the pinned sha from $MARKETPLACE"` and `[ "${#sha}" -eq 40 ] || fail ...` with `sha="$(upstream_sha obra/superpowers)"`; its comment stays. (Plan B deletes it with its one caller.)

Replace the whole `# ---- Ownership` section from its comment through the closing `}` of `guards()` with:

```bash
# ---- Ownership (spec §7.2, Q62) ---------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: a copy, a tree in a record's `trees` map, which is
# upstream's bytes at the pin and is held there by tests/test-upstream.sh. A
# fork is first-party and is linted. The exclusion is derived from
# vendored.json, so a copy that leaves the records joins the linters the same
# moment, and tests/test-ownership.sh holds the derivation: every trees key a
# tracked directory checked() does not list, every forks key one it lists.
EXCLUDED="$(jq -r '[.records[].trees | keys[]] | map("^" + . + "/") | join("|")' "$REPO_ROOT/vendored.json")" \
  || { printf 'FAIL: could not derive the excluded trees from vendored.json\n' >&2; exit 1; }
[ -n "$EXCLUDED" ] || EXCLUDED='^$'
```

`checked()` and everything after it stay.

- [ ] **Step 3: The ownership test holds the derivation (T23)**

Replace `tests/test-ownership.sh` whole:

```bash
#!/usr/bin/env bash
# The ownership derivation stays honest (spec §7.2, T23). The excluded files
# are the records' copies and nothing else: every `trees` key in vendored.json
# is a tracked directory that checked() does not list, and every `forks` key
# a tracked path that checked() lists, so a misspelled key fails rather than
# leaving a copy linted or a fork unlinted. The checked list is non-empty, no
# checked path carries whitespace, a glob character, or a quoted path, which
# is what lets the tool tests expand `$(checked ...)` unquoted, one path per
# word, and every checked file that opens with a bash shebang is one
# checked_shell() lists. Needs no network.
. "$(dirname "$0")/lib.sh"

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"

n_trees=0
while IFS= read -r key; do
  [ -n "$key" ] || continue
  files="$(git -C "$REPO_ROOT" ls-files -- "$key" | grep . || true)"
  [ -n "$files" ] || fail "the trees key $key in vendored.json is not a tracked directory"
  listed="$(grep -xF -f <(printf '%s\n' "$files") <<<"$list" || true)"
  [ -z "$listed" ] || fail "checked() lists files of the copy $key; EXCLUDED is not derived from vendored.json:"$'\n'"$listed"
  n_trees=$((n_trees + 1))
done < <(tree_keys)
[ "$n_trees" -gt 0 ] || fail "vendored.json declares no copy; the derivation went vacuous"
n_forks=0
while IFS= read -r key; do
  [ -n "$key" ] || continue
  files="$(git -C "$REPO_ROOT" ls-files -- "$key" | grep . || true)"
  [ -n "$files" ] || fail "the forks key $key in vendored.json is not a tracked path"
  missing="$(grep -vxF -f <(printf '%s\n' "$list") <<<"$files" || true)"
  [ -z "$missing" ] || fail "the fork $key has files checked() does not list; a fork is linted:"$'\n'"$missing"
  n_forks=$((n_forks + 1))
done < <(fork_keys)

odd="$(grep '[[:space:]*?[\\"]' <<<"$list" || true)"
[ -z "$odd" ] \
  || fail "a tracked path carries whitespace, a glob character, or a quoted path; the tool tests expand the list unquoted:"$'\n'"$odd"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
grep -qx 'bin/setup' <<<"$shell" || fail "checked_shell() does not list bin/setup, a shell file with no extension"
# The floor under that pin, derived rather than enumerated: every checked file
# whose first line names bash must be in checked_shell, so a shell file cannot
# leave the shell checkers' scope on one character. checked_shell's
# exact-shebang rule stands: this says what joining it costs, it does not
# relax it.
missing=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$(head -n 1 "$REPO_ROOT/$f")" in
    '#!'*bash*)
      grep -qxF -- "$f" <<<"$shell" || missing="$missing $f"
      ;;
  esac
done < <(printf '%s\n' "$list")
[ -z "$missing" ] \
  || fail "these checked file(s) open with a bash shebang and checked_shell() does not list them:$missing"$'\n'"their first line must be exactly '#!/usr/bin/env bash', or they leave shellcheck, shfmt and cspell unnoticed"

printf 'ownership: %s cop(y|ies) excluded, %s fork(s) linted; %s checked file(s), %s of them shell\n' \
  "$n_trees" "$n_forks" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
```

Red first: in the working tree, misspell the adhd key in `vendored.json` as `plugins/sensemaking/skills/adhdd`. Expected FAIL `is not a tracked directory`. Revert.

Run: `bash tests/test-ownership.sh`
Expected: PASS with two copies and two forks.

- [ ] **Step 4: The two drift tests read the records**

`tests/test-vendored-adhd.sh`: delete the `guards plugins/sensemaking/skills/adhd/SKILL.md ...` line; replace `SHA="$(vendored_sha plugins/sensemaking/skills/adhd)"` with:

```bash
SHA="$(record_rows | awk -F'\t' '$1 == "UditAkhourii/adhd" { print $3 }')"
[ "${#SHA}" -eq 40 ] || fail "vendored.json declares no 40-character sha for UditAkhourii/adhd (got '$SHA')"
```

`tests/test-vendored-diagnosing-bugs.sh`: delete the `guards ...` line; replace the lines `REF="v1.2.3"` and `SHA="6acc160e4e0cd062dbbbd7a1b26ae92855edf07e" # the commit v1.2.3 peels to` with:

```bash
row="$(record_rows | awk -F'\t' '$1 == "mattpocock/skills"')"
REF="$(cut -f2 <<<"$row")"
SHA="$(cut -f3 <<<"$row")"
[ -n "$REF" ] && [ "${#SHA}" -eq 40 ] || fail "vendored.json declares no pin for mattpocock/skills"
```

Both tests still hold the headers and the LICENSE shas; Task 8 replaces them.

Run: `bash tests/test-vendored-adhd.sh && bash tests/test-vendored-diagnosing-bugs.sh` (network)
Expected: PASS.

- [ ] **Step 5: The watch's record loop**

In `scripts/upstream-watch`, replace section 1b, from `# 1b. Each vendored or forked tree` through its `report ""`, with:

```bash
# 1b. Each record of vendored.json with a pin of its own: its sha against its
# branch's tip, or its tag against the newest stable tag. A record without a
# pin takes its subset entry's and is reported on the entry's line above
# (T24). Each line names the record's copies and the upstream paths of its
# forks, whose diff a bump reads (Q36).
report "### vendored and forked trees"
report ""
record_rows="$(jq -r '.records[] | [.repo, (.ref // ""), (.sha // ""), ((.trees | keys) | join(" ")), ((.forks | to_entries | map(.value)) | join(" "))] | @tsv' "$VENDORED_JSON")" \
  || die "could not read the records from $VENDORED_JSON"
[ -n "$record_rows" ] || die "no record could be read from $VENDORED_JSON"
while IFS="$(printf '\t')" read -r repo ref sha trees forks; do
  [ -n "$repo" ] || continue
  url="https://github.com/$repo.git"
  # shellcheck disable=SC2086  # the paths are space-separated by construction and carry no whitespace
  fork_list="$(printf '`%s` ' $forks)"
  # shellcheck disable=SC2086  # as above
  tree_list="$(printf '`%s` ' $trees)"
  if [ -z "$ref" ] && [ -z "$sha" ]; then
    n="$(jq -r --arg u "$url" '[.plugins[] | select(.source.source? == "git-subdir" and .source.url == $u)] | length' "$MARKETPLACE")" \
      || die "could not read $MARKETPLACE"
    [ "$n" -eq 1 ] || die "$repo carries no pin of its own and $n subset entries pin it; exactly one must"
    report "- \`$repo\`: pinned through its subset entry above${forks:+; forks to re-read at a bump: $fork_list}"
    continue
  fi
  if [ -z "$ref" ] || [ -z "$sha" ]; then die "$repo carries one of ref and sha without the other"; fi
  compare_pin "\`$repo\`${trees:+ (copies: $tree_list)}" "$url" "$ref" "$sha" \
    "Bump by editing \`vendored.json\`: move \`ref\` and \`sha\`; re-copy each copy from the new pin, keeping its declared changes; for a copy upstream no longer has, remove it or move its path to \`forks\`; read the diff of each fork's upstream path${forks:+ ($fork_list)} and port what is worth it; then run test-upstream.sh. Bump the version of each plugin whose shipped files moved: Claude Code updates only on a version change."
done <<<"$record_rows"
report ""
```

In section 1, the entries' loop, name the record that resolves through the entry. Replace the `compare_pin "\`$name\` ($url)" ...` call with:

```bash
  repo="${url#https://github.com/}"
  repo="${repo%.git}"
  trees="$(jq -r --arg r "$repo" '.records[] | select(.repo == $r) | .trees | keys | join(" ")' "$VENDORED_JSON")"
  forks="$(jq -r --arg r "$repo" '.records[] | select(.repo == $r) | .forks | to_entries | map(.value) | join(" ")' "$VENDORED_JSON")"
  # shellcheck disable=SC2086  # space-separated paths with no whitespace of their own
  tree_list="$(printf '`%s` ' $trees)"
  # shellcheck disable=SC2086  # as above
  fork_list="$(printf '`%s` ' $forks)"
  compare_pin "\`$name\` ($url)" "$url" "$ref" "$sha" \
    "Bump by editing \`.claude-plugin/marketplace.json\`: move \`ref\`, \`sha\` and \`version\` together, \`version\` from upstream's manifest at the new pin where it has one and by hand otherwise${trees:+; re-copy $tree_list from the new pin, keeping the declared changes}${forks:+; read the diff of $fork_list and port what is worth it}; then run test-upstream.sh, which names each new upstream skill to list or exclude. Bump the version of each plugin whose shipped files moved: Claude Code updates only on a version change."
```

- [ ] **Step 6: The offline test's fixture**

In `tests/test-upstream-watch.sh`: `TAG_URL` becomes `https://github.com/example/tag-upstream.git` (a record without a pin resolves through an entry by its GitHub URL). Replace `write_vendored` with:

```bash
write_vendored() { # $1 the branch record's sha
  cat >"$W/vendored.json" <<JSON
{
  "\$comment": "fixture",
  "records": [
    {
      "repo": "example/tree-upstream",
      "ref": "main",
      "sha": "$1",
      "trees": { "plugins/p/skills/three": "skills/three" },
      "forks": { "plugins/p/skills/five": "skills/five" }
    },
    {
      "repo": "example/tag-upstream",
      "trees": { "plugins/p/skills/six": "skills/six" },
      "forks": {}
    }
  ]
}
JSON
}
```

In case 1's first run (every pin current), add after the `Everything matches` assertion:

```bash
grep -qF -- 'skills/five' <<<"$out" || fail "the record's fork path is not named on its line:"$'\n'"$out"
grep -qF -- 'pinned through its subset entry' <<<"$out" || fail "the record without a pin is not reported through its entry:"$'\n'"$out"
```

In case 2's tree drift, `grep -qF 'plugins/p/skills/three'` becomes `grep -qF 'example/tree-upstream'` and the message `the drifted tree was not named` becomes `the drifted record was not named`. Update the header comment's fixture sentence: `a fixture vendored.json with one branch record and one record without a pin, matching the tag entry`.

Run: `bash tests/test-upstream-watch.sh && bash tests/test-workflows.sh`
Expected: PASS.

- [ ] **Step 7: The README's Layout line**

In `README.md`'s `## Layout`, the `vendored.json` line becomes `vendored.json      one record per upstream repository copied or forked from: its pin, its copies and its forks`.

- [ ] **Step 8: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips; cite `tests/results.tsv`.

```bash
git add vendored.json tests/lib.sh tests/test-ownership.sh tests/test-vendored-adhd.sh tests/test-vendored-diagnosing-bugs.sh scripts/upstream-watch tests/test-upstream-watch.sh README.md
git commit -m "Hold one record per upstream repository, with its copies and forks, and derive the linters' exclusion from it"
```

### Task 8: One upstream test, one LICENSE grammar, no provenance headers (§7.1, §7.3, §7.4; constraints 5 and 7; T45, T26, T6, T8, T34, T44, Q47)

**Files:**

- Create: `tests/test-upstream.sh` (named `test-upstream.sh` in prose; the plans are no longer scanned after Task 2)
- Delete: `tests/test-vendored-adhd.sh`, `tests/test-vendored-diagnosing-bugs.sh`, `tests/test-upstream-pin.sh`, `tests/test-subset-writing-clearly-and-concisely.sh`, `plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md`
- Modify: `tests/lib.sh` (`fetch_pinned`'s HEAD assertion; `peel_tag`)
- Modify: `plugins/software-dev/LICENSE`, `plugins/sensemaking/LICENSE` (rewritten whole)
- Modify: the `SKILL.md` of `adhd`, `diagnosing-bugs`, `finding-duplicate-functions` and `setup-matt-pocock-skills` (the provenance headers; adhd's description)
- Modify: `plugins/software-dev/README.md`, `plugins/sensemaking/README.md` (sentences naming the headers and `PROVENANCE.md`)

**Interfaces:**

- Produces: `tests/test-upstream.sh` with its `DECLARED` rows and `EXCLUSIONS` map, which plan B's Task 1 extends with the mattpocock entry's twenty-two exclusions and Task 3 trims; the LICENSE grammar (T26) plan B's Task 2 moves adhd's section under; `peel_tag <url> <tag>` in `tests/lib.sh`.
- Consumes: Task 7's `record_rows`, `record_map`, `tree_keys`; Task 6's `entry_rows`, `entry_skills`, `skill_name_matches`.

- [ ] **Step 1: `fetch_pinned` asserts the HEAD; `peel_tag`**

In `tests/lib.sh`'s `fetch_pinned`, after `git -C "$dir" checkout -q FETCH_HEAD || fail "could not check out FETCH_HEAD in $dir"`, add:

```bash
  [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ] \
    || fail "$url: the checkout's HEAD is $(git -C "$dir" rev-parse HEAD), not the pinned $sha; an annotated tag's object was pinned where its commit should be"
```

After `fetch_upstream`, add:

```bash
# The commit the tag $2 names at $1, a URL: the peeled object of an annotated
# tag, the tag itself for a lightweight one; empty when there is no such tag.
peel_tag() {
  local sha
  sha="$(git ls-remote --tags "$1" "refs/tags/$2^{}" | cut -f1)"
  [ -n "$sha" ] || sha="$(git ls-remote --tags "$1" "refs/tags/$2" | cut -f1)"
  printf '%s\n' "$sha"
}
```

- [ ] **Step 2: The LICENSE sections (T26)**

Replace `plugins/software-dev/LICENSE` whole; `<MIT permission text>` stands for the eleven lines from `Permission is hereby granted` to `SOFTWARE.` exactly as the file carries them today:

```text
MIT License

Copyright (c) 2026 Eran Roseman

<MIT permission text>

----------------------------------------------------------------------
https://github.com/mattpocock/skills
skills/diagnosing-bugs: copied, with one declared change, its frontmatter description
skills/setup-matt-pocock-skills: forked

Copyright (c) 2026 Matt Pocock

----------------------------------------------------------------------
https://github.com/obra/superpowers-lab
skills/finding-duplicate-functions: forked. Phase 1 is reimplemented in Python as scripts/extract-functions.py and scripts/cluster.py, with a structural pre-filter; upstream's three shell scripts have no counterpart; SKILL.md is rewritten; the two prompt templates under scripts/ began as upstream's. The fork point is unknown; the fork was compared against upstream's tip of 2026-08-29.

Copyright (c) 2025 Jesse Vincent

----------------------------------------------------------------------
<MIT permission text>
```

After the last section come one line of dashes and the MIT permission text, once, for every section that shares it (T26). The sha `PROVENANCE.md` named is dropped with the file (Q1: no section names a sha); its date stays.

Replace `plugins/sensemaking/LICENSE` whole:

```text
MIT License

Copyright (c) 2026 Eran Roseman

<MIT permission text>

----------------------------------------------------------------------
https://github.com/UditAkhourii/adhd
skills/adhd: copied, with two declared changes, the invocation gate in its frontmatter and the Codex policy file agents/openai.yaml

Copyright (c) 2026 ADHD contributors

----------------------------------------------------------------------
<MIT permission text>
```

- [ ] **Step 3: The headers go; adhd's description is upstream's**

`plugins/sensemaking/skills/adhd/SKILL.md`: line 3 becomes upstream's, verbatim:

```text
description: Parallel divergent ideation for coding agents. Spawns N isolated branches under different cognitive frames (regulator, biology, speedrunner, 10-year-old, $0 budget), scores, clusters, prunes traps, and deepens top survivors. Use on /adhd, "ADHD mode", brainstorm/ideate intents, or open-ended design, architecture, naming, API/SDK surface, and fuzzy-debugging decisions. Skip for syntax, lookups, bugs with known root cause, or closed phrasing ("quick", "standard", "canonical", "textbook"). Full pre-flight gate is in the skill body.
```

and the seven-line `<!-- Vendored from https://github.com/UditAkhourii/adhd ... -->` comment after the frontmatter is deleted. `plugins/software-dev/skills/diagnosing-bugs/SKILL.md`: the six-line `<!-- Vendored from https://github.com/mattpocock/skills ... -->` comment is deleted. The scaffolder's `SKILL.md`: the eight-line `<!-- Vendored from ... -->` comment is deleted. `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md`: the six-line `<!-- Forked from ... -->` comment is deleted, with the blank line before it, so one blank line follows the frontmatter.

```bash
git rm -q plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md
```

In `plugins/software-dev/README.md`, the `skills/finding-duplicate-functions/` bullet's last sentence becomes `The plugin LICENSE records what changed.`, and the `skills/diagnosing-bugs/` bullet's clause on how it is held becomes:

```text
copied at the pin `vendored.json` records, with one change, a description that
no longer shares a trigger word with `superpowers:systematic-debugging`
```

In `plugins/sensemaking/README.md`, the `adhd` bullet's last two sentences become:

```text
Copied from `UditAkhourii/adhd` at the pin `vendored.json` records, with one
change, the invocation gate; the plugin LICENSE names it.
```

- [ ] **Step 4: Write the upstream test, red first**

```bash
git rm -q tests/test-vendored-adhd.sh tests/test-vendored-diagnosing-bugs.sh tests/test-upstream-pin.sh tests/test-subset-writing-clearly-and-concisely.sh
```

Create `tests/test-upstream.sh`:

```bash
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
# No complement is kept beyond `path`: softaworks ships each of its skills
# twice, under skills/ and under dist/plugins/, and a complement over the
# repository would fail on every name.
#
# Bare sibling names (T44): for a record whose pin is its entry's, every
# upstream skill name that a listed skill at the pin, a copy or a fork names
# as /name or in backticks must be one a marketplace entry delivers. Before
# such a record exists the check is vacuous, and the summary line says so.
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
  $'plugins/sensemaking/skills/adhd/SKILL.md\tadded\tdisable-model-invocation: true\tthe invocation gate, Claude Code\'s half: about ten agent calls, a cost only the user can authorize'
  $'plugins/sensemaking/skills/adhd/agents/openai.yaml\tadded\t<file>\tthe invocation gate, Codex\'s half'
)

# ---- Declared exclusions, per entry (§7.3, T36) -----------------------------
# Lines of `skill<TAB>reason`: the skill directories under the entry's path
# that the entry does not list, each with one reason. An exclusion upstream
# no longer has fails; so does a listed skill that is also excluded.
declare -A EXCLUSIONS=(
  [superpowers]=$'brainstorming\tthe narrowed copy that excluded it left with Q78; the entry itself leaves with the README\'s obra lines'
  [writing-clearly-and-concisely]=''
)

cache_for() { printf '%s/software-dev-upstream-%s\n' "${TMPDIR:-/tmp}" "$(tr / - <<<"$1")"; }

# The declared rows for the local path $1: kind, anchor, reason, tab-separated.
declared_for() {
  local r
  for r in "${DECLARED[@]}"; do
    if [ "${r%%$'\t'*}" = "$1" ]; then printf '%s\n' "${r#*$'\t'}"; fi
  done
}

# Upstream's file $3 against the local file $2, both named $1 in messages,
# under the declared rows for $1 (§7.1's two rules).
compare_file() {
  local key="$1" lf="$2" uf="$3" rows kind anchor reason loc up n pos
  rows="$(declared_for "$key")"
  if [ -z "$rows" ]; then
    cmp -s "$uf" "$lf" || fail "$key differs from upstream at the pin, with no declared change"
    return
  fi
  loc="$(cat "$lf")"
  up="$(cat "$uf")"
  while IFS=$'\t' read -r kind anchor reason; do
    [ "$kind" = added ] && [ "$anchor" != '<file>' ] || continue
    n="$(grep -cxF -- "$anchor" <<<"$loc" || true)"
    [ "$n" -eq 1 ] || fail "$key: the declared addition '$anchor' appears $n times locally, not once"
    if grep -qxF -- "$anchor" <<<"$up"; then fail "$key: the declared addition '$anchor' is present upstream at the pin; retire the declaration"; fi
    loc="$(grep -vxF -- "$anchor" <<<"$loc" || true)"
  done <<<"$rows"
  while IFS=$'\t' read -r kind anchor reason; do
    [ "$kind" = line ] || continue
    n="$(grep -cxF -- "$anchor" <<<"$up" || true)"
    [ "$n" -eq 1 ] || fail "$key: the declared line's upstream side appears $n times upstream at the pin, not once; retire or re-anchor the declaration ($reason)"
    pos="$(grep -nxF -- "$anchor" <<<"$up" | cut -d: -f1)"
    [ "$(sed -n "${pos}p" <<<"$loc")" != "$anchor" ] \
      || fail "$key: the declared change at line $pos was reverted; it equals upstream's line ($reason)"
    loc="$(sed "${pos}d" <<<"$loc")"
    up="$(sed "${pos}d" <<<"$up")"
  done <<<"$rows"
  diff <(printf '%s\n' "$up") <(printf '%s\n' "$loc") \
    || fail "$key differs from upstream at the pin beyond its declared changes"
}

# The copy $2 (a REPO_ROOT-relative path) against $3 (a path under the
# checkout $4) of the repository $1: file set, modes, bytes.
compare_tree() {
  local repo="$1" local_path="$2" up_path="$3" U="$4" f up_files loc_files added lmode umode
  [ -d "$U/$up_path" ] || fail "$repo has no $up_path at its pin"
  up_files="$(cd "$U/$up_path" && find . -type f | sed 's#^\./##' | sort)"
  loc_files="$(git -C "$REPO_ROOT" ls-files -- "$local_path" | sed "s#^$local_path/##" | sort)"
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
  want="$(grep '^Copyright' "$U/LICENSE" | sort -u)"
  [ -n "$want" ] || fail "$repo's LICENSE at the pin carries no Copyright line"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    lic="$REPO_ROOT/plugins/$p/LICENSE"
    [ -f "$lic" ] || fail "plugins/$p has no LICENSE"
    section="$(license_section "$lic" "https://github.com/$repo")"
    [ -n "$section" ] || fail "plugins/$p/LICENSE has no section opening with https://github.com/$repo"
    got="$(grep '^Copyright' <<<"$section" | sort -u)"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") \
      || fail "plugins/$p/LICENSE's section for $repo does not carry upstream's Copyright line(s) at the pin (upstream above, ours below)"
    SECTIONS=$((SECTIONS + 1))
  done < <({ record_map trees "$repo"; record_map forks "$repo"; } | cut -f1 | cut -d/ -f2 | sort -u)
}

# T44, for the record $2 whose pin is the entry $1's: every upstream skill name
# ($6, one per line) that a listed skill ($5, paths under $4 in the checkout
# $3), a copy or a fork names as /name or in backticks is delivered by a
# marketplace entry.
sibling_names() {
  local entry="$1" repo="$2" U="$3" path="$4" listed="$5" up_names="$6" delivered files f names n
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
    { record_map trees "$repo"; record_map forks "$repo"; } | cut -f1 | while IFS= read -r k; do
      git -C "$REPO_ROOT" ls-files -- "$k" | grep '\.md$' | sed "s#^#$REPO_ROOT/#"
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

# Every declared row names a path under a copy, so a stale row fails.
for r in "${DECLARED[@]}"; do
  p="${r%%$'\t'*}"
  under=0
  while IFS= read -r key; do
    case "$p" in "$key"/*) under=1 ;; esac
  done < <(tree_keys)
  [ "$under" -eq 1 ] || fail "the declared change for $p names a path under no copy in vendored.json"
done

# ---- The records -------------------------------------------------------------
while IFS=$'\t' read -r repo ref sha; do
  [ -n "$repo" ] || continue
  url="https://github.com/$repo.git"
  U="$(fetch_pinned "$url" "$sha" "$(cache_for "$repo")")"
  if ! git ls-remote "$url" "refs/heads/$ref" | grep -q .; then
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
done < <(record_rows)
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
while IFS=$'\t' read -r name url path ref sha version; do
  [ -n "$name" ] || continue
  repo="${url#https://github.com/}"
  repo="${repo%.git}"
  U="$(fetch_pinned "$url" "$sha" "$(cache_for "$repo")")"
  [ "$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .strict' "$MARKETPLACE")" = false ] \
    || fail "$name: strict must be false; see the header comment"
  if ! git ls-remote "$url" "refs/heads/$ref" | grep -q .; then
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
  diff <(printf '%s\n' "$up_names") <({ entry_skills "$name"; printf '%s\n' "$excl" | cut -f1; } | grep . | sort) \
    || fail "$name: the skill directories under $path at the pin (above) are not the listed skills plus the declared exclusions (below); list or exclude each new skill with its reason"
  if jq -e --arg r "$repo" '.records[] | select(.repo == $r) | (has("sha") | not)' "$VENDORED_JSON" >/dev/null 2>&1; then
    sibling_names "$name" "$repo" "$U" "$path" "$listed" "$up_names"
  fi
  ENTRIES=$((ENTRIES + 1))
done < <(entry_rows)
[ "$ENTRIES" -gt 0 ] || fail "the marketplace holds no subset entry"

printf 'upstream: %s record(s) at their pins, %s copied file(s) held with %s declared change(s), %s LICENSE section(s) carry upstream'"'"'s copyright; %s entr(y|ies) at their pins with %s exclusion(s); %s sibling name(s) resolve\n' \
  "$RECORDS" "$FILES" "${#DECLARED[@]}" "$SECTIONS" "$ENTRIES" "$EXCLUDED_N" "$SIBLINGS"
```

Run: `bash tests/test-upstream.sh`
Expected: PASS: three records, five copied files (adhd's two, diagnosing-bugs' three), three declared changes, three sections, two entries with one exclusion, zero sibling names.

- [ ] **Step 5: The mutations (T31), each in a scratch clone**

```bash
S="$(mktemp -d)"; git clone -q --local /home/eranr/agent-plugins "$S/repo"; cp tests/test-upstream.sh tests/lib.sh "$S/repo/tests/"
```

Then, in `$S/repo`, one at a time, each run with `bash tests/test-upstream.sh` and the clone reset with `git checkout -- . && git clean -fdq` after:

1. Copyright: change `Copyright (c) 2026 Matt Pocock` to `2025` in `plugins/software-dev/LICENSE`. Expected FAIL `does not carry upstream's Copyright line(s)`.
2. A section for a URL no record holds: insert a section `https://github.com/example/nobody` with a Copyright line before the closing dashes of `plugins/sensemaking/LICENSE`. Expected FAIL `which no record holds`.
3. The declared line reverted: set `diagnosing-bugs`' description to upstream's. Expected FAIL `was reverted`.
4. Modes: `chmod +x plugins/software-dev/skills/diagnosing-bugs/scripts/hitl-loop.template.sh && git update-index --chmod=+x plugins/software-dev/skills/diagnosing-bugs/scripts/hitl-loop.template.sh`. Expected FAIL `has mode 100755; upstream's at the pin is 100644`.
5. The complement: add `$'nosuch\tnever evaluated'` to superpowers' exclusions. Expected FAIL `is not a skill under skills at the pin`. Then delete the `brainstorming` exclusion instead. Expected FAIL `are not the listed skills plus the declared exclusions`.
6. The layout check (T34): a synthetic upstream. In `$S`, `git init -q synth && mkdir -p synth/pkg/skills/{one,two} && printf -- '---\nname: one\n---\n' >synth/pkg/skills/one/SKILL.md && printf -- '---\nname: two\n---\n' >synth/pkg/skills/two/SKILL.md && git -C synth add -A && git -C synth -c user.email=t@example.com -c user.name=t commit -qm seed`; add to `$S/repo/.claude-plugin/marketplace.json` an entry `{"name":"synth","description":"x","category":"development","source":{"source":"git-subdir","url":"<absolute path of synth>","path":"pkg","ref":"master","sha":"<its HEAD>"},"version":"0.0.1","strict":false,"skills":["./skills/one"]}` (use `git -C synth rev-parse HEAD` and `git -C synth branch --show-current` for the ref). Expected FAIL `pkg/skills/two holds a skill the entry does not list`.
7. A stale declared row: change the first `DECLARED` row's path to `plugins/software-dev/skills/nowhere/SKILL.md`. Expected FAIL `names a path under no copy`.

The sibling-name mutation (the fork under its old name) is plan B's, once a record resolves through an entry.

- [ ] **Step 6: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips: `tests/test-upstream.sh` PASS, the four deleted tests gone from the result file, the spelling and lint tests passing over the edited skills. Cite `tests/results.tsv`.

```bash
git add -A tests plugins/software-dev/LICENSE plugins/sensemaking/LICENSE plugins/software-dev/skills plugins/sensemaking/skills plugins/software-dev/README.md plugins/sensemaking/README.md
git commit -m "Hold every copy and entry in one upstream test, credit each upstream in one LICENSE section, and drop the provenance headers"
```

### Task 9: One marketplace file, and the install job (§6.4, §14; constraints 8 and 9; Q49, Q54, Q63, Q64, T13, T14, T15, T41)

**Files:**

- Delete: `.agents/plugins/marketplace.json`, `tests/test-codex-marketplace.sh`
- Create: `tests/install-check.sh` (named `install-check.sh` in prose)
- Modify: `README.md` (the Install and Update blocks gain their markers)
- Modify: `.github/workflows/validate.yml` (a `schedule:` trigger; the `install` job beside `setup-e2e`)

**Interfaces:**

- Produces: `tests/install-check.sh` with `readme_block <name>`, `details_names <plugin@marketplace> <Skills|Agents>`, `codex_catalogue`, and the two entry points (no argument: install then assert; `--assert`: assert over the `HOME` and `CODEX_HOME` given); the README's marked blocks `install-claude`, `install-codex`, `update-claude`, `update-codex`, this plan's version of each; the CI job `install`.
- Consumes: Task 6's `entry_rows`, `entry_skills`.

- [ ] **Step 1: The Codex marketplace file goes**

```bash
cd /home/eranr/agent-plugins
git rm -q .agents/plugins/marketplace.json tests/test-codex-marketplace.sh
```

Codex reads `.claude-plugin/marketplace.json` once the `.agents` file is gone (§6.4). Measured locally before the commit: `codex plugin marketplace add "$PWD"` from a scratch `CODEX_HOME` lists all four entries, where today it lists two:

```bash
H="$(mktemp -d)"; mkdir -p "$H/.codex"
HOME="$H" CODEX_HOME="$H/.codex" codex plugin marketplace add "$PWD"
HOME="$H" CODEX_HOME="$H/.codex" codex plugin list --json | jq -r '.available[]?.pluginId // empty, .installed[]?.pluginId // empty' | sort -u
```

Expected: `sensemaking@eranroseman`, `software-dev@eranroseman`, `superpowers@eranroseman`, `writing-clearly-and-concisely@eranroseman` (the key names in `codex plugin list --json`'s output may differ by version; the four plugin ids are what matters).

- [ ] **Step 2: The README's marked blocks (interim, P7)**

In `README.md`, `## Install`: replace the fenced block that reads

````markdown
```sh
claude plugin marketplace add eranroseman/agent-plugins
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```
````

with

````markdown
```sh install-claude
claude plugin marketplace add eranroseman/agent-plugins
claude plugin install software-dev@eranroseman
```

```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev sensemaking superpowers writing-clearly-and-concisely; do codex plugin add "$p@eranroseman"; done
```

Then the script converges the rest, the pinned clones and the skills.sh set:

```sh
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```
````

and change the sentence before it, `One command adds the marketplace, and the script it delivers does the rest.`, to `The marketplace installs with each agent CLI's own commands, and the script it delivers does the rest.` In `## Update`, replace the fenced block that reads

````markdown
```sh
claude plugin marketplace update eranroseman
codex plugin marketplace upgrade eranroseman
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```
````

with

````markdown
```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update sensemaking@eranroseman
claude plugin update superpowers@eranroseman
claude plugin update writing-clearly-and-concisely@eranroseman
```

```sh update-codex
codex plugin marketplace upgrade eranroseman
```

```sh
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```
````

The prose around both stays until plan B's Task 1 rewrites Install and Update; `tests/test-setup-doctor.sh` still finds `bash` 4.4 or later in `## Checks`. The marker is the info string's second word; the install job runs the two `install-` blocks and nothing else.

- [ ] **Step 3: Write `install-check.sh`**

Create `tests/install-check.sh`, mode 755:

````bash
#!/usr/bin/env bash
# The plugin and its entries install (spec §14). On a fresh scratch HOME the
# README's install blocks run as a user runs them, with the marketplace source
# replaced by this checkout and nothing else, and what loaded is asserted on
# both agent CLIs. Claude Code, from `claude plugin details`: each local
# plugin's skills equal its skill directories and its agents the stems under
# agents/, and each subset entry's skills equal the last segments of its list.
# Codex, from `codex debug prompt-input`: each local plugin's model-visible
# skills equal its skill directories less those whose Codex policy file sets
# allow_implicit_invocation: false, and each entry's its list less the skills
# whose policy file in the installed cache does; the cache is never the
# oracle for what loads, since both agent CLIs cache the whole path.
#
#   tests/install-check.sh            install into a fresh scratch HOME, then assert
#   tests/install-check.sh --assert   assert only, over the HOME and CODEX_HOME in the environment
#
# Outside tests/run.sh's glob: it needs both agent CLIs at their newest stable
# versions, which the validate job does not install, and the runner has no
# probe for codex. The install job in .github/workflows/validate.yml runs it.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
README="$REPO_ROOT/README.md"

# The lines of the fenced block of README.md whose info string's second word
# is $1 (T13); empty when there is none.
readme_block() {
  awk -v want="$1" '
    /^```/ {
      if (inblock) { inblock = 0; name = ""; next }
      inblock = 1
      split($0, w, " ")
      name = w[2]
      next
    }
    inblock && name == want { print }
  ' "$README"
}

# Run the block $1 under bash -euo pipefail, with the marketplace source
# replaced by this checkout's path and nothing else (Q64). Obra's lines run as
# written.
run_block() {
  local body
  body="$(readme_block "$1")"
  [ -n "$body" ] || fail "README.md has no fenced block marked $1"
  printf '%s\n' "$body" | sed "s|eranroseman/agent-plugins|$REPO_ROOT|g" >"$HOME/block-$1.sh"
  printf '== %s ==\n' "$1"
  cat "$HOME/block-$1.sh"
  bash -euo pipefail "$HOME/block-$1.sh"
}

# The names on the $2 line (Skills or Agents) of `claude plugin details $1`,
# one per line, sorted; nothing for `Agents (0)`.
details_names() {
  claude plugin details "$1" | sed -n "s/^  $2 ([0-9]*) *//p" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . | sort || true
}

# Every skill in Codex's model-visible catalogue, as the catalogue names it
# (plugin:skill for a plugin's, bare for a skill root's), one per line.
codex_catalogue() {
  (cd "$HOME" && codex debug prompt-input) \
    | jq -r '.. | objects | select(has("text")) | .text' \
    | grep -oE '^- [a-z][a-z0-9-]*(:[a-z][a-z0-9-]*)?: ' | sed 's/^- //; s/: $//' | sort || true
}

# $1 a label, $2 and $3 sets, one name per line, in any order.
expect_equal() {
  diff <(printf '%s\n' "$2" | grep . | sort) <(printf '%s\n' "$3" | grep . | sort) \
    || fail "$1: the sets differ (expected above, found below)"
}

# True when the Codex policy file $1 keeps its skill out of the model's
# catalogue.
gated() { [ -f "$1" ] && grep -qx '  allow_implicit_invocation: false' "$1"; }

MODE="${1:-}"
case "$MODE" in
  '')
    SCRATCH="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/install-check.XXXXXX")" || fail "mktemp failed"
    export HOME="$SCRATCH/home"
    export CODEX_HOME="$HOME/.codex"
    unset CLAUDE_CONFIG_DIR
    # Codex refuses a CODEX_HOME that does not exist (measured).
    mkdir -p "$CODEX_HOME" || fail "could not create $CODEX_HOME"
    # Named so a later --assert run, or a mutation, can find this machine.
    printf 'HOME=%s\nCODEX_HOME=%s\n' "$HOME" "$CODEX_HOME"
    ;;
  --assert)
    [ -n "${HOME:-}" ] && [ -n "${CODEX_HOME:-}" ] || fail "--assert needs HOME and CODEX_HOME in the environment"
    ;;
  *)
    printf 'usage: tests/install-check.sh [--assert]\n' >&2
    exit 2
    ;;
esac
command -v claude >/dev/null 2>&1 || fail "claude is not on PATH"
command -v codex >/dev/null 2>&1 || fail "codex is not on PATH"
# A log line, not an assertion: a red run says which release broke it.
printf 'claude: %s\ncodex: %s\n' "$(claude --version)" "$(codex --version)"

if [ -z "$MODE" ]; then
  run_block install-claude
  run_block install-codex
fi

local_rows="$(jq -r '.plugins[] | select(.source | type == "string") | [.name, .source] | @tsv' "$MARKETPLACE")"
[ -n "$local_rows" ] || fail "no local plugin in $MARKETPLACE"

# ---- Claude Code -------------------------------------------------------------
while IFS=$'\t' read -r name src; do
  [ -n "$name" ] || continue
  dir="$REPO_ROOT/${src#./}"
  want_skills="$(for d in "$dir"/skills/*/; do basename "$d"; done)"
  want_agents="$(for a in "$dir"/agents/*.md; do if [ -f "$a" ]; then basename "$a" .md; fi; done)"
  expect_equal "claude: $name's skills" "$want_skills" "$(details_names "$name@eranroseman" Skills)"
  expect_equal "claude: $name's agents" "$want_agents" "$(details_names "$name@eranroseman" Agents)"
done <<<"$local_rows"
while IFS=$'\t' read -r name _; do
  [ -n "$name" ] || continue
  expect_equal "claude: the entry $name's skills" "$(entry_skills "$name")" "$(details_names "$name@eranroseman" Skills)"
done < <(entry_rows)

# ---- Codex -------------------------------------------------------------------
catalogue="$(codex_catalogue)"
[ -n "$catalogue" ] || fail "codex debug prompt-input listed no skill"
visible_of() { grep "^$1:" <<<"$catalogue" | sed "s/^$1://" || true; }
while IFS=$'\t' read -r name src; do
  [ -n "$name" ] || continue
  dir="$REPO_ROOT/${src#./}"
  want="$(for d in "$dir"/skills/*/; do gated "$d/agents/openai.yaml" || basename "$d"; done)"
  expect_equal "codex: $name's model-visible skills" "$want" "$(visible_of "$name")"
done <<<"$local_rows"
while IFS=$'\t' read -r name _; do
  [ -n "$name" ] || continue
  cache="$(printf '%s\n' "$CODEX_HOME"/plugins/cache/eranroseman/"$name"/*/)"
  [ "$(printf '%s\n' "$cache" | grep -c .)" -eq 1 ] || fail "codex: expected one installed cache for $name, found:"$'\n'"$cache"
  want="$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .skills[] | sub("^\\./"; "")' "$MARKETPLACE" \
    | while IFS= read -r lp; do gated "${cache%/}/$lp/agents/openai.yaml" || basename "$lp"; done)"
  expect_equal "codex: the entry $name's model-visible skills" "$want" "$(visible_of "$name")"
done < <(entry_rows)

printf 'install-check: every local plugin and subset entry loads the skills it declares on Claude Code and Codex\n'
````

Run locally, as a smoke run on this machine's older CLIs: `bash tests/install-check.sh`
Expected: PASS: the install blocks print as they run, then the summary line. (Claude Code 2.1.273 and codex-cli 0.147.0 here; the job runs the newest stable ones.)

Red first (§15.3): in a scratch clone, drop `superpowers` from the README's `install-codex` block and run `bash tests/install-check.sh` there. Expected FAIL `codex: the entry superpowers's model-visible skills: the sets differ`.

- [ ] **Step 4: The CI job and the daily schedule**

In `.github/workflows/validate.yml`: the trigger becomes

```yaml
on:
  push:
  pull_request:
  schedule:
    # Daily, so an agent CLI release that changes install behavior shows within
    # a day rather than at the next push (spec §14). The validate job runs too,
    # the price of one workflow for #70's pre-check.
    - cron: "41 6 * * *"
```

and after the `setup-e2e` job, append:

```yaml
  install:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: 22

      # The newest stable release of each agent CLI, not a pin (Q54): Claude
      # Code's `stable` dist-tag, since `latest` has run a build the stable
      # channel did not; Codex's `latest`, since its package has no `stable`.
      # The script logs both versions before any install.
      - name: Install the newest stable agent CLIs
        run: npm install -g @anthropic-ai/claude-code@stable @openai/codex@latest

      # The README's install blocks, run as written against this checkout
      # into a scratch HOME under RUNNER_TEMP, then the assertions (spec §14).
      - name: Install through the README's blocks and assert what loaded
        run: tests/install-check.sh
```

Run: `bash tests/test-workflows.sh`
Expected: PASS (actionlint over the new job).

- [ ] **Step 5: Run the suite and commit**

Run: `bash tests/run.sh`
Expected: green but for skips; `tests/test-codex-marketplace.sh` is gone from the result file; the shell lint and format tests cover `install-check.sh` through its shebang. Cite `tests/results.tsv`.

```bash
git add -A .agents tests README.md .github/workflows/validate.yml
git commit -m "Serve both agent CLIs from one marketplace file, and install the plugin in CI through the README's own blocks"
```

### Task 10: Gate A: the suite and both CI jobs green on the pushed branch

**Files:** none changed. This gate ends plan A; plan B's Task 1 begins from the pushed branch tip.

- [ ] **Step 1: The suite, every network test run**

Run: `bash tests/run.sh`
Expected: `0 failed`; `tests/test-upstream.sh`, `tests/test-codex-validate.sh` and `tests/test-upstream-watch.sh` PASS; the only SKIP rows are for tools this machine lacks, if any. Cite `tests/results.tsv`'s header line and its rows.

- [ ] **Step 2: The install check, locally**

Run: `bash tests/install-check.sh`
Expected: PASS on this machine's Claude Code 2.1.273 and codex-cli 0.147.0; the job's run on the newest stable releases is the binding one.

- [ ] **Step 3: Push the branch and watch CI**

```bash
git push -u origin standalone-and-references
gh run list --branch standalone-and-references --limit 3
gh run watch "$(gh run list --branch standalone-and-references --workflow validate --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: the `validate` workflow's three jobs, `validate`, `setup-e2e` and `install`, all green. Record the run id. If `install` is red, read its log: the first lines name both CLI versions, then each block as it ran, then the first failing assertion with the two sets. A failure that is a release's behavior change is filed as an issue with the run id and fixed on the branch before plan B starts; a failure in the script is fixed here.

- [ ] **Step 4: Record the gate**

Nothing merges. Plan B opens by reading `tests/results.tsv`'s header for this tree and the run id from Step 3.

## Self-review

- **Spec coverage, constraints 1 to 9 of §18:** 1 (Task 1), 2 (Task 4), 3 (Task 5), 4 (Task 7), 5 and 7 (Task 8), 6 (Task 3; the rename in Task 4 needs no literal edit since the derivation lands first), 8 and 9 (Task 9). Unordered items landed here: Q18 and T18 (Task 2), `tests/test-format-apply.sh` and the runner's #68 items (Task 2), Dependabot (Task 1), the widened scan with its negative fixture, uniqueness, named scripts and the name helper (Task 6).
- **Red-first list of §15.3, this plan's share:** the copyright check, the bare agent name, the name helper, skill-name uniqueness, named scripts, the validator's derivation, the layout check, the complement, modes, the ownership derivation, the workflows test's recording stub, and the install job's dropped entry: each has its mutation in its task. The sibling-name check, the vocabulary scan over the glossary and the superpowers check are plan B's.
- **Names:** `entry_rows`, `entry_skills`, `shipped_texts`, `skill_name_matches` (Task 6); `VENDORED_JSON`, `upstream_sha`, `upstream_ref`, `record_rows`, `record_map`, `tree_keys`, `fork_keys`, `EXCLUDED` (Task 7); `peel_tag` and `fetch_pinned`'s assertion (Task 8); `readme_block`, `details_names`, `codex_catalogue` (Task 9); `resolve_ref` (Task 1): each used by later tasks under the name its defining task gives.
- **What this plan leaves on the branch for plan B:** `bin/setup`, `bin/doctor`, their nine tests and four helpers, `setup-e2e`, `tests/test-setup-upgrade.sh`, `skills.json`, `tests/test-skills-pin.sh`, the watch's skills.sh section, `fetch_upstream`, the superpowers and `writing-clearly-and-concisely` entries, `sensemaking`, the mattpocock record's own pin, `CONTEXT.md`, the README's interim Install and Update sections, `consistency-audit`'s hedges, the fork's bare `/wayfinder` and `` `pr` ``, and `software-dev` at 0.8.0.
