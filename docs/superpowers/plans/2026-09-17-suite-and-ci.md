# The Suite Tells the Truth, and CI Checks What We Own — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every way `tests/run.sh` or `bin/doctor` can pass for the wrong reason, then build the substrate that keeps it closed: one ownership derivation, one prerequisite gate with declared needs and a result file, an engine that cannot fall silent, pinned formatters and linters over the files we own, least-privilege CI with pinned inputs, and a README Checks section that describes the suite as it stands.

**Architecture:** Every list of "the files we own" comes from one function in `tests/lib.sh` over `git ls-files`, minus six vendored patterns each paired with the drift test that guards it. `tests/run.sh` holds three things hard (`bash` 4, `jq`, `git`), reads a `# needs:` line from each test's header, probes each need once, skips an unmet one (or fails it under `--no-skip`, which CI runs), and writes `tests/results.tsv` for reports to cite. `bin/setup` counts every report line and brackets every check, so a check that prints nothing is a `FAIL:`; four tab-IFS `read` loops become parameter-expansion splits; both scripts stop calling `dirname`. Milestone 2 adds four configuration files, a version registry, `bin/format`, six one-tool tests, sha-pinned actions with `permissions:` and `persist-credentials: false`, and a CI step that installs exactly the registry's versions ahead of the image's own.

**Tech Stack:** bash (no `set -e` in the engine; `set -euo pipefail` in the tests), jq, git, `sha256sum`, shellcheck 0.9.0, actionlint 1.7.12, shfmt 3.14.1, prettier 3.9.6, markdownlint-cli2 0.23.2, cspell 10.2.2, Claude Code CLI 2.1.220 (CI) / 2.1.273 (local), codex-cli 0.147.0, GitHub Actions, `gh`.

**Spec:** `docs/superpowers/specs/2026-09-17-suite-and-ci-design.md`. Section numbers below (§4, §5.2, §6.1, …) refer to it. The design it supersedes, _Repository quality gates_ (D), is recoverable as `2825752:docs/superpowers/specs/2026-09-06-repository-quality-gates-design.md`. `docs/superpowers/plans/2026-09-05-setup-and-drift.md` is the house style this plan follows.

**One plan, not two.** The maintainer ruled one spec, one plan, one branch (§3, source M): milestone 1 then milestone 2, a gate after each, one merge. Each half consumes the other — the ownership derivation feeds the formatters, the gate is what every new tool test passes through, and CI is where the new fixtures are proved on a machine nobody configured — so the split point would fall in the middle of a dependency.

## What was verified while planning (2026-09-17, tree at `55f1bcc`)

Every count and exit status below was measured in this checkout or in a scratch copy (`git archive HEAD` into `/tmp/fmt-probe`), not taken from the spec; where the two differ the plan says so.

