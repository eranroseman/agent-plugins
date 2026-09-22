# The suite tells the truth, and CI checks what we own

**Status:** design, 2026-09-17, awaiting the maintainer's review. Milestones 1 (_Suite tells the truth_) and 2 (_CI, lint and the Checks section_) of the tracker, in one spec, one plan and one branch, `suite-and-ci`. §3 lists every decision with its source: the maintainer's answers of 2026-09-17, or the deleted design of 2026-09-06 where nothing newer overrides it. §12 lists three deviations from an answer, each with its veto line.
**Scope:** milestone 1: [#1](https://github.com/eranroseman/agent-plugins/issues/1), [#5](https://github.com/eranroseman/agent-plugins/issues/5), [#16](https://github.com/eranroseman/agent-plugins/issues/16), [#18](https://github.com/eranroseman/agent-plugins/issues/18) (the extractor only), [#27](https://github.com/eranroseman/agent-plugins/issues/27), [#38](https://github.com/eranroseman/agent-plugins/issues/38), [#40](https://github.com/eranroseman/agent-plugins/issues/40), [#41](https://github.com/eranroseman/agent-plugins/issues/41), [#42](https://github.com/eranroseman/agent-plugins/issues/42) (the repository half), [#43](https://github.com/eranroseman/agent-plugins/issues/43). Milestone 2: [#3](https://github.com/eranroseman/agent-plugins/issues/3), [#6](https://github.com/eranroseman/agent-plugins/issues/6) (item 1), [#7](https://github.com/eranroseman/agent-plugins/issues/7), [#8](https://github.com/eranroseman/agent-plugins/issues/8), [#28](https://github.com/eranroseman/agent-plugins/issues/28), [#29](https://github.com/eranroseman/agent-plugins/issues/29).
**Not in scope:** the README beyond its Checks section ([#37](https://github.com/eranroseman/agent-plugins/issues/37), [#57](https://github.com/eranroseman/agent-plugins/issues/57), milestone 7), including #18's "on Codex too" sentence; #42's template half, declined by the maintainer (§12); the engine's coverage gaps ([#17](https://github.com/eranroseman/agent-plugins/issues/17)) and the watch surface (milestone 4); vocabulary ([#26](https://github.com/eranroseman/agent-plugins/issues/26), milestone 3).

## 1. Evidence standard

A claim below is a fact only when it rests on one of: the tree at `aa8e78d`, read on 2026-09-17; the fact-finding pass of the same day (nine investigations, eighteen agents, every claim adversarially re-checked, five corrected); a primary document read the same day; or a run made the same day in a scratch copy of the checkout. Counts are outputs at `aa8e78d`, not targets; the plan re-measures on the branch. §13 lists each mechanism claim with its source.

The design of 2026-09-06, _Repository quality gates_ (deleted in `1511eb8`, recoverable as `2825752:docs/superpowers/specs/2026-09-06-repository-quality-gates-design.md`), was read in full. Its measurements and its ownership analysis are reused with attribution. Where a decision here differs from it, the maintainer's newer answer wins and §3 says so.

## 2. Purpose

Two milestones share one property: **a green run means what it says.**

Milestone 1 closes every way `tests/run.sh` or `bin/doctor` can pass for the wrong reason: a check that reports nothing, an assertion satisfied by an error message, a plugin skipped rather than failed, a hardcoded directory list that a rename walks out of, a rules file nothing byte-compares, a report whose evidence an agent typed from memory. Milestone 2 builds the substrate that keeps it that way: CI with least privilege and pinned inputs, a formatter and a linter over the files we own, one prerequisite gate, and a Checks section that describes the suite as it stands.

They land together because each half consumes the other. The ownership derivation (§4) is what the formatters, the JSON check and the lint list all read; the gate (§5) is what every new tool passes through; and CI is where the new fixtures are proved on a machine nobody configured. One branch, one gate, one merge.

## 3. Decisions

Sources: **G1** and **G2** are the first and second question rounds of 2026-09-17; **M** is the maintainer's direct ruling in the opening of that session; **D** is the deleted spec of 2026-09-06, kept where nothing newer overrides it.

| Question                                             | Decision                                                                                                                                                                | Source                                                              |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| One spec for both milestones?                        | Yes. One plan, one branch                                                                                                                                               | M                                                                   |
| #42, reports that paste test output                  | `tests/run.sh` writes a result file; reports cite its path. No skill edit, no prose rule anywhere                                                                       | M                                                                   |
| #5, GNU-only constructs in tests                     | Make the tests portable                                                                                                                                                 | M                                                                   |
| #3, local and CI validators can disagree             | Assert the hash of **both** validator files at the local default path; point at CI's fetch recipe from the README and from the failure message                          | M, G2                                                               |
| #8, `pull_request:` trigger                          | Keep it                                                                                                                                                                 | G1 Q1                                                               |
| #8, path filter                                      | None. Every push runs CI, and `docs/` is checked like the rest; the first answer, `docs/**` ignored, was reversed after the Q11 collision on the cost measured in §9.3  | M, 2026-09-17, reversing G2 Q8                                      |
| #41, rung 1 in scope?                                | Both rungs. A `REPORTED` counter bumped in the four reporting helpers, snapshotted around each check                                                                    | G2 Q2                                                               |
| #41, a silent check's bucket                         | `FAIL:`, counted in "N check(s) failed"; exit 1                                                                                                                         | G2 Q3                                                               |
| #38, the second-entry fixture                        | In the new silence test, beside the first-entry one                                                                                                                     | G1 Q3, G2                                                           |
| #29, tool set                                        | All four: `shfmt`, `prettier`, `markdownlint-cli2`, `cspell`                                                                                                            | G2 Q4                                                               |
| #29, spelling locale                                 | `en-US`                                                                                                                                                                 | G1 Q5                                                               |
| #29, tool versions                                   | One registry declares tool and version; CI installs exactly that; a local mismatch is a SKIP that names both versions                                                   | G2 Q5                                                               |
| Absent-tool policy                                   | One gate                                                                                                                                                                | G2 Q6                                                               |
| What the gate holds hard                             | `bash` 4 or later, `jq`, `git`. Everything else is a declared need, skipped when absent. Network stays a FAIL                                                           | G2 Q7                                                               |
| #27 and #29, ownership                               | One derivation in `tests/lib.sh`, over `git ls-files`, consumed by every list                                                                                           | G2 Q9                                                               |
| #28, actionlint and the two properties it cannot see | actionlint plus greps in `tests/test-workflows.sh`: every `uses:` sha-pinned, `permissions:` at workflow level; `persist-credentials: false` by hand in the same change | G1 Q7, G2 Q10                                                       |
| #42, the result file's shape                         | TSV at a fixed, gitignored path, header with commit and timestamp, one row per test; CI uploads it                                                                      | G1 Q10                                                              |
| #43, source of truth for `payload-rules.md`          | The spec's §4.2 block, extracted at test time; that spec is maintained, and its stale byte counts are corrected                                                         | G2 Q11                                                              |
| #16, the vacuous refusal grep                        | Replace the external `dirname` in `bin/setup` and `bin/doctor` with parameter expansion; both survive an empty `PATH`                                                   | G2 Q12                                                              |
| #18, the README extractor                            | Reset scope on `#` and `##`; a `###` stays inside its parent                                                                                                            | G2 Q13                                                              |
| #18, the LICENSE comma                               | Decline as moot; correct the issue's wording                                                                                                                            | G2 Q14                                                              |
| #18, a `Note:` commit for `4b23edc`                  | Decline                                                                                                                                                                 | G1 Q11                                                              |
| #40, the remaining tab-IFS `read` loops              | The same parameter-expansion split, here, with one fixture                                                                                                              | G2 Q15                                                              |
| Plugin versions                                      | Patch bump at the end, both manifests per plugin, one commit                                                                                                            | G1 Q13                                                              |
| Branch and gate                                      | One branch `suite-and-ci`, milestone 1 then milestone 2, full suite green with the result file cited, then merge to `main` and push                                     | G1 Q14                                                              |
| `shfmt` flags, prettier options, markdownlint rules  | `-i 2 -ci -bn`; `proseWrap: preserve`, `embeddedLanguageFormatting: off`; MD013, MD033, MD041 off                                                                       | D §3, §5.2                                                          |
| `cspell` over comments in shell and YAML             | Yes, through an `overrides` entry, as D §3 ruled; veto drops that entry                                                                                                 | D §3                                                                |
| `cspell` scope                                       | The checked markdown outside the three record directories under `docs/` (`superpowers`, `research`, `archive`); `docs/agents/` stays in                                 | D §3's scope, widened by two directories on the measurement in §8.1 |
| `bin/format` as the apply script                     | Yes                                                                                                                                                                     | G1 Q8 default                                                       |
| A skip in CI                                         | `tests/run.sh --no-skip` makes every unmet need a `FAIL`; CI runs with it, with the pinned binaries ahead of the image's on `PATH`                                      | this spec, from G1 Q6's "CI installs everything, so CI never skips" |

## 4. Ownership: one derivation

Every list of "the files we own" comes from one function in `tests/lib.sh`. One class of tracked file is not in it, and a drift test governs every member.

**Vendored.** An upstream pin constrains the bytes, and a drift test asserts them. Six patterns, taken from D §2, anchored at the start of the path:

```text
plugins/sensemaking/skills/adhd/
plugins/software-dev/skills/brainstorming/
plugins/software-dev/skills/diagnosing-bugs/
plugins/software-dev/skills/setup-repository/
plugins/software-dev/skills/finding-duplicate-functions/scripts/*-prompt.md
plugins/software-dev/hooks/payload.md
```

Twenty-three files match at `aa8e78d`. `payload.md` is rebuilt from the pinned clone by `bin/bump-superpowers --emit-payload` and diffed by `tests/test-hook.sh`, which is the same constraint. `adhd/agents/openai.yaml` is authored here but sits inside a vendored directory; the directory is excluded whole, because the drift test's file-set assertion governs the directory and `tests/test-plugin-skills.sh` already asserts the one policy line the file exists to carry. `finding-duplicate-functions` is a fork: only its two prompt templates are upstream's, so only they are excluded.

**Nothing else is excluded.** `docs/` is checked like the rest: its fifteen markdown files are formatted and linted, and spelling is scoped by directory in §8.1. The first draft of this spec carried `docs/` as a second class, to match a CI path filter that skipped docs-only pushes; the maintainer dropped the filter on 2026-09-17 (§9.3), and the class went with it. A plan is a record that freezes once executed (`a3c797f`), and formatting one changes whitespace and emphasis markers, never a sentence; §8.1 says what the one-time pass does to them.

Everything else is checked. At `aa8e78d`, with this spec added, that is 72 files: 26 shell (the first line is `#!/usr/bin/env bash`; five have no extension), 8 JSON, 5 YAML, 27 markdown, 2 Python, and 4 that no formatter parses (`.gitignore` and the three `LICENSE` files).

```sh
EXCLUDED='^plugins/sensemaking/skills/adhd/|^plugins/software-dev/skills/(brainstorming|diagnosing-bugs|setup-repository)/|^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\.md$|^plugins/software-dev/hooks/payload\.md$'
checked() { git -C "$REPO_ROOT" ls-files "$@" | grep -vE "$EXCLUDED"; }
```

`git -C "$REPO_ROOT"`, never bare: `git ls-files` is cwd-relative and `lib.sh` never changes directory. The contract is _tracked files_: a new file joins when it is staged, which is also the moment anything else in the repository notices it. The stale worktree at `.kilo/worktrees/brass-settee` holds byte-identical copies of the tree; a `find` would see them and `ls-files` does not.

Consumers, each filtering by type and each asserting a non-empty list (#27's vacuity guard; `prettier --check` on a file it cannot parse exits 0, D §5.2, so an empty or wrong list is a false green): the shellcheck list and the `shfmt` list (shell by shebang), the three prettier lists (`*.json`, `*.yml` and `*.yaml`, `*.md`), `markdownlint-cli2` (`*.md`) and `cspell` (`*.md` within §8.1's scope, plus the shell and YAML lists for comments), `tests/test-json-wellformed.sh` (`*.json`, closing #27: eight files where the hardcoded `find` saw seven), `tests/test-links-resolve.sh` (`*.md`), and `bin/format`. The `*/skills/*` exclusion in the JSON check goes; no tracked JSON lives there, and the vendored patterns cover the case it guarded against.

A new `tests/test-ownership.sh` keeps the exclusion honest: every vendored pattern matches at least one tracked file, and every pattern's path is named in a `tests/test-vendored-*.sh` or in `tests/test-hook.sh`, so nothing sits in the excluded set without a drift test behind it.

## 5. The gate

### 5.1 What is hard

`tests/run.sh` probes three things before running anything, and refuses with the complete list when one is missing, exit 2, in the shape `bin/setup`'s `require_tools` uses:

```text
the test suite needs: bash 4 or later (found 3.2), jq, git
```

The line between hard and a need (§5.2): a tool is hard when the suite's shared substrate cannot run without it, so that absent it no test's verdict means anything; it is a need when one test's subject requires it, so that absent it that test cannot speak and the others still can. The hard list is three names in `run.sh`, and growing it is a visible edit.

`jq` because `lib.sh`'s `upstream_sha` reads the marketplace with it; `git` because `fetch_pinned` fetches every pin with it and `checked()` (§4) lists every file with it; `bash` 4 because `bin/setup`, the subject of five tests, declares an associative array in `report_pool`, and on bash 3.2 that `local -A` fails and the array degrades into an indexed one with no message. Once #5 lands the tests themselves need nothing past bash 3.2; the engine does.

Everything on the previous hard list (`claude`, `node`, `npx`, `python3` with `pyyaml`, `sha256sum`, `cmp`) falls into one of two other buckets. Assumed: part of a base GNU/Linux install, not probed, and loud with `command not found` when absent. Or a declared need.

### 5.2 Needs

A test that wants an optional tool says so on one line in its header, `# needs: claude` or `# needs: python3 pyyaml codex-validator`. `run.sh` reads that line, probes each need once per run, and does not run a test whose need is unmet:

```text
SKIP tests/test-claude-validate.sh (needs claude)
```

The probes live in `run.sh`, one per name: `claude`, `python3`, `shellcheck`, `actionlint`, `shfmt`, `prettier`, `markdownlint-cli2`, `cspell` by `command -v` and, for the six lint and format tools, the first dotted version in the tool's version output compared with the registry (§8.2); `pyyaml` by `python3 -c 'import yaml'`; `codex-validator` by the file at `${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}`. A need that no probe knows is exit 2, so a misspelled need cannot skip a test quietly. The run ends with one line that sums what it did not verify, the shape of the doctor's `for want of:` verdict:

```text
19 passed, 0 failed, 3 skipped for want of: claude, shfmt 3.14.1 (found 3.8.0)
```

Skips never change the exit status, with one flag that inverts it: `tests/run.sh --no-skip` turns every unmet need into `FAIL tests/test-format-shell.sh (needs shfmt 3.14.1; found 0.9.0)` and exits 1. CI runs with it (§9.5). Without the flag a skip is an honest account of a contributor's machine; with it, a skip is a broken installation, which is what it is on a runner that was told to install everything, and a run that verified less than it claims cannot be green there. Running one test directly bypasses the gate and a missing tool then fails loudly, which is acceptable: `run.sh` is the entry point the README names.

Who declares what:

| Test                                                                                                       | Needs                                                           |
| ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `test-claude-validate.sh`, `test-setup-upgrade.sh` (new, §7.2)                                             | `claude`                                                        |
| `test-codex-validate.sh`                                                                                   | `python3 pyyaml codex-validator`                                |
| `test-vendored-duplicates.sh`                                                                              | `python3`                                                       |
| `test-lint-shell.sh` (new, §8.3)                                                                           | `shellcheck`                                                    |
| `test-format-shell.sh`, `test-format-prettier.sh`, `test-lint-markdown.sh`, `test-spelling.sh` (new, §8.3) | `shfmt`, `prettier`, `markdownlint-cli2`, `cspell` respectively |
| `test-workflows.sh` (new, §9.4)                                                                            | `actionlint shellcheck`                                         |
| every other test                                                                                           | nothing beyond §5.1                                             |

Network is not a need. Ten tests fetch from GitHub and three of those run `git ls-remote` on every run; an offline run fails them with `lib.sh`'s "no network, or the pinned sha is gone", which is the right shape, because a pin that could not be verified is not a pin that was skipped.

### 5.3 What leaves

Three `SKIP` branches exist today, and none survives as a branch.

- `tests/test-setup-doctor.sh:34-36`, shellcheck absent: the lint moves to `test-lint-shell.sh` under a need. The `upstream-watch --newest-stable-tag` assertion at `:29-33` sits inside that `if` by accident and moves out, ungated.
- `tests/test-setup-doctor.sh:195`, claude absent: the upgrade-path block becomes `tests/test-setup-upgrade.sh` with `# needs: claude`, so a machine without the CLI skips one file and still runs the engine-shape assertions. Its `node` and `npx` become stubs like the next bullet's, since the pinned lockfile means neither runs; only `claude` is real, because the fixture drives it.
- `tests/test-doctor-faults.sh:212-216`, claude absent: unreachable, because the fixture loop three lines above already fails without `claude`, `node` and `npx`. It is deleted rather than made reachable. The repair fixture links the real three only to satisfy `require_tools`; the seeded registry and the pinned lockfile mean no Claude or skills.sh command ever runs, so stubs that exit 1 serve as well and turn any unexpected invocation into a visible `FAIL:`. The second fixture already stubs `claude` this way. Measured 2026-09-17 in a scratch copy: with the three stubbed the test passes, real `PATH` or not. The test becomes hermetic and declares no need. **Deviation:** the maintainer expected this SKIP to "become a real gate"; making the tool unnecessary is the higher rung. Veto: a `# needs: claude` line restores the gate.

The engine's own `SKIP:` lines that `test-setup-doctor.sh:102`, `:203` and `:221` assert, and the two `NOTE` branches at `:99` and `:200`, stay. They test what the engine prints, not whether a tool is installed.

### 5.4 The result file

`tests/run.sh` writes `tests/results.tsv`, gitignored, overwritten on every run. Line one names the tree: `# aa8e78d dirty 2026-09-17T15:04:05Z`, with `dirty` present only when `git status --porcelain` is non-empty. Then one row per test: path, `PASS`/`FAIL`/`SKIP`, exit status, and the test's last stdout line or the skip reason. CI uploads the file as a build artifact (§9.6).

That is the repository half of #42, and the whole of what the maintainer admitted. A report cites the path or the artifact; a reviewer reads the file. There is nothing to transcribe, so there is nothing to invent. The template half is declined in §12.

## 6. The engine cannot fall silent

### 6.1 Rung 1: every check reports, or the run fails

`ok`, `bad`, `skip` and `note` each increment `REPORTED`. `did` does not; a `DID:` line never stands alone on any path, measured. `main` calls every check through one wrapper:

```sh
run_check() {
  local before=$REPORTED
  "$@"
  [ "$REPORTED" -gt "$before" ] \
    || bad "check $1 reported nothing; this machine is unchecked, not verified"
}
```

No capture and no subshell: the checks run in `main`'s own shell today (`bin/setup:725-731`), and a `$(...)` around them would run each in a child and lose every increment `bad` and `needs` make to `FAILURES`, `UNANSWERED` and `UNCHECKED`. A counter in the parent needs none of that.

The nested calls need the same wrapper at their own sites. `report_only` prints two `NOTE:` lines before it reaches `report_duplicates`, so a wrapper around `report_only` alone would see a count and never notice `report_duplicates` saying nothing; `report_duplicates` wraps `report_pool` for the same reason. Three wrapped sites inside the functions, seven in `main`.

A silent check is `FAIL:` (`bad`), so it counts in "N check(s) failed" and exits 1. It is a defect in the engine, not a tool the machine lacks, which is what the `for want of:` verdict is for. In apply mode `main`'s own pass runs the wrapper too, but its verdict is the child `--check` pass's (`bin/setup:735-736`); a silent check is caught there.

This closes the class, not the instances. The seventh shape, found live on 2026-09-17 and covered by no guard: `upstream/skills.json` whose declared skill names are all empty strings passes `ensure_skills_sh`'s exit-status guard (jq exits 0) and its non-empty guard (each row is `repo<TAB>ref<TAB>`), then every iteration hits `[ -n "$name" ] || continue` at `bin/setup:495`, and the function prints nothing. Under rung 1 that is one `FAIL:` line with no fixture written for it.

### 6.2 Rung 2: `tests/test-doctor-silence.sh`

One file enumerates the unreadable machines and asserts, for each, that `bin/setup --check` exits non-zero and prints no line equal to `clean`. Each fixture is a scratch checkout: a symlinked `bin/setup` beside a corrupted declaration, the shape `tests/test-doctor-faults.sh:92-119` uses today, so the real `marketplace.json` is never touched.

1. A malformed `.claude-plugin/marketplace.json`.
2. A well-formed one with every `git-subdir` entry removed.
3. The first `git-subdir` entry without `.skills`: jq aborts before any row (exit 5, zero rows). A non-zero exit catches it, and a row count would too. This block moves here from `tests/test-doctor-faults.sh:84-119` with its comment corrected, which is #38.
4. The second `git-subdir` entry without `.skills`: jq aborts after thirteen rows (exit 5, thirteen rows). Only the exit status catches it; a row count passes. The shape a counter cannot see, which both issue bodies attributed to the wrong entry.
5. `jq` off `PATH`. Moves here from `tests/test-setup-doctor.sh:63-95`, which is already this fixture for one shape.
6. `sha256sum` off `PATH`.
7. An empty `HOME`.
8. `upstream/skills.json` with all-empty skill names, asserting rung 1's line names `ensure_skills_sh`.
9. A `git-subdir` entry whose `name` is the empty string, asserting the `FAIL:` line names a malformed entry rather than reading the URL as the name (§6.3).

### 6.3 The remaining tab-IFS `read` loops

`ensure_links` was cured in `0aa11d2`: a tab is IFS whitespace, so `read` drops an empty leading field and shifts every later value left, and a first-field guard is then satisfied by the wrong value. Four loops still read that way: `ensure_clones` (`bin/setup:145`), the curated-version loop in `ensure_claude` (`:392`), `ensure_skills_sh` (`:494`) and the Codex cache loop in `report_duplicates` (`:663`). The maintainer named three; the fourth is where the seventh shape lives, and it is the same defect in the same file, so all four get the split `ensure_links` has: `${line%%$'\t'*}` and `${rest#*$'\t'}`, an empty field reported as `bad "... malformed"`, never carried on. Fixture 9 proves it for `ensure_clones`.

### 6.4 The report-only messages (#40)

`report_pool` says how many trees it hashed: `Claude: 104 skill tree(s) hashed; no name resolves to more than one tree`. Trees hashed, not passed, so a `SKILL.md` that `sha256sum` could not read lowers the count instead of hiding inside it. That one sentence retires three of #40's four sites: an empty pool, a Claude pool that lost every plugin skill to a malformed `installed_plugins.json`, and a Codex pool that collapsed. The Codex note is gated on `[ -n "$CODEX_LIST" ]`, the pool being complete, rather than on `have codex`: with `codex` present and `codex plugin list --json` failed, `FAIL: codex plugin list failed` already stands, and the note now stays silent instead of reporting an all-clear over a pool missing its plugin half. `tests/test-doctor-duplicates.sh` keeps passing: it greps the finding lines and the absence of `NOTE: Codex:` without `codex`, none of which move. The fourth site, a registry entry whose install directory is gone, stays declined as #40 records it.

### 6.5 `dirname` (#16, Q12)

`bin/setup:21` and `bin/doctor:4` run the external `dirname` before anything else. Under an empty `PATH` bash prints `<$0>: dirname: command not found` first, and in the documented deployment path `$0` contains `.claude`, so `tests/test-setup-doctor.sh:56`'s `grep -q 'claude'` is satisfied by that line alone. Both sites become parameter expansion, guarded for a `$0` with no slash (`case "$0" in */*) ... ;; *) ... ;; esac`), which are builtins. One more external lookup hides in `bin/doctor`: it `exec`s `bin/setup` through the file's `#!/usr/bin/env bash` line, and `env` resolves `bash` through `PATH`. The doctor therefore becomes `exec "$BASH" "$dir/setup" --check "$@"`, `$BASH` being the running shell's own path, which is why the test already invokes both scripts as `/bin/bash <script>`. Then `bin/setup` refuses under an empty `PATH` with nothing but its own refusal, and `bin/doctor` survives it: every check opens on `needs jq`, the skill root is reported missing, and the verdict is `for want of: jq`, exit 1. The test's comment that the doctor is exercised under an empty `PATH` becomes true instead of deleted, and the refusal grep tightens to the refusal's own words. `tests/test-setup-doctor.sh:39-40`'s shape assertions on the doctor (six lines at most, invokes `--check`) still hold.

## 7. Tests that were wrong or vacuous

### 7.1 Manifests that can disagree (#1)

In `tests/test-references-resolve.sh`, for each plugin: `name`, `version`, `author`, `homepage`, `repository`, `license` and `keywords` equal between `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json`, compared as one projected object under `jq -S`. `description` is excluded on purpose: `software-dev`'s two differ ("and its inspector" on the Claude side, because the subagent ships only there) and `tests/test-hook.sh:83-88` guards that direction. The Codex manifest's `skills` pointer must resolve to a directory (item 3 of the issue). In `tests/test-codex-marketplace.sh`, which already holds both files, each `.agents/plugins/marketplace.json` entry's `category` equals its Codex manifest's `interface.category`; the Claude marketplace uses a different vocabulary (`development` against `Developer Tools`) and is not mapped. `tests/test-claude-validate.sh:12`'s `|| continue` becomes `|| fail`, matching its Codex sibling.

`tests/test-hook.sh:79-80` pin both `software-dev` manifests to the literal `0.7.0`. They go: the equality check catches the drift they caught by accident, every other version-aware test reads the manifests, and the literal breaks on every release. **Deviation:** the maintainer's answer on the version bump said the assertion is "updated in the same commit"; deleting it is the smaller standing cost. Veto: keep the two lines and bump them.

Each guard is proved by the mutation the issue names: drift one key, add a `plugins/ghost/` with only a Codex manifest, move `plugins/sensemaking/skills` aside, break a category. The suite must fail naming the file, then the mutation is reverted.

### 7.2 `tests/test-setup-doctor.sh` (#16)

Every unguarded `cp`, `mkdir`, `ln`, `cat >` and bare `$(...)` capture in the file gets `|| fail` or the `if out="$(...)"` form, not only the four the issue counted; the sensemaking additions doubled them by copying the pattern. The comment at `:51-53` ("every capture below is wrapped in `if`") narrows to the commands meant to exit non-zero. The comment at `:131-134` about a github-source clone being stale goes; nothing here measures that, and `ensure_fresh_clone` carries its own account. The upgrade-path block (`:106-196`) becomes `tests/test-setup-upgrade.sh` (§5.3). The shellcheck block becomes `tests/test-lint-shell.sh` (§8.3).

### 7.3 The README extractor (#18)

`extract_scoped_blocks` resets scope on `/^## /` only. A `###` under `## Install` stays in scope, which the issue calls a defect, and a `#` h1 after it leaks too, which the issue missed. The regex becomes `/^##? /`: an h1 or h2 closes the scope, an h3 stays inside its parent, which is what "every fenced block in the Install and Update sections" means. Proved against a synthetic README carrying all three headings.

The LICENSE comma (`plugins/software-dev/LICENSE:55`) and the `Note:` commit for `4b23edc` are declined in §12. The plugin README's "on Codex too" sentence is milestone 7's, per the milestone note.

### 7.4 `payload-rules.md` against its spec (#43)

`tests/test-hook.sh` extracts the fenced block under `### 4.2` of [the hook design](2026-09-04-session-start-hook-design.md), guarded the way `require_once` guards a sentinel: the heading matches exactly once and a fence pair follows it, so a vanished heading cannot pass on two empty strings. The block and `plugins/software-dev/hooks/payload-rules.md` are diffed byte for byte through process substitution, the form `tests/test-vendored-scaffolder.sh:194-200` uses between two live files. Three of today's five shape checks are subsumed and go: the one-trailing-newline pair at `:43-44`, `worktree` at `:45`, the `superpowers:brainstorming` exclusion at `:46`. The curated-list loop at `:47-52` stays, because it cross-checks the marketplace, which the spec cannot.

That spec is therefore maintained, not frozen, until converted into a plan and implemented; at that point it becomes a historical record. `a3c797f` already amended its §4.2 when the plugin was renamed, and its message states the wrong rule: specs move when the tree moves, plans do not. The same change corrects the two figures the rename left behind: §4.3's `3,343` and `387` bytes are `3,335` and `379`, the emitted string `3,714` bytes and `3,702` code points; §12's `3,343` is `3,335`. Its Status line gains one sentence saying §4.2 is read by a test. `tests/test-links-resolve.sh:6-9`, which calls specs "never amended after the fact", is reworded to the same rule. Specs and plans can be amended after implementation to keep them readable; for example, when a file's name changes, never keep them as a living document that moves when the tree moves. 

### 7.5 Comments describing replaced code (#40)

`tests/test-codex-validate.sh:31` ("is not the one recorded exception") names three; `:38` ("both greps exit 1") describes one grep, since the no-bullets case is caught at `:34`.

### 7.6 Portable tests (#5)

`mapfile` at `tests/test-upstream-pin.sh:14` becomes a `while IFS= read -r` loop into the array; `find -printf '%f\n'` at `tests/test-upstream-pin.sh:24` and `tests/test-vendored-scaffolder.sh:209,217` becomes a glob loop printing `${d%/}` basenames. Three sites, mechanical, and no probe for GNU `find` joins the gate. `sha256sum` and `readlink -f` stay: they are the engine's, and the engine is not what #5 is about.

### 7.7 The link check gains a subject

Over `checked '*.md'`, `tests/test-links-resolve.sh` finds 23 relative markdown links where it found none: 20 resolve, and 3 are broken, all the same one. `docs/superpowers/plans/2026-09-04-session-start-hook.md` links its spec three times by bare filename, which resolves against `plans/`; the spec sits in `../specs/`. The commit that widens the scope fixes those three paths. A link path in a frozen plan is not its prose. The rewrite over backticked paths, the form this repository's references actually take, is [#59](https://github.com/eranroseman/agent-plugins/issues/59) and not this design.

## 8. Formatters, linters, spelling (#29)

### 8.1 What each type gets

| Type      | N   | Formats                                                    | Lints                                         | Spelling                                                |
| --------- | --- | ---------------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| shell     | 26  | `shfmt -i 2 -ci -bn`                                       | `shellcheck -e SC1091 -e SC2016`              | `cspell`, `#` comments only                             |
| JSON      | 8   | `prettier`                                                 | the two validators, `test-json-wellformed.sh` | none                                                    |
| YAML      | 5   | `prettier`                                                 | `actionlint`, the two workflows               | `cspell`, `#` comments only                             |
| markdown  | 27  | `prettier`, `proseWrap: preserve`, embedded code untouched | `markdownlint-cli2`, MD013/MD033/MD041 off    | `cspell`, `en-US`, outside the three record directories |
| Python    | 2   | none                                                       | none                                          | none; `ast.parse` in the fork's drift test              |
| no parser | 4   | none                                                       | none                                          | none                                                    |

Measured at `aa8e78d`, plus this spec, on 2026-09-17 with the candidate versions of §8.2:

- `shfmt -i 2 -ci -bn` rewrites 17 of the 26 shell files, 272 changed lines, none inside a heredoc body. On the reformatted tree `tests/test-setup-doctor.sh`, `tests/test-doctor-faults.sh` and `tests/test-doctor-duplicates.sh` pass and shellcheck is clean. The flag set is D's, chosen there by measurement as the closest to the existing code; `-sr` was dropped because it restyled a further 140 lines.
- `prettier` with `proseWrap: preserve` and `embeddedLanguageFormatting: off` changes 20 of the 40 markdown, JSON and YAML files, 1,020 lines: 17 markdown files, 12 of them under `docs/`, where table padding and `*em*` becoming `_em_` account for 945 of the lines; three JSON (`upstream/skills.json` among them); no YAML. `AGENTS.md` and `hooks/payload-rules.md` are unchanged, which §8.4 depends on. In one plan, nine paragraphs followed by a bare `---` are setext headings to CommonMark and are rewritten as `##` headings, which is what the renderer already showed (D §2.1).
- `markdownlint-cli2` with the three rules off reports 224 findings before prettier and **67 after**: 25 MD040 (a fence with no language), 14 MD038 (a space inside a code span), 8 MD003, 7 MD029, 7 MD026 (a heading ending in a full stop; the setext headings above, seven of which end that way), and six singletons. 61 of the 67 sit under `docs/`, 56 of them in four plans; the other 6 are fence languages in shipped files. Formatter first, then linter: prettier retires 157 findings free, every MD032, MD049, MD009 and MD022 among them. The 67 are fixed by hand once; a fence language, a code-span space or a heading's full stop in a plan is not its content. Veto: a per-directory `.markdownlint-cli2.jsonc` under `plans/` switching those rules off, at the cost of a second configuration file.
- `cspell` `en-US`, code ignored, over the fifteen markdown files in scope (the twelve outside `docs/` and the three under `docs/agents/`): 77 hits, about 33 distinct words, not one a typo. Four are British spellings (`behaviour`, `organisational`, `recognises`, `summarise`); the rest are proper nouns (`eranroseman`, `Akhourii`, `mattpocock`, `obra`, `primeradiant`), domain terms (`sensemaking`, `scaffolder`, `wayfinder`, `worktrees`, `diffable`) and coinages (`custodied`, `relitigated`, `repointed`, `unrouted`). That is the dictionary. The scope is the case for itself: `docs/research/` alone adds 123 hits, 61 words and 15 British forms, and `docs/superpowers/` alone 693 hits and 127 words, a record's vocabulary being its author's and every new record growing the list with words no shipped file uses; `docs/archive/` adds two words and is out on the same principle. The scope is a pathspec handed to `checked`, `':(exclude)docs/superpowers' ':(exclude)docs/research' ':(exclude)docs/archive'` (since 2026-09-20 only `':(exclude)docs/superpowers'`: `docs/research/` was folded into #47 and `docs/archive/` into this repository's roster spec §8.2 and #64, and both directories were deleted), an argument rather than an ignore file. Comments in the 26 shell and 5 YAML files are read through an `overrides` entry with an `includeRegExpList` for `#` lines, D's ruling; D measured 62 hits and 27 words there, eight not already in the markdown list.

The locale is `en-US`. The prose is mixed today (`behavior` and `normalization` sit in the same skills as the four British spellings), which is the case for choosing, and everything this repository embeds is American. A spelling correction inside an authored skill is an edit to the skill and goes through `superpowers:writing-skills`, as any other skill edit does.

Configuration lives in four files, each carrying the reason beside the setting: `.prettierrc.yaml` (`proseWrap: preserve` for §8.4; `embeddedLanguageFormatting: off` because fenced blocks quote other files verbatim, and the README recipes are compared byte for byte against `bin/setup --help`), `.markdownlint-cli2.jsonc` (three rules off, no globs), `cspell.json` (locale, words, the comment override; the scope lives at the call site, not here), and the `shfmt` flags in one variable in `tests/lib.sh` read by the test and by `bin/format`. No per-tool ignore file: `.prettierignore`, `.markdownlintignore` and cspell's `ignorePaths` would each restate §4's list, which is #27's defect four times over. Every tool receives explicit paths from `checked`.

### 8.2 The registry, and versions

Formatter output varies by version, so CI and a local run must agree on the version or the check is two checks. `tests/tools.txt` declares the six tools the suite may need, one per line: name, version, and for the three release binaries the sha256 of the linux-amd64 asset:

```text
# tool  version  sha256 of the linux-amd64 release asset (- for npm packages)
shellcheck         0.9.0    (recorded by the plan)
actionlint         1.7.12   (recorded by the plan)
shfmt              3.14.1   (recorded by the plan)
prettier           3.9.6    -
markdownlint-cli2  0.23.2   -
cspell             10.2.2   -
```

The third column is filled when the plan pins the versions. `actionlint` publishes a checksum file with its releases and its recorded sha256 is verified against it when the plan pins it; `shfmt` and `shellcheck` publish none, so theirs are pins taken from the first download and held from then on.

`run.sh` compares each tool's version with its line and skips on mismatch, naming both: `SKIP tests/test-format-shell.sh (needs shfmt 3.14.1; found 3.8.0)`. CI installs exactly the file's contents (§9.5). `shellcheck` and `actionlint` join the registry although only `shfmt` and the three npm tools were asked about: the principle is the same, a check against an unpinned tool can disagree with itself, and D measured shellcheck 0.9.0 and 0.10.0 agreeing on this tree, which makes the pin cheap today rather than unnecessary.

The versions above are candidates, read on 2026-09-17: the three npm tools at the versions the measurement pass cached, `actionlint` and `shellcheck` at the versions installed here, `shfmt` at its newest release because no measured binary exists on this machine and apt's 3.8.0 is two years old. The registry, not this spec, is the record; the plan pins whatever the reformat commit was produced with. Locally the three npm tools install with `npm install -g` and the three binaries from their release pages; the README says so in one line and names the file (§10.1).

### 8.3 Where the checks run, and `bin/format`

Six test files, one tool each, so a contributor lacking one tool skips one file:

- `tests/test-lint-shell.sh`: `shellcheck -e SC1091 -e SC2016` over the shell list, moved from `test-setup-doctor.sh:14-27` with its comment.
- `tests/test-format-shell.sh`: `shfmt -d` with the pinned flags over the same list.
- `tests/test-format-prettier.sh`: `prettier --check` over the three prettier lists.
- `tests/test-lint-markdown.sh`: `markdownlint-cli2` over `checked '*.md'`.
- `tests/test-spelling.sh`: `cspell` over the markdown list and, for comments, the shell and YAML lists.
- `tests/test-workflows.sh`: §9.4.

`bin/format` applies what the first three check: `shfmt -w`, `prettier --write`, then `markdownlint-cli2 --fix`, over the same lists, sourcing `tests/lib.sh` for `checked`. No check mode of its own: the tests are the check. No pre-commit hook: the suite is the gate.

The one-time reformat lands as its own commit, separate from the mechanism, verified by the full suite rather than by reading 1,300 changed lines. The hand corrections follow in a third commit: the 67 markdownlint findings, the four spellings, the dictionary, and the three link paths of §7.7.

### 8.4 Couplings

Three byte-equalities cross a boundary, and each needs to be known rather than ruled on.

- **`AGENTS.md` ↔ the vendored scaffolder.** `tests/test-vendored-scaffolder.sh:194-200` holds two sections of `AGENTS.md` byte-identical to a block inside `setup-repository/SKILL.md`, which is vendored and unformattable. Prettier leaves `AGENTS.md` unchanged today only because `proseWrap` is `preserve`; with `always` the formatter and the drift test become mutually unsatisfiable. The setting is pinned with that sentence beside it.
- **`hooks/payload-rules.md` ↔ the hook spec's §4.2.** Both sides pass through the same prettier run, so the formatter cannot separate them; only a hand edit to one side can, and `tests/test-hook.sh` catches it. Prettier changes neither today.
- **Lines tests pin byte for byte inside shipped files.** `tests/test-plugin-skills.sh:30-31` and `:64-66` grep exact lines of authored `SKILL.md` and `openai.yaml` files; `tests/test-hook.sh` reads `payload-rules.md` whole. Prettier's defaults satisfy every one of them today, measured. Recorded so that a version bump of a formatter that stops satisfying one is read as a coupling, not a mystery.

## 9. CI

### 9.1 Least privilege and pins (#3's bundle, #6 item 1)

`validate.yml` gains `permissions: contents: read` at workflow level, the smaller change with two jobs; `upstream-watch.yml` already scopes its own. Every `uses:` in both files, six sites, is pinned to a 40-character sha with the tag in a trailing comment, in a repository that pins `obra/superpowers`, `mattpocock/skills` and the Codex validator the same way. Each `actions/checkout` step sets `persist-credentials: false`; nothing here pushes, and the default writes the token into `.git/config`. `pip install pyyaml` becomes `pip install pyyaml==<version>`, the workflow's one unpinned install. The `claude-code@2.1.220` pin, present in both jobs, stays: it is the version the engine's design was measured against, and moving it is not this spec's business.

### 9.2 One validator, two copies, both checked (#3)

`tests/test-codex-validate.sh` keeps reading the validator from the local default path or `CODEX_PLUGIN_VALIDATOR`, and now asserts the sha256 of **both** `validate_plugin.py` and `identifier_validation.py` against two constants recorded from `openai/codex` at `f3f6922519fa38487c8250c2b8a670a39a2cf9ff`, the sha CI fetches. CI today records an md5 for one file only. A mismatch is:

```text
FAIL: validate_plugin.py at <path> is not the copy CI pins (openai/codex@f3f6922…); re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a copy fetched by the recipe in .github/workflows/validate.yml
```

An absent file is the gate's `SKIP` (§5.2), whose text names the same recipe, which closes #7's "the failure message does not say where to get the file" on both paths. CI keeps its fetch step and its `CODEX_PLUGIN_VALIDATOR` export, so CI and a local run assert the same two constants against their own copies: one source of truth, no network on a local run. The day `codex-cli` moves the local files, the local suite fails on that line and the message says what to do. **Deviation:** the ruling said md5; sha256 is used because `sha256sum` is already the repository's one hashing tool. Veto: md5 constants instead.

### 9.3 Triggers (#8)

`push` stays unfiltered by branch, since it is the only coverage feature branches get, and `pull_request` stays for the contributor PR this public repository has not yet received. Neither gets a path filter.

The first answer was `paths-ignore: ['docs/**']`, given on the fact that no test read anything under `docs/`. §7.4 changed that fact: `tests/test-hook.sh` reads the hook spec, so a push editing its §4.2 would have skipped CI while the suite went red on the next code push. GitHub's `paths` filter can re-include one file after `!docs/**`, and a test could have held that list honest, but the filter's whole yield was measured the same day: a full run is 45 to 60 seconds across two jobs, 9 of the last 30 commits on `main` were docs-only, and runner minutes are free on a public repository. About a minute and a dozen upstream fetches per docs push, against a negated pattern list, a guard test, and fifteen files outside every check. The maintainer dropped the filter, and the `docs/` exclusion class the first draft of §4 carried went with it.

### 9.4 `tests/test-workflows.sh` (#28, #6)

`# needs: actionlint shellcheck`. `actionlint` runs shellcheck over every `run:` block when shellcheck is on `PATH` and quietly does not when it is absent, so both are needs. Measured on 2026-09-17: actionlint 1.7.12 reports zero findings on the two workflows, surfaces an injected SC2086 tagged `[shellcheck]`, and flags neither a missing `permissions:` block nor a floating `actions/*` tag nor an unresolvable `uses:`. #28's "would catch #6" is false, so the two properties get a guard of their own, beside actionlint, with no new dependency:

- every `uses:` line in `.github/workflows/*.yml` ends in `@` followed by forty hex characters;
- every workflow has `permissions:` at the top level;
- every `actions/checkout` step carries `persist-credentials: false`.

Proved by mutation: an unquoted expansion in a `run:` block fails naming the workflow and line; a `@v4` fails; a deleted `permissions:` fails.

### 9.5 Installing the tools

One step reads `tests/tools.txt`: `npm install -g` for the three npm packages at their exact versions, and for `shellcheck`, `actionlint` and `shfmt` a download of the linux-amd64 release asset checked against the recorded sha256 before it is placed on `PATH`. The downloads go on `$GITHUB_PATH` ahead of the image's own tools: `ubuntu-latest` ships a shellcheck, and one that shadowed the pinned copy would fail the version probe and, without the flag below, skip the lint under a green run. The `command -v shellcheck || apt-get install` line goes with its comment: a pinned download replaces a workaround for the SKIP it was defeating. `setup-node` and `setup-python` stay for `claude` and the validator.

The static-checks step runs `tests/run.sh --no-skip` (§5.2). An unmet need in CI is then a failed install, reported by name with the version found, never a skip that leaves the run green.

### 9.6 The result artifact

After `tests/run.sh`, a sha-pinned `actions/upload-artifact` step with `if: always()` uploads `tests/results.tsv`, so a CI claim is citable the way a local one is.

## 10. The README's Checks section, and the release

### 10.1 Checks (#7)

The section is rewritten to say what runs and what it needs, without counts that rot:

- `tests/run.sh` needs `bash` 4 or later, `jq` and `git`, and refuses with the list otherwise.
- Some checks need a tool the machine may lack; each is skipped with a line naming the tool, and the run ends by summing what it did not verify. The versions those checks are held to are in `tests/tools.txt`; the three npm tools install with `npm install -g`, the three binaries from their release pages.
- The Codex manifest check needs `python3` with `pyyaml` and the validator that `codex-cli` installs, or a copy fetched by the recipe in `.github/workflows/validate.yml`.
- The pin and drift checks fetch from GitHub; offline, they fail rather than skip.
- Every run writes `tests/results.tsv`; a report cites it.
- `bin/format` rewrites what the format checks check.
- CI runs the same script with `--no-skip`, so nothing is skipped there, uploads the result file, and runs `bin/setup` end to end against a scratch `HOME`.

The user-facing prerequisites of `bin/setup` are already correct and do not change.

### 10.2 The version bump

Formatting a shipped file changes the shipped plugin, and `version` is the only thing that moves an installed copy. At the branch's end, one commit: `software-dev` `0.7.0` → `0.7.1` and `sensemaking` `0.2.0` → `0.2.1`, both manifests each. §7.1's equality check guards the pairs; no test carries the literal any more.

## 11. Sequencing and the gate

Branch `suite-and-ci` from `main`. Milestone 1 first, a gate, then milestone 2, a gate, one merge.

1. **Ownership.** `checked()` and `EXCLUDED` in `tests/lib.sh`; `test-json-wellformed.sh`, `test-links-resolve.sh` and the shellcheck list adopt it; `test-ownership.sh`. Red first: the JSON check must report eight files where it reported seven, and the link check must fail on the three plan links of §7.7.
2. **The suite tells the truth.** The gate in `run.sh` with its probes and the result file; `# needs:` headers; the three splits (`test-setup-upgrade.sh`, `test-lint-shell.sh`, the hermetic repair fixture); #5's three sites; #16's guards and comments; #18's extractor; #1's assertions; #43's extraction and the spec amendments; #40's two comments.
3. **The engine.** §6.5's `dirname`; the four loop splits; the two report-only messages; rung 1; `test-doctor-silence.sh` with its nine fixtures, taking the two blocks that move into it. Rung 2 lands before rung 1 and guards its edit to `main`.
4. **Gate 1.** Full suite green locally with `tests/results.tsv` cited; CI green on the branch.
5. **Tools.** The four configuration files, `tests/tools.txt`, `bin/format`, the five tool tests, the CI install step. Red on arrival. Then the reformat, one commit; then the hand corrections, one commit.
6. **CI.** Pins, `permissions:`, `persist-credentials`, `pyyaml`, `test-workflows.sh`, the artifact upload.
7. **Checks section**, then the version bump.
8. **Gate 2**, the same evidence as gate 1, then merge to `main` and push in the same motion.

Every guard is added red first, by the mutation its issue names, and the plan cites the result file for each green rather than transcribing output.

## 12. Positions not adopted, and the three deviations

Declines, each with its home here so the workspace can close:

- **#42's template half.** Upstreaming, vendoring or locally prompting `subagent-driven-development` to cite artifacts: the maintainer ruled no skill edit and no prose rule. The result file is the whole answer.
- **Hard fail on every absent tool** (D §5.1): superseded by one gate with declared needs.
- **GNU/Linux declared and probed** (D §5.1, #5): superseded by making the three sites portable.
- **The validator fetched by the test** (D §5.1, #3): superseded by the hash assertion at the local path, which needs no network.
- **Dropping `pull_request:`** (#8 option 1): kept.
- **A path filter on the CI triggers** (#8 option 2, and the first answer to G2 Q8): dropped on the measurement in §9.3, and the `docs/` exclusion class the first draft of §4 carried went with it.
- **Spell-checking the records under `docs/`**: `superpowers`, `research` and `archive` stay outside cspell's scope (§8.1); the dictionary would triple with words no shipped file uses.
- **`zizmor` as a running tool** (Q10 b): its three actionable classes are two regexes and one hand edit.
- **Per-tool ignore files**: one derivation instead.
- **A `Note:` commit for `4b23edc`**: history is history; one more object to explain a count.
- **The LICENSE comma** (`plugins/software-dev/LICENSE:55`): present since the line's first commit, in this repository's own attribution prose, not in any upstream license text; three of the four attribution blocks use the comma form and `tests/test-vendored-diagnosing-bugs.sh:76` greps one of them. Restoring the plan's literal wrap breaks `tests/test-vendored-scaffolder.sh:221`. Declined as moot; the issue's "re-wrap" wording is corrected when it closes.
- **The second-entry fixture in `test-doctor-faults.sh`**: in the silence test instead, where the shapes live together.
- **`dependabot.yml` for actions** (D §6): a stale sha pin is the watch surface's business (§14).
- **A network-test count in the README**: eliminated rather than corrected again.

Deviations from an answer, each with its veto line in place: the hermetic repair fixture instead of a `claude` gate (§5.3); deleting `test-hook.sh`'s version literals instead of bumping them (§7.1); sha256 instead of md5 for the validator (§9.2).

## 13. Mechanism claims and their sources

| Claim                                                                                                                                                                                                  | Source, read or run 2026-09-17                                                                           |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| The checks run in `main`'s own shell with no capture; `bad` and `needs` mutate `FAILURES`, `UNANSWERED`, `UNCHECKED` there; a `$(...)` wrapper would lose them                                         | `bin/setup:61-86`, `:725-731`; fact-finding, #41                                                         |
| `DID:` never stands alone                                                                                                                                                                              | fact-finding, #41, every `did` call site                                                                 |
| Apply mode's verdict is the child `--check` pass's                                                                                                                                                     | `bin/setup:733-737`                                                                                      |
| Stripping `.skills` from the first entry: jq exit 5, zero rows; from the second: exit 5, thirteen rows                                                                                                 | fact-finding, #41, measured                                                                              |
| All-empty skill names in `skills.json` pass both guards and print nothing                                                                                                                              | fact-finding, #41, measured live; `bin/setup:492-495`                                                    |
| `read` with a tab IFS drops an empty leading field                                                                                                                                                     | `bin/setup:224-231`, the comment `0aa11d2` wrote; four remaining loops at `:145`, `:392`, `:494`, `:663` |
| Under an empty `PATH`, `bin/setup` prints `<$0>: dirname: command not found` before its refusal; `$0` contains `.claude` in the deployment path                                                        | fact-finding, #16                                                                                        |
| `test-doctor-faults.sh` passes with `claude`, `node`, `npx` stubbed in the repair fixture                                                                                                              | scratch copy, `/tmp/faults-stub-probe`, exit 0                                                           |
| The hook spec's §4.2 fence is the only ` ```markdown ` fence in the file; the block and `payload-rules.md` are 379 bytes and identical; §4.3's figures are stale by the rename's eight bytes           | fact-finding, #43; `wc -c`                                                                               |
| A full CI run is 45 to 60 s across two jobs; 9 of the last 30 `main` commits were docs-only; the repository is public                                                                                  | `gh run view`, `git log --name-only`, `gh repo view`                                                     |
| actionlint 1.7.12 runs shellcheck over `run:` blocks (SC2086 mutation surfaced), flags neither `permissions:` nor floating tags nor unresolvable `uses:`                                               | fact-finding, #28, measured                                                                              |
| `prettier --check` on a file with no parser exits 0                                                                                                                                                    | D §5.2, prettier 3.3.3                                                                                   |
| 95 tracked files with this spec; 23 vendored; 72 checked, 26 of them shell and 27 markdown                                                                                                             | `git ls-files` at `aa8e78d` plus this file                                                               |
| `shfmt` v3.14.1 `-i 2 -ci -bn`: 17 of 26 files, 272 lines; three engine tests and shellcheck pass after                                                                                                | release binary in `/tmp`, scratch copy                                                                   |
| prettier 3.9.6: 20 of 40 files, 1,020 lines, 945 of them under `docs/`; `AGENTS.md`, `payload-rules.md` unchanged                                                                                      | `npx prettier@3.9.6 --list-different`, and `diff` per file                                               |
| markdownlint-cli2 0.23.2: 224 findings before prettier, 67 after, 61 of them under `docs/`                                                                                                             | `npx markdownlint-cli2@0.23.2` on the tree and on a formatted scratch copy                               |
| cspell 10.2.2 `en-US`: 77 hits and about 33 words over the 15 files in scope, four British; `docs/research/` alone 123 hits, 61 words, 15 British forms; `docs/superpowers/` alone 693 hits, 127 words | `npx cspell@10.2.2 --words-only`, per directory                                                          |
| 23 relative markdown links in the 27 authored markdown files; 3 broken, all in one plan                                                                                                                | each resolved by hand against its document's directory                                                   |
| Newest releases: shfmt v3.14.1, actionlint v1.7.12, shellcheck v0.11.0; npm prettier 3.9.8, markdownlint-cli2 0.23.2, cspell 10.3.3; installed here: shellcheck 0.9.0, actionlint 1.7.12               | `gh api …/releases/latest`, `npm view`, `--version`                                                      |
| The local `npx` cache holds prettier 3.9.6, markdownlint-cli2 0.23.2, cspell 10.2.2                                                                                                                    | `~/.npm/_npx/*/package.json`                                                                             |
| Ten tests reach the network; three run `ls-remote` on every run                                                                                                                                        | fact-finding, #7, per file                                                                               |
| `git ls-files` does not list `.kilo/worktrees/brass-settee`; it is excluded through `.git/info/exclude`                                                                                                | `git status --ignored`                                                                                   |

## 14. Open items carried forward

- **`.claude-plugin/marketplace.json`'s `$schema` URL is a 404** (D §5.3); one line pointing at SchemaStore would let editors validate. Not a gate; filed as [#58](https://github.com/eranroseman/agent-plugins/issues/58).
- **`bin/setup` has no bash-4 probe of its own.** On bash 3.2, `local -A` in `report_pool` fails and the array degrades silently. Two lines in `require_tools` and one `needs`-style guard in `report_pool`; milestone 4, beside #17.
- **A sha-pinned action goes stale the same way an upstream pin does.** The watch surface (milestone 4, the class #56 names) is where it belongs, not `dependabot.yml`.
- **`tests/test-links-resolve.sh` was satisfied by documents with no links.** Widened, it has 23 links and three day-one reds (§7.7). D §5.4's rewrite over backticked paths, the form this repository's references actually take, is not adopted here; filed as [#59](https://github.com/eranroseman/agent-plugins/issues/59) and corrected there the same day.
- **`docs/agents/*.md` are byte-identical to the scaffolder's templates** and will diverge, since the template cannot be repaired and the copies are meant to be edited. Both sides have a mechanism; no rule (D §8).
- **#21 may devendor `payload.md` or `setup-repository/SKILL.md`.** That edits `EXCLUDED` and nothing else.
- **`CONTEXT.md`** is a placeholder in the checked set; #26 writes it.