- **Files.** `git ls-files` lists 96 paths in the main checkout's index: the 95 at `aa8e78d` plus this spec, plus a staged, uncommitted `docs/Professional-Editorial-Standards-2024.md` that is not this plan's (see Global Constraints). The six vendored patterns match 23. Of the 72 checked files (73 with the staged one): 26 shell by shebang (`#!/usr/bin/env bash`; `bin/*` and `hooks/session-start` have no extension), 8 JSON, 5 YAML, 27 markdown, 2 Python, 4 with no parser (`.gitignore`, three `LICENSE`).
- **shfmt 3.14.1 `-i 2 -ci -bn`** rewrites 17 of the 26 shell files, 272 changed lines. shellcheck 0.9.0 with `-e SC1091 -e SC2016` is clean before and after. On the reformatted scratch tree `test-doctor-faults.sh`, `test-doctor-duplicates.sh`, `test-json-wellformed.sh`, `test-references-resolve.sh`, `test-codex-marketplace.sh` and `test-plugin-skills.sh` pass.
- **prettier 3.9.6** with `proseWrap: preserve` and `embeddedLanguageFormatting: "off"` changes 20 of the 40 JSON, YAML and markdown files, 1,018 lines; `AGENTS.md`, `hooks/payload-rules.md` and `docs/agents/*.md` are unchanged, which §8.4 and §14 depend on. `prettier --check` on a file it has no parser for (`bin/setup`) exits **2** — D §5.2 measured 0 on 3.3.3, which is stale — but on an **empty file list** it exits **0** with only a stderr complaint. The non-empty guard at every call site exists for the second case.
- **markdownlint-cli2 0.23.2** with MD013, MD033 and MD041 off: 67 findings after prettier (25 MD040, 14 MD038, 8 MD003, 7 MD029, 7 MD026, 2 MD034, 1 each MD046, MD028, MD004, MD001), 61 of them under `docs/`. `--fix` retires 31 and leaves 36: 25 MD040, 8 MD003, MD046, MD028, MD001, listed by file in Task 20. MD041 without the override fires on `AGENTS.md` (opens at `##`, the scaffolder's template shape), `CLAUDE.md` (`@AGENTS.md`), `CONTEXT.md`, the archived design, and every `SKILL.md` and agent file that opens with a paragraph after its frontmatter.
- **cspell 10.2.2 `en-US`** over the 15 markdown files in scope: 77 hits, 31 distinct words, four British (`behaviour`, `organisational`, `recognises`, `summarise`), the rest proper nouns, domain terms and coinages. Over the 26 shell and 5 YAML files through a `#`-comment override: 58 hits, 27 words, four British (`behaviour`, `canonicalises`, `Serialised`, `synthesise`). A config file placed **outside** the repository silently checked whole files, because `overrides.filename` globs resolve relative to the config's directory; the config therefore lives at the repository root and every tool test runs from `REPO_ROOT`.
- **actionlint 1.7.12** reports zero findings on both workflows.
- **`bin/setup` under an empty `PATH`** prints `bin/setup: line 21: dirname: command not found` before `ERROR: bin/setup needs these on PATH: git jq node npx claude`, exit 2. `bin/doctor` there prints the same `dirname` line and then `bin/doctor: line 4: /setup: No such file or directory`, exit 127. `$BASH` is `/bin/bash` when the script is invoked as `/bin/bash <script>`; a six-line doctor built on `${0%/*}` and `exec "$BASH"` is shfmt-stable and runs under `env -i PATH=/nowhere`.
- **jq shapes.** `.skills` deleted from the first git-subdir entry: exit 5, 0 rows. From the second: exit 5, 13 rows. `upstream/skills.json` with every skill name empty: exit 0, rows of the form `mattpocock/skills<TAB>v1.2.3<TAB>`. A git-subdir entry with `name: ""` fed to today's tab-IFS `read` in `ensure_clones` yields `name='https://…/superpowers.git' url='main' sha='skills'`: the shift §6.3 describes.
- **The hook payload.** `payload.md` is 3,335 bytes, `payload-rules.md` 379, the emitted string 3,714 bytes and 3,702 code points: exactly the corrections §7.4 makes to the hook design's §4.3. `payload-rules.md:3` carries `recognises`; `recognizes` is the same length, so those figures survive the spelling fix.
- **`claude` is an ELF binary here** (`~/.local/bin/claude`) but a `#!/usr/bin/env node` script wherever it is installed with `npm install -g`, which is what `validate.yml` does. Deviation P1 follows from this.
- **Tool version output.** `shellcheck --version` → `version: 0.9.0`; `actionlint -version` → `1.7.12`; `shfmt --version` → `v3.14.1`; `prettier --version` → `3.9.6`; `markdownlint-cli2 --version` → `markdownlint-cli2 v0.23.2 (markdownlint v0.41.1)`; `cspell --version` → `10.2.2`. The first dotted triple is the version in every case.
- **Pins**, recorded in Global Constraints: the four action tag shas from `git ls-remote --tags` (`v4` and `v5` are lightweight tags on the newest patch of each major); the three release-asset sha256s from downloads, actionlint's verified against `actionlint_1.7.12_checksums.txt`, mvdan/sh v3.14.1 and shellcheck v0.9.0 publishing none; both validator sha256s from `raw.githubusercontent.com` at the pinned sha, byte-identical to the local codex-cli copies (and the md5 `validate.yml` records matches); pyyaml 6.0.3, the newest on PyPI and the version installed here.
- **History has no merge commits**: branches land fast-forward. Commit messages carry no type prefix and end with the `Co-Authored-By` trailer.
- **The plan's code was run before the plan was handed over.** Every fenced block was extracted and syntax-checked; the full files were shellchecked; and the tasks were applied in order to scratch copies of `55f1bcc` and their tests run: milestone 1 end to end (Tasks 1–15, 20, and the #5, #1 and #43 edits — `tests/run.sh` on the result reports `23 passed, 0 failed, 0 skipped`), and milestone 2's mechanism (Task 17 red on arrival, Task 18's `bin/format` leaving `AGENTS.md` and `payload-rules.md` untouched and every engine and drift test green, the workflow hardening and install step passing `tests/test-workflows.sh` and `prettier --check`, and Task 22's dry run of the install step downloading and verifying all three binaries). Task 6's `tests/test-setup-upgrade.sh` ran against the real `claude` with `node` real and `npx` a stub, and passed in 9 seconds. Two findings from those runs shaped the plan: shellcheck's SC2317 against §6.1's wrapper (Deviation P8), and an unused loop variable in `split_tsv`.

## Deviations decided while planning

Visible choices, each with a veto line. Any of them can be reversed; each says what changes if it is.

- **P1. The upgrade fixture keeps `node` real and stubs only `npx`.** §5.3 says `node` and `npx` both become stubs. `claude` is a node script on the CI runner (installed with `npm install -g`), so a stub `node` on the fixture's `PATH` would kill every `claude` call there: green on this machine's native binary, red in CI. `npx` is safe to stub: the pinned lockfile means `ensure_skills_sh` never runs it, and a stub that exits 1 turns an unexpected call into a `FAIL:` line. Veto: stub `node` too, and accept that `tests/test-setup-upgrade.sh` fails in CI until CI installs the native binary, which is not this spec's business.
- **P2. Fixture 8 asserts the malformed-line `FAIL:`; rung 1 is proved by a manufactured silent check (fixture 10).** §6.2's fixture 8 asserts that rung 1's line names `ensure_skills_sh` on all-empty skill names. §6.3 splits that loop and reports an empty name as `bad "… malformed"`, so after the split the shape is no longer silent and rung 1's line never appears for it — the two sections cannot both hold. Read the four splits and §6.4 together and no declaration shape remains silent, which is the point of them; so the wrapper is proved on a scratch copy of `bin/setup` whose last line, `main "$@"`, is preceded by a redefinition of `ensure_fresh_clone` that prints nothing, and fixture 8 asserts the malformed line. Veto: keep `[ -n "$name" ] || continue` in `ensure_skills_sh` (an empty name skipped, not reported), which contradicts §6.3's "all four", and let fixture 8 assert rung 1's line instead of fixture 10.
- **P3. `cspell.config.yaml`, not `cspell.json`.** §8.1 wants each configuration file to carry the reason beside the setting, and `tests/test-json-wellformed.sh` runs `jq empty` over every checked `*.json`; a JSON file cannot do both. cspell reads `cspell.config.yaml` with the same `overrides` mechanism (measured). Veto: `cspell.json` with no comments, and the reasons move into `tests/test-spelling.sh`'s header.
- **P4. `tests/tools.txt` lands in milestone 1 (Task 4), not step 5.** `tests/run.sh` holds the six lint and format tools to the registry's versions, and `tests/test-lint-shell.sh` declares `shellcheck` from step 2 onward, so the probe reads the file before any formatter exists. The versions and hashes are the ones recorded below; Task 18's reformat is produced with exactly those binaries, which is what §8.2's "the plan pins whatever the reformat commit was produced with" asks. Veto: an empty registry until Task 17, with `shellcheck` probed by presence alone until then.
- **P5. Six literal patterns in an array, paired with their guards.** §4 writes the vendored set as one regex with an inner `(brainstorming|diagnosing-bugs|setup-repository)` group. `tests/test-ownership.sh` has to iterate the patterns, and a `|`-split of that regex splits the group; so `tests/lib.sh` declares `VENDORED_PATTERNS` (six entries, the spec's "six patterns") beside `VENDORED_GUARDS` (the drift test for each) and joins them into `EXCLUDED` at load. Veto: the single regex, and a hand-maintained list in the ownership test.
- **P6. One `split_tsv` helper instead of four inline copies of the split.** §6.3 says the four loops get "the split `ensure_links` has". The split is six lines each time; a helper that fills a six-field array `F` by parameter expansion is the same split, written once, and `ensure_links` keeps its own so the helper's comment can point at it. Veto: inline the six lines at each of the four sites.
- **P7. `SHFMT_FLAGS` is a bash array.** §8.1 says "one variable". An array expands unsplit under `set -u` and keeps shellcheck clean; a string would need an unquoted expansion and an SC2086 waiver at both call sites. Veto: `SHFMT_FLAGS='-i 2 -ci -bn'` with the waivers.
- **P8. Rung 1 is a direct call bracketed by `reported`, not the spec's `run_check "$@"` wrapper.** Measured on the engine with §6.1's `run_check` in place: shellcheck 0.9.0 reports every check, and every helper only the checks call, as unreachable — 541 SC2317 findings — because it cannot see through a function invoked as `"$@"`; the only thing that silences it is a file-wide `# shellcheck disable=SC2317`, which retires a check the engine's own header relies on. So each site is three lines: `before=$REPORTED`, the check called by name, `reported "$before" <name>`. The semantics are §6.1's exactly (a snapshot in the parent shell, no capture, no subshell, a `bad` on silence); only the shape differs. Veto: the spec's `run_check` plus the file-wide directive.

## Global Constraints

Copied from the spec unless marked; every task's requirements implicitly include this section.

- **Branch and gate.** All work on `suite-and-ci`, cut from `main` (Task 1). Milestone 1 (Tasks 1–16), Gate 1 (Task 16), milestone 2 (Tasks 17–24), Gate 2 (Task 25), then merge to `main` and push in the same motion, fast-forward as every branch before it. Issue dispositions (Task 26) after the push.
- **Execute in a worktree.** The main checkout's index holds a staged, uncommitted `docs/Professional-Editorial-Standards-2024.md` that is not this plan's; a worktree (`superpowers:using-git-worktrees`) has a fresh index, and `git ls-files` there lists 95 files, the spec's counts. If executing in the main checkout instead: never unstage it, never `git add -A` or `git commit -a` (this repository's `.gitignore` records `git add -A` sweeping working files into an unrelated commit twice), and every commit names its paths: `git add <paths>` then `git commit -m … -- <paths>`. `tests/results.tsv` will read `dirty` there on every run; that is the header telling the truth.
- **Commit style.** Sentence-case subject, no type prefix, a body that says why, ending in `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Every commit lists its paths explicitly.
- **Hard prerequisites** (§5.1): `bash` 4 or later, `jq`, `git`; refusal text `the test suite needs: bash 4 or later (found 3.2), jq, git`, exit 2. Nothing else is hard. Assumed and unprobed: base GNU/Linux tools (`sed`, `awk`, `grep`, `head`, `tail`, `tee`, `tr`, `date`, `mktemp`, `cut`, `sort`, `find`, `cp`, `mv`, `ln`, `mkdir`, `rm`, `cat`, `readlink`, `basename`, `dirname`, `sha256sum`, `cmp`, `tar`, `curl`), loud with `command not found` when absent. Network is never a need: an offline pin test fails with `lib.sh`'s "no network, or the pinned sha is gone".
- **Needs** (§5.2): one line in a test's leading comment block, `# needs: <name> [<name>…]`. Known names: `claude`, `python3`, `pyyaml`, `codex-validator`, and the six registry tools `shellcheck`, `actionlint`, `shfmt`, `prettier`, `markdownlint-cli2`, `cspell`. A registry tool is met only at the registry's version. Unknown name: exit 2. Who declares what: `test-claude-validate.sh` and `test-setup-upgrade.sh` → `claude`; `test-codex-validate.sh` → `python3 pyyaml codex-validator`; `test-vendored-duplicates.sh` → `python3`; `test-lint-shell.sh` → `shellcheck`; `test-format-shell.sh` → `shfmt`; `test-format-prettier.sh` → `prettier`; `test-lint-markdown.sh` → `markdownlint-cli2`; `test-spelling.sh` → `cspell`; `test-workflows.sh` → `actionlint shellcheck`; every other test nothing.
- **Skip and summary shapes**, verbatim from §5.2 and §8.2, both kept: the per-test line `SKIP tests/test-format-shell.sh (needs shfmt 3.14.1; found 3.8.0)` (`FAIL` in place of `SKIP` under `--no-skip`, exit 1), and the run's last line `19 passed, 0 failed, 3 skipped for want of: claude, shfmt 3.14.1 (found 3.8.0)`. `for want of:` is omitted when nothing was unmet.
- **The result file** (§5.4): `tests/results.tsv`, gitignored, removed at the start of every run and rewritten; line one `# <short sha>[ dirty] <UTC ISO-8601 time>`, `dirty` when `git status --porcelain` is non-empty; then one row per test: path, `PASS`/`FAIL`/`SKIP`, exit status (`-` when the test did not run), the test's last output line or `needs …`. CI uploads it as the artifact `results`.
- **Registry** (`tests/tools.txt`, §8.2), the versions the reformat is produced with and CI installs:

  ```text
  # tool  version  sha256 of the linux-amd64 release asset (- for npm packages)
  shellcheck         0.9.0    700324c6dd0ebea0117591c6cc9d7350d9c7c5c287acbad7630fa17b1d4d9e2f
  actionlint         1.7.12   8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
  shfmt              3.14.1   76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
  prettier           3.9.6    -
  markdownlint-cli2  0.23.2   -
  cspell             10.2.2   -
  ```

  Assets: `shellcheck-v0.9.0.linux.x86_64.tar.xz` (the binary at `shellcheck-v0.9.0/shellcheck` inside), `actionlint_1.7.12_linux_amd64.tar.gz` (`actionlint` at its root), `shfmt_v3.14.1_linux_amd64` (the binary itself).

- **Tool settings** (§3, §8.1): shfmt `-i 2 -ci -bn`; prettier `proseWrap: preserve`, `embeddedLanguageFormatting: "off"` (quoted: bare `off` is YAML `false`); markdownlint MD013, MD033, MD041 off and nothing else; cspell `en-US`, code ignored, comments in shell and YAML read through one `overrides` entry with an `includeRegExpList` for `#` lines; shellcheck `-e SC1091 -e SC2016`. Configuration lives in exactly four files at the root: `.prettierrc.yaml`, `.markdownlint-cli2.jsonc`, `cspell.config.yaml` (P3), and `SHFMT_FLAGS` in `tests/lib.sh`. **No per-tool ignore file**: no `.prettierignore`, `.markdownlintignore`, `ignorePaths`; every tool receives explicit paths from `checked`.
- **cspell scope** (§8.1): `checked '*.md' ':(exclude)docs/superpowers' ':(exclude)docs/research' ':(exclude)docs/archive'` plus the shell and YAML lists for comments. `docs/agents/` stays in. A spelling correction inside an authored `SKILL.md` goes through `superpowers:writing-skills`.
- **Ownership** (§4): `checked()` over `git -C "$REPO_ROOT" ls-files "$@"`, never bare `git`; six vendored patterns anchored at the start of the path; every consumer filters by type and asserts a non-empty list; the `*/skills/*` exclusion in the JSON check goes.
- **Engine rules** still binding from earlier specs: no `set -e` in `bin/setup`; report, never repair; never `--scope project`; never re-run `codex plugin marketplace add`; a squatter is moved aside, never deleted. New: `ok`, `bad`, `skip`, `note` increment `REPORTED`; `did` does not; every check is bracketed by `before=$REPORTED` and `reported "$before" <name>`, including `report_duplicates` inside `report_only` and `report_pool` inside `report_duplicates`; a silent check is `bad`, counted in "N check(s) failed", exit 1. No `$(…)` around a check, and no wrapper that invokes a check through `"$@"` (Deviation P8).
- **Test idiom.** Tests source `tests/lib.sh` (`set -euo pipefail`), use its `fail`, and are named `tests/test-*.sh`. A capture of a command meant to exit non-zero is `if out="$(…)"; then status=0; else status=$?; fi`, or `|| true` inside the substitution. `grep -q X && fail …` is safe under `set -e`. Every `cp`, `mkdir`, `ln`, `cat >`, `mktemp` and bare capture in a test gets `|| fail "…"`. Portable: no `mapfile`, no `find -printf`; `[[:space:]]` not `\s`. Fixture `PATH`s never carry `claude`, `codex`, `node` or `npx` unless the fixture drives them.
- **shellcheck must exit 0** over every owned shell file with `-e SC1091 -e SC2016`, style and info findings included. No `.shellcheckrc`. An `SC2086` waiver is allowed only on an unquoted `$(checked …)`/`$files` expansion and only because `tests/test-ownership.sh` asserts no tracked path carries whitespace or a glob character; the waiver's comment says so.
- **CI** (§9): `permissions: contents: read` at workflow level in `validate.yml`; every `uses:` sha-pinned with the tag in a trailing comment; `persist-credentials: false` on every `actions/checkout`; `pip install pyyaml==6.0.3`; the `claude-code@2.1.220` pin stays; triggers `push:` and `pull_request:` stay, unfiltered. Pins, resolved 2026-09-17: `actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0`, `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0`, `actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0`, `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2`.
- **The Codex validator** (§9.2): openai/codex at `f3f6922519fa38487c8250c2b8a670a39a2cf9ff`; `validate_plugin.py` sha256 `f4eeadb733b28b0c3e714de263a76d6542866a672f3e99bdffcf4dbcdf85e944`; `identifier_validation.py` sha256 `a6d51ce4a9a7e8f85626ff5808a467a67574e7f8cdf1167ffb467c5f67e57223`. Local default path `$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py`, overridden by `CODEX_PLUGIN_VALIDATOR`. Failure text: `validate_plugin.py at <path> is not the copy CI pins (openai/codex@f3f6922); re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a copy fetched by the recipe in .github/workflows/validate.yml`.
- **Versions** (§10.2): `software-dev` `0.7.0` → `0.7.1`, `sensemaking` `0.2.0` → `0.2.1`, both manifests each, one commit, last before Gate 2. No test carries the literal after Task 11.
- **Hook design amendments** (§7.4): §4.3's `3,343` → `3,335`, `387` → `379`, `3,730` → `3,714`, `3,718` → `3,702`; §12's `3,343` → `3,335`; the Status line says §4.2 is read by a test. Specs move when the tree moves, plans do not (`a3c797f`). Plans still take a link-path fix (§7.7) and formatting (§8.1), never a sentence.
- **Declines**, each with its home in §12, none of them work here: #42's template half; hard-fail on every absent tool; GNU/Linux probed rather than fixed; the validator fetched by the test; dropping `pull_request:`; a path filter; spell-checking `docs/superpowers`, `docs/research`, `docs/archive`; `zizmor`; per-tool ignore files; a `Note:` commit for `4b23edc`; the `LICENSE:55` comma; `dependabot.yml`; a network-test count in the README.

## File map

Created:

- `tests/test-ownership.sh` — the derivation stays honest (Task 1).
- `tests/tools.txt` — the version registry (Task 4).
- `tests/test-runner.sh` — `tests/run.sh` proved on a scratch repository (Task 4).
- `tests/test-lint-shell.sh` — shellcheck over the shell list, `# needs: shellcheck` (Task 5).
- `tests/test-setup-upgrade.sh` — the upgrade path, `# needs: claude` (Task 6).
- `tests/test-doctor-silence.sh` — the ten unreadable machines (Tasks 8, 13, 15).
- `.prettierrc.yaml`, `.markdownlint-cli2.jsonc`, `cspell.config.yaml`, `bin/format`, `tests/test-format-shell.sh`, `tests/test-format-prettier.sh`, `tests/test-lint-markdown.sh`, `tests/test-spelling.sh` (Task 17).
- `tests/test-workflows.sh` (Task 21).

Modified: `tests/lib.sh` (Tasks 1, 17), `tests/run.sh` (Task 4, rewritten), `.gitignore` (Task 4), `tests/test-json-wellformed.sh` (2), `tests/test-links-resolve.sh` (3), `docs/superpowers/plans/2026-09-04-session-start-hook.md` (3, three link paths), `tests/test-claude-validate.sh` (5, 11), `tests/test-codex-validate.sh` (5, 20), `tests/test-vendored-duplicates.sh` (5), `tests/test-setup-doctor.sh` (5, 8, 9 — rewritten in 9), `tests/test-doctor-faults.sh` (7, 8), `tests/test-upstream-pin.sh` and `tests/test-vendored-scaffolder.sh` (10), `tests/test-references-resolve.sh` and `tests/test-codex-marketplace.sh` (11), `tests/test-hook.sh` (11, 12), `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` (12, 19), `bin/setup` (9, 13, 14, 15), `bin/doctor` (9), `tests/test-doctor-duplicates.sh` (14), 17 shell and 20 JSON/YAML/markdown files by the formatters (18), the markdown files with residual findings and the eight spelling sites (19), `.github/workflows/validate.yml` and `upstream-watch.yml` (21, 22), `README.md` (23), the four plugin manifests (24).

---

## Milestone 1: the suite tells the truth

### Task 1: Cut the branch and derive ownership in `tests/lib.sh`

**Files:**

- Modify: `tests/lib.sh` (append after `fetch_upstream`, line 48)
- Create: `tests/test-ownership.sh`

**Interfaces:**

- Produces: `VENDORED_PATTERNS` and `VENDORED_GUARDS` (parallel bash arrays, six entries each), `EXCLUDED` (the patterns joined by `|`), `checked "$@"` (prints owned tracked paths relative to `REPO_ROOT`, one per line; arguments are git pathspecs), `checked_shell` (the subset whose first line is `#!/usr/bin/env bash`). Every later task's file list comes from these two functions.

- [ ] **Step 1: Cut the branch**

```bash
cd /home/eranr/agent-plugins
git fetch origin
git checkout main && git pull --ff-only origin main
git checkout -b suite-and-ci
```

Expected: `Switched to a new branch 'suite-and-ci'`. If executing in a worktree, create it from `main` via `superpowers:using-git-worktrees` instead and run the rest of the plan there.

- [ ] **Step 2: Write the failing ownership test**

Create `tests/test-ownership.sh`:

```bash
#!/usr/bin/env bash
# The ownership derivation stays honest (spec §4). Every vendored pattern in
# tests/lib.sh matches at least one tracked file and is paired with a drift
# test that names what it excludes, so nothing sits in the excluded set
# without a test behind it. The checked list is non-empty, and no checked
# path carries whitespace or a glob character, which is what lets the tool
# tests expand `$(checked ...)` unquoted, one path per word.
. "$(dirname "$0")/lib.sh"

[ "${#VENDORED_PATTERNS[@]}" -eq "${#VENDORED_GUARDS[@]}" ] \
  || fail "VENDORED_PATTERNS and VENDORED_GUARDS differ in length; every pattern needs its guard"
[ "${#VENDORED_PATTERNS[@]}" -gt 0 ] || fail "no vendored pattern is declared"

i=0
while [ "$i" -lt "${#VENDORED_PATTERNS[@]}" ]; do
  pat="${VENDORED_PATTERNS[$i]}"
  guard="${VENDORED_GUARDS[$i]}"
  i=$((i + 1))
  git -C "$REPO_ROOT" ls-files | grep -qE "$pat" \
    || fail "pattern '$pat' matches no tracked file; drop it from tests/lib.sh or fix it"
  [ -f "$REPO_ROOT/$guard" ] || fail "pattern '$pat' names a guard that does not exist: $guard"
  # The subject: the fourth path segment with regex escapes removed --
  # plugins/<plugin>/<skills|hooks>/<subject>. The guard must name it.
  subject="${pat#^plugins/*/}"
  subject="${subject#*/}"
  subject="${subject%%/*}"
  subject="${subject%\$}"
  subject="${subject//\\/}"
  grep -qF -- "$subject" "$REPO_ROOT/$guard" \
    || fail "$guard never names '$subject', so nothing asserts the bytes '$pat' excludes"
done

list="$(checked)"
[ -n "$list" ] || fail "checked() listed nothing; the ownership derivation went vacuous"
printf '%s\n' "$list" | grep -q '[[:space:]*?[]' \
  && fail "a tracked path carries whitespace or a glob character; the tool tests expand the list unquoted:"$'\n'"$(printf '%s\n' "$list" | grep '[[:space:]*?[]')"
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing"
printf '%s\n' "$shell" | grep -qx 'bin/setup' || fail "checked_shell() does not list bin/setup, a shell file with no extension"
printf '%s\n' "$list" | grep -q '^plugins/software-dev/hooks/payload\.md$' \
  && fail "checked() lists the vendored payload.md"

printf 'ownership: %s vendored pattern(s) each guarded; %s checked file(s), %s of them shell\n' \
  "${#VENDORED_PATTERNS[@]}" "$(printf '%s\n' "$list" | grep -c .)" "$(printf '%s\n' "$shell" | grep -c .)"
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash tests/test-ownership.sh`
Expected: exit 1 with `VENDORED_PATTERNS: unbound variable` (lib.sh is `set -u`).

- [ ] **Step 4: Append the derivation to `tests/lib.sh`**

Append after `fetch_upstream` (after line 48):

```bash

# ---- Ownership (spec §4) ----------------------------------------------------
# Every list of "the files we own" comes from checked() below. One class of
# tracked file is excluded: vendored, where an upstream pin constrains the
# bytes and the paired drift test asserts them. Six patterns, anchored at the
# start of the path, each beside the test that guards it;
# tests/test-ownership.sh checks every pair. #21 may devendor payload.md or
# setup-repository/SKILL.md: that edits these two arrays and nothing else.
# adhd/agents/openai.yaml is authored here but sits inside a vendored
# directory; the directory is excluded whole, because the drift test's
# file-set assertion governs it and tests/test-plugin-skills.sh already
# asserts the one policy line the file exists to carry.
VENDORED_PATTERNS=(
  '^plugins/sensemaking/skills/adhd/'
  '^plugins/software-dev/skills/brainstorming/'
  '^plugins/software-dev/skills/diagnosing-bugs/'
  '^plugins/software-dev/skills/setup-repository/'
  '^plugins/software-dev/skills/finding-duplicate-functions/scripts/[a-z-]+-prompt\.md$'
  '^plugins/software-dev/hooks/payload\.md$'
)
# shellcheck disable=SC2034  # read by tests/test-ownership.sh
VENDORED_GUARDS=(
  tests/test-vendored-adhd.sh
  tests/test-vendored-brainstorming.sh
  tests/test-vendored-diagnosing-bugs.sh
  tests/test-vendored-scaffolder.sh
  tests/test-vendored-duplicates.sh
  tests/test-hook.sh
)
EXCLUDED="$(IFS='|'; printf '%s' "${VENDORED_PATTERNS[*]}")"

# Tracked files this repository owns, one path per line relative to
# REPO_ROOT. Arguments are git pathspecs: checked '*.md', or
# checked '*.md' ':(exclude)docs/superpowers'. `git -C`, never bare: ls-files
# is cwd-relative and this file never changes directory. Tracked, not
# present: a new file joins when it is staged, which is also the moment
# anything else in the repository notices it, and the stale worktree under
# .kilo/ that a `find` would see is not listed. Every caller asserts the
# list is non-empty: an empty list is a false green for most tools.
checked() {
  git -C "$REPO_ROOT" ls-files "$@" | { grep -vE "$EXCLUDED" || true; }
}

# The shell files: every checked file whose first line is the bash shebang.
# By shebang, not extension: five of them have none. Arguments narrow the
# list the same way checked's do.
checked_shell() {
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ "$(head -n 1 "$REPO_ROOT/$f")" = '#!/usr/bin/env bash' ]; then
      printf '%s\n' "$f"
    fi
  done < <(checked "$@")
}
```

Also change lib.sh's line 2 to read: `# Shared helpers for tests/test-*.sh and bin/format. Source this file; do not execute it.`

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/test-ownership.sh`
Expected: `ownership: 6 vendored pattern(s) each guarded; 72 checked file(s), 26 of them shell` — the counts at `55f1bcc` (73 in the main checkout, where the staged editorial-standards file is in the index; one more if this plan was committed first). The new test is not in either count yet: the contract is tracked files, and it joins both when Step 6 stages it. Each later task's files join the same way. Then `bash tests/test-doctor-faults.sh` and `bash tests/test-setup-doctor.sh` still pass (lib.sh is sourced by every test), and `shellcheck -e SC1091 -e SC2016 tests/lib.sh tests/test-ownership.sh` exits 0.

- [ ] **Step 6: Commit**

```bash
git add tests/lib.sh tests/test-ownership.sh
git commit -m "Derive the files we own from git ls-files, six vendored patterns each with its guard" -m "One derivation in tests/lib.sh over git ls-files (spec §4), consumed by every list from here on. tests/test-ownership.sh keeps the exclusion honest: every pattern matches a tracked file and its paired drift test names the subject, so nothing sits in the excluded set without a test behind it, and no owned path carries a character that would break an unquoted expansion.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 2: `tests/test-json-wellformed.sh` over the derivation (#27)

**Files:**

- Modify: `tests/test-json-wellformed.sh` (whole file, 13 lines)

**Interfaces:**

- Consumes: `checked '*.json'` from Task 1.

- [ ] **Step 1: Record the count the hardcoded list reports**

Run: `bash tests/test-json-wellformed.sh`
Expected: `json: 7 files well-formed`. The eighth owned JSON file, `upstream/skills.json`, sits outside the three hardcoded directories.

- [ ] **Step 2: Replace the file**

```bash
#!/usr/bin/env bash
# Every JSON file this repository owns parses. The list is derived, never
# hardcoded (#27): a manifest in a new directory joins the moment it is
# tracked, and the vendored set is excluded by the one derivation rather than
# by a second `-not -path` that had to be kept in step with it.
. "$(dirname "$0")/lib.sh"

found=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  jq empty "$REPO_ROOT/$f" || fail "not valid JSON: $f"
  found=$((found + 1))
done < <(checked '*.json')

[ "$found" -gt 0 ] || fail "checked '*.json' listed nothing; the ownership derivation went vacuous"
printf 'json: %s files well-formed\n' "$found"
```

- [ ] **Step 3: Run it to verify the count moved**

Run: `bash tests/test-json-wellformed.sh`
Expected: `json: 8 files well-formed` — the seven plus `upstream/skills.json`.

- [ ] **Step 4: Prove the guard with a mutation**

Run: `printf '{' > /tmp/bad.json && cp /tmp/bad.json upstream/skills.json && bash tests/test-json-wellformed.sh; git checkout -- upstream/skills.json`
Expected: `FAIL: not valid JSON: upstream/skills.json` (the jq error above it), then the checkout restores the file. Run `git status --short upstream/` and expect nothing.

- [ ] **Step 5: Commit**

```bash
git add tests/test-json-wellformed.sh
git commit -m "Check every owned JSON file, derived rather than listed" -m "The hardcoded find saw seven files; checked '*.json' sees the eight, upstream/skills.json among them (#27). The */skills/* exclusion goes: no tracked JSON lives there, and the vendored patterns cover the case it guarded against.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 3: The link check gains a subject (§7.7)

**Files:**

- Modify: `tests/test-links-resolve.sh` (lines 1–18, 40–41)
- Modify: `docs/superpowers/plans/2026-09-04-session-start-hook.md` (lines 432, 440, 448)

**Interfaces:**

- Consumes: `checked '*.md'`.

- [ ] **Step 1: Widen the scope and reword the header**

Replace lines 1–18 of `tests/test-links-resolve.sh` with:

```bash
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
```

Keep lines 19–39 as they are (the loop already iterates `$docs` unquoted, one path per word, which Task 1's test licenses). Replace the final `printf` (lines 40–41) with:

```bash
printf 'links-resolve: %s relative link(s) across %s owned document(s) resolve\n' \
  "$checked" "$scanned"
```

- [ ] **Step 2: Run it to verify it fails on the three plan links**

Run: `bash tests/test-links-resolve.sh`
Expected: `FAIL: docs/superpowers/plans/2026-09-04-session-start-hook.md links [2026-09-04-session-start-hook-design.md], which does not exist (looked at docs/superpowers/plans/2026-09-04-session-start-hook-design.md)`. The spec sits in `../specs/`; lines 500 and 657 of the same plan already link it that way.

- [ ] **Step 3: Fix the three paths**

In `docs/superpowers/plans/2026-09-04-session-start-hook.md`, on lines 432, 440 and 448, change the link target `2026-09-04-session-start-hook-design.md` to `../specs/2026-09-04-session-start-hook-design.md`. Nothing else in the plan changes.

Run: `grep -c '](../specs/2026-09-04-session-start-hook-design.md)' docs/superpowers/plans/2026-09-04-session-start-hook.md`
Expected: `4` (the three fixed plus line 657's, which was already right; line 500 links a different spec).

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-links-resolve.sh`
Expected: `links-resolve: 23 relative link(s) across 27 owned document(s) resolve` (28 documents in the main checkout). The count of links must be greater than zero; a `0 relative link(s)` line means the scope did not widen.

- [ ] **Step 5: Commit**

```bash
git add tests/test-links-resolve.sh docs/superpowers/plans/2026-09-04-session-start-hook.md
git commit -m "Resolve links in every owned markdown file, and fix the three a plan had wrong" -m "Over checked '*.md' the test finds 23 relative links where it found none (spec §7.7); three were broken, all in the session-start-hook plan, which linked its spec by bare filename from plans/. A link path in a frozen plan is not its prose. The header's claim that specs are never amended goes: a3c797f amended one, and specs move when the tree moves.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 4: The gate, the needs, the result file (§5, #42)

**Files:**

- Modify: `tests/run.sh` (whole file, 15 lines → rewritten)
- Create: `tests/tools.txt`
- Modify: `.gitignore` (append)
- Create: `tests/test-runner.sh`

**Interfaces:**

- Produces: `tests/run.sh [--no-skip]`; the `# needs:` header contract (Global Constraints); `tests/results.tsv`; `tests/tools.txt` with the `<tool> <version> <sha256|->` line shape, read by `run.sh` here and by `validate.yml` in Task 22.
- One reading of §5.4, stated so it is not read as drift: the row's last column is the test's last line of **merged** stdout and stderr, not stdout alone. `fail` writes to stderr, so for a `FAIL` row that is the line that says why; for a `PASS` row it is the test's own summary line, as before.

- [ ] **Step 1: Write the registry**

Create `tests/tools.txt` with exactly the block from Global Constraints (the comment line, then six rows, whitespace-separated).

- [ ] **Step 2: Ignore the result file**

Append to `.gitignore`:

```text

# Written by every tests/run.sh run and cited by reports instead of pasted
# output (spec §5.4). Ignored so the run's own output never marks the tree
# dirty in the header line it writes.
tests/results.tsv
```

- [ ] **Step 3: Write the failing runner test**

Create `tests/test-runner.sh`:

```bash
#!/usr/bin/env bash
# tests/run.sh itself (spec §5): the hard gate refuses with a list; a
# declared need that is unmet skips the test, or fails it under --no-skip; a
# registry tool at the wrong version is unmet and the line names both
# versions; a need no probe knows is exit 2; and every run writes
# tests/results.tsv with a header naming the tree and one row per test.
# Proved on a scratch repository carrying synthetic tests, never on this one.
# Needs no network.
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

# The scratch repository: the runner and the registry copied in, the result
# file ignored, one commit so the header has a sha, and four synthetic tests.
R="$T/repo"
mkdir -p "$R/tests" || fail "could not create $R/tests"
cp "$REPO_ROOT/tests/run.sh" "$R/tests/run.sh" || fail "could not copy run.sh"
cp "$REPO_ROOT/tests/tools.txt" "$R/tests/tools.txt" || fail "could not copy tools.txt"
printf 'tests/results.tsv\n' > "$R/.gitignore" || fail "could not write .gitignore"
printf '#!/usr/bin/env bash\n# passes, and says so\nprintf "alpha ok\\n"\n' > "$R/tests/test-a-pass.sh" \
  || fail "could not write test-a-pass.sh"
printf '#!/usr/bin/env bash\n# fails with status 3\nprintf "beta broke\\n"\nexit 3\n' > "$R/tests/test-b-fail.sh" \
  || fail "could not write test-b-fail.sh"
printf '#!/usr/bin/env bash\n# needs: claude\nexit 0\n' > "$R/tests/test-c-needs-claude.sh" \
  || fail "could not write test-c-needs-claude.sh"
printf '#!/usr/bin/env bash\n# needs: shfmt\nexit 0\n' > "$R/tests/test-d-needs-shfmt.sh" \
  || fail "could not write test-d-needs-shfmt.sh"
git -C "$R" init -q || fail "git init failed in $R"
git -C "$R" add -A || fail "git add failed in $R"
git -C "$R" -c user.email=t@example.com -c user.name=t commit -q -m seed || fail "could not seed a commit"
sha="$(git -C "$R" rev-parse --short HEAD)" || fail "could not read the scratch sha"

# A PATH carrying what the runner uses and nothing it must not: no claude,
# and a stub shfmt reporting a version the registry does not declare.
BIN="$T/bin"
mkdir -p "$BIN" || fail "could not create $BIN"
for t in bash dirname rm git jq awk grep head tail tee tr date mktemp cat; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t" || fail "could not link $t into $BIN"
done
printf '#!/usr/bin/env bash\nprintf "v0.0.1\\n"\n' > "$BIN/shfmt" || fail "could not write the shfmt stub"
chmod +x "$BIN/shfmt" || fail "could not make the shfmt stub executable"
NOJQ="$T/bin-nojq"
mkdir -p "$NOJQ" || fail "could not create $NOJQ"
for t in bash dirname rm git; do ln -sf "$BIN/$t" "$NOJQ/$t" || fail "could not link $t into $NOJQ"; done

# 1. The hard gate: without jq the run refuses with the list, exit 2, and
# writes no result file.
if out="$(env PATH="$NOJQ" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "without jq the runner must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -qx 'the test suite needs: jq' \
  || fail "the refusal must name what is missing in the documented shape:"$'\n'"$out"
[ ! -e "$R/tests/results.tsv" ] || fail "a refused run must not leave a result file"

# 2. A skipping run: the failing test fails, the unmet needs skip and are
# summed, the exit status is 1 for the failure alone.
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "a run with one failing test must exit 1, got $status:"$'\n'"$out"
for line in \
  'PASS tests/test-a-pass.sh' \
  'FAIL tests/test-b-fail.sh' \
  'SKIP tests/test-c-needs-claude.sh (needs claude)' \
  'SKIP tests/test-d-needs-shfmt.sh (needs shfmt 3.14.1; found 0.0.1)' \
  '1 passed, 1 failed, 2 skipped for want of: claude, shfmt 3.14.1 (found 0.0.1)'
do
  printf '%s\n' "$out" | grep -qxF -- "$line" || fail "missing line: $line"$'\n'"$out"
done
RES="$R/tests/results.tsv"
[ -f "$RES" ] || fail "the run wrote no $RES"
sed -n 1p "$RES" | grep -qE "^# $sha [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" \
  || fail "the header must be '# <sha> <UTC time>' on a clean tree: $(sed -n 1p "$RES")"
for row in \
  "$(printf 'tests/test-a-pass.sh\tPASS\t0\talpha ok')" \
  "$(printf 'tests/test-b-fail.sh\tFAIL\t3\tbeta broke')" \
  "$(printf 'tests/test-c-needs-claude.sh\tSKIP\t-\tneeds claude')" \
  "$(printf 'tests/test-d-needs-shfmt.sh\tSKIP\t-\tneeds shfmt 3.14.1; found 0.0.1')"
do
  grep -qxF -- "$row" "$RES" || fail "missing row in results.tsv: $row"$'\n'"$(cat "$RES")"
done
[ "$(grep -c . "$RES")" -eq 5 ] || fail "results.tsv should hold a header and four rows:"$'\n'"$(cat "$RES")"

# 3. --no-skip: an unmet need is a FAIL, counted, and the run is red for it.
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" --no-skip 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "--no-skip with unmet needs must exit 1, got $status:"$'\n'"$out"
for line in \
  'FAIL tests/test-c-needs-claude.sh (needs claude)' \
  'FAIL tests/test-d-needs-shfmt.sh (needs shfmt 3.14.1; found 0.0.1)' \
  '1 passed, 3 failed, 0 skipped for want of: claude, shfmt 3.14.1 (found 0.0.1)'
do
  printf '%s\n' "$out" | grep -qxF -- "$line" || fail "missing line under --no-skip: $line"$'\n'"$out"
done
grep -qxF -- "$(printf 'tests/test-c-needs-claude.sh\tFAIL\t-\tneeds claude')" "$RES" \
  || fail "under --no-skip the result row must read FAIL:"$'\n'"$(cat "$RES")"

# 4. A dirty tree is named as such.
printf 'scratch\n' > "$R/untracked" || fail "could not dirty the scratch tree"
env PATH="$BIN" /bin/bash "$R/tests/run.sh" >/dev/null 2>&1 || true
sed -n 1p "$RES" | grep -qE "^# $sha dirty [0-9]{4}-" \
  || fail "the header must say dirty when git status is non-empty: $(sed -n 1p "$RES")"
rm -f "$R/untracked"

# 5. A need no probe knows is exit 2, naming the test and the need.
printf '#!/usr/bin/env bash\n# needs: nosuchtool\nexit 0\n' > "$R/tests/test-e-unknown.sh" \
  || fail "could not write test-e-unknown.sh"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "an unknown need must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'tests/test-e-unknown.sh declares a need no probe knows: nosuchtool' \
  || fail "the unknown need must be named with its test:"$'\n'"$out"
rm -f "$R/tests/test-e-unknown.sh"

# 6. A wholly green run exits 0 with no `for want of`.
rm -f "$R/tests/test-b-fail.sh" "$R/tests/test-c-needs-claude.sh" "$R/tests/test-d-needs-shfmt.sh"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 0 ] || fail "an all-green run must exit 0, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -qxF '1 passed, 0 failed, 0 skipped' \
  || fail "the summary of a green run must carry no 'for want of':"$'\n'"$out"

printf 'runner: hard gate refuses, needs skip or fail, versions compared, results.tsv written\n'
```

- [ ] **Step 4: Run it to verify it fails**

Run: `bash tests/test-runner.sh`
Expected: `FAIL: without jq the runner must exit 2, got 0:` — today's runner has no gate and runs the synthetic tests under a `PATH` with no jq.

- [ ] **Step 5: Rewrite `tests/run.sh`**

Replace the whole file:

```bash
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
cd "$(dirname "$0")/.." || { printf 'FAIL: could not cd to the repository root\n' >&2; exit 1; }

NO_SKIP=0
case "${1:-}" in
  '') ;;
  --no-skip) NO_SKIP=1 ;;
  *) printf 'usage: tests/run.sh [--no-skip]\n' >&2; exit 2 ;;
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
[ -z "$missing" ] || { printf 'the test suite needs:%s\n' "${missing#,}" >&2; exit 2; }
[ -f "$REGISTRY" ] || { printf 'FAIL: %s is missing\n' "$REGISTRY" >&2; exit 2; }

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
      command -v "$need" >/dev/null 2>&1 || WANT[$need]="$need" ;;
    pyyaml)
      python3 -c 'import yaml' >/dev/null 2>&1 || WANT[$need]="pyyaml" ;;
    codex-validator)
      [ -f "${CODEX_PLUGIN_VALIDATOR:-$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py}" ] \
        || WANT[$need]="codex-validator (the file codex-cli installs, or a copy fetched by the recipe in .github/workflows/validate.yml, named by CODEX_PLUGIN_VALIDATOR)" ;;
    *)
      printf 'ERROR: %s declares a need no probe knows: %s\n' "$2" "$need" >&2
      exit 2 ;;
  esac
}

# The `# needs:` line of a test's header: the block of comment lines that
# opens the file, ending at the first line that is not one.
declared_needs() {
  local line
  while IFS= read -r line; do
    case "$line" in
      '#!'*) ;;
      '# needs: '*) printf '%s\n' "${line#'# needs: '}"; return 0 ;;
      '#'*) ;;
      *) return 0 ;;
    esac
  done < "$1"
  return 0
}

# The header: short sha, `dirty` when the tree differs from HEAD, UTC time.
# tests/results.tsv is gitignored, so the run's own output never counts.
tree="$(git rev-parse --short HEAD 2>/dev/null || printf 'no-commit')"
[ -z "$(git status --porcelain 2>/dev/null)" ] || tree="$tree dirty"
printf '# %s %s\n' "$tree" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$RESULTS"

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
      printf '%s\tFAIL\t-\tneeds %s\n' "$t" "$unmet" >> "$RESULTS"
      failed=$((failed + 1))
    else
      printf 'SKIP %s (needs %s)\n' "$t" "$unmet"
      printf '%s\tSKIP\t-\tneeds %s\n' "$t" "$unmet" >> "$RESULTS"
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
    printf '%s\tPASS\t%s\t%s\n' "$t" "$status" "$last" >> "$RESULTS"
    passed=$((passed + 1))
  else
    printf 'FAIL %s\n' "$t"
    printf '%s\tFAIL\t%s\t%s\n' "$t" "$status" "$last" >> "$RESULTS"
    failed=$((failed + 1))
  fi
done

summary="$passed passed, $failed failed, $skipped skipped"
[ -z "$unmet_list" ] || summary="$summary for want of: ${unmet_list#, }"
printf '%s\n' "$summary"
[ "$failed" -eq 0 ]
```

- [ ] **Step 6: Run the runner test to verify it passes**

Run: `bash tests/test-runner.sh`
Expected: `runner: hard gate refuses, needs skip or fail, versions compared, results.tsv written`.

- [ ] **Step 7: Run the real suite once and read the result file**

Run: `tests/run.sh; head -n 3 tests/results.tsv`
Expected: every existing test `PASS` (the network ones need a connection), the last line `N passed, 0 failed, 0 skipped` with N the number of `tests/test-*.sh` files (21 at this point: the 19 that existed plus `test-ownership.sh` and this one), and a header `# <sha> <time>` (with `dirty` in the main checkout). `git status --short tests/` shows `results.tsv` nowhere, because it is ignored. `shellcheck -e SC1091 -e SC2016 tests/run.sh tests/test-runner.sh` exits 0.

- [ ] **Step 8: Commit**

```bash
git add tests/run.sh tests/tools.txt tests/test-runner.sh .gitignore
git commit -m "Gate the suite on bash 4, jq and git; declare every other tool as a need; write results.tsv" -m "tests/run.sh refuses with the complete list when the shared substrate cannot run (spec §5.1), reads one '# needs:' line per test and skips what a machine lacks, naming the tool and, for the six registry tools in tests/tools.txt, both versions (§5.2). --no-skip turns every unmet need into a FAIL for CI. Every run writes tests/results.tsv with a header naming the tree and one row per test, the repository half of #42: a report cites the path and nothing is transcribed. tests/test-runner.sh proves each of these on a scratch repository.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 5: Declare the needs, and move the shell lint into its own test

**Files:**

- Modify: `tests/test-claude-validate.sh` (header), `tests/test-codex-validate.sh` (header, lines 30–39), `tests/test-vendored-duplicates.sh` (header)
- Create: `tests/test-lint-shell.sh`
- Modify: `tests/test-setup-doctor.sh:14-36`

**Interfaces:**

- Consumes: the `# needs:` contract and `checked_shell`.
- Produces: `tests/test-lint-shell.sh`, the one place shellcheck runs from now on.

- [ ] **Step 1: Write the lint test**

Create `tests/test-lint-shell.sh`:

```bash
#!/usr/bin/env bash
# Every shell file this repository authors is shellcheck clean, style and
# info findings included, at the shellcheck version tests/tools.txt declares.
# Two exclusions, both structural rather than per-site: SC1091 because the
# tests source lib.sh through a path shellcheck cannot follow, and SC2016
# because the expected-output strings are single-quoted on purpose and must
# not expand. The vendored skills' scripts are upstream's and are covered by
# the drift tests instead.
# needs: shellcheck
. "$(dirname "$0")/lib.sh"

files="$(checked_shell)"
[ -n "$files" ] || fail "checked_shell() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
shellcheck -e SC1091 -e SC2016 $files || fail "shellcheck reported problems"
printf 'lint-shell: %s shell file(s) clean\n' "$(printf '%s\n' "$files" | grep -c .)"
```

- [ ] **Step 2: Prove it red by mutation, then run it green**

Run: `printf 'x=1\necho $x\n' >> tests/test-ownership.sh && bash tests/test-lint-shell.sh; git checkout -- tests/test-ownership.sh`
Expected: an `SC2086` finding on `tests/test-ownership.sh`, then `FAIL: shellcheck reported problems`, then the checkout restores the file.

Run: `bash tests/test-lint-shell.sh`
Expected: `lint-shell: 28 shell file(s) clean` — the 26 plus `test-ownership.sh` and `test-runner.sh`, committed by earlier tasks; this file joins the list once Step 7 stages it.

- [ ] **Step 3: Take the lint out of `tests/test-setup-doctor.sh` and ungate the tag assertion**

Replace lines 14–36 (`if command -v shellcheck …` through `fi`) with:

```bash
# upstream-watch's tag filter, with no network: the newest stable release
# wins over a prerelease, a -dev build, and a parallel tag series.
got="$(printf '%s\n' archify-dsh-v0.1.0 v2.16.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 \
  | bash "$REPO_ROOT/bin/upstream-watch" --newest-stable-tag)" \
  || fail "upstream-watch --newest-stable-tag failed"
[ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"
```

The assertion sat inside the shellcheck `if` by accident and was skipped wherever shellcheck was absent (§5.3).

- [ ] **Step 4: Add the `# needs:` lines**

In `tests/test-claude-validate.sh`, insert `# needs: claude` as a new line 5, directly before `. "$(dirname "$0")/lib.sh"`.

In `tests/test-vendored-duplicates.sh`, insert `# needs: python3` directly before `. "$(dirname "$0")/lib.sh"` (line 7 becomes line 8); `ast.parse` at line 33 is what needs it.

In `tests/test-codex-validate.sh`, insert `# needs: python3 pyyaml codex-validator` directly before `. "$(dirname "$0")/lib.sh"`.

- [ ] **Step 5: Correct the two comments in `tests/test-codex-validate.sh` (#40)**

Replace lines 30–33 (now 31–34):

```bash
    # A non-zero exit with no `- ` bullet at all -- a traceback, a missing
    # dependency, a message-format change -- is not one of the three
    # recorded exceptions and must fail loudly rather than fall through the
    # filter below with an empty $others.
```

Replace lines 36–39 (now 37–40):

```bash
    # -f with a process substitution, not -e: there is more than one pattern
    # and each begins with a dash, which would otherwise be read as options.
    # `|| true` because the inverting grep exits 1 when every bullet is a
    # known one, which is the case that must pass; the no-bullets case was
    # caught above.
```

- [ ] **Step 6: Run the suite and read the skips**

Run: `tests/run.sh; tail -n 1 tests/results.tsv`
Expected: every test `PASS` or, on a machine lacking a tool, a `SKIP` line naming it (`SKIP tests/test-lint-shell.sh (needs shellcheck 0.9.0; found 0.10.0)` on a machine with a different shellcheck). No `FAIL`. The tag assertion now runs on every machine.

- [ ] **Step 7: Commit**

```bash
git add tests/test-lint-shell.sh tests/test-setup-doctor.sh tests/test-claude-validate.sh tests/test-codex-validate.sh tests/test-vendored-duplicates.sh
git commit -m "Declare each test's needs, and lint the shell files from their own test" -m "The shellcheck block leaves tests/test-setup-doctor.sh for tests/test-lint-shell.sh under '# needs: shellcheck', over the derived shell list; the newest-stable-tag assertion that sat inside its 'if' by accident now runs everywhere (spec §5.3). claude, python3, pyyaml and the Codex validator are declared where they are used. Two comments in test-codex-validate.sh described code a task replaced (#40).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 6: The upgrade path becomes `tests/test-setup-upgrade.sh` (§5.3, §7.2)

**Files:**

- Create: `tests/test-setup-upgrade.sh`
- Modify: `tests/test-setup-doctor.sh` (delete the block that begins `# The upgrade path.` and ends at the `fi` after `printf 'SKIP: claude is not installed…'`, lines 106–196 at `55f1bcc`, about 90 lines below the edit of Task 5)

**Interfaces:**

- Consumes: `fetch_upstream`, `fetch_pinned`, `MARKETPLACE` from `tests/lib.sh`; `SD_MARKETPLACE_SOURCE` from `bin/setup`.

- [ ] **Step 1: Write the new test**

Create `tests/test-setup-upgrade.sh` (the moved block, with every command guarded and the fixture per Deviation P1):

```bash
#!/usr/bin/env bash
# The upgrade path. `claude plugin install` is a no-op on an already-installed
# plugin -- it prints "already installed", exits 0 and leaves the old version
# on disk -- so a machine holding an older version only moves under `claude
# plugin update`. The CI end-to-end job starts from an empty HOME and
# structurally cannot reach this path. The older install below is a real one
# rather than a hand-edited `version` field, because the CLI reads the version
# from the install path and answers "already at the latest version" to a
# seeded field. Fetches the pinned upstream trees, so it needs network.
# needs: claude
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
W="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$W"' EXIT
PJ="plugins/software-dev/.claude-plugin/plugin.json"
# sensemaking too: it installs as a dependency, and a parent's update does
# not carry it, so its own update path is exercised here on every run.
PJS="plugins/sensemaking/.claude-plugin/plugin.json"
cp -a "$REPO_ROOT" "$W/repo" || fail "could not copy the checkout into $W"
jq '.version = "0.0.1"' "$REPO_ROOT/$PJ" > "$W/lowered" || fail "could not lower the version"
cp "$W/lowered" "$W/repo/$PJ" || fail "could not seed the lowered manifest"
jq '.version = "0.0.1"' "$REPO_ROOT/$PJS" > "$W/lowered-s" || fail "could not lower sensemaking's version"
cp "$W/lowered-s" "$W/repo/$PJS" || fail "could not seed sensemaking's lowered manifest"

mkdir -p "$W/home" || fail "could not create $W/home"
env HOME="$W/home" claude plugin marketplace add "$W/repo" >/dev/null 2>&1 \
  || fail "could not add the copied marketplace"
env HOME="$W/home" claude plugin install software-dev@eranroseman --scope user \
  >/dev/null 2>&1 || fail "could not seed the 0.0.1 install"
# Back to the declared version, and refresh the catalogue, mirroring the
# documented real-machine step.
cp "$REPO_ROOT/$PJ" "$W/repo/$PJ" || fail "could not restore the manifest"
cp "$REPO_ROOT/$PJS" "$W/repo/$PJS" || fail "could not restore sensemaking's manifest"
env HOME="$W/home" claude plugin marketplace update eranroseman >/dev/null 2>&1 \
  || fail "could not refresh the copied marketplace"

# The pinned clone, seeded from the shared checkout, so the only thing left
# for bin/setup to converge is the Claude half.
CLONE="$W/home/.local/share/software-dev/upstream/superpowers"
mkdir -p "$(dirname "$CLONE")" || fail "could not create the upstream root"
cp -a "$(fetch_upstream)" "$CLONE" || fail "could not seed the pinned clone"
# Every other curated entry's clone, the same way, so bin/setup has nothing
# to fetch: the CI end-to-end job is where the real clone is exercised.
while IFS="$(printf '\t')" read -r name url sha; do
  [ -n "$name" ] || continue
  [ "$name" != superpowers ] || continue
  cp -a "$(fetch_pinned "$url" "$sha" "${TMPDIR:-/tmp}/software-dev-upstream-$name")" \
    "$(dirname "$CLONE")/$name" || fail "could not seed the $name clone"
done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir")
                | [.name, .source.url, .source.sha] | @tsv' "$MARKETPLACE")

# A bin directory without codex, mirroring tests/test-doctor-faults.sh: on a
# machine that has codex on PATH, ensure_codex is no longer a stub, and an
# inherited PATH would make it add the real eranroseman marketplace by
# cloning it over the network into this scratch CODEX_HOME on every run.
# claude is real, because the fixture drives it, and so is node: wherever
# claude was installed with npm, as on the CI runner, it is a node script.
# npx is a stub that exits 1: the pinned lockfile below means ensure_skills_sh
# never runs it, and an unexpected call is then a visible FAIL line rather
# than a network install.
BIN="$W/bin"
mkdir -p "$BIN" || fail "could not create $BIN"
for t in bash git jq node claude sed awk grep find date readlink basename dirname \
         rm mv ln mkdir cp cat sha256sum; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t" || fail "could not link $t into $BIN"
done
printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/npx" || fail "could not write the npx stub"
chmod +x "$BIN/npx" || fail "could not make the npx stub executable"

# A fully pinned lockfile, mirroring tests/test-doctor-faults.sh: without it,
# ensure_skills_sh would find every declared skill unpinned and try to
# install all of them over the network on every run of this test.
mkdir -p "$W/home/.agents" || fail "could not create $W/home/.agents"
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' \
  "$REPO_ROOT/upstream/skills.json" > "$W/home/.agents/.skill-lock.json" \
  || fail "could not synthesize a pinned lockfile"

want="$(jq -r .version "$REPO_ROOT/$PJ")" || fail "could not read the declared version"
if out="$(env HOME="$W/home" CODEX_HOME="$W/home/.codex" SD_MARKETPLACE_SOURCE="$W/repo" \
    PATH="$BIN" bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
got="$(jq -r '.plugins["software-dev@eranroseman"][0].version' \
  "$W/home/.claude/plugins/installed_plugins.json")" || fail "could not read the installed version"
[ "$got" = "$want" ] \
  || fail "bin/setup left software-dev at $got, declared $want:"$'\n'"$out"
want_s="$(jq -r .version "$REPO_ROOT/$PJS")" || fail "could not read sensemaking's declared version"
got_s="$(jq -r '.plugins["sensemaking@eranroseman"][0].version' \
  "$W/home/.claude/plugins/installed_plugins.json")" || fail "could not read sensemaking's installed version"
[ "$got_s" = "$want_s" ] \
  || fail "bin/setup left sensemaking at $got_s, declared $want_s; a dependency does not move with its parent:"$'\n'"$out"
[ "$status" -eq 0 ] \
  || fail "bin/setup did not converge on an upgradeable machine (exit $status):"$'\n'"$out"

printf 'setup-upgrade: software-dev and sensemaking moved to the declared versions under claude plugin update\n'
```

- [ ] **Step 2: Delete the block from `tests/test-setup-doctor.sh`**

Delete from the line `# The upgrade path. \`claude plugin install\` is a no-op on an already-installed`through the line`fi`that follows` printf 'SKIP: claude is not installed, so the upgrade path was not exercised\n'`(inclusive; lines 106–196 at`55f1bcc`, shifted by Task 5's edit). The next surviving line is`# The Codex half is gated the same way, and says so.`

- [ ] **Step 3: Run both tests**

Run: `bash tests/test-setup-upgrade.sh && bash tests/test-setup-doctor.sh`
Expected: `setup-upgrade: software-dev and sensemaking moved to the declared versions under claude plugin update`, then `setup-doctor: two entry points, lint clean, prerequisites split as documented`. On a machine without `claude` the first prints `FAIL:` from the CLI's absence when run directly; through `tests/run.sh` it is `SKIP tests/test-setup-upgrade.sh (needs claude)`.

Run: `grep -c 'SKIP:' tests/test-setup-doctor.sh`
Expected: `3` — the three assertions on the engine's own `SKIP:` lines remain; the two `SKIP` branches of the test itself are gone (the jq fixture's move follows in Task 8).

- [ ] **Step 4: Commit**

```bash
git add tests/test-setup-upgrade.sh tests/test-setup-doctor.sh
git commit -m "Move the upgrade path into its own test, declared on claude" -m "tests/test-setup-upgrade.sh carries the block with '# needs: claude', so a machine without the CLI skips one file and still runs the engine-shape assertions (spec §5.3). Every cp, mkdir and capture is guarded (#16). node stays real in the fixture because claude is a node script wherever npm installed it, as on the CI runner; only npx is a stub, and the pinned lockfile means it is never called.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 7: The repair fixture becomes hermetic (§5.3)

**Files:**

- Modify: `tests/test-doctor-faults.sh` (lines 2–5, 192–216)

- [ ] **Step 1: Replace the repair fixture's `PATH` and delete the skip**

Replace lines 205–216 (from `BIN="$H/bin"` through the `fi` that closes `if [ ! -x "$BIN/claude" ]; then`) with:

```bash
BIN="$H/bin"
mkdir -p "$BIN" || fail "could not create $BIN"
for t in bash git jq sed awk grep find date readlink basename dirname \
         rm mv ln mkdir cp cat sha256sum; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t" || fail "could not link $t into $BIN"
done
# claude, node and npx are stubs that exit 1, on PATH to satisfy require_tools
# and nothing else: the seeded registry and the pinned lockfile mean no
# Claude or skills.sh command ever runs, so a real binary would prove nothing
# a stub does not, and an unexpected invocation becomes a visible FAIL line.
# This is what makes the test hermetic on a machine without the CLI.
for t in claude node npx; do
  printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/$t" || fail "could not write the $t stub"
  chmod +x "$BIN/$t" || fail "could not make the $t stub executable"
done
```

Also amend the comment above it (lines 192–204): after `#     The unpinned entry seeded above was for the check pass only.` the bullet list is complete as written; leave the rest.

Replace lines 2–5 of the header with:

```bash
# bin/doctor must report each seeded fault by name against a scratch HOME, and
# bin/setup must repair it. The assertions check that the named lines appear,
# not that they are the only ones. Needs no network and no CLI: every fault is
# filesystem or git state, and every harness binary on the fixture PATH is a
# stub that exits 1.
```

- [ ] **Step 2: Run it with the real `claude` hidden, then normally**

Run: `env PATH=/usr/bin:/bin bash tests/test-doctor-faults.sh` — a `PATH` without `~/.local/bin`, where `claude` lives on this machine, so nothing real is available to the fixture.
Expected: `doctor-faults: six seeded faults reported and the local ones repaired` — no `SKIP:` line.

Run: `bash tests/test-doctor-faults.sh && grep -c 'SKIP' tests/test-doctor-faults.sh`
Expected: the same success line, then `0`.

- [ ] **Step 3: Commit**

```bash
git add tests/test-doctor-faults.sh
git commit -m "Stub the three harness binaries in the repair fixture instead of skipping without them" -m "The repair fixture linked the real claude, node and npx only to satisfy require_tools; the seeded registry and the pinned lockfile mean none of them ever runs. Stubs that exit 1 serve as well and turn an unexpected invocation into a FAIL line, and the SKIP branch, unreachable anyway because the fixture loop above it already failed without the three, is deleted (spec §5.3). The test is hermetic and declares no need.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 8: `tests/test-doctor-silence.sh`, fixtures 1–7 (§6.2, #38)

**Files:**

- Create: `tests/test-doctor-silence.sh`
- Modify: `tests/test-doctor-faults.sh` (delete the first-entry block, lines 84–119 at `55f1bcc`: from `# A curated entry whose \`skills\` array cannot be iterated`through the`|| fail "bin/setup did not report the unreadable curated skill list:…"`line; also the`W`/`WH` temporaries it created)
- Modify: `tests/test-setup-doctor.sh` (delete the jq fixture, lines 63–95 at `55f1bcc`: from `# A machine the doctor could not read is not a clean machine.` through the `|| fail "the verdict does not say which tool left the machine unchecked:…"` line)

**Interfaces:**

- Produces: `scratch_repo <name>` (prints a scratch checkout under `$T` holding a symlinked `bin/setup` and copies of both declarations), `bin_without [name…]` (prints a restricted `PATH` directory), `run_case <label> <repo> <home> <path>` (runs `bin/setup --check`, asserts non-zero exit and no `clean`, leaves the output in `OUT`). Tasks 13 and 15 append fixtures 8–10 using these.

- [ ] **Step 1: Write the test with the first seven fixtures**

```bash
#!/usr/bin/env bash
# The machines the doctor cannot read (spec §6.2). For each, bin/setup --check
# must exit non-zero and never print the line `clean`; most cases also assert
# the line that names what could not be read. Each fixture is a scratch
# checkout -- a symlinked bin/setup beside a corrupted declaration -- so the
# real marketplace.json is never touched. Needs no network and no CLI: every
# fixture PATH omits claude, codex, node and npx, so both harness halves report
# skipped and nothing can reach the network.
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

# A restricted PATH: everything the engine runs in check mode, minus the
# names given. Prints the directory.
bin_without() {
  local dir="$T/bin-without${1:+-$1}" t x skip p
  mkdir -p "$dir" || fail "could not create $dir"
  for t in bash git jq sed awk grep find date readlink basename dirname \
           mv ln mkdir cp cat sha256sum; do
    skip=0
    for x in "$@"; do [ "$t" != "$x" ] || skip=1; done
    [ "$skip" -eq 0 ] || continue
    p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
    ln -sf "$p" "$dir/$t" || fail "could not link $t into $dir"
  done
  printf '%s\n' "$dir"
}

# A scratch checkout named $1 under $T: a symlinked bin/setup, so REPO_ROOT
# resolves to the scratch directory, and intact copies of both declarations
# for the case to corrupt. Prints its path.
scratch_repo() {
  local r="$T/$1"
  mkdir -p "$r/bin" "$r/.claude-plugin" "$r/upstream" || fail "could not seed $r"
  ln -s "$REPO_ROOT/bin/setup" "$r/bin/setup" || fail "could not link bin/setup into $r"
  cp "$MARKETPLACE" "$r/.claude-plugin/marketplace.json" || fail "could not copy the marketplace into $r"
  cp "$REPO_ROOT/upstream/skills.json" "$r/upstream/skills.json" || fail "could not copy skills.json into $r"
  printf '%s\n' "$r"
}

# $1 a label, $2 the scratch checkout, $3 the HOME, $4 the PATH directory.
# Runs bin/setup --check, asserts the two properties every unreadable machine
# must have, and leaves the output in OUT for the case's own assertions.
run_case() {
  local label="$1" repo="$2" home="$3" path="$4" status
  mkdir -p "$home" || fail "$label: could not create $home"
  if OUT="$(env HOME="$home" CODEX_HOME="$home/.codex" PATH="$path" \
      /bin/bash "$repo/bin/setup" --check 2>&1)"; then status=0; else status=$?; fi
  [ "$status" -ne 0 ] || fail "$label: bin/setup --check exited 0:"$'\n'"$OUT"
  printf '%s\n' "$OUT" | grep -qx 'clean' \
    && fail "$label: the doctor called an unread machine clean:"$'\n'"$OUT"
  return 0
}
saw() { printf '%s\n' "$OUT" | grep -q -- "$1"; }

# A HOME whose skill root exists, so every check gets past ensure_links'
# root guard and reaches the declaration it reads. Prints the path.
seeded_home() {
  mkdir -p "$T/home-$1/.agents/skills" || fail "could not seed home-$1"
  printf '%s\n' "$T/home-$1"
}

BIN="$(bin_without)"

# 1. A malformed marketplace.json: jq fails on every read, and each reader
# says so rather than iterating nothing.
R="$(scratch_repo malformed)"
printf '{\n' > "$R/.claude-plugin/marketplace.json" || fail "could not corrupt the marketplace"
run_case "malformed marketplace" "$R" "$(seeded_home 1)" "$BIN"
saw 'no curated (git-subdir) entry could be read' \
  || fail "malformed marketplace: ensure_clones did not report the unreadable declarations:"$'\n'"$OUT"
saw 'the curated skill list could not be read from' \
  || fail "malformed marketplace: ensure_links did not report the unreadable declarations:"$'\n'"$OUT"

# 2. Well-formed, with every git-subdir entry removed: zero curated entries
# is a declaration defect, not a clean machine.
R="$(scratch_repo no-curated)"
jq 'del(.plugins[] | select(.source.source? == "git-subdir"))' "$MARKETPLACE" \
  > "$R/.claude-plugin/marketplace.json" || fail "could not remove the git-subdir entries"
run_case "no curated entries" "$R" "$(seeded_home 2)" "$BIN"
saw 'no curated (git-subdir) entry could be read' \
  || fail "no curated entries: the zero-entry guard did not fire:"$'\n'"$OUT"
saw 'no curated skill is declared' \
  || fail "no curated entries: the zero-skill guard did not fire:"$'\n'"$OUT"

# 3. The first git-subdir entry without `.skills`: the jq program that feeds
# ensure_links aborts before printing a single row (exit 5, zero rows). The
# non-zero exit catches it, and a row count would too; fixture 4 is the shape
# only the exit status can see. This block moved here from
# tests/test-doctor-faults.sh, where its comment described fixture 4's shape
# while seeding this one (#38).
first="$(jq -r '[.plugins[] | select(.source.source? == "git-subdir")][0].name' "$MARKETPLACE")" \
  || fail "could not read the first git-subdir entry"
R="$(scratch_repo first-no-skills)"
jq --arg n "$first" 'del(.plugins[] | select(.name == $n) | .skills)' "$MARKETPLACE" \
  > "$R/.claude-plugin/marketplace.json" || fail "could not strip .skills from $first"
run_case "first entry without .skills" "$R" "$(seeded_home 3)" "$BIN"
saw 'the curated skill list could not be read from' \
  || fail "first entry without .skills: the unreadable list was not reported:"$'\n'"$OUT"

# 4. The second git-subdir entry without `.skills`: jq aborts after the first
# entry's thirteen rows (exit 5, thirteen rows). A row count passes; only
# the exit status catches it. Both issue bodies attributed this shape to the
# wrong entry, which is why the two fixtures sit side by side.
second="$(jq -r '[.plugins[] | select(.source.source? == "git-subdir")][1].name' "$MARKETPLACE")" \
  || fail "could not read the second git-subdir entry"
if [ -z "$second" ] || [ "$second" = null ]; then fail "the marketplace declares fewer than two git-subdir entries"; fi
R="$(scratch_repo second-no-skills)"
jq --arg n "$second" 'del(.plugins[] | select(.name == $n) | .skills)' "$MARKETPLACE" \
  > "$R/.claude-plugin/marketplace.json" || fail "could not strip .skills from $second"
run_case "second entry without .skills" "$R" "$(seeded_home 4)" "$BIN"
saw 'the curated skill list could not be read from' \
  || fail "second entry without .skills: the partial list was not reported:"$'\n'"$OUT"

# 5. jq off PATH. jq is not an optional harness like claude or codex, whose
# absence makes one half genuinely inapplicable: it is the reader of this
# repository's own declarations, so without it every check is unanswered.
# The home passes the one guard that needs no jq -- a skill root that merely
# exists, the converged-then-drifted machine the doctor is for -- so nothing
# stands between "could not read" and a false all-clear. Moved here from
# tests/test-setup-doctor.sh.
R="$(scratch_repo jqless)"
mkdir -p "$T/home-5/.local/share/software-dev/upstream/superpowers/.git" "$T/home-5/.agents/skills" \
  || fail "could not seed the jqless home"
run_case "jq off PATH" "$R" "$T/home-5" "$(bin_without jq)"
saw 'jq is not on PATH' || fail "jq off PATH: the doctor did not name the tool it was missing:"$'\n'"$OUT"
saw 'for want of: jq' || fail "jq off PATH: the verdict does not say which tool left the machine unchecked:"$'\n'"$OUT"

# 6. sha256sum off PATH: the duplicate check cannot compare content, says so,
# and the verdict names it.
R="$(scratch_repo hashless)"
run_case "sha256sum off PATH" "$R" "$(seeded_home 6)" "$(bin_without sha256sum)"
saw 'sha256sum is not on PATH' || fail "sha256sum off PATH: the skip was not reported:"$'\n'"$OUT"
saw 'for want of: sha256sum' || fail "sha256sum off PATH: the verdict does not name it:"$'\n'"$OUT"

# 7. An empty HOME: nothing is installed, and the doctor describes that
# rather than dying on it.
R="$(scratch_repo empty-home)"
run_case "empty HOME" "$R" "$T/home-7" "$BIN"
saw 'FAIL:' || fail "empty HOME: no FAIL line at all:"$'\n'"$OUT"
saw 'the skill root is missing' || fail "empty HOME: the skill root was not reported:"$'\n'"$OUT"

printf 'doctor-silence: 7 unreadable machines, none reported clean\n'
```

- [ ] **Step 2: Run it**

Run: `bash tests/test-doctor-silence.sh`
Expected: `doctor-silence: 7 unreadable machines, none reported clean`. All seven pass against today's engine: they are the regression guards the two moved blocks already were, plus five shapes nothing asserted.

- [ ] **Step 3: Delete the two moved blocks**

In `tests/test-doctor-faults.sh`, delete from `# A curated entry whose \`skills\` array cannot be iterated must produce a`through the line` || fail "bin/setup did not report the unreadable curated skill list:"$'\n'"$out"`(inclusive). The`W`and`WH`directories are created in that block only; the later`trap 'rm -rf "$H" "$W" "$WH" "$H2"' EXIT`line therefore becomes`trap 'rm -rf "$H" "$H2"' EXIT`.

In `tests/test-setup-doctor.sh`, delete from `# A machine the doctor could not read is not a clean machine. jq is not an` through the line `|| fail "the verdict does not say which tool left the machine unchecked:"$'\n'"$out"` (inclusive).

- [ ] **Step 4: Run the three tests**

Run: `bash tests/test-doctor-faults.sh && bash tests/test-setup-doctor.sh && bash tests/test-doctor-silence.sh && bash tests/test-lint-shell.sh`
Expected: all four success lines; shellcheck clean (an unused `W` or `WH` would be an SC2034 finding).

- [ ] **Step 5: Commit**

```bash
git add tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh
git commit -m "Enumerate the machines the doctor cannot read in one test" -m "tests/test-doctor-silence.sh holds seven fixtures (spec §6.2): a malformed marketplace, no curated entry, the first and the second git-subdir entry without .skills, jq and sha256sum off PATH, an empty HOME. The first-entry block moves in from test-doctor-faults.sh with its comment corrected -- it described the second-entry shape while seeding the first (#38) -- beside the second-entry fixture that only the exit status can catch; the jq fixture moves in from test-setup-doctor.sh.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 9: `tests/test-setup-doctor.sh` rewritten; `bin/setup` and `bin/doctor` stop calling `dirname` (#16, #18, §6.5)

**Files:**

- Modify: `tests/test-setup-doctor.sh` (whole file)
- Modify: `bin/setup:21`
- Modify: `bin/doctor` (whole file)

**Interfaces:**

- Consumes: `bin/setup`'s refusal text `bin/setup needs these on PATH: git jq node npx claude (bin/doctor needs none)` and the doctor's `for want of:` verdict.

- [ ] **Step 1: Replace `tests/test-setup-doctor.sh`**

````bash
#!/usr/bin/env bash
# The engine's shape: two entry points, one of them a wrapper; a usage text;
# the documented prerequisite split, with both scripts run under an empty
# PATH; a doctor that describes an empty machine rather than dying on it; the
# gated halves reporting their own absence; the report-only checks; and the
# README recipes against the usage text. Needs no network and no CLI. The
# shell lint is tests/test-lint-shell.sh, the upgrade path is
# tests/test-setup-upgrade.sh, and the machines the doctor cannot read are
# tests/test-doctor-silence.sh.
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
DOCTOR="$REPO_ROOT/bin/doctor"
[ -x "$SETUP" ] || fail "bin/setup missing or not executable"
[ -x "$DOCTOR" ] || fail "bin/doctor missing or not executable"

# upstream-watch's tag filter, with no network: the newest stable release
# wins over a prerelease, a -dev build, and a parallel tag series.
got="$(printf '%s\n' archify-dsh-v0.1.0 v2.16.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 \
  | bash "$REPO_ROOT/bin/upstream-watch" --newest-stable-tag)" \
  || fail "upstream-watch --newest-stable-tag failed"
[ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"

# bin/doctor is the same engine in check mode, not a second implementation.
[ "$(grep -c . "$DOCTOR")" -le 6 ] || fail "bin/doctor should be a thin wrapper over bin/setup --check"
grep -q -- '--check' "$DOCTOR" || fail "bin/doctor must invoke bin/setup --check"

"$SETUP" --help >/dev/null 2>&1 || fail "bin/setup --help must exit 0"
"$SETUP" --nonsense >/dev/null 2>&1 && fail "an unknown argument must not exit 0"

# Prerequisites: fatal for setup, gated for the doctor. An empty PATH removes
# every one of the five, so setup must refuse and the doctor must not.
H="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$H"' EXIT
# /bin/bash by absolute path: with an empty PATH, `bash` itself would not
# resolve and the failure would be the shell's 127, not the script's 2. A
# command meant to exit non-zero is captured as `if out="$(...)"`: lib.sh is
# `set -e`, and a bare capture whose command fails kills the test on that
# line, before `status=$?` runs.
if out="$(env -i HOME="$H" PATH="$H/nowhere" /bin/bash "$SETUP" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "bin/setup must exit 2 when a fatal prerequisite is missing (got $status)"
# The refusal's own words, not a substring the script's path could supply:
# under the deployment path, `<path>: dirname: command not found` once
# carried `.claude` and satisfied a grep for `claude` on its own (#16).
printf '%s\n' "$out" | grep -q 'bin/setup needs these on PATH:.*claude' \
  || fail "the refusal must name the missing tools in its own words: $out"
printf '%s\n' "$out" | grep -q 'command not found' \
  && fail "bin/setup ran an external command before refusing:"$'\n'"$out"

# The doctor under the same empty PATH: nothing is fatal, every check opens
# on `needs jq`, the skill root is reported missing, and the verdict names
# the tool. The doctor resolves its own directory by parameter expansion and
# the shell by $BASH, which is why both scripts are invoked as
# `/bin/bash <script>` here rather than through their shebang.
if out="$(env -i HOME="$H" PATH="$H/nowhere" /bin/bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/doctor under an empty PATH must exit 1, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'command not found' \
  && fail "bin/doctor ran an external command under an empty PATH:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'the skill root is missing' \
  || fail "the doctor under an empty PATH did not report the skill root:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'for want of: jq' \
  || fail "the doctor under an empty PATH did not name jq in its verdict:"$'\n'"$out"

# The doctor on an empty machine: describes it, exits 1, dies on nothing.
if out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 1 ] || fail "bin/doctor on an empty HOME must exit 1, got $status"
printf '%s\n' "$out" | grep -q 'FAIL:' || fail "the doctor reported no failure on an empty HOME"

# The Claude half reports its own absence rather than assuming it.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="/usr/bin:/bin" bash "$DOCTOR" 2>&1 || true)"
if command -v claude >/dev/null 2>&1 && [ -x /usr/bin/claude ]; then
  printf 'NOTE: claude is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: claude' \
    || fail "with claude off PATH the doctor must report the Claude half as skipped"
fi

# The Codex half is gated the same way, and says so.
if command -v codex >/dev/null 2>&1 && [ -x /usr/bin/codex ]; then
  printf 'NOTE: codex is on the minimal PATH; the gating assertion is not exercised\n'
else
  printf '%s\n' "$out" | grep -q 'SKIP: codex' \
    || fail "with codex off PATH the doctor must report the Codex half as skipped"
fi

# Report-only checks: present on every run, never repaired.
out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'telemetry' \
  || fail "the doctor does not report the telemetry variable"
printf '%s\n' "$out" | grep -q 'auto-update' \
  || fail "the doctor does not report the auto-update state"

# A scratch HOME whose marketplace entry is a directory has no clone to compare,
# so the staleness check must skip rather than fail.
mkdir -p "$H/.claude/plugins" || fail "could not create $H/.claude/plugins"
cat > "$H/.claude/plugins/known_marketplaces.json" <<JSON || fail "could not write known_marketplaces.json"
{"eranroseman":{"source":{"source":"directory","path":"$REPO_ROOT"},"installLocation":"$REPO_ROOT"}}
JSON
out="$(env HOME="$H" CODEX_HOME="$H/.codex" bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'SKIP: the marketplace source is a directory' \
  || fail "a directory marketplace source must skip the staleness check, not fail it"

# Every fenced block in an Install or Update section of either README must
# appear verbatim in the usage text, so a command cannot be documented in one
# place and not the other. Scoped to those two headings -- not every fenced
# block in the file -- so a non-command sample under an unrelated heading (a
# JSON example under Environment, say) cannot produce a false failure.
help_text="$("$SETUP" --help 2>&1)" || fail "bin/setup --help failed"
# Extract fenced blocks whose nearest preceding h2 starts with "Install" or
# "Update" (so "## Updates" counts too). An h1 or an h2 closes the scope; an
# h3 stays inside its parent, which is what "every fenced block in the
# section" means (#18). \036 is the record separator awk prints between
# blocks; no README carries it.
extract_scoped_blocks() {
  awk '
    /^## / { insection = ($0 ~ /^## (Install|Update)/); next }
    /^```/ { infence = !infence; if (!infence && insection) print "\036"; next }
    infence && insection { print }
  ' "$1"
}
# The scope rule, proved on a synthetic README carrying all three headings:
# a block under `### Sub` inside Install is in, blocks after a `# Top` or
# under `## Other` are out.
S="$H/scope.md"
printf '%s\n' '# Title' '```' 'h1-before' '```' '## Install' '```' 'in-install' '```' \
  '### Sub' '```' 'in-sub' '```' '# Top' '```' 'after-h1' '```' '## Update' '```' 'in-update' '```' \
  '## Other' '```' 'in-other' '```' > "$S" || fail "could not write $S"
got="$(extract_scoped_blocks "$S" | tr -d '\036' | grep . | tr '\n' ' ')" || true
[ "$got" = "in-install in-sub in-update " ] \
  || fail "extract_scoped_blocks must keep an h3 inside its section and close on an h1 or h2; got '$got'"
# $1 the README path, $2 the minimum number of Install/Update blocks it must
# contribute -- the "found 0" guard from before, now per file, so a renamed
# heading cannot silently drop a whole README out of coverage.
check_readme_blocks() {
  local readme="$1" min="$2" blocks=0 buf=""
  while IFS= read -r line; do
    if [ "$line" = "$(printf '\036')" ]; then
      [ -n "$buf" ] || continue
      case "$help_text" in
        *"$buf"*) blocks=$((blocks + 1)) ;;
        *) fail "a fenced Install/Update block in $readme is missing from bin/setup --help: $buf" ;;
      esac
      buf=""
    elif [ -z "$buf" ]; then
      buf="$line"
    else
      buf="$buf
$line"
    fi
  done < <(extract_scoped_blocks "$readme")
  [ "$blocks" -ge "$min" ] \
    || fail "expected at least $min fenced Install/Update block(s) in $readme, found $blocks"
}
check_readme_blocks "$REPO_ROOT/README.md" 2
check_readme_blocks "$REPO_ROOT/plugins/software-dev/README.md" 1

printf 'setup-doctor: two entry points, prerequisites split as documented, recipes match the usage text\n'
````

- [ ] **Step 2: Run it to verify it fails on the extractor**

Run: `bash tests/test-setup-doctor.sh`
Expected: exit 1 at `bin/setup ran an external command before refusing:` — the `dirname: command not found` line is still printed. That is the first red; the extractor's red comes after the engine is fixed, so fix the engine first.

- [ ] **Step 3: Fix `bin/setup:21` and rewrite `bin/doctor`**

In `bin/setup`, replace line 21, `REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"`, with:

```bash
# Builtins only until require_tools has spoken: under an empty PATH the
# external dirname is `command not found`, and that line, carrying the
# script's own path, once satisfied a test's grep for `claude` before the
# refusal was printed (#16). A $0 with no slash was found through PATH or run
# as `bash setup` from its own directory, so its directory is `.`.
script_dir="${0%/*}"
[ "$script_dir" != "$0" ] || script_dir=.
REPO_ROOT="$(cd "$script_dir/.." && pwd)"
```

Replace `bin/doctor` whole (six non-empty lines, the most the shape assertion allows):

```bash
#!/usr/bin/env bash
# The check mode of bin/setup: report this machine and change nothing. Builtins
# only, and the shell by its own path, so an empty PATH cannot stop it (#16).
dir="${0%/*}"
[ "$dir" != "$0" ] || dir=.
exec "$BASH" "$dir/setup" --check "$@"
```

`exec "$BASH"` rather than the file's shebang: `#!/usr/bin/env bash` resolves `bash` through `PATH`, and the doctor exists to describe a machine that has nothing.

- [ ] **Step 4: Run it to verify it fails on the extractor now**

Run: `bash tests/test-setup-doctor.sh`
Expected: `FAIL: extract_scoped_blocks must keep an h3 inside its section and close on an h1 or h2; got 'in-install in-sub after-h1 in-update '` — the `# Top` block leaks, because only `##` resets the scope.

- [ ] **Step 5: Fix the extractor's regex**

In `extract_scoped_blocks`, change `/^## / { insection = …` to `/^##? / { insection = …`. The `$0 ~ /^## (Install|Update)/` test on the same line stays, so an h1 sets `insection` to 0 and an h3 never reaches the rule.

- [ ] **Step 6: Run the test to verify it passes, then the neighbours**

Run: `bash tests/test-setup-doctor.sh && bash tests/test-doctor-faults.sh && bash tests/test-doctor-silence.sh && bash tests/test-doctor-duplicates.sh && bash tests/test-lint-shell.sh`
Expected: `setup-doctor: two entry points, prerequisites split as documented, recipes match the usage text` and the other four success lines. Then `env -i HOME="$(mktemp -d)" PATH=/nowhere /bin/bash bin/doctor; echo "exit=$?"` by hand (`HOME` set, because the engine reads it under `set -u`): every check opens on `SKIP: jq is not on PATH`, one `FAIL: the skill root is missing`, the verdict `4 check(s) could not run for want of: jq; this machine is unchecked, not verified`, `exit=1`, and no `command not found` anywhere.

- [ ] **Step 7: Commit**

```bash
git add tests/test-setup-doctor.sh bin/setup bin/doctor
git commit -m "Guard every command in the engine-shape test, and keep both scripts alive under an empty PATH" -m "bin/setup and bin/doctor resolved their own directory with the external dirname before anything else; under an empty PATH bash printed '<path>: dirname: command not found' first, and in the deployment path that line carries '.claude', so the test's grep for the refusal was satisfied by the noise (#16). Both use parameter expansion now, and the doctor execs \$BASH rather than resolving bash through the shebang, so the doctor survives an empty PATH and says 'for want of: jq' (spec §6.5). The test asserts both and greps the refusal's own words. Every cp, mkdir, cat and capture is guarded; two stale comments go; the README extractor closes its scope on an h1 or an h2 and keeps an h3 inside its parent, proved on a synthetic README (#18).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 10: Portable tests (#5, §7.6)

**Files:**

- Modify: `tests/test-upstream-pin.sh:14,24`
- Modify: `tests/test-vendored-scaffolder.sh:209,217`

- [ ] **Step 1: Replace `mapfile` and the three `find -printf` sites**

`tests/test-upstream-pin.sh` line 14, `mapfile -t listed < <(…)`, becomes:

```bash
listed=()
while IFS= read -r s; do listed+=("$s"); done \
  < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##' | sort)
```

Line 24 (now 26), `<(find "$UP/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)`, becomes:

```bash
     <(for d in "$UP"/skills/*/; do d="${d%/}"; printf '%s\n' "${d##*/}"; done | sort) \
```

`tests/test-vendored-scaffolder.sh` line 209, inside `available="$(…)"`, `find "$REPO_ROOT/plugins" -mindepth 3 -maxdepth 3 -type d -path '*/skills/*' -printf '%f\n'` becomes:

```bash
  for d in "$REPO_ROOT"/plugins/*/skills/*/; do d="${d%/}"; printf '%s\n' "${d##*/}"; done
```

Line 217, `done < <(find "$U/.." -mindepth 1 -maxdepth 1 -type d -printf '%f\n')`, becomes:

```bash
done < <(for d in "$U"/../*/; do d="${d%/}"; printf '%s\n' "${d##*/}"; done)
```

A trailing-slash glob matches directories only, `${d%/}` strips the slash and `${d##*/}` leaves the basename: the same list `-type d -printf '%f\n'` produced, in POSIX shell.

- [ ] **Step 2: Confirm no GNU-only construct remains**

Run: `grep -n 'mapfile\|readarray\|-printf\|grep -P\|sed -i\|date -d' tests/*.sh`
Expected: no output. (`find -not` in `test-skills-pin.sh:61` stays: BSD find accepts it.)

- [ ] **Step 3: Run the two tests (network)**

Run: `bash tests/test-upstream-pin.sh && bash tests/test-vendored-scaffolder.sh && bash tests/test-lint-shell.sh`
Expected: `upstream-pin: 13 listed dirs exist at b36e0829…; brainstorming excluded; version 6.3.0`, `vendored-scaffolder: matches mattpocock/skills v1.2.3 except header + declared regions; N skill name(s) resolve` with N greater than zero, and the lint clean.

- [ ] **Step 4: Commit**

```bash
git add tests/test-upstream-pin.sh tests/test-vendored-scaffolder.sh
git commit -m "Make the three GNU-only test sites portable" -m "mapfile becomes a read loop and find -printf becomes a glob loop printing basenames, at the three sites #5 named (spec §7.6). No probe for GNU find joins the gate; the tests themselves now need nothing past bash 3.2, and the engine's sha256sum and readlink -f stay, because the engine is not what #5 is about.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 11: Manifests that can disagree (#1, §7.1)

**Files:**

- Modify: `tests/test-references-resolve.sh` (append Check C before the final `printf`)
- Modify: `tests/test-codex-marketplace.sh:23`
- Modify: `tests/test-claude-validate.sh:12`
- Modify: `tests/test-hook.sh:79-80` (delete)

- [ ] **Step 1: Add the equality check**

In `tests/test-references-resolve.sh`, before the final `printf`, insert:

```bash
# Check C: the two manifests of each plugin agree on every field they share
# (#1). Compared as one projected object under jq -S, so a drifted key shows
# itself in the diff. description is excluded on purpose: software-dev's two
# differ by design ("and its inspector" on the Claude side, where the
# subagent ships) and tests/test-hook.sh guards that direction. The Codex
# manifest's skills pointer must resolve to a directory.
pairs=0
proj='{name, version, author, homepage, repository, license, keywords}'
for p in "$REPO_ROOT"/plugins/*/; do
  name="$(basename "$p")"
  cm="$p/.claude-plugin/plugin.json"
  xm="$p/.codex-plugin/plugin.json"
  [ -f "$cm" ] || fail "$name has no .claude-plugin/plugin.json"
  [ -f "$xm" ] || fail "$name has no .codex-plugin/plugin.json"
  diff <(jq -S "$proj" "$cm") <(jq -S "$proj" "$xm") \
    || fail "$name: the Claude and Codex manifests disagree on a shared field (the diff above)"
  skills="$(jq -r '.skills // empty' "$xm")"
  [ -n "$skills" ] || fail "$name: the Codex manifest declares no skills pointer"
  [ -d "$p/$skills" ] || fail "$name: the Codex manifest's skills pointer '$skills' is not a directory under $p"
  pairs=$((pairs + 1))
done
[ "$pairs" -gt 0 ] || fail "no plugin directories under plugins/"
```

and change the final line to:

```bash
printf 'references-resolve: %s string-source path(s) resolve, %s dependency name(s) resolve, %s manifest pair(s) agree\n' "$found" "$depcount" "$pairs"
```

In `tests/test-codex-marketplace.sh`, after line 23 (`jq -e ".plugins[$i].category …`), insert:

```bash
  [ "$(jq -r ".plugins[$i].category" "$M")" = "$(jq -r '.interface.category' "$manifest")" ] \
    || fail "$name: the marketplace category differs from the manifest's interface.category"
```

In `tests/test-claude-validate.sh`, line 12 (now 13), `[ -f "$p/.claude-plugin/plugin.json" ] || continue` becomes `[ -f "$p/.claude-plugin/plugin.json" ] || fail "$p has no .claude-plugin/plugin.json"`, matching its Codex sibling.

In `tests/test-hook.sh`, delete lines 79 and 80, the two `Claude manifest version must be 0.7.0` / `Codex manifest version must be 0.7.0` assertions. The equality check catches the drift they caught by accident, every other version-aware test reads the manifests, and the literal breaks on every release (Deviation, §7.1).

- [ ] **Step 2: Prove each guard by the mutation the issue names**

Run each, and revert after each with the `git checkout` shown:

```bash
# drift one key
jq '.license = "Apache-2.0"' plugins/sensemaking/.codex-plugin/plugin.json > /tmp/m && cp /tmp/m plugins/sensemaking/.codex-plugin/plugin.json
bash tests/test-references-resolve.sh; git checkout -- plugins/sensemaking/.codex-plugin/plugin.json
```

Expected: a diff showing `"license": "MIT"` against `"Apache-2.0"`, then `FAIL: sensemaking: the Claude and Codex manifests disagree on a shared field (the diff above)`.

```bash
# a plugin with only a Codex manifest
mkdir -p plugins/ghost/.codex-plugin && printf '{"name":"ghost","version":"0.0.0","skills":"./skills/"}\n' > plugins/ghost/.codex-plugin/plugin.json
bash tests/test-claude-validate.sh; bash tests/test-references-resolve.sh; rm -r plugins/ghost
```

Expected: `FAIL: /…/plugins/ghost/ has no .claude-plugin/plugin.json` from the first (it needs `claude`; without it the second's `ghost has no .claude-plugin/plugin.json` is the proof).

```bash
# the skills pointer resolves to nothing
mv plugins/sensemaking/skills plugins/sensemaking/skills.aside
bash tests/test-references-resolve.sh; mv plugins/sensemaking/skills.aside plugins/sensemaking/skills
```

Expected: `FAIL: sensemaking: the Codex manifest's skills pointer './skills/' is not a directory under …`.

```bash
# a category that disagrees
jq '.plugins[1].category = "Developer Tools"' .agents/plugins/marketplace.json > /tmp/m && cp /tmp/m .agents/plugins/marketplace.json
bash tests/test-codex-marketplace.sh; git checkout -- .agents/plugins/marketplace.json
```

Expected: `FAIL: sensemaking: the marketplace category differs from the manifest's interface.category`.

Then `git status --short` shows only the four test files modified.

- [ ] **Step 3: Run the four tests and the hook test**

Run: `bash tests/test-references-resolve.sh && bash tests/test-codex-marketplace.sh && bash tests/test-hook.sh && bash tests/test-lint-shell.sh`
Expected: `references-resolve: 2 string-source path(s) resolve, 3 dependency name(s) resolve, 2 manifest pair(s) agree`, `codex-marketplace: 2 local plugins, manifests match, no superpowers entry`, `hook: payload exact, envelope round-trips, wiring correct, control characters escaped`, lint clean. (`test-claude-validate.sh` needs `claude`; run it too where present.)

- [ ] **Step 4: Commit**

```bash
git add tests/test-references-resolve.sh tests/test-codex-marketplace.sh tests/test-claude-validate.sh tests/test-hook.sh
git commit -m "Hold each plugin's two manifests to the same shared fields" -m "name, version, author, homepage, repository, license and keywords must agree between .claude-plugin and .codex-plugin, compared as one projected object; description is excluded because software-dev's differ by design and test-hook.sh guards that direction (#1, spec §7.1). The Codex skills pointer must be a directory, the Codex marketplace category must equal the manifest's, and a plugin with only a Codex manifest fails the Claude validator's loop instead of being skipped. test-hook.sh's two 0.7.0 literals go: the equality check catches what they caught by accident, and they broke on every release.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 12: `payload-rules.md` against its spec (#43, §7.4)

**Files:**

- Modify: `tests/test-hook.sh:40-46` (the `(1b)` block)
- Modify: `tests/test-hook.sh:2-7` (header)
- Modify: `docs/superpowers/specs/2026-09-04-session-start-hook-design.md:3,61,181`

**Interfaces:**

- Consumes: the hook design's `### 4.2` heading and the single fenced block under it.

- [ ] **Step 1: Write the extraction and the diff**

In `tests/test-hook.sh`, replace lines 40–46 (from `# (1b) the authored rules file` through the `superpowers:brainstorming` check, keeping the `[ -s … ]` line and the curated-list loop at 47–52) with:

````bash
# (1b) the authored rules file is the block the hook design's §4.2 shows,
# byte for byte (#43). The heading must match exactly once and a closed fence
# pair must follow it, so a vanished heading cannot pass on two empty
# strings; the rule is `require_once`'s. That spec is maintained, not
# frozen: a3c797f amended §4.2 with the plugin rename, and an edit to either
# side lands with its twin or fails here. The three shape checks this
# subsumes -- one trailing newline, the worktree rule, no
# superpowers:brainstorming -- are gone; the curated-list loop below stays,
# because it cross-checks the marketplace, which the spec cannot.
SPEC="$REPO_ROOT/docs/superpowers/specs/2026-09-04-session-start-hook-design.md"
[ "$(grep -c '^### 4\.2 ' "$SPEC")" -eq 1 ] || fail "the hook design must carry exactly one '### 4.2' heading"
extract_42() {
  awk '
    /^### 4\.2 / { s = 1; next }
    s && /^```/ { if (f) { closed = 1; exit } f = 1; next }
    s && f { print; next }
    s && /^#/ { exit }
    END { if (!closed) exit 1 }
  ' "$SPEC"
}
block="$(extract_42)" || fail "no closed fenced block follows the hook design's §4.2 heading"
[ -s "$H/payload-rules.md" ] || fail "payload-rules.md is empty"
diff <(printf '%s\n' "$block") "$H/payload-rules.md" \
  || fail "payload-rules.md differs from the block in the hook design's §4.2; specs move when the tree moves, so amend §4.2 in the same change"
````

The block's lines are printed without the fences; `printf '%s\n'` restores the one trailing newline the old pair of `tail -c` checks asserted, so the diff also asserts it.

Replace the header's items so it reads (lines 2–7):

```bash
# The SessionStart hook must (1) carry upstream's using-superpowers text inside
# upstream's frame with exactly one edit, (1b) carry the rules block the hook
# design's §4.2 shows, (2) emit both as the documented JSON envelope so that a
# JSON parser recovers the payload byte-for-byte, (3) be wired by
# claude-hooks.json, (4) escape every C0 control character, not just the
# common five, and (5) fail rather than emit a rules-only envelope when
# payload.md is missing. Needs network access for (1).
```

- [ ] **Step 2: Run it to verify it passes today, then prove it red**

Run: `bash tests/test-hook.sh`
Expected: the success line — the block and the file are already 379 identical bytes.

Run: `printf 'x\n' >> plugins/software-dev/hooks/payload-rules.md && bash tests/test-hook.sh; git checkout -- plugins/software-dev/hooks/payload-rules.md`
Expected: a one-line diff (`> x`) then `FAIL: payload-rules.md differs from the block in the hook design's §4.2; …`.

Run: `sed -i 's/^### 4\.2 /### 4.2x /' docs/superpowers/specs/2026-09-04-session-start-hook-design.md && bash tests/test-hook.sh; git checkout -- docs/superpowers/specs/2026-09-04-session-start-hook-design.md`
Expected: `FAIL: the hook design must carry exactly one '### 4.2' heading` — the vanished-heading case cannot pass on two empty strings.

- [ ] **Step 3: Amend the hook design's stale figures and its Status line**

In `docs/superpowers/specs/2026-09-04-session-start-hook-design.md`:

Line 61: `\`payload.md\` is 3,343 bytes and the appendix 387, so the emitted string is 3,730 bytes, 3,718 code points.`→`\`payload.md\` is 3,335 bytes and the appendix 379, so the emitted string is 3,714 bytes, 3,702 code points.`(the rename in`a3c797f`shortened each side by eight bytes; measured 2026-09-17 with`wc -c`and`jq '.hookSpecificOutput.additionalContext | length'`).

Line 181: `| Current \`hooks/payload.md\` is 3,343 bytes and equals …`→`3,335 bytes`.

Line 3, append one sentence to the Status line: `§4.2 is read by \`tests/test-hook.sh\`, which diffs its fenced block against \`hooks/payload-rules.md\` byte for byte, so the two move together.`

Run: `grep -c '3,343\|3,730\|3,718\|appendix 387' docs/superpowers/specs/2026-09-04-session-start-hook-design.md`
Expected: `0`.

- [ ] **Step 4: Run the tests**

Run: `bash tests/test-hook.sh && bash tests/test-links-resolve.sh && bash tests/test-lint-shell.sh`
Expected: three success lines.

- [ ] **Step 5: Commit**

```bash
git add tests/test-hook.sh docs/superpowers/specs/2026-09-04-session-start-hook-design.md
git commit -m "Diff payload-rules.md against the hook design's §4.2, and correct the design's byte counts" -m "The fenced block under '### 4.2' is extracted at test time, guarded the way require_once guards a sentinel, and compared byte for byte with hooks/payload-rules.md (#43, spec §7.4). Three shape checks it subsumes go. The design is therefore maintained, as a3c797f already treated it: its §4.3 and §12 figures were stale by the rename's eight bytes on each side and now read 3,335, 379, 3,714 and 3,702, and its Status line says a test reads §4.2.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 13: The four tab-IFS `read` loops (§6.3, #40)

**Files:**

- Modify: `tests/test-doctor-silence.sh` (append fixtures 8 and 9 before the final `printf`)
- Modify: `bin/setup` (a `split_tsv` helper after `aside_path`, line 140; the loops at 145, 392, 494, 663)

**Interfaces:**

- Produces: `split_tsv <line>` in `bin/setup`, filling the caller's array `F` with six fields (empty where the line has fewer).

- [ ] **Step 1: Append fixtures 8 and 9 to the silence test**

Insert before `printf 'doctor-silence: …'`:

```bash
# 8. upstream/skills.json whose declared skill names are all empty strings:
# it passes the exit-status guard (jq exits 0) and the non-empty guard (each
# row is repo<TAB>ref<TAB>), and before the loop split every iteration hit
# `[ -n "$name" ] || continue` and the check printed nothing at all -- the
# seventh shape (spec §6.1). An empty field is reported as malformed, never
# skipped.
R="$(scratch_repo empty-skill-names)"
jq '.sources |= map(.skills |= map(""))' "$REPO_ROOT/upstream/skills.json" \
  > "$R/upstream/skills.json" || fail "could not blank the skill names"
run_case "all-empty skill names" "$R" "$(seeded_home 8)" "$BIN"
saw 'a declared skill line is malformed' \
  || fail "all-empty skill names: ensure_skills_sh did not report the malformed rows:"$'\n'"$OUT"

# 9. A git-subdir entry whose name is the empty string. With a tab IFS,
# `read` dropped the empty leading field and shifted every value left, so
# the entry was reported under its URL; the split by parameter expansion
# keeps each field where it was and reports the empty one (spec §6.3).
R="$(scratch_repo empty-entry-name)"
jq '(.plugins[] | select(.name == "superpowers") | .name) = ""' "$MARKETPLACE" \
  > "$R/.claude-plugin/marketplace.json" || fail "could not blank the entry name"
run_case "empty entry name" "$R" "$(seeded_home 9)" "$BIN"
saw "a curated entry is malformed: name=''" \
  || fail "empty entry name: ensure_clones did not name the empty field:"$'\n'"$OUT"
saw 'the https://github.com/obra/superpowers.git entry' \
  && fail "empty entry name: the URL was read as the name:"$'\n'"$OUT"
```

and change the final line's count from `7` to `9`.

- [ ] **Step 2: Run it to verify both are red**

Run: `bash tests/test-doctor-silence.sh`
Expected: `FAIL: all-empty skill names: ensure_skills_sh did not report the malformed rows:` — the output above it holds no line about skills.sh at all.

- [ ] **Step 3: Add `split_tsv` and convert the four loops**

In `bin/setup`, after `aside_path() { … }` (line 140), insert:

```bash

# Split a tab-separated line into the six fields of F by parameter expansion,
# never by feeding `read` a tab IFS: a tab is IFS whitespace, so `read`
# collapses a run of them and drops one at either end, and a row with an
# empty leading or middle field shifts every later value left by one, which
# misnames the field in the report and lets a first-field guard pass on the
# wrong value. ensure_links carries the same split inline with the full
# account (0aa11d2). Six tabs are appended so a short row leaves its missing
# fields empty. F is the caller's local; bash scopes it dynamically.
split_tsv() {
  local rest="$1"$'\t\t\t\t\t\t'
  F=()
  for _ in 1 2 3 4 5 6; do
    F+=("${rest%%$'\t'*}")
    rest="${rest#*$'\t'}"
  done
}
```

`ensure_clones`: change `local name url sha dir have n=0` to `local name url sha dir have n=0 line F`, and replace

```bash
  while IFS="$(printf '\t')" read -r name url _ sha _ _; do
    [ -n "$name" ] || continue
    n=$((n + 1))
```

with

```bash
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
    split_tsv "$line"
    name="${F[0]}" url="${F[1]}" sha="${F[3]}"
    if [ -z "$name" ] || [ -z "$url" ]; then
      bad "a curated entry is malformed: name='$name' url='$url'"
      continue
    fi
```

`ensure_claude`: change `local want have installed_sd name` to `local want have installed_sd name line F`, and replace

```bash
  while IFS="$(printf '\t')" read -r name _ _ _ _ want; do
    [ -n "$name" ] || continue
```

with

```bash
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    split_tsv "$line"
    name="${F[0]}" want="${F[5]}"
    if [ -z "$name" ] || [ -z "$want" ]; then
      bad "a curated entry is malformed: name='$name' version='$want'"
      continue
    fi
```

`ensure_skills_sh`: change `local repo ref name have lines` to `local repo ref name have lines line F`, and replace

```bash
  while IFS="$(printf '\t')" read -r repo ref name; do
    [ -n "$name" ] || continue
```

with

```bash
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    split_tsv "$line"
    repo="${F[0]}" ref="${F[1]}" name="${F[2]}"
    if [ -z "$repo" ] || [ -z "$ref" ] || [ -z "$name" ]; then
      bad "a declared skill line is malformed: repo='$repo' ref='$ref' name='$name'"
      continue
    fi
```

`report_duplicates`: change `local root dir path mkt name version` to `local root dir path mkt name version line F`, and replace

```bash
    while IFS="$(printf '\t')" read -r mkt name version; do
      [ -n "$name" ] || continue
```

with

```bash
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      split_tsv "$line"
      mkt="${F[0]}" name="${F[1]}" version="${F[2]}"
      if [ -z "$mkt" ] || [ -z "$name" ] || [ -z "$version" ]; then
        bad "a codex plugin list entry is malformed: marketplace='$mkt' name='$name' version='$version'"
        continue
      fi
```

Run: `grep -c "IFS=\"\$(printf '\\\\t')\"" bin/setup`
Expected: `0` — no tab-IFS `read` remains in the engine.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test-doctor-silence.sh && bash tests/test-doctor-faults.sh && bash tests/test-doctor-duplicates.sh && bash tests/test-setup-doctor.sh && bash tests/test-lint-shell.sh`
Expected: `doctor-silence: 9 unreadable machines, none reported clean` and the other four success lines. Where `claude` is present, also `bash tests/test-setup-upgrade.sh` (the curated-version loop drives it).

- [ ] **Step 5: Commit**

```bash
git add bin/setup tests/test-doctor-silence.sh
git commit -m "Split every tab-separated row in the engine by parameter expansion" -m "ensure_links was cured in 0aa11d2; ensure_clones, the curated loop in ensure_claude, ensure_skills_sh and the Codex cache loop in report_duplicates still read with a tab IFS, which drops an empty leading field and shifts the rest (spec §6.3). One split_tsv helper replaces the four, and an empty field is reported as malformed rather than carried on or skipped. Two fixtures prove it: all-empty skill names in skills.json, the shape that used to print nothing (§6.1), and a git-subdir entry with an empty name, which used to be reported under its URL.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 14: The report-only messages (§6.4, #40)

**Files:**

- Modify: `tests/test-doctor-duplicates.sh` (append before the final `printf`)
- Modify: `bin/setup` (`report_pool`, and the Codex gate in `report_duplicates`)

- [ ] **Step 1: Write the two failing assertions**

In `tests/test-doctor-duplicates.sh`, insert before `printf 'doctor-duplicates: …'`:

```bash
# The all-clear says how many trees it hashed (#40): trees hashed, not
# passed, so a SKILL.md sha256sum could not read lowers the count instead
# of hiding inside it. A second HOME with two distinct skills and no
# duplicate.
H2="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$H" "$H2"' EXIT
mkdir -p "$H2/.agents/skills" || fail "could not seed $H2"
skill "$H2/.agents/skills/alpha" "alpha alone"
skill "$H2/.agents/skills/beta" "beta alone"
out="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'NOTE: Claude: 2 skill tree(s) hashed; no name resolves to more than one tree' \
  || fail "the Claude all-clear does not say how many trees it hashed:"$'\n'"$out"

# The Codex all-clear is gated on the pool being complete, not on codex being
# on PATH (#40): with codex present and `codex plugin list --json` failing,
# the FAIL line stands and no all-clear is printed over a pool missing its
# plugin half. A stub codex that exits 1 is that machine.
printf '#!/usr/bin/env bash\nexit 1\n' > "$BIN/codex" || fail "could not write the codex stub"
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
out="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
printf '%s\n' "$out" | grep -q 'FAIL: codex plugin list failed' \
  || fail "a failing codex plugin list was not reported:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'NOTE: Codex:' \
  && fail "the Codex pool was reported over a failed codex plugin list:"$'\n'"$out"
rm -f "$BIN/codex"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-doctor-duplicates.sh`
Expected: `FAIL: the Claude all-clear does not say how many trees it hashed:` with `NOTE: Claude: no skill name resolves to more than one tree` in the output above.

- [ ] **Step 3: Change the two messages**

In `report_pool`, change `local harness="$1" dir name h found=0` to `local harness="$1" dir name h found=0 hashed=0`; after `h="$(sha256sum "$dir/SKILL.md" 2>/dev/null)" || continue` insert `hashed=$((hashed + 1))`; and change the last line to:

```bash
  [ "$found" -eq 0 ] && note "$harness: $hashed skill tree(s) hashed; no name resolves to more than one tree"
```

In `report_duplicates`, replace

```bash
  if [ "$can_hash" -eq 1 ] && have codex; then report_pool Codex "${codex_dirs[@]}"; fi
```

with

```bash
  # Gated on the pool being complete, not on `have codex`: with codex present
  # and `codex plugin list --json` failed, CODEX_LIST is empty, the FAIL line
  # already stands above, and an all-clear here would speak for a pool
  # missing its plugin half (#40).
  if [ "$can_hash" -eq 1 ] && [ -n "$CODEX_LIST" ]; then report_pool Codex "${codex_dirs[@]}"; fi
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test-doctor-duplicates.sh && bash tests/test-doctor-silence.sh && bash tests/test-setup-doctor.sh && bash tests/test-lint-shell.sh`
Expected: `doctor-duplicates: one Claude duplicate and one residue reported; three false positives quiet` and the other three success lines. The existing assertions — the `beta` and `epsilon` findings, the absence of `NOTE: Codex:` without `codex`, `NOTE:` never `FAIL:` for a finding — still hold; none of those lines moved.

- [ ] **Step 5: Commit**

```bash
git add bin/setup tests/test-doctor-duplicates.sh
git commit -m "Say how many trees the duplicate check hashed, and gate the Codex note on a complete pool" -m "The all-clear read identically whether 104 trees were compared or zero, and it printed for a Codex pool that had collapsed because 'codex plugin list --json' failed (#40, spec §6.4). The count is trees hashed, so an unreadable SKILL.md lowers it rather than hiding inside it; the Codex note is gated on CODEX_LIST rather than on codex being present, so it stays silent where the FAIL line already speaks. The fourth site #40 names, a registry entry whose install directory is gone, stays declined as it records.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 15: Rung 1 — every check reports, or the run fails (§6.1, #41)

**Files:**

- Modify: `tests/test-doctor-silence.sh` (append fixture 10)
- Modify: `bin/setup` (`REPORTED`, the four helpers, `reported`, ten call sites)

- [ ] **Step 1: Append fixture 10**

Insert before `printf 'doctor-silence: …'`:

```bash
# 10. A check that reports nothing (spec §6.1). After the loop splits and the
# counted all-clear no declaration shape is silent any more, which is the
# point of them, so the silent check is manufactured: a copy of bin/setup
# whose last line, `main "$@"`, is preceded by a redefinition of
# ensure_fresh_clone that prints nothing. The bracket around it must name
# it as a FAIL, counted in the verdict, and the run must not read as clean.
[ "$(tail -n 1 "$REPO_ROOT/bin/setup")" = 'main "$@"' ] \
  || fail "bin/setup no longer ends in 'main \"\$@\"'; this fixture needs to know where to override"
R="$(scratch_repo silent-check)"
rm "$R/bin/setup" || fail "could not drop the symlink for the silent-check copy"
{ sed '$d' "$REPO_ROOT/bin/setup"; printf 'ensure_fresh_clone() { :; }\nmain "$@"\n'; } > "$R/bin/setup" \
  || fail "could not write the silent-check copy"
run_case "silent check" "$R" "$(seeded_home 10)" "$BIN"
saw 'FAIL: check ensure_fresh_clone reported nothing; this machine is unchecked, not verified' \
  || fail "silent check: the bracket around it did not name it:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -qE '^[0-9]+ check\(s\) failed$' \
  || fail "silent check: it was not counted in the verdict:"$'\n'"$OUT"
```

and change the final line's count from `9` to `10`.

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-doctor-silence.sh`
Expected: `FAIL: silent check: the bracket around it did not name it:` — the copy runs, other checks fail on the empty home, and nothing mentions `ensure_fresh_clone`.

- [ ] **Step 3: Count every report and wrap every check**

In `bin/setup`, after `FAILURES=0` (line 47) insert:

```bash
# Every ok, bad, skip and note bumps this; did does not, because a DID: line
# never stands alone on any path. Each check is bracketed by a snapshot of
# it and a reported() call.
REPORTED=0
```

Replace the four helpers (lines 61, 62, 65, 66):

```bash
ok()   { printf 'OK:   %s\n' "$*"; REPORTED=$((REPORTED + 1)); }
bad()  { printf 'FAIL: %s\n' "$*"; FAILURES=$((FAILURES + 1)); REPORTED=$((REPORTED + 1)); }
skip() { printf 'SKIP: %s\n' "$*"; REPORTED=$((REPORTED + 1)); }
note() { printf 'NOTE: %s\n' "$*"; REPORTED=$((REPORTED + 1)); }
```

(`die` and `did` are unchanged.) After `needs() { … }` (line 86) insert:

```bash

# Every check reports, or the run fails (spec §6.1). A check that prints
# nothing has verified nothing: a jq program that emitted rows with empty
# names, a loop whose every iteration hit `continue`. Each call site
# snapshots REPORTED, runs the check directly, and passes the snapshot and
# the name here: no capture and no subshell, because the checks run in
# main's own shell and a $(...) around them would lose every increment bad
# and needs make to FAILURES, UNANSWERED and UNCHECKED; and no wrapper that
# invokes the check through "$@", because shellcheck then reports every
# check and every helper they call as unreachable (SC2317). A silent check
# is a defect in the engine, so it is bad, counted in "N check(s) failed",
# and not the `for want of:` verdict, which is for a tool the machine lacks.
# Nested callers bracket their callees at their own sites: report_only
# prints two NOTE lines before report_duplicates, and report_duplicates
# before report_pool, so a bracket around the outer call alone would see a
# count and never notice the inner one saying nothing.
reported() {
  [ "$REPORTED" -gt "$1" ] \
    || bad "check $2 reported nothing; this machine is unchecked, not verified"
}
```

In `report_only`, change `local v set_names="" link actual name` to `local v set_names="" link actual name before`, and the last statement `report_duplicates` to:

```bash
  before=$REPORTED
  report_duplicates
  reported "$before" report_duplicates
```

In `report_duplicates`, add `before` to its `local` line (`local root dir path mkt name version line F before`), and replace `[ "$can_hash" -eq 1 ] && report_pool Claude "${claude_dirs[@]}"` with:

```bash
  if [ "$can_hash" -eq 1 ]; then
    before=$REPORTED
    report_pool Claude "${claude_dirs[@]}"
    reported "$before" report_pool
  fi
```

and Task 14's Codex line, `if [ "$can_hash" -eq 1 ] && [ -n "$CODEX_LIST" ]; then report_pool Codex "${codex_dirs[@]}"; fi`, with:

```bash
  if [ "$can_hash" -eq 1 ] && [ -n "$CODEX_LIST" ]; then
    before=$REPORTED
    report_pool Codex "${codex_dirs[@]}"
    reported "$before" report_pool
  fi
```

In `main`, add `local before` as the first line of the function body (before the `while [ $# -gt 0 ]` loop), and replace the seven bare calls:

```bash
  before=$REPORTED
  ensure_fresh_clone
  reported "$before" ensure_fresh_clone
  before=$REPORTED
  ensure_clones
  reported "$before" ensure_clones
  before=$REPORTED
  ensure_links
  reported "$before" ensure_links
  before=$REPORTED
  ensure_claude
  reported "$before" ensure_claude
  before=$REPORTED
  ensure_codex
  reported "$before" ensure_codex
  before=$REPORTED
  ensure_skills_sh
  reported "$before" ensure_skills_sh
  before=$REPORTED
  report_only
  reported "$before" report_only
```

Run: `grep -c '^ *reported "\$before" ' bin/setup`
Expected: `10` — seven in `main`, three nested. Every check is still called directly, so shellcheck sees each one reached.

- [ ] **Step 4: Run every engine test**

Run: `for t in tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-doctor-duplicates.sh tests/test-setup-doctor.sh tests/test-lint-shell.sh; do bash "$t" || break; done`
Expected: `doctor-silence: 10 unreadable machines, none reported clean` and the other four success lines. `test-setup-doctor.sh`'s empty-`PATH` doctor still reads `for want of: jq` and nothing about a silent check: every check there opens on `needs jq`, which is a `skip`, which counts. `bash tests/test-lint-shell.sh` must be clean: no SC2317, because every check is still called by name.

- [ ] **Step 5: Commit**

```bash
git add bin/setup tests/test-doctor-silence.sh
git commit -m "Fail a check that reports nothing" -m "ok, bad, skip and note count what they print; main and the two nested callers snapshot the count before each check and pass it to reported() after, which turns a check that printed nothing into a FAIL counted in the verdict (#41, spec §6.1). A direct call plus reported(), not a wrapper invoking the check through \"\$@\": shellcheck marks everything reached only that way as unreachable. This closes the class rather than the instances: the seventh shape, all-empty skill names, was silent until Task 13 and would have been one FAIL line here with no fixture written for it. Proved on a copy of the engine with one check redefined to print nothing, since no declaration shape is silent any more.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 16: Gate 1

**Files:** none modified.

- [ ] **Step 1: The full suite, locally**

Run: `tests/run.sh; echo "exit=$?"; head -n 1 tests/results.tsv; tail -n 1 tests/results.tsv`
Expected: `exit=0`; every row `PASS` except tests whose need this machine lacks, which are `SKIP` rows naming the need; the summary line `N passed, 0 failed, K skipped[ for want of: …]`. Cite `tests/results.tsv` by path in the task report; do not transcribe rows.

- [ ] **Step 2: Push the branch and watch CI**

Run: `git push -u origin suite-and-ci && gh run watch --exit-status "$(gh run list --branch suite-and-ci --limit 1 --json databaseId --jq '.[0].databaseId')"`
Expected: both jobs green. (A run can take a few seconds to appear after the push; if `gh run list` prints nothing, run the command again.) CI still runs the old `validate.yml` at this point: `tests/run.sh` without `--no-skip`, so `tests/test-lint-shell.sh` reads `SKIP … (needs shellcheck 0.9.0; found <the image's version>)` if the runner image ships a different shellcheck — an honest account, not a failure; Task 22 pins the binary and turns skips into failures. Read the run's log for `SKIP` lines and record them in the task report beside the result-file citation.

If a job is red, fix forward on the branch; Gate 1 holds only when the run is green.

## Milestone 2: CI, lint, and the Checks section

### Task 17: The tool mechanism — four configuration files, `bin/format`, four tests, red on arrival (§8)

**Files:**

- Create: `.prettierrc.yaml`, `.markdownlint-cli2.jsonc`, `cspell.config.yaml`, `bin/format`, `tests/test-format-shell.sh`, `tests/test-format-prettier.sh`, `tests/test-lint-markdown.sh`, `tests/test-spelling.sh`
- Modify: `tests/lib.sh` (append `SHFMT_FLAGS`)

**Interfaces:**

- Produces: `SHFMT_FLAGS` (bash array in `tests/lib.sh`), `bin/format` (applies shfmt, prettier, `markdownlint-cli2 --fix` over the derived lists), and the four tests, each `# needs:` one tool.

- [ ] **Step 1: Install the six tools at the registry's versions**

On this machine shellcheck 0.9.0 and actionlint 1.7.12 are already installed; the other four are not. These are global installs onto the maintainer's machine (`npm install -g`, a binary in `~/.local/bin`): confirm with the maintainer before running them. The alternative that touches nothing global is the CI step's own shape — Task 22's dry run puts all six into a scratch directory placed ahead of `PATH` — and either satisfies the version probes. With the go-ahead, run:

```bash
npm install -g prettier@3.9.6 markdownlint-cli2@0.23.2 cspell@10.2.2
mkdir -p ~/.local/bin
curl -sfL https://github.com/mvdan/sh/releases/download/v3.14.1/shfmt_v3.14.1_linux_amd64 -o ~/.local/bin/shfmt
echo "76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf  $HOME/.local/bin/shfmt" | sha256sum -c -
chmod +x ~/.local/bin/shfmt
for t in shellcheck actionlint shfmt prettier markdownlint-cli2 cspell; do printf '%-18s' "$t"; "$t" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1; done
```

Expected: `shfmt_v3.14.1_linux_amd64: OK` from `sha256sum -c`, then the six versions exactly as `tests/tools.txt` declares them. On a machine where shellcheck or actionlint differ, install them from the release assets named in Global Constraints and verify their sha256 the same way.

- [ ] **Step 2: Write the four configuration files**

`.prettierrc.yaml`:

```yaml
# Read by tests/test-format-prettier.sh and bin/format over the explicit file
# lists tests/lib.sh derives (spec §8.1). No .prettierignore: the list is the
# scope, and an ignore file would restate the vendored set a second time.

# tests/test-vendored-scaffolder.sh holds two sections of AGENTS.md
# byte-identical to a block inside the vendored setup-repository/SKILL.md,
# which no formatter may touch; with `always` the formatter and that drift
# test become mutually unsatisfiable (§8.4).
proseWrap: preserve

# Fenced blocks quote other files verbatim -- the AGENTS.md block in the
# specs, the README recipes tests/test-setup-doctor.sh compares byte for byte
# against `bin/setup --help` -- and quoted material must not be restyled by
# the document quoting it. Quoted: a bare `off` is YAML for false.
embeddedLanguageFormatting: "off"
```

`.markdownlint-cli2.jsonc`:

```jsonc
{
  // Read by tests/test-lint-markdown.sh and bin/format over the explicit
  // list tests/lib.sh derives (spec §8.1): no globs here, no ignore file.
  "config": {
    // Line length: proseWrap is preserve, so a paragraph is one line.
    "MD013": false,
    // Inline HTML: the specs' <details> blocks and the skills' gates.
    "MD033": false,
    // First line a top-level heading: AGENTS.md opens at ## by the
    // scaffolder's template shape, CLAUDE.md is an @AGENTS.md include, and
    // every SKILL.md and agent file opens with a paragraph after its
    // frontmatter.
    "MD041": false
  }
}
```

`cspell.config.yaml` (Deviation P3; the `words` list is filled in Task 19):

```yaml
# Read by tests/test-spelling.sh over the explicit lists tests/lib.sh derives
# (spec §8.1): the owned markdown outside docs/superpowers, docs/research and
# docs/archive, plus the comments of the shell and YAML files. The scope is
# an argument at the call site, not an ignorePaths here.
version: "0.2"
# The prose was mixed (behaviour beside behavior in the same skills) and
# everything this repository embeds is American, so a decision: US English.
language: en-US
ignorePaths: []
# Proper nouns, domain terms and coinages the owned prose uses. Never a
# misspelling: a typo is fixed, not listed.
words: []
# Shell and YAML files are read for their `#` comments only. The override
# globs resolve relative to this file, which is why it lives at the root.
patterns:
  - name: hash-comments
    pattern: "/#.*$/gm"
overrides:
  - filename:
      - "bin/*"
      - "tests/*.sh"
      - "plugins/software-dev/hooks/session-start"
      - "**/*.yml"
      - "**/*.yaml"
    languageId: shellscript
    includeRegExpList:
      - hash-comments
```

Append to `tests/lib.sh`:

```bash

# shfmt's flags, read by tests/test-format-shell.sh and bin/format (spec
# §8.1): the set measured closest to the code as written, 17 files and 272
# lines at aa8e78d; -sr was dropped because it restyled a further 140 lines.
# shellcheck disable=SC2034  # read by the test and by bin/format
SHFMT_FLAGS=(-i 2 -ci -bn)
```

- [ ] **Step 3: Write the four tests**

`tests/test-format-shell.sh`:

```bash
#!/usr/bin/env bash
# Every shell file this repository owns is formatted as shfmt formats it with
# the flags tests/lib.sh declares (spec §8). bin/format applies them.
# needs: shfmt
. "$(dirname "$0")/lib.sh"

files="$(checked_shell)"
[ -n "$files" ] || fail "checked_shell() listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
shfmt -d "${SHFMT_FLAGS[@]}" $files || fail "shfmt would reformat the files above; run bin/format"
printf 'format-shell: %s shell file(s) formatted\n' "$(printf '%s\n' "$files" | grep -c .)"
```

`tests/test-format-prettier.sh`:

```bash
#!/usr/bin/env bash
# Every JSON, YAML and markdown file this repository owns is formatted as
# prettier formats it under .prettierrc.yaml (spec §8). Three lists, each
# asserted non-empty: on an empty list `prettier --check` exits 0 with only
# a stderr complaint (measured, 3.9.6), which is a false green. A file it has
# no parser for exits 2, which is why the lists are filtered by extension.
# needs: prettier
. "$(dirname "$0")/lib.sh"

json="$(checked '*.json')"
[ -n "$json" ] || fail "checked '*.json' listed nothing"
yaml="$(checked '*.yml' '*.yaml')"
[ -n "$yaml" ] || fail "checked '*.yml' '*.yaml' listed nothing"
md="$(checked '*.md')"
[ -n "$md" ] || fail "checked '*.md' listed nothing"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
prettier --log-level warn --check $json $yaml $md || fail "prettier would reformat the files above; run bin/format"
printf 'format-prettier: %s JSON, %s YAML, %s markdown file(s) formatted\n' \
  "$(printf '%s\n' "$json" | grep -c .)" "$(printf '%s\n' "$yaml" | grep -c .)" "$(printf '%s\n' "$md" | grep -c .)"
```

`tests/test-lint-markdown.sh`:

```bash
#!/usr/bin/env bash
# Every markdown file this repository owns passes markdownlint-cli2 under
# .markdownlint-cli2.jsonc (spec §8). Formatter first, then linter: prettier
# retires most findings free, and bin/format runs --fix for the rest it can;
# what remains -- a fence with no language, a heading style -- is fixed by
# hand once.
# needs: markdownlint-cli2
. "$(dirname "$0")/lib.sh"

md="$(checked '*.md')"
[ -n "$md" ] || fail "checked '*.md' listed nothing; the ownership derivation went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
markdownlint-cli2 $md || fail "markdownlint-cli2 reported the findings above"
printf 'lint-markdown: %s markdown file(s) clean\n' "$(printf '%s\n' "$md" | grep -c .)"
```

`tests/test-spelling.sh`:

```bash
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
```

- [ ] **Step 4: Run the four and see them red**

Run: `for t in tests/test-format-shell.sh tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh; do bash "$t" >/dev/null 2>&1; echo "$t exit=$?"; done`
Expected: `exit=1` for all four. `bash tests/test-format-shell.sh 2>&1 | grep -c '^--- '` reports 17 files; `bash tests/test-format-prettier.sh 2>&1 | grep -c '\[warn\]'` reports 20 files plus the summary line; the lint reports about 224 findings (before prettier); cspell reports the 77 markdown hits and the 58 comment hits. Counts may differ by a few on a tree with later commits; the shape is what matters.

- [ ] **Step 5: Write `bin/format`**

```bash
#!/usr/bin/env bash
# Rewrite what the format checks check (spec §8.3): shfmt over the shell
# files, prettier over JSON, YAML and markdown, then markdownlint-cli2 --fix
# over markdown, each over the list tests/lib.sh derives. No check mode of
# its own: the tests are the check (tests/test-format-shell.sh,
# tests/test-format-prettier.sh, tests/test-lint-markdown.sh). No pre-commit
# hook: the suite is the gate. Versions are held in tests/tools.txt.
set -euo pipefail
. "$(dirname "$0")/../tests/lib.sh"

for t in shfmt prettier markdownlint-cli2; do
  command -v "$t" >/dev/null 2>&1 || fail "bin/format needs $t on PATH; the versions are in tests/tools.txt"
done
shell="$(checked_shell)"
[ -n "$shell" ] || fail "checked_shell() listed nothing; the ownership derivation went vacuous"
docs="$(checked '*.json' '*.yml' '*.yaml' '*.md')"
[ -n "$docs" ] || fail "the prettier list is empty"
md="$(checked '*.md')"
[ -n "$md" ] || fail "the markdown list is empty"
cd "$REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
shfmt -w "${SHFMT_FLAGS[@]}" $shell
# shellcheck disable=SC2086  # as above
prettier --log-level warn --write $docs
# --fix exits 1 while findings it cannot fix remain; those are the test's to
# report, not this script's to hide.
# shellcheck disable=SC2086  # as above
markdownlint-cli2 --fix $md || true
```

Run: `chmod +x bin/format && git add .prettierrc.yaml .markdownlint-cli2.jsonc cspell.config.yaml tests/lib.sh bin/format tests/test-format-shell.sh tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh && bash tests/test-ownership.sh && bash tests/test-lint-shell.sh`
Expected: `ownership: 6 vendored pattern(s) each guarded; 86 checked file(s), 36 of them shell` (staged first, because the derivation lists tracked files: the four tests and `bin/format` join the shell list, the three configuration files join the others; one more markdown file if this plan is committed), and the lint clean over 36 files.

- [ ] **Step 6: Commit the mechanism, red**

```bash
git add .prettierrc.yaml .markdownlint-cli2.jsonc cspell.config.yaml tests/lib.sh bin/format tests/test-format-shell.sh tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh
git commit -m "Add the formatters, the linters and the spell checker over the files we own" -m "Four configuration files, each carrying the reason beside the setting; the shfmt flags in tests/lib.sh; bin/format to apply; and one test per tool, each declaring its need, each over a list derived from git ls-files and asserted non-empty (spec §8, #29). The tree is not yet formatted, so this commit is red on arrival by design: the one-time reformat lands next as its own commit, verified by the suite rather than by reading the diff, and the hand corrections after it.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 18: The one-time reformat (§8.3)

**Files:** every owned shell, JSON, YAML and markdown file the tools change (17 shell, about 20 others).

- [ ] **Step 1: Run `bin/format`**

Run: `bin/format; git diff --stat | tail -n 1`
Expected: about 37 files changed, roughly 1,300 lines. The markdownlint findings it cannot fix are printed and left.

- [ ] **Step 2: Check the couplings §8.4 names**

Run: `git diff --quiet -- AGENTS.md plugins/software-dev/hooks/payload-rules.md && echo "couplings untouched"`
Expected: `couplings untouched`. If either changed, stop: prettier's behaviour moved from what was measured, and Task 17's `.prettierrc.yaml` needs re-measuring before anything is committed.

- [ ] **Step 3: Run the full suite on the reformatted tree**

Run: `tests/run.sh; echo "exit=$?"; grep -c PASS tests/results.tsv; grep FAIL tests/results.tsv`
Expected: `exit=1` with exactly two `FAIL` rows, `tests/test-lint-markdown.sh` and `tests/test-spelling.sh`, which Task 19 turns green; `tests/test-format-shell.sh` and `tests/test-format-prettier.sh` are `PASS`, and so is every engine, drift, hook and recipe test — that is the verification of the reformat.

- [ ] **Step 4: Commit the reformat alone**

```bash
git add -u
git commit -m "Reformat every owned file with the pinned formatters" -m "bin/format at the versions tests/tools.txt declares: shfmt -i 2 -ci -bn over the shell files, prettier with proseWrap preserve and embedded formatting off over JSON, YAML and markdown, markdownlint-cli2 --fix over markdown (spec §8.3). Mechanical, and verified by the suite rather than by reading the diff: every test passes on this tree except the two lint tests the hand corrections satisfy next. AGENTS.md and hooks/payload-rules.md are byte-identical to before, which the scaffolder drift test and the hook test require.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

(In the main checkout rather than a worktree, `git add -u` is still correct — it stages modified tracked files only — but commit with `-- $(git diff --cached --name-only | grep -v '^docs/Professional-Editorial')` so the unrelated staged file stays out; see Global Constraints.)

### Task 19: The hand corrections (§8.1, §8.3)

**Files:**

- Modify: the markdown files with residual findings (Step 1), the eight spelling sites (Step 2), `cspell.config.yaml` (Step 3), `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` §4.2 (Step 2), `plugins/software-dev/skills/consistency-audit/SKILL.md:123` (Step 2)

- [ ] **Step 1: Fix the 36 findings `--fix` could not**

Run: `bash tests/test-lint-markdown.sh` and fix each finding by hand. Measured at `55f1bcc` after prettier and `--fix`:

- **MD040, 25 fences with no language** — `README.md` (2, the Install and Update recipes), `docs/agents/domain.md` (2), `docs/superpowers/plans/2026-09-05-setup-and-drift-review.md` (3), `docs/superpowers/plans/2026-09-05-setup-and-drift.md` (1), `docs/superpowers/plans/2026-09-06-roster-and-retirement.md` (12), `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` (1), `plugins/software-dev/README.md` (1), `plugins/software-dev/skills/consistency-audit/SKILL.md` (2), `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md` (1). Add the language after the opening fence: `sh` for commands, `text` for output or plain samples, `json`, `yaml` or `markdown` where the content is that. `embeddedLanguageFormatting` is `"off"`, so no language makes prettier restyle the block, and `tests/test-setup-doctor.sh` compares the README recipes' content, not their fence line.
- **MD003, 8 setext headings** in `docs/superpowers/plans/2026-09-05-setup-and-drift-review.md` (lines 84, 148, 206, 227, 284, 297, 312, 336 after formatting): rewrite each underlined heading as an ATX `##` or `###` at the level the surrounding headings use.
- **MD046** at `…setup-and-drift-review.md:95`: an indented code block becomes a fenced one with a language.
- **MD028** at `docs/superpowers/plans/2026-09-04-session-start-hook.md:510`: a blank line inside a blockquote becomes a `>` line.
- **MD001** at `…setup-and-drift-review.md:11`: an `###` directly under an `#` becomes `##` (or the headings below it move with it, so the increment holds).

A fence language, a heading style or a blockquote marker in a plan is not its content (§8.1). Re-run until `lint-markdown: N markdown file(s) clean`, N being 27 at `55f1bcc`, plus this plan once committed, plus the staged file in the main checkout.

- [ ] **Step 2: The eight British spellings become US English**

Four in the markdown scope, four in comments:

| Site                                                                                                                                                                              | Change                                                                                                                                    |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `plugins/software-dev/README.md:117`                                                                                                                                              | `network-behaviour decision` → `network-behavior decision`                                                                                |
| `plugins/sensemaking/README.md:12`                                                                                                                                                | `organisational` → `organizational`                                                                                                       |
| `plugins/software-dev/hooks/payload-rules.md:3` **and** the same line inside the fenced block under `### 4.2` of `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` | `recognises` → `recognizes` (same byte length, so §4.3's figures hold; `tests/test-hook.sh` fails unless both move)                       |
| `plugins/software-dev/skills/consistency-audit/SKILL.md:123`                                                                                                                      | `will summarise instead` → `will summarize instead`, made through `superpowers:writing-skills` because it is an edit to an authored skill |
| `bin/bump-superpowers:13`                                                                                                                                                         | `change behaviour` → `change behavior`                                                                                                    |
| `bin/setup:256` and `:266`                                                                                                                                                        | `canonicalises` → `canonicalizes`                                                                                                         |
| `tests/test-doctor-faults.sh` (`could not synthesise a pinned lockfile`)                                                                                                          | `synthesise` → `synthesize`                                                                                                               |
| `.github/workflows/upstream-watch.yml:12`                                                                                                                                         | `Serialised` → `Serialized`                                                                                                               |

Run: `bash tests/test-hook.sh`
Expected: the success line — both sides of the §4.2 coupling moved together.

- [ ] **Step 3: Fill the dictionary**

Run, from the repository root, the same scope `tests/test-spelling.sh` uses (the vendored `agents/openai.yaml` files are excluded by the derivation, so never list a word that only they carry):

```bash
bash -c '. tests/lib.sh; cd "$REPO_ROOT"; cspell --no-progress --words-only --unique $(checked "*.md" ":(exclude)docs/superpowers" ":(exclude)docs/research" ":(exclude)docs/archive") $(checked_shell) $(checked "*.yml" "*.yaml")' | sort -f
```

Read every word. Measured at `55f1bcc`, none is a typo; the list is proper nouns (`Akhourii`, `Eran`, `Roseman`, `eranroseman`, `mattpocock`, `Pocock`, `obra`, `primeradiant`, `softaworks`, `Udit`), domain terms (`archify`, `cavecrew`, `diffable`, `frontmatter`, `heredocs`, `HITL`, `pycache`, `scaffolder`, `sensemaking`, `SIGPIPE`, `wayfinder`, `wayfinding`, `worktrees`, `relpath`, `insection`) and coinages (`actioned`, `custodied`, `relativization`, `relitigated`, `repointed`, `unrouted`), plus one hex fragment (`ffdd`) which is better excluded by wrapping the value it sits in with backticks than listed. Put each remaining word into `cspell.config.yaml`'s `words:` list, one per line, sorted case-insensitively. A word that is a misspelling is fixed in the file instead. Possessives (`mattpocock's`) resolve once their base word is listed; if cspell still reports one, list the base word only and fix the reference to a form cspell accepts.

Run: `bash tests/test-spelling.sh`
Expected: `spelling: 15 markdown, 36 shell and 7 YAML file(s) spelled` (16 markdown in the main checkout; the plan is under `docs/superpowers` and outside the scope).

- [ ] **Step 4: The full suite**

Run: `tests/run.sh; echo "exit=$?"; tail -n 1 tests/results.tsv`
Expected: `exit=0`, no `FAIL` row, and no `SKIP` row on this machine now that all six tools are installed. Cite `tests/results.tsv`.

- [ ] **Step 5: Commit**

```bash
git add -u
git commit -m "Fix what the formatters could not: fence languages, heading styles, eight spellings, the dictionary" -m "The 36 markdownlint findings --fix leaves (a fence with no language, a setext heading, an indented block, a blank line in a blockquote, a heading increment), none of them content; the eight British spellings in scope become US English, the hook design's §4.2 moving with payload-rules.md and the consistency-audit skill edited through writing-skills; and cspell.config.yaml's word list holds every proper noun, term and coinage the owned prose uses, not one of them a typo (spec §8.1). The suite is green on this tree.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 20: One validator, two copies, both checked (#3, #7, §9.2)

**Files:**

- Modify: `tests/test-codex-validate.sh` (after the `VALIDATOR=` lines)

- [ ] **Step 1: Write the hash assertion**

After `[ -f "$VALIDATOR" ] || fail "Codex validator not found …"` insert:

```bash
# One validator, two copies, both checked (#3). The local copy -- whatever
# codex-cli installed, or the file CODEX_PLUGIN_VALIDATOR names -- must be
# the bytes CI fetches from openai/codex at the pinned sha, for both files
# the validator is made of. sha256, because sha256sum is the repository's
# one hashing tool; recorded 2026-09-17 from raw.githubusercontent.com at
# the sha below and byte-identical to the codex-cli 0.147.0 copies. The day
# codex-cli moves the files, this fails and the message says what to do.
PIN=f3f6922519fa38487c8250c2b8a670a39a2cf9ff
VDIR="${VALIDATOR%/*}"
for pair in \
  'validate_plugin.py f4eeadb733b28b0c3e714de263a76d6542866a672f3e99bdffcf4dbcdf85e944' \
  'identifier_validation.py a6d51ce4a9a7e8f85626ff5808a467a67574e7f8cdf1167ffb467c5f67e57223'
do
  f="${pair%% *}"
  want="${pair#* }"
  [ -f "$VDIR/$f" ] || fail "$f is missing beside $VALIDATOR; the validator is two files"
  got="$(sha256sum "$VDIR/$f")" || fail "could not hash $VDIR/$f"
  got="${got%% *}"
  [ "$got" = "$want" ] \
    || fail "$f at $VDIR is not the copy CI pins (openai/codex@${PIN:0:7}); re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a copy fetched by the recipe in .github/workflows/validate.yml"
done
```

- [ ] **Step 2: Prove it red with a modified copy, then green**

Run:

```bash
D="$(mktemp -d)" && cp ~/.codex/skills/.system/plugin-creator/scripts/{validate_plugin,identifier_validation}.py "$D/" \
  && printf '\n# x\n' >> "$D/validate_plugin.py" \
  && CODEX_PLUGIN_VALIDATOR="$D/validate_plugin.py" bash tests/test-codex-validate.sh; rm -rf "$D"
```

Expected: `FAIL: validate_plugin.py at /tmp/… is not the copy CI pins (openai/codex@f3f6922); re-check the pin, or point CODEX_PLUGIN_VALIDATOR at a copy fetched by the recipe in .github/workflows/validate.yml`.

Run: `bash tests/test-codex-validate.sh; echo "exit=$?"`
Expected: `exit=0` (the test prints nothing on success today; the local copies are the pinned bytes).

- [ ] **Step 3: Commit**

```bash
git add tests/test-codex-validate.sh
git commit -m "Assert the sha256 of both Codex validator files against the pin CI fetches" -m "Local and CI ran the same validator from two sources nothing compared (#3). The test now holds both validate_plugin.py and identifier_validation.py, wherever they were read from, to the bytes at openai/codex f3f6922, and a mismatch names the recipe that fetches a good copy, which is also what the absent-file SKIP says (#7, spec §9.2). No network on a local run; CI keeps its fetch step and asserts the same two constants against its own copy.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 21: `tests/test-workflows.sh`, and the workflows hardened (#28, #6 item 1, #8, §9.1, §9.4)

**Files:**

- Create: `tests/test-workflows.sh`
- Modify: `.github/workflows/validate.yml` (whole file), `.github/workflows/upstream-watch.yml:26`

**Interfaces:**

- Consumes: `checked '.github/workflows/*.yml'`.

- [ ] **Step 1: Write the test**

```bash
#!/usr/bin/env bash
# The workflows' embedded `run:` shell is linted (#28), and the two
# properties actionlint cannot see are asserted beside it (spec §9.4):
# every `uses:` is pinned to a 40-character sha, every workflow declares
# `permissions:` at the top level, and every actions/checkout step sets
# persist-credentials: false. actionlint runs shellcheck over run: blocks
# when shellcheck is on PATH and quietly does not when it is absent, so both
# are needs. Measured 2026-09-17: actionlint 1.7.12 flags neither a missing
# permissions block nor a floating tag nor an unresolvable uses:, so the
# greps are not redundant with it.
# needs: actionlint shellcheck
. "$(dirname "$0")/lib.sh"

files="$(checked '.github/workflows/*.yml')"
[ -n "$files" ] || fail "no workflow under .github/workflows; the list went vacuous"
cd "$REPO_ROOT" || fail "could not cd to $REPO_ROOT"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
actionlint $files || fail "actionlint reported problems"

for f in $files; do
  unpinned="$(grep -nE '^[[:space:]]*-?[[:space:]]*uses:' "$f" \
    | grep -vE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}([[:space:]]|$)' || true)"
  [ -z "$unpinned" ] || fail "$f: a uses: line is not pinned to a 40-character sha:"$'\n'"$unpinned"
  grep -qE '^permissions:' "$f" || fail "$f declares no top-level permissions: block"
  checkouts="$(grep -cE 'uses:[[:space:]]*actions/checkout@' "$f" || true)"
  persists="$(grep -cE '^[[:space:]]*persist-credentials:[[:space:]]*false[[:space:]]*$' "$f" || true)"
  [ "$checkouts" -eq "$persists" ] \
    || fail "$f: $checkouts actions/checkout step(s) but $persists persist-credentials: false line(s)"
done

printf 'workflows: %s workflow(s) linted, every uses: sha-pinned, permissions declared, credentials not persisted\n' \
  "$(printf '%s\n' "$files" | grep -c .)"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-workflows.sh`
Expected: `FAIL: .github/workflows/upstream-watch.yml: a uses: line is not pinned to a 40-character sha:` followed by `26:      - uses: actions/checkout@v4` (the files sort with `upstream-watch.yml` first). actionlint itself passes.

- [ ] **Step 3: Harden both workflows**

Replace `.github/workflows/validate.yml` whole:

```yaml
name: validate

on:
  push:
  pull_request:

# Read-only everywhere: nothing here pushes, comments or writes (spec §9.1).
# upstream-watch scopes its own.
permissions:
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          # Nothing here pushes, and the default writes the token into
          # .git/config for every later step to read.
          persist-credentials: false

      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version: 22

      - uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0
        with:
          python-version: "3.12"

      # `claude plugin validate` needs no login or onboarding: verified
      # 2026-09-04 by running it with an empty HOME. Pinned to the version the
      # design was measured against.
      - name: Install Claude Code CLI
        run: npm install -g @anthropic-ai/claude-code@2.1.220

      # Codex ships validate_plugin.py inside the CLI's system skills, which a
      # fresh runner does not have. The same two files live in openai/codex
      # (Apache-2.0); fetch them at a pinned sha. tests/test-codex-validate.sh
      # asserts the sha256 of both files against the constants it records, so
      # this copy and a local codex-cli copy are held to the same bytes.
      - name: Fetch the Codex plugin validator
        run: |
          pip install pyyaml==6.0.3
          mkdir -p "$RUNNER_TEMP/codex-validator"
          for f in validate_plugin.py identifier_validation.py; do
            curl -sfL "https://raw.githubusercontent.com/openai/codex/f3f6922519fa38487c8250c2b8a670a39a2cf9ff/codex-rs/skills/src/assets/samples/plugin-creator/scripts/$f" \
              -o "$RUNNER_TEMP/codex-validator/$f"
          done
          echo "CODEX_PLUGIN_VALIDATOR=$RUNNER_TEMP/codex-validator/validate_plugin.py" >> "$GITHUB_ENV"

      # ubuntu-latest ships shellcheck, but the lint assertion must not quietly
      # skip if a future image drops it.
      - name: Ensure shellcheck
        run: command -v shellcheck || sudo apt-get install -y shellcheck

      - name: Run static checks
        run: tests/run.sh

  setup-e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false

      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version: 22

      - name: Install Claude Code CLI
        run: npm install -g @anthropic-ai/claude-code@2.1.220

      # The runner has claude and no codex, which is exactly the Claude-only
      # machine section 7.2 supports. SD_MARKETPLACE_SOURCE points the install
      # at this checkout: without it, `marketplace add eranroseman/agent-plugins`
      # would clone origin main and the run would test the wrong declarations.
      - name: bin/setup against a scratch HOME
        env:
          SD_MARKETPLACE_SOURCE: ${{ github.workspace }}
        run: |
          mkdir -p "$RUNNER_TEMP/home"
          HOME="$RUNNER_TEMP/home" CODEX_HOME="$RUNNER_TEMP/home/.codex" \
            bash bin/setup

      - name: bin/doctor reports clean over the same HOME
        run: |
          HOME="$RUNNER_TEMP/home" CODEX_HOME="$RUNNER_TEMP/home/.codex" \
            bash bin/doctor
```

(The `Ensure shellcheck` step and the bare `tests/run.sh` survive this task and go in Task 22, which replaces them with the pinned install and `--no-skip`.) The triggers stay as they were: `push:` unfiltered by branch, `pull_request:` kept, no path filter (#8, §9.3).

In `.github/workflows/upstream-watch.yml`, replace line 26, `- uses: actions/checkout@v4`, with:

```yaml
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
```

Its `permissions:` block (`contents: read`, `issues: write`) already sits at the top level.

- [ ] **Step 4: Run the test to verify it passes, then prove the three greps by mutation**

Run: `bash tests/test-workflows.sh`
Expected: `workflows: 2 workflow(s) linted, every uses: sha-pinned, permissions declared, credentials not persisted`.

Mutations, each reverted with `git checkout -- .github/workflows/validate.yml`:

```bash
sed -i 's|run: npm install -g @anthropic-ai/claude-code@2.1.220|run: npm install -g $PKG|' .github/workflows/validate.yml && bash tests/test-workflows.sh; git checkout -- .github/workflows/validate.yml
```

Expected: an actionlint line tagged `[shellcheck]` with `SC2086` naming `validate.yml` and its line, then `FAIL: actionlint reported problems`.

```bash
sed -i 's|actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0|actions/setup-node@v4|' .github/workflows/validate.yml && bash tests/test-workflows.sh; git checkout -- .github/workflows/validate.yml
```

Expected: `FAIL: .github/workflows/validate.yml: a uses: line is not pinned to a 40-character sha:` naming the line.

```bash
sed -i '/^permissions:/,/^  contents: read$/d' .github/workflows/validate.yml && bash tests/test-workflows.sh; git checkout -- .github/workflows/validate.yml
```

Expected: `FAIL: .github/workflows/validate.yml declares no top-level permissions: block`.

Then `bash tests/test-format-prettier.sh && bash tests/test-lint-shell.sh` (both workflows are in the YAML list; prettier must be satisfied by the new file as written).

- [ ] **Step 5: Commit**

```bash
git add tests/test-workflows.sh .github/workflows/validate.yml .github/workflows/upstream-watch.yml
git commit -m "Lint the workflows' embedded shell, pin every action by sha, and drop to read-only" -m "tests/test-workflows.sh runs actionlint, which runs shellcheck over every run: block, and asserts beside it the three properties actionlint cannot see: every uses: pinned to a 40-character sha, permissions: at the top level, persist-credentials: false on every checkout (#28, #6 item 1, spec §9.4). validate.yml gains contents: read at workflow level, every uses: in both files is pinned with the tag in a trailing comment, and pyyaml is pinned, the workflow's one unpinned install (§9.1). The triggers stay: push unfiltered, pull_request kept, no path filter (#8).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 22: CI installs the registry, runs `--no-skip`, uploads the result file (§9.5, §9.6)

**Files:**

- Modify: `.github/workflows/validate.yml` (the `Ensure shellcheck` and `Run static checks` steps)

- [ ] **Step 1: Replace the two steps**

In the `validate` job, replace from `# ubuntu-latest ships shellcheck, but the lint assertion must not quietly` through `run: tests/run.sh` with:

```yaml
      # The suite's optional tools at exactly the versions tests/tools.txt
      # declares (spec §9.5): npm packages by version, release binaries by the
      # sha256 of the linux-amd64 asset, verified before anything is placed on
      # PATH. The directory goes ahead of the image's own tools, so the
      # shellcheck ubuntu-latest ships cannot shadow the pinned one. The
      # registry is read on fd 3: npm and curl would drain a loop's stdin.
      - name: Install the pinned tools
        run: |
          set -euo pipefail
          bin="$RUNNER_TEMP/tools"
          mkdir -p "$bin"
          while read -r tool version sha <&3; do
            case "$tool" in '' | '#'*) continue ;; esac
            case "$tool" in
              prettier | markdownlint-cli2 | cspell)
                npm install -g "$tool@$version"
                ;;
              shellcheck)
                curl -sfL "https://github.com/koalaman/shellcheck/releases/download/v$version/shellcheck-v$version.linux.x86_64.tar.xz" \
                  -o "$RUNNER_TEMP/shellcheck.tar.xz"
                echo "$sha  $RUNNER_TEMP/shellcheck.tar.xz" | sha256sum -c -
                tar -xJf "$RUNNER_TEMP/shellcheck.tar.xz" -C "$RUNNER_TEMP" "shellcheck-v$version/shellcheck"
                mv "$RUNNER_TEMP/shellcheck-v$version/shellcheck" "$bin/shellcheck"
                ;;
              actionlint)
                curl -sfL "https://github.com/rhysd/actionlint/releases/download/v$version/actionlint_${version}_linux_amd64.tar.gz" \
                  -o "$RUNNER_TEMP/actionlint.tar.gz"
                echo "$sha  $RUNNER_TEMP/actionlint.tar.gz" | sha256sum -c -
                tar -xzf "$RUNNER_TEMP/actionlint.tar.gz" -C "$bin" actionlint
                ;;
              shfmt)
                curl -sfL "https://github.com/mvdan/sh/releases/download/v$version/shfmt_v${version}_linux_amd64" \
                  -o "$bin/shfmt"
                echo "$sha  $bin/shfmt" | sha256sum -c -
                chmod +x "$bin/shfmt"
                ;;
              *)
                echo "tests/tools.txt names a tool this step cannot install: $tool" >&2
                exit 1
                ;;
            esac
          done 3< tests/tools.txt
          echo "$bin" >> "$GITHUB_PATH"

      # Every unmet need is a FAIL here (spec §5.2): a runner that was told to
      # install everything and still lacks a tool has a broken installation,
      # and a run that verified less than it claims cannot be green.
      - name: Run static checks
        run: tests/run.sh --no-skip

      # The result file the run wrote, so a CI claim is citable the way a
      # local one is (spec §5.4, §9.6).
      - name: Upload the result file
        if: always()
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2
        with:
          name: results
          path: tests/results.tsv
```

- [ ] **Step 2: Lint, format and run the install step locally**

Run: `bash tests/test-workflows.sh && bash tests/test-format-prettier.sh`
Expected: both success lines (actionlint lints the new `run:` block; prettier accepts the file as written — if it does not, run `bin/format` and keep its result).

Run the step's body by hand against a scratch directory, to catch a wrong asset name before CI does:

```bash
export RUNNER_TEMP="$(mktemp -d)"
export GITHUB_PATH="$RUNNER_TEMP/path"
bash -c "$(sed -n '/^          set -euo pipefail$/,/^          echo "\$bin" >> "\$GITHUB_PATH"$/p' .github/workflows/validate.yml | sed 's/^          //' | grep -v 'npm install')"
ls "$RUNNER_TEMP/tools"; "$RUNNER_TEMP/tools/shellcheck" --version | sed -n 2p; "$RUNNER_TEMP/tools/actionlint" -version | head -n 1; "$RUNNER_TEMP/tools/shfmt" --version
```

Expected: three `OK` lines from `sha256sum -c`, then `shellcheck actionlint shfmt`, `version: 0.9.0`, `1.7.12`, `v3.14.1`. (The `npm install` lines are filtered out of the local dry run; they are the same command Task 17 ran.)

- [ ] **Step 3: Commit and watch CI**

```bash
git add .github/workflows/validate.yml
git commit -m "Install the registry's tools in CI ahead of the image's, run --no-skip, upload results.tsv" -m "One step reads tests/tools.txt: npm packages at their exact versions, the three binaries downloaded and checked against the recorded sha256 before they go on PATH, placed ahead of ubuntu-latest's own shellcheck so it cannot shadow the pin (spec §9.5). The static checks run with --no-skip, so an unmet need in CI is a failed install reported by name, never a skip under a green run. The result file is uploaded on every run, green or red (§9.6). The apt-get workaround goes: a pinned download replaces a workaround for the skip it was defeating.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git push && gh run watch --exit-status "$(gh run list --branch suite-and-ci --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: both jobs green; the `Run static checks` log ends `N passed, 0 failed, 0 skipped` with no `SKIP` line anywhere, and the run's artifacts list `results`. Download it (`gh run download <id> -n results`) and read its header: the branch's sha, no `dirty`.

### Task 23: The README's Checks section (#7, §10.1)

**Files:**

- Modify: `README.md` (the `## Checks` section, lines 93–103 at `55f1bcc`, shifted by the fence languages Task 19 added)
- Modify: `cspell.config.yaml` (if a new term appears)

- [ ] **Step 1: Replace the section**

Replace everything from `## Checks` to the end of the file with:

```markdown
## Checks

`tests/run.sh` runs every check under `tests/`. It needs `bash` 4 or later,
`jq` and `git`, and refuses with the list otherwise. Some checks need a tool
this machine may lack: each such check is skipped with a line naming the
tool, and the run ends by summing what it did not verify. The versions those
checks are held to are declared in `tests/tools.txt`; the three npm tools
install with `npm install -g <tool>@<version>`, the three binaries from their
release pages. The Codex manifest check needs `python3` with `pyyaml` and the
validator `codex-cli` installs, or a copy fetched by the recipe in
`.github/workflows/validate.yml` and named by `CODEX_PLUGIN_VALIDATOR`. The
pin and drift checks fetch from GitHub; offline, they fail rather than skip.

Every run writes `tests/results.tsv`, one row per check under a header naming
the commit; a report cites that file rather than pasting output. `bin/format`
rewrites what the format checks check. CI runs the same script with
`--no-skip`, so nothing is skipped there, uploads the result file as an
artifact, and runs `bin/setup` end to end against a scratch `HOME`.
```

No count of checks and no count of network tests: both rotted before (§10.1, §12). The Install and Update sections, and their prerequisites paragraph, do not change.

- [ ] **Step 2: Run the tests that read the README**

Run: `bash tests/test-setup-doctor.sh && bash tests/test-links-resolve.sh && bash tests/test-lint-markdown.sh && bash tests/test-format-prettier.sh && bash tests/test-spelling.sh`
Expected: five success lines. If cspell flags `pyyaml`, add it to `cspell.config.yaml`'s `words:` in this commit; it is a package name, not a typo.

- [ ] **Step 3: Commit**

```bash
git add README.md cspell.config.yaml
git commit -m "Describe the suite as it stands in the README's Checks section" -m "What runs, what it needs, where the versions are declared, what a skip means, that every run writes tests/results.tsv for a report to cite, and what CI does differently (#7, spec §10.1). No counts that rot: the old section's 'ten of them touch the network' was corrected once already and is eliminated rather than corrected again.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 24: The version bump (§10.2)

**Files:**

- Modify: `plugins/software-dev/.claude-plugin/plugin.json`, `plugins/software-dev/.codex-plugin/plugin.json`, `plugins/sensemaking/.claude-plugin/plugin.json`, `plugins/sensemaking/.codex-plugin/plugin.json`

- [ ] **Step 1: Bump both manifests of each plugin**

Run:

```bash
sed -i 's/"version": "0.7.0"/"version": "0.7.1"/' plugins/software-dev/.claude-plugin/plugin.json plugins/software-dev/.codex-plugin/plugin.json
sed -i 's/"version": "0.2.0"/"version": "0.2.1"/' plugins/sensemaking/.claude-plugin/plugin.json plugins/sensemaking/.codex-plugin/plugin.json
git diff --stat
grep -rn '"version": "0\.7\.0"\|"version": "0\.2\.0"' plugins/
```

Expected: four files, one line each; the grep prints nothing.

- [ ] **Step 2: Run the tests that read the versions**

Run: `bash tests/test-references-resolve.sh && bash tests/test-format-prettier.sh && bash tests/test-doctor-faults.sh && bash tests/test-json-wellformed.sh`
Expected: `… 2 manifest pair(s) agree` (the equality check guards the pairs; no test carries the literal any more), and the other three success lines. Where `claude` is present, `bash tests/test-setup-upgrade.sh` moves both plugins to the new versions.

- [ ] **Step 3: Commit**

```bash
git add plugins/software-dev/.claude-plugin/plugin.json plugins/software-dev/.codex-plugin/plugin.json plugins/sensemaking/.claude-plugin/plugin.json plugins/sensemaking/.codex-plugin/plugin.json
git commit -m "Release software-dev 0.7.1 and sensemaking 0.2.1" -m "Formatting a shipped file changes the shipped plugin, and version is the only thing that moves an installed copy (spec §10.2). Both manifests of each plugin, one commit; tests/test-references-resolve.sh holds the pairs equal.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

### Task 25: Gate 2, merge, push (§11)

**Files:** none modified.

- [ ] **Step 1: The full suite locally, nothing skipped**

Run: `tests/run.sh --no-skip; echo "exit=$?"; head -n 1 tests/results.tsv; tail -n 1 tests/results.tsv`
Expected: `exit=0`; the summary `N passed, 0 failed, 0 skipped` with N the number of `tests/test-*.sh` files (29 on the branch: the 19 that existed plus ownership, runner, lint-shell, setup-upgrade, doctor-silence, format-shell, format-prettier, lint-markdown, spelling and workflows); the header carrying the branch's short sha with no `dirty` (in a worktree). Cite `tests/results.tsv` in the task report.

- [ ] **Step 2: CI green on the branch, with the artifact**

Run: `git push && gh run watch --exit-status "$(gh run list --branch suite-and-ci --limit 1 --json databaseId --jq '.[0].databaseId')"`
Expected: both jobs green, `results` among the artifacts, the `Run static checks` log ending `N passed, 0 failed, 0 skipped`. If `gh run list` prints nothing yet, run the command again a few seconds later.

- [ ] **Step 3: Merge to `main` and push in the same motion**

```bash
git fetch origin
git checkout main
git merge --ff-only origin/main
git merge --ff-only suite-and-ci
git push origin main
gh run watch --exit-status "$(gh run list --branch main --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: a fast-forward (the history has never carried a merge commit), the push accepted, and the `main` run green. Record the new `main` sha for Task 26. If `origin/main` moved while the branch was open, rebase `suite-and-ci` onto it, repeat Steps 1 and 2, then merge.

If executing in a worktree, run Step 3 from the main checkout; then `git worktree remove <path>` and `git worktree prune` there once `main` carries the branch.

### Task 26: Dispositions land in the tracker

**Files:** none; GitHub Issues via `gh`, per `docs/agents/issue-tracker.md`.

- [ ] **Step 1: Close what landed, comment on what was partial or declined**

`M` below is the `main` sha from Task 25, `S` the spec path `docs/superpowers/specs/2026-09-17-suite-and-ci-design.md`. Each body is normal prose for the tracker's readers.

```bash
M="$(git rev-parse --short main)"
S=docs/superpowers/specs/2026-09-17-suite-and-ci-design.md
close() { gh issue close "$1" --comment "$2"; }

close 1  "Landed on main at $M ($S §7.1): the two manifests of each plugin are held equal on name, version, author, homepage, repository, license and keywords; the Codex skills pointer must be a directory; the marketplace category must equal the manifest's; and a plugin with only a Codex manifest fails the Claude validator's loop instead of being skipped."
close 3  "Landed on main at $M ($S §9.2): tests/test-codex-validate.sh asserts the sha256 of both validator files, wherever they were read from, against the bytes CI fetches at openai/codex f3f6922, and the failure message names the fetch recipe. sha256 rather than md5, because sha256sum is the repository's one hashing tool."
close 5  "Landed on main at $M ($S §7.6): the three GNU-only sites are portable (mapfile to a read loop, find -printf to a glob loop). No GNU probe joined the gate; the tests need nothing past bash 3.2, and the engine's sha256sum and readlink -f stay because the engine is not what this issue was about."
close 7  "Landed on main at $M ($S §10.1): the Checks section says what runs, what it needs, where tests/tools.txt declares the versions, what a skip means, and that every run writes tests/results.tsv. The network count is eliminated rather than corrected again."
close 8  "Decided on main at $M ($S §9.3): push stays unfiltered by branch, pull_request stays, and no path filter is added. Every push runs CI and docs/ is checked like the rest; the filter's whole yield was a minute per docs push on a public repository, against a negated pattern list and fifteen unchecked files."
close 16 "Landed on main at $M ($S §6.5, §7.2): bin/setup and bin/doctor resolve their own directory by parameter expansion and the doctor execs \$BASH, so both survive an empty PATH; the refusal grep matches the refusal's own words; every capture and command in tests/test-setup-doctor.sh is guarded; the two stale comments are gone."
close 27 "Landed on main at $M ($S §4): one derivation in tests/lib.sh over git ls-files, minus six vendored patterns each paired with its drift test, feeds every list; tests/test-json-wellformed.sh reports eight files where the hardcoded find saw seven; tests/test-ownership.sh keeps the exclusion honest."
close 28 "Landed on main at $M ($S §9.4): tests/test-workflows.sh runs actionlint, which lints every run: block with shellcheck, and asserts beside it what actionlint cannot see: every uses: sha-pinned, permissions: at the top level, persist-credentials: false on every checkout."
close 29 "Landed on main at $M ($S §8): shfmt, prettier, markdownlint-cli2 and cspell (en-US) over the files we own, at the versions tests/tools.txt declares, applied by bin/format and checked by one test each. The one-time reformat and the hand corrections landed as their own commits."
close 38 "Landed on main at $M ($S §6.2): the first-entry fixture moved into tests/test-doctor-silence.sh with its comment corrected, beside a second-entry fixture for the shape only the exit status can catch."
close 41 "Landed on main at $M ($S §6.1): ok, bad, skip and note count what they print, and every check is bracketed by a snapshot of that count and a reported() call that fails a check which printed nothing. Both rungs; the class, not the instances."
close 42 "The repository half landed on main at $M ($S §5.4): every tests/run.sh run writes tests/results.tsv, CI uploads it, and a report cites the path. The template half -- editing or prompting the SDD skill to cite artifacts -- is declined: no skill edit and no prose rule (§12)."
close 43 "Landed on main at $M ($S §7.4): tests/test-hook.sh extracts the fenced block under the hook design's §4.2 and diffs it against hooks/payload-rules.md byte for byte; the design's stale byte counts are corrected and its Status line says a test reads §4.2."
close 40 "Landed on main at $M ($S §6.3, §6.4, §7.5): the four remaining tab-IFS read loops are split by parameter expansion and an empty field is reported as malformed, with fixtures for the all-empty-names and empty-entry-name shapes; the duplicate all-clear says how many trees it hashed and the Codex note is gated on a complete pool; the two comments in test-codex-validate.sh are corrected. The registry entry whose install directory is gone stays declined, as recorded here."
close 18 "Landed on main at $M ($S §7.3, §12), item by item: the README extractor closes its scope on an h1 or an h2 and keeps an h3 inside its parent, proved on a synthetic README. The test-codex-validate.sh header was already corrected. The LICENSE:55 comma is declined as moot: the line is this repository's own attribution prose, not upstream license text, three of the four attribution blocks use the comma form, and a drift test greps one of them, so 're-wrap' was the wrong word for it. A Note: commit for 4b23edc is declined: history is history. The task-10 report no longer exists. The plugin README's 'on Codex too' sentence is milestone 7's, tracked by #37 and #57."
gh issue comment 6 --body "Item 1 landed on main at $M ($S §9.1): validate.yml declares permissions: contents: read at workflow level, every uses: in both workflows is sha-pinned, and every checkout sets persist-credentials: false. The other items are untouched and this issue stays open for them."
```

Expected: fifteen issues closed, one comment on #6, each visible with `gh issue view <n> --comments`.

- [ ] **Step 2: Confirm nothing is left in the workspace**

Run: `gh issue list --state open --json number,title --jq '.[] | "\(.number)\t\(.title)"' | sort -n`
Expected: none of 1, 3, 5, 7, 8, 16, 18, 27, 28, 29, 38, 40, 41, 42, 43 among them; #6, #58 and #59 still open, as intended. If the SDD skill left a `.superpowers/sdd/` workspace, every Concern's disposition is now an issue comment, a spec section, or a decline recorded in §12; the workspace may close.

---

## Self-review

**Spec coverage.** §4 → Tasks 1–3 (`checked`, the JSON and link consumers, `test-ownership.sh`); the shellcheck consumer → Task 5; the three prettier lists, markdownlint, cspell, `bin/format` → Task 17. §5.1–5.2 → Task 4 (gate, needs, probes, `--no-skip`, the two shapes), headers → Task 5 and each new test. §5.3 → Tasks 5 (lint moved, tag assertion ungated), 6 (upgrade split), 7 (hermetic repair). §5.4 → Task 4. §6.1 → Task 15. §6.2's nine fixtures → Tasks 8 (1–7), 13 (8–9), plus fixture 10 (Deviation P2). §6.3 → Task 13. §6.4 → Task 14. §6.5 → Task 9. §7.1 → Task 11. §7.2 → Task 9 (guards, comments) and Task 6 (the block). §7.3 → Task 9. §7.4 → Task 12. §7.5 → Task 5. §7.6 → Task 10. §7.7 → Task 3. §8.1–8.4 → Tasks 17–19 (the couplings checked in Task 18 Step 2). §8.2's registry → Task 4 (Deviation P4), consumed in Tasks 17 and 22. §9.1 → Task 21. §9.2 → Task 20. §9.3 → Task 21 (no change, recorded). §9.4 → Task 21. §9.5–9.6 → Task 22. §10.1 → Task 23. §10.2 → Task 24. §11's gates → Tasks 16 and 25. §12's declines and the three deviations → recorded in Global Constraints and closed in Task 26. §14's open items are not this plan's.

**Placeholder scan.** Every code step carries its code; the two full-file rewrites (`tests/run.sh`, `tests/test-setup-doctor.sh`) and the three new fixture files are complete; the hand corrections of Task 19 list each finding by file and rule with the fix each rule takes, and the dictionary by word.

**Type consistency.** `checked`, `checked_shell`, `VENDORED_PATTERNS`, `VENDORED_GUARDS`, `EXCLUDED`, `SHFMT_FLAGS` are defined in Task 1 (17 for the last) and used under those names in Tasks 2, 3, 5, 17, 18, 19. `scratch_repo`, `bin_without`, `seeded_home`, `run_case`, `saw` and `OUT` are defined in Task 8 and used in Tasks 13 and 15. `split_tsv` and the array `F` are defined and used in Task 13. `REPORTED`, `reported` in Task 15. `WANT`, `FOUND`, `probe`, `declared_needs`, `registry_version`, `tool_version` are internal to `tests/run.sh` and appear only there. The result-file row shape asserted in Task 4's test is the one Task 4's runner writes and Task 25 cites. The pins and hashes in Global Constraints are the ones Tasks 4, 20, 21 and 22 use, character for character.
