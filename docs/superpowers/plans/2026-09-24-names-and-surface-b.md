# A Doctor That Reports Everything — Implementation Plan B (milestone 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `bin/doctor` and the watch report everything they can see, fail when they cannot see, and repair the one class of residue they can prove; then make the suite's own guards true and land milestone 4 on `main`.

**Architecture:** Engine correctness first (a bash 4.4 floor, the self re-check through `$BASH`, the capture-and-check idiom on both subset loops, the `CODEX_LIST` guard, the bump script's temporaries), each red first by the mutation its issue names. Then the doctor's new surface: a report-only pass (archify's variable, undeclared skills.sh installs, the two CLI versions, the sensemaking false OK), a cache walk that deletes Claude's orphaned plugin caches under four positive guards and reports Codex's, and a freshness check that reads the watch's run history over the public API. Then the records the watch reads: `vendored.json` for the two vendored-tree pins, `not_adopted` and `via_subset_entry` buckets in `skills.json` with a complement test, and the action pins read from the workflow files themselves. Then the suite's efficacy items from #61, #62, #63 and #65, CI, the version bump, gate 2, the merge, and the dispositions.

**Tech Stack:** bash 4.4+ (`set -euo pipefail` in the tests, no `set -e` in the engine), git, jq, curl (optional, the doctor's freshness check), GNU `date` and `find`, shellcheck 0.9.0, shfmt 3.14.1, prettier 3.9.6, markdownlint-cli2 0.23.2, cspell 10.2.2, actionlint 1.7.12, `gh`, GitHub Actions on node24 runtimes.

**Spec:** `docs/superpowers/specs/2026-09-20-names-and-surface-design.md`, §10 to §19 and §20's plan B list. Section numbers below refer to it. Plan A, `docs/superpowers/plans/2026-09-23-names-and-surface-a.md`, is the house style this plan follows, and its gate commit `6fe852e` lists what this plan inherits.

**This is plan B of two.** It is written against `names-and-surface` at `6fe852e`, twenty-one commits past `main`, and every line number below is a position on that tree. The spec says names, sections and anchors, never line numbers, for plan B; where a number appears it is a locator for the executor, and the quoted text beside it is what binds.

## What was verified while planning (2026-09-24, tree at `6fe852e`)

Every count and fact below was measured in the worktree, on this machine, or against the live services; where the spec's §22 claims differ, the plan says so.

- **The engine's externals.** `bin/setup` calls `git`, `jq`, `grep`, `readlink`, `basename`, `dirname`, `mv`, `ln`, `mkdir`, `cat`, `sha256sum` and, in `ensure_fresh_clone`, `cut`; it calls none of `sed`, `awk`, `find`, `cp`, `rm`, `date`. The fixture PATH lists in `tests/test-doctor-silence.sh`, `tests/test-doctor-duplicates.sh`, `tests/test-doctor-faults.sh` and `tests/test-setup-upgrade.sh` carry `sed awk find cp` and not `cut` (M14). After this plan the engine also calls `find` (the mtime guard of §11) and `date` (the age in §12), so `find` and `date` stay on every list; `sed`, `awk` and `cp` go; `cut` joins.
- **The Claude plugin cache on this machine** holds thirteen directories: nine registered marketplaces (`known_marketplaces.json` names ten; `claude-plugins-official` has no cache) and four `temp_subdir_*.clone` directories from 2026-09-18, 204 to 464 KB each, none named by any `installPath` in `installed_plugins.json`, all older than an hour. §11's four guards delete exactly those four and nothing else here.
- **The Codex cache on this machine** holds eight directories. `codex plugin marketplace list` names four (`caveman`, `eranroseman`, `jrjsmrtn-skills`, `obsidian-skills`); `~/.codex/config.toml` carries `[marketplaces.NAME]` sections for five (those four and `ponytail`, which the list omits). `openai-curated` and `openai-curated-remote` appear in neither: they are Codex's own curated marketplaces, the second refreshed on 2026-09-23 18:30 and holding ten plugins, and `codex plugin list --json` names `codex-security@openai-curated` as installed. Under §11's rule for the Codex half, `openai-curated-remote` is unregistered, holds no installed plugin's path and is older than an hour, so it would be deleted, and so would `agent-toolkit`, an empty directory from 2026-09-06 that is genuine residue. No command Codex exposes tells the two apart. Deviation P1 follows.
- **§23's "Codex's plugin cache has no registry file"** is wrong at 0.147.0: `~/.codex/config.toml` records each user-added marketplace as a `[marketplaces.NAME]` table. The Codex half reads that file, offline, and the CLI's `plugin list --json` for the installed set.
- **`temp_subdir_*.clone`** directories are the CLI's scratch clones from git-subdir installs (§22); four here, as measured.
- **The Claude Code launcher** holds exactly three versions, `2.1.261`, `2.1.263`, `2.1.273`, with `~/.local/bin/claude` a symlink to the last: §22's retention claim, confirmed by count. #64 is declined on that fact.
- **`claude --version`** prints `2.1.273 (Claude Code)`; **`codex --version`** prints `codex-cli 0.147.0`. The NOTE lines of #44 carry those strings whole.
- **The lockfile on this machine** carries twenty keys; one, `typesafe-ai`, is in no source of `skills.json`, and its entry has `source` and `skillPath` but no `ref`. #54's NOTE will fire here and must print a missing ref as such.
- **`~/.claude/settings.json`** has no `env` map at all here, so #50's unset case is the maintainer's own machine.
- **The runs API** answers 200 unauthenticated from this address: 18 completed scheduled runs, the latest `2026-09-24T11:46:48Z`, conclusion `success`; the three latest landed 5h20m to 5h30m after the 06:17 UTC slot, inside §12's 4.5 to 6.5 hour window. `date -u -d '2026-09-24T11:46:48Z' +%s` parses the timestamp.
- **The actions' current releases** are `actions/checkout@v7.0.1` (`3d3c42e5aac5ba805825da76410c181273ba90b1`), `actions/setup-node@v7.0.0` (`820762786026740c76f36085b0efc47a31fe5020`), `actions/setup-python@v7.0.0` (`5fda3b95a4ea91299a34e894583c3862153e4b97`), `actions/upload-artifact@v7.0.1` (`043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`); each declares `runs.using: node24`, and each tag is lightweight (`git ls-remote` shows no `^{}` peel), so the sha beside the tag is the commit. The four pinned today declare `node20`. §14's "first node24 majors" (v5, v5, v6, v6) are two majors behind; "current" means these.
- **The skills.sh sources at their refs.** `mattpocock/skills@v1.2.3` ships 35 `SKILL.md` files under four category directories, 35 distinct basenames; `obra/superpowers-developing-for-claude-code@v0.3.1` ships 4, two of them under `examples/*/skills/`; `tt-a1i/archify@v2.16.0` ships one, at `archify/SKILL.md`. Against `skills.json`'s 19 declared names and the 7 the test blocks, 13 names are in no bucket, not #53's fourteen: 11 in mattpocock (`ask-matt`, `claude-handoff`, `git-guardrails-claude-code`, `loop-me`, `migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`), 2 in developing-for-claude-code (`professional-greeting`, `workflow`), plus `grill-me` with its alias reason; #53 counted `grill-me` among its fourteen.
- **The vendored upstreams.** `obra/superpowers-lab` `main` is at `51111f74f24058117752d9aa917cb19859f8ec86`, the pinned sha: clean. `UditAkhourii/adhd` `main` is at `dd08acc38693127cd0ca2325fe6bf9579131ede1`, past the pinned `16dc239ff186b869372e75095cfa58fc0ee89927`: the watch's first run reports it moved, as §14 says it will. The in-tree records at HEAD: adhd's sha in `tests/test-vendored-adhd.sh`, its `SKILL.md` header and `plugins/sensemaking/LICENSE`; superpowers-lab's in `tests/test-vendored-duplicates.sh`, its `SKILL.md` header, `PROVENANCE.md` (twice, once short) and `plugins/software-dev/LICENSE`.
- **`prettier --check .markdownlint-cli2.jsonc`** fails today: prettier's jsonc parser wants trailing commas on the last members. M19's one reformat is those two commas.
- **M20 is already fixed**: plan A's Task 9 rewrapped the sensemaking README's `adhd` bullet and `/adhd <problem>` sits on one line. No task; recorded here.
- **#6's items 1 to 4** are already on the tree (the `permissions:` block, the marketplace line in `tests/test-claude-validate.sh`'s header, the `CLAUDE_PLUGIN_ROOT` comment and the trap in `tests/test-hook.sh`); only the action bump remains, and #6 closes on it.
- **Every doctor run in the tests that inherits the real PATH** (`tests/test-setup-doctor.sh`, `tests/test-doctor-faults.sh` line 70) will reach the freshness check once it exists and, with `curl` present, make one request; a fixture PATH without `curl` prints the SKIP instead. Task 8 gives both invocations a PATH without `curl` so the tests' "needs no network" headers stay true.
- **The branch** is twenty-one commits past `main` and `main` has nothing the branch lacks; a fast-forward merge is available at gate 2 as long as `main` does not move.
- **Plan B is inside the reference check.** Once committed, every new file this plan names in a backticked span with a slash is a typo to `tests/test-links-resolve.sh` until the file exists. Task 1 declares them absent and each creating task drops its own line; the plan was scanned with the branch's test before handover (Gate 2, Step 2 repeats it).

## Deviations decided while planning

Visible choices, each with a veto line.

- **P1. The Codex half of the cache walk reports and never deletes.** §11 keys the Codex half on `codex plugin marketplace list`, which omits Codex's own curated marketplaces; on this machine the rule would delete `openai-curated-remote`, ten plugins the CLI refreshed yesterday. The walk names each Codex cache directory that neither `~/.codex/config.toml`'s `[marketplaces.*]` tables nor an installed plugin's path accounts for, as one NOTE, and touches nothing. The Claude half stands as §11 wrote it. Veto: delete under §11's guards and accept that a built-in cache is destroyed on the first apply.
- **P2. The Codex half reads `config.toml`, not the CLI's list.** §23 said Codex had no registry file; it does, and the list omits a marketplace the file records. The file is read offline with a `grep` over `^\[marketplaces\.` headers, so the doctor's no-network fixtures cover it; `codex plugin list --json` still supplies the installed set when it succeeds. Veto: the CLI's list, and `ponytail` reads as unregistered here.
- **P3. New focused test files instead of growing `tests/test-doctor-faults.sh`.** It is 210 lines; the report-only fixtures, the cache walk, the freshness check and the apply-block stubs each get a file of their own, named for what they prove. Veto: append to the faults test.
- **P4. Dispositions after the merge and push, not before gate 2.** §20 lists them fifth of seven; a closing comment cites a commit on `main`, so they follow the fast-forward. Veto: close on the branch's shas.
- **P5. The action pins go to the newest node24 releases, v7.** §14 names the first node24 majors as measured on 2026-09-20; two majors have shipped since and "current" is what the watch will hold them to. Veto: pin v5.0.0, v5.0.0, v6.0.0, v6.0.0 and let the watch report drift on its first run.
- **P6. The watch's `uses:` section peels an annotated tag and falls back to the bare tag.** All four current tags are lightweight; a peel-only read would report drift on every one. Veto: annotated tags only, and a hand-kept exception.
- **P7. `find` stays on the fixture PATH lists; `sed`, `awk`, `cp` go; `cut` and `date` are present.** M14 was measured before §11's `find -mmin` guard and §12's `date -d` existed. Veto: drop `find` and rewrite the mtime guard with `date -r`.
- **P8. #65's hardening lands here, four fixes and four declines.** Plan A filed the reference check's latent weaknesses as plan B's to make or decline. Fixed: the unanchored `.gitignore` entries, `git log HEAD` in place of `--all`, the URL test before the `NAME=` strip, and a class-5 regex that accepts only `owner/repo`, a hex revision, or `plugin@marketplace` before the colon. Declined, on the issue: the basename rule in `names_successor` (every current pass is a genuine mention), indented fences, escaped backticks inside a span, and the per-line fork cost. Veto: leave #65 open untouched.
- **P9. The hook test regains all three shape checks.** #63 item 2 names two; the third, one trailing newline, is one `tail -c` line and the gate commit asked for a ruling. Veto: two.
- **P10. `tests/test-format-apply.sh` un-formats copies in a scratch git clone.** `checked()` reads `git ls-files`, so a scratch tree must be a clone, not a copy. Veto: a copy with a hand-written file list, which is the drift #62 item 2 exists to close.
- **P11. The Layout section also gains `.claude-plugin/`**, per the comment on #35, beside the `vendored.json` line §14 adds. Veto: leave it to milestone 7.
- **P12. Version numbers:** software-dev `0.7.1` to `0.8.0` (minor: the hook directory's file names changed), sensemaking `0.2.1` to `0.2.2` (patch), both manifests of each. Veto: other numbers.

## Global Constraints

Copied from the spec unless marked; every task's requirements implicitly include this section.

- **Branch and gates.** All work on `names-and-surface`, rebased onto `main` only if `main` moves. Gate 2 is Task 16: the same evidence as gate 1 (full suite green with `tests/results.tsv` cited, CI green on the pushed branch), then merge to `main` and push in the same motion, fast-forward. Dispositions (Task 17) follow the push.
- **Commit style.** Sentence-case subject, no type prefix, a body that says why, ending in the executing model's `Co-Authored-By` trailer (plan A's ruling R4). Every commit names its paths: `git add <paths>` then `git commit -m … -- <paths>`; after a `git mv`, the old path or a directory holding it joins the pathspec (R9). Never `git add -A` or `git commit -a`.
- **Suite green after every commit.** `bash tests/run.sh` before each commit; skips only for tools this machine lacks. Every guard is added red first, by the mutation its issue names, and the plan cites the result file for each green rather than transcribing output.
- **Report vocabulary** (§5.5, `CONTEXT.md`): desired state, subset entry, first-party, user-invocable only, agent CLI, additional context; no `_Avoid_` form in any new comment, string or file: `tests/test-vocabulary.sh` scans every checked file.
- **The reporting helpers** in `bin/setup`: `ok`, `bad` (counts a failure), `skip` (a half the machine lacks, or a tool `needs` names), `note`, `did` (never alone). Every check is bracketed at its call site: `before=$REPORTED`, the call, `reported "$before" <name>`. A check that prints nothing is a `bad`. `needs <tool> <why>` for a tool a check cannot run without; plain `skip` for `curl`, which is optional the way the Codex half is.
- **The reference check** scans this plan once it is staged: every fence carries a language; new files this plan creates are in `DECLARED_ABSENT` from Task 1 until their task creates them.
- **Formatting and spelling.** `scripts/format` before committing any markdown, JSON or YAML; `shfmt -w -i 2 -ci -bn` on any shell file; `shellcheck -e SC1091 -e SC2016` clean; cspell over comments. New words this plan needs in `cspell.config.yaml`: none known; add a term rather than misspell around it.
- **Issue numbers this plan closes** (§19, Task 17): #6, #13, #14, #17, #22, #24, #25, #26, #37, #44, #50, #53, #54, #56, #57, #58, #59, #61, #62, #63, #64, #65.

---

### Task 1: The engine's floor and its three guards (§13: bash 4.4, M9, M13, the `CODEX_LIST` read)

**Files:**

- Modify: `bin/setup` (the header and `set -uo pipefail` at lines 16–19; `ensure_clones` line 268; `ensure_claude` line 516; `ensure_codex` line 571; `main` line 898)
- Modify: `tests/run.sh` (lines 8, 42–43), `README.md` (line 83), `tests/test-doctor-silence.sh` (a new fixture 11 before the summary line), `tests/test-doctor-faults.sh` (the repair fixture's `bin/setup` path), `tests/test-links-resolve.sh` (`DECLARED_ABSENT`)

**Interfaces:**

- Produces: `bin/setup` refusing below bash 4.4 with `ERROR: bin/setup needs bash 4.4 or later (found X.Y)`, exit 2; `tests/run.sh` refusing with `the test suite needs: bash 4.4 or later (found X.Y)`; `ensure_clones` and `ensure_claude` reading `subset_entries` into a variable and reporting `the subset entries could not be read whole from <marketplace>; a partial list checks nothing` on a mid-stream abort; `DECLARED_ABSENT` naming the four test files Tasks 3 to 6 create.

- [ ] **Step 1: Declare the files this plan creates**

In `tests/test-links-resolve.sh`, after the `'.claude/settings.json'` line of `DECLARED_ABSENT`, add:

```bash
  'tests/test-setup-apply.sh'      # created by plan B Task 3, which drops this line
  'tests/test-doctor-report.sh'    # created by plan B Task 4, which drops this line
  'tests/test-doctor-cache.sh'     # created by plan B Task 5, which drops this line
  'tests/test-doctor-freshness.sh' # created by plan B Task 6, which drops this line
```

`bash tests/test-links-resolve.sh` stays green once this plan is staged (Gate 2, Step 2, proves it on the final tree).

- [ ] **Step 2: The floor, at both entry points and the README**

In `bin/setup`, directly after `set -uo pipefail` (line 19), insert:

```bash

# bash 4.4 or later, refused before anything else runs and with builtins
# only: below 4.4 an empty array's "${a[@]}" is unbound under set -u and the
# engine dies mid-check with no verdict (#61 M3). Every distribution that
# ships an older bash is end of life, so the version goes, not the idiom.
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 4 ]; }; then
  printf 'ERROR: bin/setup needs bash 4.4 or later (found %s.%s)\n' "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" >&2
  exit 2
fi
```

In `tests/run.sh`, line 8's `bash 4 or later` becomes `bash 4.4 or later`, and lines 42–43 become:

```bash
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 4 ]; }; then
  missing="$missing, bash 4.4 or later (found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})"
fi
```

`README.md` line 83: ``It needs `bash` 4 or later,`` becomes ``It needs `bash` 4.4 or later,``. This machine runs bash 5.2, so the refusal cannot be exercised here; `tests/test-setup-doctor.sh` gains, after its `--help` checks, the coupling that keeps the three sites saying one number:

```bash
# The bash floor is stated in three places and must be one number; the
# refusal itself cannot run on a machine whose bash is above it.
for f in "$SETUP" "$REPO_ROOT/tests/run.sh" "$REPO_ROOT/README.md"; do
  grep -q 'bash.*4\.4 or later' "$f" || fail "$f does not state the bash 4.4 floor"
done
```

- [ ] **Step 3: M9, the self re-check through `$BASH`**

`bin/setup` line 898, `"$REPO_ROOT/bin/setup" --check`, becomes `"$BASH" "$REPO_ROOT/bin/setup" --check`, as `bin/doctor` already does. Red first, in `tests/test-doctor-faults.sh`'s repair fixture: the run at line 199 invokes `"$SETUP"`; before it, add

```bash
# The engine re-checks itself through $BASH, not its shebang, so a deployed
# copy that lost its mode bit still prints its verdict (#61 M9): this run
# uses a copy of bin/setup with no +x beside the real desired state.
SETUP_NOX="$H/repo/bin/setup"
mkdir -p "$H/repo/bin" "$H/repo/.claude-plugin" || fail "could not seed $H/repo"
cp "$SETUP" "$SETUP_NOX" && chmod -x "$SETUP_NOX" || fail "could not copy bin/setup without +x"
cp "$MARKETPLACE" "$H/repo/.claude-plugin/" && cp "$REPO_ROOT/skills.json" "$H/repo/" || fail "could not copy the desired state"
cp -R "$REPO_ROOT/plugins" "$H/repo/" || fail "could not copy the plugins"
```

and the run itself invokes `/bin/bash "$SETUP_NOX"` in place of `/bin/bash "$SETUP"`. Run `bash tests/test-doctor-faults.sh` before Step 3's one-line change: expected `FAIL: bin/setup exited 126; the re-check must run and report the unrepairable clone` (the test's existing message; it names the status). After the change: green, and `printf '%s\n' "$out" | grep -q -- '--- re-checking ---'` at line 201 holds.

- [ ] **Step 4: M13, the capture-and-check idiom on both subset loops**

In `ensure_clones`, the loop header `while IFS= read -r line; do` (line 210) and its close `done < <(subset_entries)` (line 268) become a capture first:

```bash
  # Read whole, then looped: a non-zero jq exit means the program aborted
  # partway (a non-scalar version, say), and the rows before the abort are a
  # partial list that checks nothing. The idiom ensure_links uses (#61 M13).
  entries="$(subset_entries)" || {
    bad "the subset entries could not be read whole from $MARKETPLACE; a partial list checks nothing"
    return
  }
  while IFS= read -r line; do
```

with `done <<<"$entries"` closing it, and `entries` added to the function's `local` line. The same in `ensure_claude`: its loop at lines 488–516 reads `entries="$(subset_entries)" || { bad "the subset entries could not be read whole from $MARKETPLACE; a partial list checks nothing"; return; }` before `while`, and `done <<<"$entries"` after; `entries` joins its `local`.

Red first, in `tests/test-doctor-silence.sh`, a fixture 11 before the summary line:

```bash
# 11. A non-scalar `version` in the second git-subdir entry: jq's @tsv aborts
# after the first entry's row (exit 5, one row). A loop fed by process
# substitution ran that one row and reported one clone; the capture reports
# the abort (#61 M13). `null` would not do: @tsv renders it as an empty
# string without error.
R="$(scratch_repo non-scalar-version)"
jq --arg n "$second" '(.plugins[] | select(.name == $n) | .version) = {"x": 1}' "$MARKETPLACE" \
  >"$R/.claude-plugin/marketplace.json" || fail "could not corrupt the second entry's version"
run_case "non-scalar version" "$R" "$(seeded_home 11)" "$BIN"
saw 'the subset entries could not be read whole from' \
  || fail "non-scalar version: the partial read was not reported:"$'\n'"$OUT"
```

and the summary line becomes `doctor-silence: 11 unreadable machines, none reported clean`. Run it before Step 4's engine change: `FAIL: non-scalar version: the partial read was not reported`. After: green.

- [ ] **Step 5: The second `CODEX_LIST` read**

`bin/setup` line 571, `CODEX_LIST="$(codex plugin list --json 2>/dev/null)"`, becomes `CODEX_LIST="$(codex plugin list --json 2>/dev/null)" || CODEX_LIST=""`. Task 3's stateful `codex` stub is the fixture that drives this line; here it is the one-line guard the spec names.

- [ ] **Step 6: Suite and commit**

Run `shellcheck -e SC1091 -e SC2016 bin/setup tests/run.sh tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh`, `shfmt -d -i 2 -ci -bn bin/setup tests/run.sh tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh`, then `bash tests/run.sh`. Expected: silent, silent, green with `doctor-silence: 11 unreadable machines, none reported clean` among the rows.

```bash
git add bin/setup tests/run.sh README.md tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh tests/test-links-resolve.sh
git commit -m "Refuse bash below 4.4, re-check through \$BASH, and read the subset entries whole" -m "The floor removes #61 M3's abort by removing the version, not by guarding the idiom (names-and-surface spec §13); a copy of bin/setup without +x now prints its verdict (M9); a jq abort mid-stream is a FAIL naming what was lost rather than a shorter list (M13), proved by a non-scalar version in the second entry; the second codex plugin list read falls back to empty (#17). The reference check declares the four test files this plan creates." -- bin/setup tests/run.sh README.md tests/test-doctor-silence.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh tests/test-links-resolve.sh
```

Append the executing model's `Co-Authored-By` trailer to this and every commit below.

### Task 2: The bump script's temporaries (#14) and its three wording sites

**Files:**

- Modify: `scripts/bump-superpowers` (lines 5, 27, 118 wording; `work=` line 81; `tmp=` line 99; `license_tmp=` line 108; `using_superpowers_tmp=` line 121; `tmp=` in `revendor_brainstorming`, line 142; `cleanup`)

**Interfaces:**

- Produces: every `mktemp` in the script guarded with `|| die`, every temporary created beside its destination and freed by `cleanup()`.

- [ ] **Step 1: Reproduce the unguarded shape**

```bash
TMPDIR=/nonexistent bash scripts/bump-superpowers 0000000000000000000000000000000000000000; echo "exit=$?"
```

Expected: `mktemp: failed to create directory via template` followed by an ambiguous-redirect or `git init` error from an empty `$work`, exit 2 from a later `die`; the failure is not named as what it was.

- [ ] **Step 2: Guard and place the five temporaries**

Line 81 becomes `work="$(mktemp -d)" || die "could not create a scratch directory (TMPDIR=${TMPDIR:-/tmp})"`. The cleanup block (lines 82–89) becomes:

```bash
using_superpowers_tmp=""
license_tmp=""
marketplace_tmp=""
skill_tmp=""
cleanup() {
  rm -rf "$work"
  [ -n "$using_superpowers_tmp" ] && rm -f "$using_superpowers_tmp"
  [ -n "$license_tmp" ] && rm -f "$license_tmp"
  [ -n "$marketplace_tmp" ] && rm -f "$marketplace_tmp"
  [ -n "$skill_tmp" ] && rm -f "$skill_tmp"
}
```

Line 99's `tmp="$(mktemp)"` becomes `marketplace_tmp="$(mktemp "$MARKETPLACE.XXXXXX")" || die "could not create a temporary beside $MARKETPLACE"`, and the four lines after it use `$marketplace_tmp` and clear it after the `mv` (`marketplace_tmp=""`), the way `license_tmp` does. Line 108 gains `|| die "could not create a temporary beside the LICENSE"`; line 121 gains `|| die "could not create a temporary beside using-superpowers.md"`. In `revendor_brainstorming`, `tmp` leaves the `local` line, line 142 becomes `skill_tmp="$(mktemp "$dest/SKILL.md.XXXXXX")" || die "could not create a temporary beside $dest/SKILL.md"`, the block writes to `"$skill_tmp"`, and after the `mv` the function sets `skill_tmp=""`. The `[ -n "${1:-}" ] && exit 0 || exit 2` line and its comment stay (#14 records it as correct).

- [ ] **Step 3: The wording the gate commit inherited**

Line 5: `print the additional context for a clone at DIR` becomes `print the using-superpowers text for a clone at DIR`; line 27: `# The one copy of the additional-context recipe.` becomes `# The one copy of the using-superpowers recipe.`; line 118: `# 2. regenerated: the additional context, then the vendored brainstorming tree.` becomes `# 2. regenerated: the using-superpowers text, then the vendored brainstorming tree.` The hook's additional context is both files; these three lines mean one.

- [ ] **Step 4: Prove it, suite, commit**

Re-run Step 1's command. Expected: `ERROR: could not create a scratch directory (TMPDIR=/nonexistent)`, exit 2, nothing else. Then `bash tests/test-hook.sh` (network; `--emit-using-superpowers` is unchanged), `shellcheck -e SC1091 -e SC2016 scripts/bump-superpowers`, `shfmt -d -i 2 -ci -bn scripts/bump-superpowers`, `bash tests/run.sh`. Expected: green, silent, silent, green.

```bash
git add scripts/bump-superpowers
git commit -m "Guard every temporary in the bump script and create each beside its destination" -m "Two mktemp sites wrote in TMPDIR and moved across devices; none checked its status, so a failure surfaced as an ambiguous redirect (#14, names-and-surface spec §13). All five now die by name, and cleanup() frees every one. Three comments say using-superpowers where they had said additional context, which is both hook files." -- scripts/bump-superpowers
```

### Task 3: The apply block, driven by stateful stubs (§13, #17)

**Files:**

- Create: `tests/test-setup-apply.sh`
- Modify: `tests/test-links-resolve.sh` (drop the `tests/test-setup-apply.sh` line)

**Interfaces:**

- Consumes: `bin/setup`'s apply paths in `ensure_claude` (`update` for a subset entry one version behind, `install` for an entry missing from the registry) and `ensure_codex` (`marketplace upgrade eranroseman`, `plugin add`, the second `plugin list --json`).
- Produces: a test that needs no network and no CLI, three fixtures, each asserting its `DID:` line and the re-check's `OK:` line.

- [ ] **Step 1: Write the test**

The file's last assertion, `saw 'NOTE: codex codex-cli 0.147.0'`, depends on Task 4's engine change: write the file without that line now and add it in Task 4. Every stub answers `--version` from the start, so Task 4 needs no stub edit.

```bash
#!/usr/bin/env bash
# The apply block of the Claude half and the whole Codex half, which no
# fixture had driven (#17): a subset entry one version behind moves under
# `claude plugin update`; an entry missing from the registry is installed by
# name; and with codex present, `marketplace upgrade eranroseman`, `plugin
# add` and the second `plugin list --json` run in order. Each CLI is a stub
# that edits the same registry file the engine reads back, so the DID line
# is a re-read and the re-check's OK line is the proof. Needs no network:
# every clone is seeded at a wrong sha with no origin, so the clone check
# fails locally and nothing else reaches out.
. "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/bin/setup"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

sd="$(jq -r .version "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json")"
sm="$(jq -r .version "$REPO_ROOT/plugins/sensemaking/.claude-plugin/plugin.json")"
sp="$(jq -r '.plugins[] | select(.name == "superpowers") | .version' "$MARKETPLACE")"
wcc="$(jq -r '.plugins[] | select(.name == "writing-clearly-and-concisely") | .version' "$MARKETPLACE")"

# A HOME whose clones exist at a sha that cannot be the declared one, with
# every skill directory present so the links have targets, and a lockfile
# pinned at the declared refs so the skills.sh half runs no command.
seed_home() {
  local h="$1" name path skill dir
  mkdir -p "$h/.agents/skills" "$h/.claude/plugins" "$h/.codex" || fail "could not seed $h"
  while IFS="$(printf '\t')" read -r name path skill; do
    [ -n "$name" ] || continue
    dir="$h/.local/share/software-dev/upstream/$name"
    if [ ! -d "$dir/.git" ]; then
      mkdir -p "$dir" || fail "could not seed $dir"
      git -C "$dir" init -q || fail "git init failed in $dir"
      git -C "$dir" -c user.email=t@example.com -c user.name=t \
        commit -q --allow-empty -m seed || fail "could not seed a commit in $dir"
    fi
    mkdir -p "$dir/$path/$skill"
  done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                  | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
  jq '{version: 3,
       skills: (reduce (.sources[] as $s | $s.skills[] |
         {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
       dismissed: {}}' "$REPO_ROOT/skills.json" >"$h/.agents/.skill-lock.json" \
    || fail "could not synthesize a pinned lockfile"
  printf '{"eranroseman":{"source":{"source":"github","repo":"eranroseman/agent-plugins"},"installLocation":"%s"}}\n' "$h/mkt" \
    >"$h/.claude/plugins/known_marketplaces.json" || fail "could not write known_marketplaces.json"
}

# The registry the claude stub edits: $1 the HOME, then name=version pairs.
write_registry() {
  local h="$1" body="" pair
  shift
  for pair in "$@"; do
    body="$body${body:+,}\"${pair%%=*}@eranroseman\":[{\"scope\":\"user\",\"version\":\"${pair#*=}\",\"installPath\":\"$h/.claude/plugins/cache/eranroseman/${pair%%=*}/${pair#*=}\"}]"
  done
  printf '{"version":2,"plugins":{%s}}\n' "$body" >"$h/.claude/plugins/installed_plugins.json" \
    || fail "could not write installed_plugins.json"
}

# A fixture PATH: the engine's own tools, a node that is never reached, an
# npx that must not be (the lockfile is pinned), and the two stubs.
fixture_bin() {
  local b="$1"
  link_tools "$b" bash git jq grep find date readlink basename dirname cut rm mv ln mkdir cat sha256sum
  printf '#!/usr/bin/env bash\nexit 1\n' >"$b/node" || fail "could not write the node stub"
  printf '#!/usr/bin/env bash\nexit 1\n' >"$b/npx" || fail "could not write the npx stub"
  chmod +x "$b/node" "$b/npx" || fail "could not make the stubs executable"
}

# The claude stub: answers --version; `plugin update X@eranroseman` sets X's
# registry version to the declared one; `plugin install X@eranroseman` adds
# X at the declared version. Anything else exits 1 and is a visible FAIL.
write_claude_stub() {
  cat >"$1/claude" <<'STUB' || fail "could not write the claude stub"
#!/usr/bin/env bash
reg="$HOME/.claude/plugins/installed_plugins.json"
declared() {
  case "$1" in
    software-dev | sensemaking) jq -r .version "$REPO/plugins/$1/.claude-plugin/plugin.json" ;;
    *) jq -r --arg n "$1" '.plugins[] | select(.name == $n) | .version' "$REPO/.claude-plugin/marketplace.json" ;;
  esac
}
case "$1 $2" in
  '--version ') printf '2.1.273 (Claude Code)\n' ;;
  'plugin update')
    name="${3%@eranroseman}"
    v="$(declared "$name")"
    jq --arg k "$3" --arg v "$v" '.plugins[$k][0].version = $v' "$reg" >"$reg.new" && mv "$reg.new" "$reg"
    ;;
  'plugin install')
    name="${3%@eranroseman}"
    v="$(declared "$name")"
    jq --arg k "$3" --arg v "$v" --arg p "$HOME/.claude/plugins/cache/eranroseman/$name/$v" \
      '.plugins[$k] = [{scope: "user", version: $v, installPath: $p}]' "$reg" >"$reg.new" && mv "$reg.new" "$reg"
    ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$1/claude" || fail "could not make the claude stub executable"
}

# The codex stub, stateful through $CODEX_HOME/state: `plugin marketplace
# list` names eranroseman, so the engine takes the upgrade branch;
# `marketplace upgrade eranroseman` and `plugin add` each record themselves;
# `plugin list --json` reports 0.0.1 until an add has run, then the declared
# version. Anything else exits 1.
write_codex_stub() {
  cat >"$1/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
state="$CODEX_HOME/state"
mkdir -p "$state"
version_of() {
  if [ -f "$state/added-$1" ]; then
    jq -r .version "$REPO/plugins/$1/.codex-plugin/plugin.json"
  else
    printf '0.0.1'
  fi
}
case "$*" in
  '--version') printf 'codex-cli 0.147.0\n' ;;
  'plugin marketplace list') printf 'MARKETPLACE  ROOT\neranroseman  /nowhere\n' ;;
  'plugin marketplace upgrade eranroseman') : >"$state/upgraded" ;;
  'plugin add software-dev@eranroseman' | 'plugin add sensemaking@eranroseman')
    : >"$state/added-${3%@eranroseman}"
    ;;
  'plugin list --json')
    printf '{"installed":[{"pluginId":"software-dev@eranroseman","marketplaceName":"eranroseman","name":"software-dev","version":"%s","enabled":true},{"pluginId":"sensemaking@eranroseman","marketplaceName":"eranroseman","name":"sensemaking","version":"%s","enabled":true}]}\n' \
      "$(version_of software-dev)" "$(version_of sensemaking)"
    ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$1/codex" || fail "could not make the codex stub executable"
}

run_apply() { # $1 HOME, $2 PATH dir; leaves the output in OUT
  OUT="$(env HOME="$1" CODEX_HOME="$1/.codex" REPO="$REPO_ROOT" PATH="$2" /bin/bash "$SETUP" 2>&1 || true)"
}
saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# 1. A subset entry one version behind: the update branch.
H1="$T/home-1"
seed_home "$H1"
write_registry "$H1" "software-dev=$sd" "sensemaking=$sm" "superpowers=0.0.1" "writing-clearly-and-concisely=$wcc"
B1="$T/bin-1"
fixture_bin "$B1"
write_claude_stub "$B1"
run_apply "$H1" "$B1"
saw "DID:  superpowers@eranroseman is now $sp" || fail "update branch: no DID line for superpowers:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   superpowers@eranroseman $sp installed")" -ge 1 ] \
  || fail "update branch: the re-check did not report superpowers at $sp:"$'\n'"$OUT"
saw 'SKIP: codex is not on PATH' || fail "update branch: the Codex half was not skipped with no codex:"$'\n'"$OUT"

# 2. A subset entry missing from the registry: the install branch.
H2="$T/home-2"
seed_home "$H2"
write_registry "$H2" "software-dev=$sd" "sensemaking=$sm" "superpowers=$sp"
run_apply "$H2" "$B1"
saw 'DID:  installed writing-clearly-and-concisely@eranroseman' || fail "install branch: no DID line:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   writing-clearly-and-concisely@eranroseman $wcc installed")" -ge 1 ] \
  || fail "install branch: the re-check did not report the entry installed:"$'\n'"$OUT"

# 3. Codex present: upgrade, add, and the second list read, in order.
H3="$T/home-3"
seed_home "$H3"
write_registry "$H3" "software-dev=$sd" "sensemaking=$sm" "superpowers=$sp" "writing-clearly-and-concisely=$wcc"
B3="$T/bin-3"
fixture_bin "$B3"
write_claude_stub "$B3"
write_codex_stub "$B3"
run_apply "$H3" "$B3"
[ -f "$H3/.codex/state/upgraded" ] || fail "codex: marketplace upgrade eranroseman never ran:"$'\n'"$OUT"
for p in software-dev sensemaking; do
  [ -f "$H3/.codex/state/added-$p" ] || fail "codex: plugin add did not run for $p:"$'\n'"$OUT"
done
saw "DID:  installed codex plugin software-dev $sd" || fail "codex: no DID line for software-dev:"$'\n'"$OUT"
saw "DID:  installed codex plugin sensemaking $sm" || fail "codex: no DID line for sensemaking:"$'\n'"$OUT"
[ "$(printf '%s\n' "$OUT" | grep -c "OK:   codex plugin software-dev $sd installed")" -ge 1 ] \
  || fail "codex: the re-check did not report software-dev installed:"$'\n'"$OUT"
saw 'NOTE: codex codex-cli 0.147.0' || fail "codex: the CLI version was not reported:"$'\n'"$OUT"

printf 'setup-apply: the update and install branches of the Claude half and the Codex half ran under stateful stubs\n'
```

- [ ] **Step 2: Run it red, then green**

Run: `bash tests/test-setup-apply.sh`
Expected on the tree before Task 1's `CODEX_LIST` guard would matter and with the engine as it stands: green for fixtures 1 and 2 (the branches exist; they were unexercised, not broken). Fixture 3 is the first run of the Codex apply block under a stub: if it is red, the FAIL text names the verb the stub did not expect, and the stub's `case` is what to fix, not the engine, unless the engine calls a verb the spec does not name. Then remove the `'tests/test-setup-apply.sh'` line from `DECLARED_ABSENT` in `tests/test-links-resolve.sh`, stage the test, and run `bash tests/test-links-resolve.sh`: green.

- [ ] **Step 3: Suite and commit**

`shellcheck -e SC1091 -e SC2016 tests/test-setup-apply.sh`, `shfmt -d -i 2 -ci -bn tests/test-setup-apply.sh`, `cspell --no-progress tests/test-setup-apply.sh`, `bash tests/run.sh`. Expected: silent ×3, green with `setup-apply: …` among the PASS rows.

```bash
git add tests/test-setup-apply.sh tests/test-links-resolve.sh
git commit -m "Drive the apply block under stateful claude and codex stubs" -m "The update and install branches of the Claude half and the whole Codex half had no fixture (#17, names-and-surface spec §13). Each stub edits the registry the engine re-reads, so the DID line and the re-check's OK line are the proof; the codex stub expects marketplace upgrade eranroseman, as the README and usage now say." -- tests/test-setup-apply.sh tests/test-links-resolve.sh
```

### Task 4: The doctor's report-only pass (§10: #50, #54, #44, the sensemaking false OK)

**Files:**

- Modify: `bin/setup` (`report_only` lines 676–729; `ensure_claude` lines 466–481; `usage()` lines 163–166), `plugins/software-dev/README.md` (lines 116–119)
- Modify: `tests/test-doctor-faults.sh`, `tests/test-doctor-duplicates.sh`, `tests/test-setup-apply.sh` (the stubs answer `--version`; the apply test's last assertion joins)
- Create: `tests/test-doctor-report.sh`; modify `tests/test-links-resolve.sh` (drop its line)

**Interfaces:**

- Produces, in `report_only`: the archify NOTE in three wordings (`archify's update check is off: …`, `archify's update check is on: …`, `archify's update check is still on: …`); one NOTE per undeclared skills.sh install, `skills.sh install NAME (SOURCE at REF) is not in the skills.sh desired state`, the none line `every skills.sh install in the lockfile is in the skills.sh desired state`, a SKIP with no lockfile, a FAIL on one jq cannot parse; `NOTE: claude <version line>` and `NOTE: codex <version line>`; and in `ensure_claude`, `FAIL: sensemaking version unreadable from plugins/sensemaking/.claude-plugin/plugin.json`.

- [ ] **Step 1: Write the test, red**

```bash
#!/usr/bin/env bash
# The doctor's report-only pass says everything it can see (spec §10). The
# archify update-check variable in its three states, read from the
# environment and from the env map in settings.json, which this script never
# writes (#50); every skills.sh install the desired state does not declare,
# by name, source and ref, with a none line, a SKIP without a lockfile and a
# FAIL on one jq cannot parse (#54); the two CLI versions, so a renamed verb
# shows as a fact change (#44); and a sensemaking manifest whose version
# cannot be read, which once reported OK (#17). Needs no network and no CLI:
# claude and codex are stubs that answer --version and nothing else.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "2.1.273 (Claude Code)\\n"; exit 0; }\nexit 1\n' >"$BIN/claude" \
  || fail "could not write the claude stub"
printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "codex-cli 0.147.0\\n"; exit 0; }\n[ "$*" = "plugin list --json" ] && { printf "{\\"installed\\":[]}\\n"; exit 0; }\nexit 1\n' >"$BIN/codex" \
  || fail "could not write the codex stub"
chmod +x "$BIN/claude" "$BIN/codex" || fail "could not make the stubs executable"

# $1 a HOME (created), $2 extra env assignments for `env`; leaves the output in OUT.
run_doctor() {
  local home="$1"
  shift
  mkdir -p "$home/.agents/skills" || fail "could not create $home"
  # shellcheck disable=SC2086  # the assignments are one word each by construction
  OUT="$(env -u ARCHIFY_UPDATE_CHECK_DISABLED HOME="$home" CODEX_HOME="$home/.codex" PATH="$BIN" "$@" /bin/bash "$DOCTOR" 2>&1 || true)"
}
saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# 1. #50, unset in both places: the check is on, and the README is named.
run_doctor "$T/h1"
saw "NOTE: archify's update check is on: ARCHIFY_UPDATE_CHECK_DISABLED is unset in the environment and in ~/.claude/settings.json; see the plugin README (this script never sets it)" \
  || fail "unset: the archify line is wrong or missing:"$'\n'"$OUT"

# 2. #50, =1 in the environment: off, and which source said so.
run_doctor "$T/h2" ARCHIFY_UPDATE_CHECK_DISABLED=1
saw "NOTE: archify's update check is off: ARCHIFY_UPDATE_CHECK_DISABLED=1 in the environment" \
  || fail "=1 in the environment: the archify line is wrong or missing:"$'\n'"$OUT"

# 3. #50, =true in settings.json's env map: still on, because check-update.mjs
# tests for exactly 1; and the file is not written, hashed before and after.
mkdir -p "$T/h3/.claude" || fail "could not seed h3"
printf '{"env":{"ARCHIFY_UPDATE_CHECK_DISABLED":"true"}}\n' >"$T/h3/.claude/settings.json" || fail "could not write settings.json"
before="$(sha256sum "$T/h3/.claude/settings.json")"
run_doctor "$T/h3"
saw "NOTE: archify's update check is still on: ARCHIFY_UPDATE_CHECK_DISABLED=true in the env map in ~/.claude/settings.json, and check-update.mjs tests for exactly 1" \
  || fail "=true in settings.json: the archify line is wrong or missing:"$'\n'"$OUT"
[ "$(sha256sum "$T/h3/.claude/settings.json")" = "$before" ] || fail "the doctor wrote settings.json"

# 4. #54: two undeclared installs, one of them the vendored scaffolder's
# unadapted twin, beside every declared one.
mkdir -p "$T/h4/.agents" || fail "could not seed h4"
jq '{version: 3,
     skills: ((reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value}))
       + {"tdd": {source: "mattpocock/skills", ref: "v1.2.3"},
          "typesafe-ai": {source: "typesafe-ai/skills"},
          "setup-matt-pocock-skills": {source: "mattpocock/skills", ref: "v1.2.3"}}),
     dismissed: {}}' "$REPO_ROOT/skills.json" >"$T/h4/.agents/.skill-lock.json" \
  || fail "could not synthesize the lockfile"
run_doctor "$T/h4"
saw 'NOTE: skills.sh install tdd (mattpocock/skills at v1.2.3) is not in the skills.sh desired state' \
  || fail "undeclared tdd was not reported with source and ref:"$'\n'"$OUT"
saw 'NOTE: skills.sh install typesafe-ai (typesafe-ai/skills at no ref) is not in the skills.sh desired state' \
  || fail "undeclared typesafe-ai was not reported with its missing ref named:"$'\n'"$OUT"
saw "NOTE: setup-matt-pocock-skills is installed through skills.sh, but this plugin vendors an adapted copy as setup-repository; remove the unadapted one with 'npx skills remove setup-matt-pocock-skills -g'" \
  || fail "the scaffolder's twin lost its remedy:"$'\n'"$OUT"
saw 'every skills.sh install in the lockfile is in the skills.sh desired state' \
  && fail "the none line was printed beside undeclared installs:"$'\n'"$OUT"

# 5. #54: a lockfile that matches the desired state exactly: the none line.
mkdir -p "$T/h5/.agents" || fail "could not seed h5"
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' "$REPO_ROOT/skills.json" >"$T/h5/.agents/.skill-lock.json" \
  || fail "could not synthesize the pinned lockfile"
run_doctor "$T/h5"
saw 'NOTE: every skills.sh install in the lockfile is in the skills.sh desired state' \
  || fail "a lockfile matching the desired state did not print the none line:"$'\n'"$OUT"

# 6. #54: no lockfile is a SKIP; an unparsable one is a FAIL, never the all-clear.
run_doctor "$T/h6"
saw 'SKIP: no skills.sh lockfile at' || fail "no lockfile: not a SKIP:"$'\n'"$OUT"
mkdir -p "$T/h7/.agents" || fail "could not seed h7"
printf '{\n' >"$T/h7/.agents/.skill-lock.json" || fail "could not corrupt the lockfile"
run_doctor "$T/h7"
saw 'FAIL: the lockfile at' || fail "an unparsable lockfile: not a FAIL:"$'\n'"$OUT"
saw 'is in the skills.sh desired state' && fail "an unparsable lockfile printed the none line:"$'\n'"$OUT"

# 7. #44: both CLI versions, as facts.
run_doctor "$T/h8"
saw 'NOTE: claude 2.1.273 (Claude Code)' || fail "the claude version was not reported:"$'\n'"$OUT"
saw 'NOTE: codex codex-cli 0.147.0' || fail "the codex version was not reported:"$'\n'"$OUT"

# 8. #17's false OK: a sensemaking manifest with no readable version is a
# FAIL in the Claude half, not an OK. A scratch checkout, since the manifest
# is the desired state and the doctor reads it beside itself.
scratch_repo() {
  local r="$T/$1"
  mkdir -p "$r/bin" "$r/.claude-plugin" "$r/plugins/sensemaking/.claude-plugin" "$r/plugins/software-dev/.claude-plugin" \
    || fail "could not seed $r"
  ln -s "$REPO_ROOT/bin/setup" "$r/bin/setup" || fail "could not link bin/setup into $r"
  cp "$MARKETPLACE" "$r/.claude-plugin/marketplace.json" || fail "could not copy the marketplace"
  cp "$REPO_ROOT/skills.json" "$r/skills.json" || fail "could not copy skills.json"
  cp "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json" "$r/plugins/software-dev/.claude-plugin/" \
    || fail "could not copy the software-dev manifest"
  printf '%s\n' "$r"
}
for shape in '{' '{"name":"sensemaking","version":""}'; do
  R="$(scratch_repo "sm-$RANDOM")"
  printf '%s\n' "$shape" >"$R/plugins/sensemaking/.claude-plugin/plugin.json" || fail "could not write the manifest"
  mkdir -p "$T/h9/.agents/skills" || fail "could not seed h9"
  OUT="$(env HOME="$T/h9" CODEX_HOME="$T/h9/.codex" PATH="$BIN" /bin/bash "$R/bin/setup" --check 2>&1 || true)"
  saw 'FAIL: sensemaking version unreadable from plugins/sensemaking/.claude-plugin/plugin.json' \
    || fail "manifest $shape: the unreadable version was not a FAIL:"$'\n'"$OUT"
  saw 'OK:   sensemaking@eranroseman' && fail "manifest $shape: the Claude half reported sensemaking OK:"$'\n'"$OUT"
done

printf 'doctor-report: archify variable in three states, undeclared installs named, both CLI versions, unreadable sensemaking version is a FAIL\n'
```

Run: `bash tests/test-doctor-report.sh`
Expected: `FAIL: unset: the archify line is wrong or missing`, exit 1.

- [ ] **Step 2: The engine**

In `report_only`, the `local` line becomes `local v src set_names="" link actual before undeclared line F` (the dead `name` goes). The numbered block comments `# 1.`, `# 2.`, `# 3.`, `# 4.` lose their numbers (`# The telemetry variable.`, `# Auto-update.`, `# Redundant Codex links:`); block 4 is replaced whole by the #54 walk below; and the `reported()` comment at lines 127–130, `report_only prints two NOTE lines before report_duplicates`, becomes `report_only prints NOTE lines before report_duplicates`. After the auto-update block, insert:

```bash
  # The archify update check: its check-update.mjs tests
  # ARCHIFY_UPDATE_CHECK_DISABLED for exactly the value 1, read from the
  # environment and from settings.json's env map. This script never sets it;
  # the plugin README says how to (#50).
  v="${ARCHIFY_UPDATE_CHECK_DISABLED:-}"
  src="the environment"
  if [ -z "$v" ]; then
    v="$(jq -r '.env.ARCHIFY_UPDATE_CHECK_DISABLED // empty' "$HOME/.claude/settings.json" 2>/dev/null)"
    src="the env map in ~/.claude/settings.json"
  fi
  if [ "$v" = 1 ]; then
    note "archify's update check is off: ARCHIFY_UPDATE_CHECK_DISABLED=1 in $src"
  elif [ -z "$v" ]; then
    note "archify's update check is on: ARCHIFY_UPDATE_CHECK_DISABLED is unset in the environment and in ~/.claude/settings.json; see the plugin README (this script never sets it)"
  else
    note "archify's update check is still on: ARCHIFY_UPDATE_CHECK_DISABLED=$v in $src, and check-update.mjs tests for exactly 1"
  fi

  # Every skills.sh install the desired state does not declare (#54): one
  # NOTE each, naming the lockfile's source and ref, worded against the
  # desired state so it stays true once #52 moves names to a subset entry.
  # The vendored scaffolder's unadapted twin keeps its remedy. Reported,
  # never removed; a lockfile jq cannot parse is a FAIL, never the all-clear.
  if [ ! -f "$LOCKFILE" ]; then
    skip "no skills.sh lockfile at $LOCKFILE; nothing to compare the desired state against"
  elif ! undeclared="$(jq -r --slurpfile d "$SKILLS_JSON" \
    '[$d[0].sources[].skills[]] as $want
     | .skills | to_entries[]
     | select(.key as $k | $want | index($k) | not)
     | [.key, (.value.source // "unknown source"), (.value.ref // "no ref")] | @tsv' \
    "$LOCKFILE" 2>/dev/null)"; then
    bad "the lockfile at $LOCKFILE could not be parsed, so undeclared installs are unknown"
  elif [ -z "$undeclared" ]; then
    note "every skills.sh install in the lockfile is in the skills.sh desired state"
  else
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      split_tsv "$line"
      if [ "${F[0]}" = setup-matt-pocock-skills ]; then
        note "setup-matt-pocock-skills is installed through skills.sh, but this plugin vendors an adapted copy as setup-repository; remove the unadapted one with 'npx skills remove setup-matt-pocock-skills -g'"
      else
        note "skills.sh install ${F[0]} (${F[1]} at ${F[2]}) is not in the skills.sh desired state"
      fi
    done <<<"$undeclared"
  fi

  # The two CLIs' versions, as facts: a CLI that renames a verb shows here
  # before it is a runtime failure (#44). Builtins only after the call, so
  # the fixture PATH lists need no head.
  if have claude; then
    v="$(claude --version 2>/dev/null)"
    note "claude ${v%%$'\n'*}"
  fi
  if have codex; then
    v="$(codex --version 2>/dev/null)"
    note "codex ${v%%$'\n'*}"
  fi
```

In `ensure_claude`, the sensemaking block (lines 466–481) becomes:

```bash
  # sensemaking installs itself as a dependency of the first install, but a
  # parent's update does not carry it (sub-project 2's plan, B2), so a copy
  # behind its manifest moves under its own update. `[ -n "$have" ]` first:
  # update fails against a plugin that is not installed, and a missing
  # dependency is the parent install's business. A version the manifest
  # does not carry is a FAIL, never an OK against an empty string (#17).
  want="$(jq -r '.version // empty' "$REPO_ROOT/plugins/sensemaking/.claude-plugin/plugin.json" 2>/dev/null)"
  if [ -n "$want" ]; then
    have="$(installed_version sensemaking)"
    if [ -n "$have" ] && [ "$have" != "$want" ] && applying; then
      claude plugin update sensemaking@eranroseman >/dev/null 2>&1 \
        || bad "claude plugin update sensemaking@eranroseman failed"
      have="$(installed_version sensemaking)"
      [ "$have" = "$want" ] && did "updated sensemaking@eranroseman to $want"
    fi
    if [ "$have" = "$want" ]; then
      ok "sensemaking@eranroseman $want installed"
    else
      bad "sensemaking@eranroseman is ${have:-not installed}, declared $want"
    fi
  else
    bad "sensemaking version unreadable from plugins/sensemaking/.claude-plugin/plugin.json"
  fi
```

The subset loop after it runs either way. In `usage()`, `Two things are deliberately left to you and only reported: the plugin auto-update toggle in /plugin, and the telemetry variable documented in the plugin README.` becomes `The operator decisions are only reported, never made here: the plugin auto-update toggle in /plugin, and the variables the plugin README documents.` (`tests/test-setup-doctor.sh` compares only the fenced blocks, so the README does not change.) In `plugins/software-dev/README.md`, the archify paragraph's closing sentence (it begins `This is a README instruction rather than a mechanism` and ends `reporting the variable's state.`) becomes `` `bin/doctor` reports the variable's state. ``

- [ ] **Step 3: The stubs answer `--version`**

`tests/test-doctor-faults.sh`: the stub at line 129 (`cat >"$BIN2/claude"`) and the loop at line 173 (`for t in claude node npx`) both write scripts that exit 1; each `claude` stub gains a first line `[ "$1" = --version ] && { printf '2.1.273 (Claude Code)\n'; exit 0; }` before `exit 1`. `tests/test-doctor-duplicates.sh`: both `codex` stubs (lines 97 and 118) gain `[ "$1" = --version ] && { printf 'codex-cli 0.147.0\n'; exit 0; }` as their first command. Every fixture PATH list in `tests/test-doctor-silence.sh`, `tests/test-doctor-duplicates.sh`, `tests/test-doctor-faults.sh` and `tests/test-setup-upgrade.sh` loses `sed awk cp` and gains `cut` (`find` and `date` stay; P7), and the silence test's comment `everything the engine runs in check mode` stays true. `rm` belongs only on a list that feeds an apply run (the faults test's two, the upgrade test's, Task 3's `fixture_bin`); no silence or duplicates fixture applies, so those lists do not gain it. Task 3's last assertion, `saw 'NOTE: codex codex-cli 0.147.0'`, joins `tests/test-setup-apply.sh` now.

- [ ] **Step 4: Green, the declared line, suite, commit**

Run `bash tests/test-doctor-report.sh`: `doctor-report: archify variable in three states, …`. Remove `'tests/test-doctor-report.sh'` from `DECLARED_ABSENT`, stage the test, `bash tests/test-links-resolve.sh` green. Then `bash tests/test-doctor-faults.sh`, `bash tests/test-doctor-duplicates.sh`, `bash tests/test-doctor-silence.sh`, `bash tests/test-setup-doctor.sh`, `bash tests/test-setup-apply.sh`, `bash tests/test-vocabulary.sh`, `shellcheck -e SC1091 -e SC2016 bin/setup tests/test-doctor-report.sh`, `shfmt -d -i 2 -ci -bn bin/setup tests/test-*.sh`, `cspell --no-progress tests/test-doctor-report.sh bin/setup`, `prettier --check plugins/software-dev/README.md`, `bash tests/run.sh`. Expected: all green and silent.

```bash
git add bin/setup plugins/software-dev/README.md tests/test-doctor-report.sh tests/test-doctor-faults.sh tests/test-doctor-duplicates.sh tests/test-doctor-silence.sh tests/test-setup-upgrade.sh tests/test-setup-apply.sh tests/test-links-resolve.sh
git commit -m "Report archify's variable, undeclared skills.sh installs and both CLI versions; fail an unreadable sensemaking version" -m "The doctor reports the operator decisions it never makes (#50), every lockfile entry outside the desired state with its source and ref (#54), and the two CLI versions as facts (#44), and the sensemaking block no longer reports OK against an empty version (#17), names-and-surface spec §10. The fixture PATH lists carry what the engine calls (#61 M14), and every stub answers --version." -- bin/setup plugins/software-dev/README.md tests/test-doctor-report.sh tests/test-doctor-faults.sh tests/test-doctor-duplicates.sh tests/test-doctor-silence.sh tests/test-setup-upgrade.sh tests/test-setup-apply.sh tests/test-links-resolve.sh
```

### Task 5: The cache walk: delete Claude's orphaned caches under four guards, report Codex's (§11, #25, #64)

**Files:**

- Modify: `bin/setup` (a new `ensure_cache()` after `report_duplicates`; `report_duplicates`'s header comment and its residue block, lines 810–819; `main`)
- Modify: `tests/test-doctor-duplicates.sh` (lines 51–52, 69–72), `tests/test-doctor-faults.sh` and `tests/test-setup-apply.sh` (`rm` on the apply PATH lists)
- Create: `tests/test-doctor-cache.sh`; modify `tests/test-links-resolve.sh` (drop its line)

**Interfaces:**

- Produces: `ensure_cache`, called from `main` after `ensure_codex` in its own bracket. Claude half: in check mode `FAIL: cache for an unregistered marketplace: PATH (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it` or the same with `scratch clone from a git-subdir install`; in apply mode `DID:  deleted cache for an unregistered marketplace: PATH`; a directory failing a guard, `NOTE: left alone: PATH (GUARD)`; an unreadable registry, one SKIP and nothing deleted; always a closing `OK:   N Claude plugin cache director(ies) walked, M registered`. Codex half (P1, P2): `NOTE: Codex plugin cache for a marketplace config.toml does not record: PATH (left alone; remove it by hand)`.

- [ ] **Step 1: Write the test, red**

```bash
#!/usr/bin/env bash
# The one class of residue the engine can prove and repair (spec §11, #25):
# a Claude plugin cache directory that known_marketplaces.json does not
# name, that no installed plugin's installPath lies under, and that has not
# been modified for an hour. Check mode names it as a FAIL with the four
# facts; apply mode deletes it and says so; a directory failing any guard is
# left alone and named with the guard; a registry jq cannot parse skips the
# whole walk and nothing is deleted; the CLI's temp_subdir_*.clone scratch
# directories are the same class under their own name. The Codex half only
# reports (plan B, P1). Needs no network; the clones are seeded at a wrong
# sha with no origin, and claude, node and npx are stubs.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
SETUP="$REPO_ROOT/bin/setup"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut rm mv ln mkdir cat sha256sum
for t in claude node npx; do
  printf '#!/usr/bin/env bash\n[ "$1" = --version ] && { printf "2.1.273 (Claude Code)\\n"; exit 0; }\nexit 1\n' >"$BIN/$t" \
    || fail "could not write the $t stub"
  chmod +x "$BIN/$t" || fail "could not make the $t stub executable"
done

skill() { mkdir -p "$1" && printf -- '---\nname: %s\n---\n%s\n' "$(basename "$1")" "$2" >"$1/SKILL.md"; }

# A HOME with a registered marketplace `mkt`, an installed plugin under it,
# and five other cache directories, one per verdict.
seed() {
  local h="$1" cache="$1/.claude/plugins/cache"
  mkdir -p "$h/.agents/skills" "$cache" || fail "could not seed $h"
  skill "$cache/mkt/plug/1.0.0/skills/alpha" "alpha"
  skill "$cache/held/plug/1.0.0/skills/beta" "beta"
  mkdir -p "$cache/gone/old/1.0.0/skills/zeta" "$cache/fresh/x" "$cache/temp_subdir_1789739987658_kwt7rv.clone/skills" \
    || fail "could not seed the cache"
  cat >"$h/.claude/plugins/installed_plugins.json" <<JSON || fail "could not write installed_plugins.json"
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"1.0.0","installPath":"$cache/mkt/plug/1.0.0"}],
  "plug@held":[{"scope":"user","version":"1.0.0","installPath":"$cache/held/plug/1.0.0"}]}}
JSON
  printf '{"mkt":{"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}\n' \
    >"$h/.claude/plugins/known_marketplaces.json" || fail "could not write known_marketplaces.json"
  # gone, held and the scratch clone are old; fresh was modified just now.
  touch -d '2 hours ago' "$cache/gone" "$cache/held" "$cache/temp_subdir_1789739987658_kwt7rv.clone" \
    || fail "could not age the directories"
}

saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# 1. Check mode: the two deletable directories are FAILs naming the facts,
# the two guarded ones are NOTEs naming the guard, the registered one is silent.
H="$T/h1"
seed "$H"
OUT="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "FAIL: cache for an unregistered marketplace: $H/.claude/plugins/cache/gone (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it" \
  || fail "check mode: the orphaned cache was not a FAIL with the four facts:"$'\n'"$OUT"
saw "FAIL: scratch clone from a git-subdir install: $H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it" \
  || fail "check mode: the scratch clone was not named as such:"$'\n'"$OUT"
saw "NOTE: left alone: $H/.claude/plugins/cache/held (an installed plugin's installPath lies under it)" \
  || fail "check mode: the directory holding an installed plugin was not left alone by name:"$'\n'"$OUT"
saw "NOTE: left alone: $H/.claude/plugins/cache/fresh (modified less than an hour ago)" \
  || fail "check mode: the fresh directory was not left alone by name:"$'\n'"$OUT"
saw "$H/.claude/plugins/cache/mkt" && fail "check mode: the registered marketplace's cache was reported:"$'\n'"$OUT"
saw 'OK:   5 Claude plugin cache director(ies) walked, 1 registered' \
  || fail "check mode: the walk's summary line is wrong or missing:"$'\n'"$OUT"

# 2. Apply mode deletes exactly the two, says so, and the re-check is clean
# of them. The clones are seeded so nothing reaches the network.
UPSTREAM="$H/.local/share/software-dev/upstream"
while IFS="$(printf '\t')" read -r name path skill; do
  [ -n "$name" ] || continue
  dir="$UPSTREAM/$name"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$dir" || fail "could not seed $dir"
    git -C "$dir" init -q || fail "git init failed in $dir"
    git -C "$dir" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m seed \
      || fail "could not seed a commit in $dir"
  fi
  mkdir -p "$dir/$path/$skill"
done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
jq '{version: 3,
     skills: (reduce (.sources[] as $s | $s.skills[] |
       {key: ., value: {source: $s.repo, ref: $s.ref}}) as $e ({}; . + {($e.key): $e.value})),
     dismissed: {}}' "$REPO_ROOT/skills.json" >"$H/.agents/.skill-lock.json" \
  || fail "could not synthesize a pinned lockfile"
OUT="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$SETUP" 2>&1 || true)"
saw "DID:  deleted cache for an unregistered marketplace: $H/.claude/plugins/cache/gone" \
  || fail "apply: the orphaned cache's deletion was not reported:"$'\n'"$OUT"
saw "DID:  deleted scratch clone from a git-subdir install: $H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone" \
  || fail "apply: the scratch clone's deletion was not reported:"$'\n'"$OUT"
[ ! -e "$H/.claude/plugins/cache/gone" ] || fail "apply: the orphaned cache survived"
[ ! -e "$H/.claude/plugins/cache/temp_subdir_1789739987658_kwt7rv.clone" ] || fail "apply: the scratch clone survived"
for keep in mkt held fresh; do
  [ -d "$H/.claude/plugins/cache/$keep" ] || fail "apply: $keep was deleted"
done
[ "$(printf '%s\n' "$OUT" | grep -c 'OK:   3 Claude plugin cache director(ies) walked, 1 registered')" -ge 1 ] \
  || fail "apply: the re-check did not walk three directories:"$'\n'"$OUT"

# 3. An unreadable registry, either one: the whole walk is one SKIP and
# nothing is deleted, even a directory that would pass every guard.
for reg in known_marketplaces.json installed_plugins.json; do
  H2="$T/h-$reg"
  seed "$H2"
  printf '{\n' >"$H2/.claude/plugins/$reg" || fail "could not corrupt $reg"
  OUT="$(env HOME="$H2" CODEX_HOME="$H2/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
  saw "SKIP: $H2/.claude/plugins/$reg does not parse" || fail "$reg unreadable: the walk was not skipped by name:"$'\n'"$OUT"
  saw 'FAIL: cache for an unregistered' && fail "$reg unreadable: a directory was still judged:"$'\n'"$OUT"
done

# 4. No cache directory at all still reports, so the bracket holds.
mkdir -p "$T/h3/.agents/skills" || fail "could not seed h3"
OUT="$(env HOME="$T/h3" CODEX_HOME="$T/h3/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw 'OK:   no Claude plugin cache at' || fail "no cache: the walk did not report:"$'\n'"$OUT"

# 5. The Codex half reports and never deletes: a directory config.toml does
# not record and no installed plugin sits under is a NOTE; the recorded one
# and the one holding an installed plugin are silent; the two stay on disk.
H4="$T/h4"
mkdir -p "$H4/.agents/skills" "$H4/.codex/plugins/cache/reg/a" "$H4/.codex/plugins/cache/orphan" "$H4/.codex/plugins/cache/inst" \
  || fail "could not seed h4"
skill "$H4/.codex/plugins/cache/inst/theta/1.0.0/skills/gamma" "gamma"
printf '[marketplaces.reg]\nsource = "x"\n' >"$H4/.codex/config.toml" || fail "could not write config.toml"
cat >"$BIN/codex" <<'STUB' || fail "could not write the codex stub"
#!/usr/bin/env bash
[ "$1" = --version ] && { printf 'codex-cli 0.147.0\n'; exit 0; }
[ "$*" = "plugin list --json" ] || exit 1
printf '{"installed":[{"pluginId":"theta@inst","marketplaceName":"inst","name":"theta","version":"1.0.0","enabled":true}]}\n'
STUB
chmod +x "$BIN/codex" || fail "could not make the codex stub executable"
OUT="$(env HOME="$H4" CODEX_HOME="$H4/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "NOTE: Codex plugin cache for a marketplace config.toml does not record: $H4/.codex/plugins/cache/orphan (left alone; remove it by hand)" \
  || fail "codex: the unrecorded cache was not reported:"$'\n'"$OUT"
saw "$H4/.codex/plugins/cache/reg" && fail "codex: the recorded marketplace's cache was reported:"$'\n'"$OUT"
saw "$H4/.codex/plugins/cache/inst" && fail "codex: the cache holding an installed plugin was reported:"$'\n'"$OUT"
rm -f "$BIN/codex"

printf 'doctor-cache: two deletable directories named and deleted, two guarded ones left alone by name, unreadable registries skip the walk, Codex reported only\n'
```

Run: `bash tests/test-doctor-cache.sh`
Expected: `FAIL: check mode: the orphaned cache was not a FAIL with the four facts`, exit 1.

- [ ] **Step 2: The engine**

In `report_duplicates`, delete the residue block (lines 810–819, from `# A Claude plugin cache whose marketplace is not registered` through its `fi`) and, in the header comment, `and report a Claude plugin cache whose marketplace is no longer registered as its own finding rather than filtering it away.` becomes `a cache whose marketplace is no longer registered is ensure_cache's, below.`, and `Reported, never repaired.` goes. After `report_pool`, add:

```bash
# The one class of residue this script can prove (spec §11, #25): a Claude
# plugin cache directory whose marketplace known_marketplaces.json no longer
# names, or one of the CLI's temp_subdir_*.clone scratch clones from a
# git-subdir install, is deleted in apply mode when four facts hold, each
# read from a registry or from the directory itself: the registry parses as
# a JSON object; the directory's name is absent from its keys; the install
# registry parses as an object whose .plugins is an object, and no
# installPath in it lies under the directory; and the directory's own mtime
# is over an hour old. A registry that fails to parse skips the whole walk
# and nothing is deleted. Deleted, not moved aside: aside_path() is for what
# a user made and might want back; a cache the CLI regenerates from a
# marketplace that no longer exists is not, and a pile of aside copies would
# keep the disk cost and add something the walk must skip. The Codex half
# only reports (plan B, P1): Codex's own built-in marketplaces are in no file
# and no list, so residue there cannot be told from the CLI's own cache; a
# directory that neither config.toml's [marketplaces.*] tables nor an
# installed plugin accounts for is named and left alone.
ensure_cache() {
  local root="$HOME/.claude/plugins/cache" dir name what why keys paths p n=0 registered=0
  local croot="${CODEX_HOME:-$HOME/.codex}/plugins/cache" cfg="${CODEX_HOME:-$HOME/.codex}/config.toml" cnames="" cpaths="" line F
  needs jq "the plugin registries cannot be read, so no cache directory is judged" || return
  if [ ! -d "$root" ]; then
    ok "no Claude plugin cache at $root"
  elif ! keys="$(jq -r 'if type == "object" then keys[] else error("not an object") end' "$KNOWN_MARKETPLACES" 2>/dev/null)"; then
    skip "$KNOWN_MARKETPLACES does not parse as a JSON object, so no cache directory is judged and none is deleted"
  elif ! paths="$(jq -r 'if type == "object" and (.plugins | type) == "object" then .plugins[][]?.installPath // empty else error("not an object") end' "$INSTALLED_PLUGINS" 2>/dev/null)"; then
    skip "$INSTALLED_PLUGINS does not parse as a JSON object with a plugins object, so no cache directory is judged and none is deleted"
  else
    for dir in "$root"/*/; do
      [ -d "$dir" ] || continue
      dir="${dir%/}"
      name="${dir##*/}"
      n=$((n + 1))
      if grep -qxF -- "$name" <<<"$keys"; then
        registered=$((registered + 1))
        continue
      fi
      case "$name" in
        temp_subdir_*.clone) what="scratch clone from a git-subdir install" ;;
        *) what="cache for an unregistered marketplace" ;;
      esac
      why=""
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        case "$p" in "$dir" | "$dir"/*) why="an installed plugin's installPath lies under it" ;; esac
      done <<<"$paths"
      if [ -z "$why" ] && [ -z "$(find "$dir" -maxdepth 0 -mmin +60)" ]; then
        why="modified less than an hour ago"
      fi
      if [ -n "$why" ]; then
        note "left alone: $dir ($why)"
      elif applying; then
        if rm -rf -- "$dir"; then
          did "deleted $what: $dir"
        else
          bad "could not delete $what: $dir"
        fi
      else
        bad "$what: $dir (not in known_marketplaces.json, no installed plugin under it, unmodified for over an hour); bin/setup deletes it"
      fi
    done
    ok "$n Claude plugin cache director(ies) walked, $registered registered"
  fi

  [ -d "$croot" ] || return
  if ! have codex; then
    return
  elif [ -z "$CODEX_LIST" ]; then
    skip "codex plugin list failed earlier, so the Codex plugin cache is not judged"
    return
  fi
  while IFS= read -r line; do
    case "$line" in
      '[marketplaces.'*']')
        line="${line:14}" # past the 14 characters of [marketplaces.
        cnames="$cnames ${line%]}"
        ;;
    esac
  done <"$cfg" 2>/dev/null
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    split_tsv "$line"
    cpaths="$cpaths"$'\n'"$croot/${F[0]}/${F[1]}/${F[2]}"
  done < <(printf '%s' "$CODEX_LIST" | jq -r '.installed[]? | [.marketplaceName, .name, .version] | @tsv')
  for dir in "$croot"/*/; do
    [ -d "$dir" ] || continue
    dir="${dir%/}"
    name="${dir##*/}"
    case " $cnames " in *" $name "*) continue ;; esac
    why=""
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$p" in "$dir" | "$dir"/*) why=under ;; esac
    done <<<"$cpaths"
    [ -n "$why" ] || note "Codex plugin cache for a marketplace config.toml does not record: $dir (left alone; remove it by hand)"
  done
}
```

Note `done <"$cfg" 2>/dev/null` reads a missing `config.toml` as no names. In `main`, after `reported "$before" ensure_codex`, add the bracket:

```bash
  before=$REPORTED
  ensure_cache
  reported "$before" ensure_cache
```

- [ ] **Step 3: The duplicates test repins**

`tests/test-doctor-duplicates.sh` lines 51–52 seed `cache/gone` young; the two assertions at lines 69–72 become:

```bash
touch -d '2 hours ago' "$H/.claude/plugins/cache/gone" || fail "could not age the residue"
```

placed after the `mkdir -p` at line 52, and

```bash
printf '%s\n' "$out" | grep -q "FAIL: cache for an unregistered marketplace: $H/.claude/plugins/cache/gone (not in known_marketplaces.json" \
  || fail "the doctor did not report the unregistered cache as ensure_cache's FAIL:"$'\n'"$out"
printf '%s\n' "$out" | grep -q "unregistered marketplace: $H/.claude/plugins/cache/mkt" \
  && fail "the doctor reported a registered marketplace's cache as unregistered"
```

in place of lines 69–72; its header comment's `and a Claude plugin cache whose marketplace is not registered` becomes `and, through ensure_cache, a Claude plugin cache whose marketplace is not registered`. `tests/test-doctor-faults.sh`'s apply-run PATH lists (lines 120 and 165) and `tests/test-setup-apply.sh`'s `fixture_bin` already carry `rm`; confirm with `grep -n 'link_tools' tests/test-doctor-faults.sh tests/test-setup-apply.sh`, and add `rm` where a list feeds an apply run without it.

- [ ] **Step 4: Green, the declared line, suite, commit**

Run `bash tests/test-doctor-cache.sh`: green. Remove `'tests/test-doctor-cache.sh'` from `DECLARED_ABSENT`, stage the test, `bash tests/test-links-resolve.sh` green. Then `bash tests/test-doctor-duplicates.sh`, `bash tests/test-doctor-faults.sh`, `bash tests/test-doctor-silence.sh`, `bash tests/test-setup-apply.sh`, `bash tests/test-vocabulary.sh`, `shellcheck -e SC1091 -e SC2016 bin/setup tests/test-doctor-cache.sh`, `shfmt -d -i 2 -ci -bn bin/setup tests/test-doctor-cache.sh tests/test-doctor-duplicates.sh`, `cspell --no-progress bin/setup tests/test-doctor-cache.sh`, `bash tests/run.sh`. Expected: all green and silent. On this machine, `bash bin/doctor` now prints four `FAIL: scratch clone from a git-subdir install: …` lines for the four `temp_subdir_*.clone` directories, which is the report doing its job; `bin/setup` would delete them, and that is the maintainer's decision, not this task's.

```bash
git add bin/setup tests/test-doctor-cache.sh tests/test-doctor-duplicates.sh tests/test-doctor-faults.sh tests/test-setup-apply.sh tests/test-links-resolve.sh
git commit -m "Delete an orphaned Claude plugin cache under four positive guards; report Codex's" -m "A cache whose marketplace known_marketplaces.json no longer names, that no installed plugin sits under and that has not changed for an hour is deleted in apply mode and a FAIL until then; a directory failing a guard is left alone by name; an unreadable registry skips the walk (names-and-surface spec §11, #25). Deleted rather than moved aside, because aside_path is for what a user made. The Codex half reports and never deletes: its own curated marketplaces are in no file and no list, so residue there cannot be told from the CLI's cache (plan B, P1 and P2). #64 is declined on the launcher's retention, three versions here." -- bin/setup tests/test-doctor-cache.sh tests/test-doctor-duplicates.sh tests/test-doctor-faults.sh tests/test-setup-apply.sh tests/test-links-resolve.sh
```

### Task 6: The watch's freshness, read over the public API (§12, #24)

**Files:**

- Modify: `bin/setup` (a new `ensure_watch_fresh()` after `ensure_fresh_clone`; `main`), `.github/workflows/validate.yml` (the `setup-e2e` job), `tests/test-doctor-faults.sh` (line 70), `tests/test-setup-doctor.sh` (lines 65, 70, 87, 99)
- Create: `tests/test-doctor-freshness.sh`; modify `tests/test-links-resolve.sh` (drop its line)

**Interfaces:**

- Produces: `ensure_watch_fresh`, called from `main` between `ensure_fresh_clone` and `ensure_clones`: `OK:   the watch ran on schedule N hour(s) ago and succeeded`; `FAIL: the watch's last scheduled run was N hours ago, over 48; see URL`, `FAIL: no completed scheduled run of the watch is on record; see URL`, `FAIL: the watch's last scheduled run concluded CONCLUSION, not success; see URL`; plain `skip` when `curl` is absent, the response is not 200, or the body does not parse. The request carries `Authorization: Bearer $GITHUB_TOKEN` whenever that variable is set.

- [ ] **Step 1: Write the test, red**

```bash
#!/usr/bin/env bash
# The doctor reads the upstream watch's run history over the public API and
# says whether the watch is alive (spec §12, #24): OK under 48 hours with a
# successful conclusion; FAIL at 48 hours or more, on an empty run list, or
# on any other conclusion; SKIP, never a need, when curl is absent, the
# response is not 200, or the body does not parse, so the exit code is
# untouched. Needs no network: curl is a stub that answers from two
# variables, and it records its arguments so the token header can be
# asserted.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT

BIN="$T/bin"
link_tools "$BIN" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum
# The stub honours the one call shape the engine makes, `-w '\n%{http_code}'`
# last: it prints $CURL_BODY, a newline, then $CURL_CODE, and logs its
# arguments.
cat >"$BIN/curl" <<'STUB' || fail "could not write the curl stub"
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_LOG"
printf '%s\n%s' "$CURL_BODY" "$CURL_CODE"
STUB
chmod +x "$BIN/curl" || fail "could not make the curl stub executable"
NOCURL="$T/bin-nocurl"
link_tools "$NOCURL" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum

runs_url='https://github.com/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml'
body() { # $1 created_at, $2 conclusion; an empty $1 is an empty list
  if [ -z "$1" ]; then
    printf '{"total_count":0,"workflow_runs":[]}'
  else
    printf '{"total_count":1,"workflow_runs":[{"created_at":"%s","conclusion":"%s"}]}' "$1" "$2"
  fi
}
# $1 body, $2 code, then env assignments; leaves the output in OUT.
run_doctor() {
  local b="$1" c="$2" h="$T/home-$RANDOM"
  shift 2
  mkdir -p "$h/.agents/skills" || fail "could not seed $h"
  OUT="$(env -u GITHUB_TOKEN HOME="$h" CODEX_HOME="$h/.codex" PATH="$BIN" CURL_BODY="$b" CURL_CODE="$c" CURL_LOG="$T/curl.log" "$@" /bin/bash "$DOCTOR" 2>&1 || true)"
}
saw() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

fresh="$(date -u -d '5 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
stale="$(date -u -d '3 days ago' +%Y-%m-%dT%H:%M:%SZ)"

# 1. Fresh and successful: OK, with the age.
run_doctor "$(body "$fresh" success)" 200
saw 'OK:   the watch ran on schedule 5 hour(s) ago and succeeded' || fail "fresh: not OK with the age:"$'\n'"$OUT"

# 2. Stale: FAIL naming the age and the workflow page.
run_doctor "$(body "$stale" success)" 200
saw "FAIL: the watch's last scheduled run was 72 hours ago, over 48; see $runs_url" || fail "stale: not a FAIL:"$'\n'"$OUT"

# 3. An empty run list, and a failed conclusion: FAIL each.
run_doctor "$(body '' '')" 200
saw "FAIL: no completed scheduled run of the watch is on record; see $runs_url" || fail "empty list: not a FAIL:"$'\n'"$OUT"
run_doctor "$(body "$fresh" failure)" 200
saw "FAIL: the watch's last scheduled run concluded failure, not success; see $runs_url" || fail "failure: not a FAIL:"$'\n'"$OUT"

# 4. Not 200, a body that does not parse, and no curl at all: SKIP, and the
# verdict does not count them as unanswered.
run_doctor '{"message":"rate limited"}' 403
saw 'SKIP: the runs API answered 403, not 200; the watch'"'"'s freshness is unanswered' || fail "403: not a SKIP:"$'\n'"$OUT"
run_doctor 'not json' 200
saw "SKIP: the runs API's body did not parse; the watch's freshness is unanswered" || fail "bad body: not a SKIP:"$'\n'"$OUT"
saw 'for want of:.*curl' && fail "curl was counted as a need:"$'\n'"$OUT"
h="$T/home-nocurl"
mkdir -p "$h/.agents/skills" || fail "could not seed $h"
OUT="$(env HOME="$h" CODEX_HOME="$h/.codex" PATH="$NOCURL" /bin/bash "$DOCTOR" 2>&1 || true)"
saw "SKIP: curl is not on PATH, so the watch's run history is unread" || fail "no curl: not a SKIP:"$'\n'"$OUT"
printf '%s\n' "$OUT" | grep -q 'for want of:.*curl' && fail "no curl: counted as a need, which it is not:"$'\n'"$OUT"

# 5. The token travels as a bearer header when set, and not otherwise.
: >"$T/curl.log"
run_doctor "$(body "$fresh" success)" 200 GITHUB_TOKEN=t0k3n
grep -q -- '-H Authorization: Bearer t0k3n' "$T/curl.log" || fail "the token was not sent as a bearer header: $(cat "$T/curl.log")"
: >"$T/curl.log"
run_doctor "$(body "$fresh" success)" 200
grep -q 'Authorization' "$T/curl.log" && fail "an Authorization header was sent with no token: $(cat "$T/curl.log")"

printf 'doctor-freshness: OK under 48 hours, FAIL on stale, empty or failed, SKIP without curl or a 200 body; the token is a bearer header\n'
```

Run: `bash tests/test-doctor-freshness.sh`
Expected: `FAIL: fresh: not OK with the age`, exit 1.

- [ ] **Step 2: The engine**

After `ensure_fresh_clone` in `bin/setup`, add:

```bash
# Is the watch alive? An empty upstream-drift list means "no drift" or
# "nothing checked", and only the run history tells them apart (spec §12,
# #24). One request to the public runs API; curl is optional the way the
# Codex half is, so its absence is a plain skip and never a need, and so is
# a response that is not 200 or does not parse. A bearer token travels when
# GITHUB_TOKEN is set, which CI does, because unauthenticated requests from
# a shared runner address are rate-limited. 48 hours, because scheduled runs
# land 4.5 to 6.5 hours after the 06:17 UTC slot and one missed slot is weak
# evidence. FAIL rather than NOTE: a machine converging to pins nobody is
# watching is a fact about that machine.
ensure_watch_fresh() {
  local url='https://api.github.com/repos/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml/runs?event=schedule&status=completed&per_page=1'
  local page='https://github.com/eranroseman/agent-plugins/actions/workflows/upstream-watch.yml'
  local out code body created conclusion now ts age
  local -a auth=()
  if ! have curl; then
    skip "curl is not on PATH, so the watch's run history is unread"
    return
  fi
  needs jq "the watch's run history cannot be parsed" || return
  [ -z "${GITHUB_TOKEN:-}" ] || auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  if ! out="$(curl -sS "${auth[@]}" -H 'Accept: application/vnd.github+json' -w '\n%{http_code}' "$url" 2>/dev/null)"; then
    skip "could not reach the runs API; the watch's freshness is unanswered"
    return
  fi
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  if [ "$code" != 200 ]; then
    skip "the runs API answered $code, not 200; the watch's freshness is unanswered"
    return
  fi
  if ! created="$(printf '%s' "$body" | jq -r '.workflow_runs[0].created_at // empty' 2>/dev/null)"; then
    skip "the runs API's body did not parse; the watch's freshness is unanswered"
    return
  fi
  if [ -z "$created" ]; then
    bad "no completed scheduled run of the watch is on record; see $page"
    return
  fi
  conclusion="$(printf '%s' "$body" | jq -r '.workflow_runs[0].conclusion // "none"')"
  now="$(date -u +%s)"
  ts="$(date -u -d "$created" +%s 2>/dev/null)" || {
    skip "the runs API's created_at did not parse: $created"
    return
  }
  age=$(((now - ts) / 3600))
  if [ "$age" -ge 48 ]; then
    bad "the watch's last scheduled run was $age hours ago, over 48; see $page"
  elif [ "$conclusion" != success ]; then
    bad "the watch's last scheduled run concluded $conclusion, not success; see $page"
  else
    ok "the watch ran on schedule $age hour(s) ago and succeeded"
  fi
}
```

In `main`, after `reported "$before" ensure_fresh_clone`:

```bash
  before=$REPORTED
  ensure_watch_fresh
  reported "$before" ensure_watch_fresh
```

- [ ] **Step 3: CI, and the two tests that ran the doctor on the real PATH**

In `.github/workflows/validate.yml`, the `setup-e2e` job gains, between `runs-on: ubuntu-latest` and `steps:`:

```yaml
    # The doctor's freshness check reads the watch's run history; the token
    # keeps the shared runner address off the unauthenticated rate limit
    # (spec §12). Read-only, and a red doctor is the second place the
    # watch's silence shows.
    permissions:
      contents: read
      actions: read
    env:
      GITHUB_TOKEN: ${{ github.token }}
```

`tests/test-doctor-faults.sh` line 70 and `tests/test-setup-doctor.sh` lines 65, 87 and 99 run the doctor with the inherited PATH and would now make a request wherever `curl` is present. Each such run gets a PATH without `curl`: in the faults test, move the `BIN="$H/bin"` fixture directory and its `link_tools` line (lines 164–166) above line 70 and run that doctor with `PATH="$BIN"`; in the setup-doctor test, build `NOCURL="$H/nocurl"` with `link_tools "$NOCURL" bash git jq grep find date readlink basename dirname cut mv ln mkdir cat sha256sum` plus `claude` and `codex` when `command -v` finds them, and run those three invocations with `PATH="$NOCURL"` (line 70's own `PATH="/usr/bin:/bin"` run keeps its purpose: it is the branch that reports the CLIs absent; add `curl` to nothing there, and accept its SKIP line). Both tests' headers keep saying they need no network, and now it is true.

- [ ] **Step 4: Green, the declared line, suite, commit**

Run `bash tests/test-doctor-freshness.sh`: green. Remove `'tests/test-doctor-freshness.sh'` from `DECLARED_ABSENT`, stage, `bash tests/test-links-resolve.sh` green. `actionlint .github/workflows/validate.yml`, `bash tests/test-workflows.sh`, `bash tests/test-doctor-faults.sh`, `bash tests/test-setup-doctor.sh`, `bash tests/test-doctor-silence.sh` (its PATH lists have no `curl`: each fixture prints the SKIP and stays clean of a need), `shellcheck -e SC1091 -e SC2016 bin/setup tests/test-doctor-freshness.sh`, `shfmt -d -i 2 -ci -bn bin/setup tests/test-doctor-freshness.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh`, `bash tests/run.sh`. Expected: green and silent throughout. Then, once on this machine, `bash bin/doctor | grep watch`: `OK:   the watch ran on schedule N hour(s) ago and succeeded`, N under 48, the live API answering as measured.

```bash
git add bin/setup .github/workflows/validate.yml tests/test-doctor-freshness.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh tests/test-links-resolve.sh
git commit -m "Read the watch's run history in the doctor: OK under 48 hours, FAIL otherwise, SKIP without curl" -m "An empty drift list could mean nothing checked; the run history says (names-and-surface spec §12, #24). curl is optional and its absence a plain skip; CI's end-to-end job passes its token so the shared runner address is not rate-limited, and a stale watch turns that job red on purpose. The two tests that ran the doctor on the real PATH now run it without curl, so they still need no network." -- bin/setup .github/workflows/validate.yml tests/test-doctor-freshness.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh tests/test-links-resolve.sh
```

### Task 7: `vendored.json`, the watch's third section, and the loud tag lookup (§14: #56, #13 part 2)

**Files:**

- Create: `vendored.json`
- Modify: `tests/lib.sh` (`vendored_sha`, beside `upstream_sha`), `tests/test-vendored-adhd.sh` (lines 13–17 and the LICENSE assertion), `tests/test-vendored-duplicates.sh` (lines 13–15 and the PROVENANCE and LICENSE assertions), `scripts/upstream-watch` (line 14 area, lines 71–74, a new section after section 1), `README.md` (the Layout fence), `CONTEXT.md` (line 67)

**Interfaces:**

- Produces: `vendored.json`, an object keyed by local tree path, each value `{repo, branch, sha, upstream_path, kind}`; `vendored_sha <local-tree>` in `tests/lib.sh`, printing the 40-character sha or failing; the watch's section `### vendored and forked trees`; `bin/setup` never reads the file: `main`'s two `die` guards on the desired-state files stay two, and the silence test's `scratch_repo` copies two.

- [ ] **Step 1: The record**

Create `vendored.json`:

```json
{
  "$comment": "The vendored and forked trees, each pinned to an upstream commit (CONTEXT.md defines the two kinds by which way edits flow). scripts/upstream-watch reports when the declared branch moves past a pin; tests/test-vendored-*.sh read their sha here and hold every in-tree record to it. bin/setup never reads this file.",
  "plugins/sensemaking/skills/adhd": {
    "repo": "UditAkhourii/adhd",
    "branch": "main",
    "sha": "16dc239ff186b869372e75095cfa58fc0ee89927",
    "upstream_path": "skills/adhd",
    "kind": "vendored"
  },
  "plugins/software-dev/skills/finding-duplicate-functions": {
    "repo": "obra/superpowers-lab",
    "branch": "main",
    "sha": "51111f74f24058117752d9aa917cb19859f8ec86",
    "upstream_path": "skills/finding-duplicate-functions",
    "kind": "forked"
  }
}
```

`bash tests/test-json-wellformed.sh` counts nine files once it is staged; `prettier --check vendored.json` is silent.

- [ ] **Step 2: The reader, and the drift tests read it before they fetch**

In `tests/lib.sh`, after `upstream_sha`:

```bash
# The pinned sha of a vendored or forked tree, $1 its repository-relative
# path, read from vendored.json, the one place it is declared; fails unless
# it is 40 characters. The subset entries keep upstream_sha(), since the
# marketplace pins them; the two mattpocock trees keep their literal until
# #52 gives them a subset entry.
vendored_sha() {
  local sha
  sha="$(jq -r --arg t "$1" '.[$t].sha // empty' "$REPO_ROOT/vendored.json")" \
    || fail "could not read vendored.json"
  [ "${#sha}" -eq 40 ] || fail "vendored.json declares no 40-char sha for $1 (got '$sha')"
  printf '%s\n' "$sha"
}
```

`tests/test-vendored-adhd.sh`: lines 13–16 (the comment and `SHA="16dc…"`) become:

```bash
# Pinned in vendored.json: the repository's HEAD on 2026-09-06, since its
# only tag, v0.1.4, predates both this SKILL.md text and the plugin manifest.
# Every in-tree record that also carries the sha is held to the declared one
# before anything is fetched, so a bump that forgets a record fails by name
# whether or not the sha is reachable (#56).
SHA="$(vendored_sha plugins/sensemaking/skills/adhd)"
grep -q "Vendored from https://github.com/UditAkhourii/adhd at commit $SHA\$" "$V/SKILL.md" \
  || fail "SKILL.md's provenance header does not carry the declared sha $SHA"
grep -q "at commit $SHA)" "$REPO_ROOT/plugins/sensemaking/LICENSE" \
  || fail "plugins/sensemaking/LICENSE does not carry the declared sha $SHA"
```

and the LICENSE assertion at the end of the file (`grep -q "at commit $SHA)" …`) goes, since it moved up. `tests/test-vendored-duplicates.sh`: line 13, `SHA="51111f…"`, becomes:

```bash
# Pinned in vendored.json; the header, PROVENANCE.md and the LICENSE are held
# to the declared sha before anything is fetched (#56).
SHA="$(vendored_sha plugins/software-dev/skills/finding-duplicate-functions)"
grep -q "Forked from https://github.com/obra/superpowers-lab at commit $SHA\$" "$V/SKILL.md" \
  || fail "SKILL.md's provenance header does not carry the declared sha $SHA"
grep -q "$SHA" "$V/PROVENANCE.md" || fail "PROVENANCE.md does not name commit $SHA"
grep -q "^$SHA); its two prompt templates" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE carries no provenance notice naming commit $SHA for the fork"
```

and the two assertions at its end (`PROVENANCE.md and the LICENSE name the same commit`) go. Red first: `jq '."plugins/sensemaking/skills/adhd".sha = "0000000000000000000000000000000000000000"' vendored.json > /tmp/v.json && cp vendored.json /tmp/v.bak && cp /tmp/v.json vendored.json && bash tests/test-vendored-adhd.sh; cp /tmp/v.bak vendored.json` prints `FAIL: SKILL.md's provenance header does not carry the declared sha 0000…` before any fetch. Then both tests green (network).

- [ ] **Step 3: The watch's new section, and the loud tag lookup**

In `scripts/upstream-watch`, after `SKILLS_JSON=…` (line 14) add `VENDORED_JSON="$REPO_ROOT/vendored.json"`, and after the `[ -f "$SKILLS_JSON" ]` guard add `[ -f "$VENDORED_JSON" ] || die "missing $VENDORED_JSON"`. Lines 71–74, the superpowers tag lookup, become:

```bash
  if [ "$name" = superpowers ]; then
    latest_tag="$(git ls-remote --tags --refs "$url" | awk -F/ '{print $NF}' | newest_stable_tag)"
    [ -n "$latest_tag" ] || die "could not resolve the newest stable tag of $url"
    report "- Latest upstream tag: \`$latest_tag\`."
  fi
```

(#13 part 2: the report is loud or it fails.) After section 1's loop (line 77) and before `# 2. Each skills.sh source`, add:

```bash
# 1b. Each vendored or forked tree: the pinned sha against the tip of the
# declared branch (vendored.json). A bump is a human decision: edit
# vendored.json, re-vendor or re-diff the tree, update the records the drift
# test holds to it.
report "### vendored and forked trees"
report ""
while IFS="$(printf '\t')" read -r tree repo branch sha kind; do
  [ -n "$tree" ] || continue
  [ "${#sha}" -eq 40 ] || die "no 40-character sha for $tree in $VENDORED_JSON"
  head_sha="$(git ls-remote "https://github.com/$repo.git" "refs/heads/$branch" | cut -f1)"
  [ -n "$head_sha" ] || die "could not resolve $repo $branch"
  if [ "$head_sha" = "$sha" ]; then
    report "- \`$tree\` ($kind from \`$repo\`) pinned at \`$sha\`, which is $branch. Nothing to do."
  else
    report "- \`$tree\` ($kind from \`$repo\`) pinned at \`$sha\`; $branch is \`$head_sha\`. Bump by editing \`vendored.json\`, then re-vendor the tree (a forked tree: re-diff its carried fragments) and update the sha in its SKILL.md header, its PROVENANCE.md if any, and the plugin LICENSE; the drift test holds them equal."
    DRIFT=1
  fi
done < <(jq -r 'to_entries[] | select(.key != "$comment") | [.key, .value.repo, .value.branch, .value.sha, .value.kind] | @tsv' "$VENDORED_JSON")
report ""
```

- [ ] **Step 4: The Layout and `CONTEXT.md` lines the gate commit inherited**

In `README.md`'s Layout fence, after the `skills.json` line add two lines and keep the column:

```text
vendored.json      the desired state for the vendored and forked trees: repo, branch, pinned sha, kind
.claude-plugin/    the Claude marketplace manifest: the two plugins and the two subset entries, with their pins
```

`CONTEXT.md` line 67, `The desired state lives in two files: …`, becomes ``- The desired state lives in three files: `.claude-plugin/marketplace.json` for the plugins and the subset entries, `skills.json` for what `skills.sh` installs, and `vendored.json` for the vendored and forked trees' pins, which the watch reads and the engine never does. `bin/setup` converges a machine to the first two; `bin/doctor` is the same engine in check mode.``

- [ ] **Step 5: Suite and commit**

Run, with network:

```bash
bash scripts/upstream-watch >/tmp/watch.md; echo "exit=$?"; sed -n '/vendored and forked/,/^### skills/p' /tmp/watch.md
```

Expected: exit 1 with the adhd line reporting `main is dd08acc3…` past the pin and the superpowers-lab line `Nothing to do`, which is the report doing its job (§14); the bump is a separate decision. Then `bash tests/test-setup-doctor.sh` (the `--newest-stable-tag` filter is untouched), `bash tests/test-vendored-adhd.sh`, `bash tests/test-vendored-duplicates.sh`, `bash tests/test-json-wellformed.sh`, `bash tests/test-links-resolve.sh`, `bash tests/test-ownership.sh`, `shellcheck -e SC1091 -e SC2016 scripts/upstream-watch tests/lib.sh tests/test-vendored-adhd.sh tests/test-vendored-duplicates.sh`, `scripts/format`, `bash tests/run.sh`. Expected: green and silent.

```bash
git add vendored.json tests/lib.sh tests/test-vendored-adhd.sh tests/test-vendored-duplicates.sh scripts/upstream-watch README.md CONTEXT.md
git commit -m "Declare the two vendored-tree pins in vendored.json, watched and held by their drift tests" -m "The superpowers-lab and adhd pins lived only inside tests and no watch saw them (#56, names-and-surface spec §14). Each drift test now reads its sha from the declaration and holds the SKILL.md header, PROVENANCE.md and the LICENSE to it before fetching; the watch gains a section shaped like its subset-entry one and reports adhd moved on its first run. A superpowers tag lookup that returns nothing is now a die (#13). The engine never reads the file." -- vendored.json tests/lib.sh tests/test-vendored-adhd.sh tests/test-vendored-duplicates.sh scripts/upstream-watch README.md CONTEXT.md
```

### Task 8: The not-adopted record and the complement test (§14, #53)

**Files:**

- Modify: `skills.json` (whole file), `tests/test-skills-pin.sh` (lines 15–39 and the summary)

**Interfaces:**

- Produces: each source in `skills.json` carries `not_adopted`, a list of `{name, reason}`, and `via_subset_entry`, a list of names, empty until #52; every reader keeps selecting `.sources[].skills[]`; `tests/test-skills-pin.sh` asserts, per source, upstream's set of `SKILL.md` directory basenames equals the union of the three buckets, the buckets are disjoint, and its summary prints the counts.

- [ ] **Step 1: The record**

Replace `skills.json` with:

```json
{
  "$comment": "Skills installed through the skills.sh CLI: bin/setup applies each source's skills at its ref and bin/doctor verifies them; both read .sources[].skills[] and nothing else. not_adopted records every skill the source ships at that ref that is deliberately not declared, with its reason, and via_subset_entry the names a marketplace subset entry provides instead, so the three buckets together are the whole of what upstream ships; tests/test-skills-pin.sh holds that equality.",
  "sources": [
    {
      "repo": "mattpocock/skills",
      "ref": "v1.2.3",
      "skills": [
        "codebase-design",
        "domain-modeling",
        "grill-with-docs",
        "grilling",
        "handoff",
        "improve-codebase-architecture",
        "prototype",
        "research",
        "resolving-merge-conflicts",
        "teach",
        "to-questionnaire",
        "triage",
        "wait-what",
        "wayfinder",
        "wizard",
        "writing-for-agents"
      ],
      "not_adopted": [
        { "name": "setup-matt-pocock-skills", "reason": "vendored into software-dev as setup-repository, an adapted copy whose file-pick rule differs; installing the unadapted one beside it is the collision of 2026-09-05" },
        { "name": "diagnosing-bugs", "reason": "vendored into software-dev with a rewritten description, so it shares no trigger word with superpowers:systematic-debugging" },
        { "name": "to-spec", "reason": "collides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)" },
        { "name": "to-tickets", "reason": "collides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)" },
        { "name": "implement", "reason": "collides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)" },
        { "name": "tdd", "reason": "collides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)" },
        { "name": "code-review", "reason": "collides with a superpowers skill; superpowers owns that slot (ruling of 2026-09-06)" },
        { "name": "grill-me", "reason": "a four-line alias whose whole body calls grilling, which is declared (ruling of 2026-09-16)" },
        { "name": "ask-matt", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "claude-handoff", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "git-guardrails-claude-code", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "loop-me", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "migrate-to-shoehorn", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "scaffold-exercises", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "setup-pre-commit", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "setup-ts-deep-modules", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "writing-beats", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "writing-fragments", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" },
        { "name": "writing-shape", "reason": "never evaluated; surfaced by the complement check on 2026-09-16" }
      ],
      "via_subset_entry": []
    },
    {
      "repo": "obra/superpowers-developing-for-claude-code",
      "ref": "v0.3.1",
      "skills": ["developing-claude-code-plugins", "working-with-claude-code"],
      "not_adopted": [
        { "name": "professional-greeting", "reason": "never evaluated; an example plugin's skill under examples/, surfaced by the complement check on 2026-09-16" },
        { "name": "workflow", "reason": "never evaluated; an example plugin's skill under examples/, surfaced by the complement check on 2026-09-16" }
      ],
      "via_subset_entry": []
    },
    {
      "repo": "tt-a1i/archify",
      "ref": "v2.16.0",
      "skills": ["archify"],
      "not_adopted": [],
      "via_subset_entry": []
    }
  ]
}
```

Run `scripts/format` (prettier lays the objects out its way; the content is the point), then `bash tests/test-doctor-silence.sh`, `bash tests/test-doctor-faults.sh`, `bash tests/test-doctor-report.sh`, `bash tests/test-setup-apply.sh`: every reader is inert to the new keys, green.

- [ ] **Step 2: The complement test, red first**

In `tests/test-skills-pin.sh`, lines 15–36 (the three hand-written blocks) become:

```bash
# The three buckets per source are disjoint, and each not_adopted entry
# carries a reason: the collision policy lives in skills.json, and a name
# in two buckets is two policies (#53).
while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  dup="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r)
    | [.skills[], (.not_adopted[].name), .via_subset_entry[]] | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$S")"
  [ -z "$dup" ] || fail "$repo: a name sits in two buckets: $dup"
  bare="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .not_adopted[] | select((.reason // "") == "") | .name' "$S")"
  [ -z "$bare" ] || fail "$repo: a not_adopted entry carries no reason: $bare"
done < <(jq -r '.sources[].repo' "$S")
```

and, inside the per-source loop after the per-name resolution (after line 64's `done < <(jq -r … .skills[])`), add:

```bash
  # The complement: upstream's SKILL.md directory basenames at the ref,
  # the repository root excluded, a duplicate basename itself a failure,
  # equal the union of the three buckets, so a new upstream skill is a
  # visible decision at the next ref bump rather than a silent omission.
  upstream="$(find "$d" -name SKILL.md -not -path '*/.git/*' | while IFS= read -r f; do
    dir="${f%/SKILL.md}"
    [ "$dir" != "$d" ] || continue
    printf '%s\n' "${dir##*/}"
  done | sort)"
  dupbase="$(printf '%s\n' "$upstream" | uniq -d)"
  [ -z "$dupbase" ] || fail "$repo@$ref: a basename resolves to more than one SKILL.md: $dupbase"$'\n'"$(find "$d" -name SKILL.md -not -path '*/.git/*' | grep -F "/$dupbase/")"
  declared_set="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | [.skills[], (.not_adopted[].name), .via_subset_entry[]] | .[]' "$S" | sort)"
  only_up="$(comm -23 <(printf '%s\n' "$upstream") <(printf '%s\n' "$declared_set"))"
  only_here="$(comm -13 <(printf '%s\n' "$upstream") <(printf '%s\n' "$declared_set"))"
  [ -z "$only_up" ] || fail "$repo@$ref ships skills no bucket names; declare or record each: $(printf '%s ' $only_up)"
  [ -z "$only_here" ] || fail "$repo@$ref does not ship these names a bucket carries: $(printf '%s ' $only_here)"
  n_decl="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .skills | length' "$S")"
  n_not="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .not_adopted | length' "$S")"
  n_via="$(jq -r --arg r "$repo" '.sources[] | select(.repo == $r) | .via_subset_entry | length' "$S")"
  per_source="$per_source $repo: $n_decl declared, $n_not not adopted, $n_via via a subset entry, of $(printf '%s\n' "$upstream" | grep -c .);"
```

with `per_source=""` declared before the loop and the summary line becoming `printf 'skills-pin: %s declared skills, every ref a real tag, every name resolving once;%s\n' "$total" "$per_source"`. The `[ "$total" -eq 19 ]` assertion stays. `comm` joins the assumed tools. Red first, against the old record: `git clone -q --local . /tmp/pin-old && git show HEAD:skills.json >/tmp/pin-old/skills.json && cp tests/test-skills-pin.sh /tmp/pin-old/tests/ && bash /tmp/pin-old/tests/test-skills-pin.sh` (network), which runs the new test over the record as it was before Step 1: `FAIL: mattpocock/skills@v1.2.3 ships skills no bucket names; declare or record each: ask-matt claude-handoff …`. Then the three mutations #53 names, each against a scratch copy of the tree: remove `writing-shape` from `not_adopted` (fails naming it as shipped and unrecorded); add `{"name": "nosuch", "reason": "x"}` (fails naming it as not shipped); add `tdd` to `skills` beside its `not_adopted` entry (fails naming the two buckets). Then green (network): `skills-pin: 19 declared skills, every ref a real tag, every name resolving once; mattpocock/skills: 16 declared, 19 not adopted, 0 via a subset entry, of 35; obra/superpowers-developing-for-claude-code: 2 declared, 2 not adopted, 0 via a subset entry, of 4; tt-a1i/archify: 1 declared, 0 not adopted, 0 via a subset entry, of 1;`.

- [ ] **Step 3: Suite and commit**

`shellcheck -e SC1091 -e SC2016 tests/test-skills-pin.sh`, `shfmt -d -i 2 -ci -bn tests/test-skills-pin.sh`, `bash tests/test-json-wellformed.sh`, `bash tests/test-vendored-scaffolder.sh` (network; it reads `.sources[].skills[]`), `bash tests/run.sh`. Expected: green and silent.

```bash
git add skills.json tests/test-skills-pin.sh
git commit -m "Record every skill the skills.sh sources ship and do not adopt, and hold the complement" -m "Each source carries not_adopted, with a reason per name, and via_subset_entry, empty until #52; the pin test asserts upstream's basenames at the ref equal the three buckets' union and that the buckets are disjoint, so a new upstream skill is a decision at the next bump (#53, names-and-surface spec §14). Thirteen names enter as never evaluated, not fourteen: grill-me carries its alias reason. Every engine reader keeps selecting .sources[].skills[]." -- skills.json tests/test-skills-pin.sh
```

### Task 9: The action pins, read from the workflows (§14, §15, #6, M15)

**Files:**

- Modify: `.github/workflows/validate.yml` (lines 16, 25, 29, 108, 116, 120), `.github/workflows/upstream-watch.yml` (line 26), `scripts/upstream-watch` (a new section after section 3; a `--workflow-pins` mode beside `--newest-stable-tag`), `tests/test-workflows.sh` (line 14, and a new assertion), `tests/test-setup-doctor.sh` (one assertion beside the tag-filter one)

**Interfaces:**

- Produces: every `uses:` pinned to the newest node24 release with its tag in the trailing comment; `scripts/upstream-watch --workflow-pins` printing one `owner/repo sha vX.Y.Z` line per distinct pin, offline; the watch's section `### action pins`, reporting a sha that is not what the named tag resolves to.

- [ ] **Step 1: Bump once, by hand**

Every `uses:` line takes the current release and its tag comment:

```yaml
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
```

(the upload-artifact line keeps its own indentation under `uses:` at line 108). Both checkout lines in `validate.yml` and the one in `upstream-watch.yml` take the same sha. `ubuntu-latest` stays (§14). Confirm each sha against the tag before committing: `for p in actions/checkout@v7.0.1 actions/setup-node@v7.0.0 actions/setup-python@v7.0.0 actions/upload-artifact@v7.0.1; do git ls-remote --tags "https://github.com/${p%@*}.git" "refs/tags/${p#*@}" "refs/tags/${p#*@}^{}"; done` prints the four shas above, and `curl -sfL https://raw.githubusercontent.com/actions/checkout/v7.0.1/action.yml | grep using:` prints `node24` (the other three likewise). `actionlint .github/workflows/validate.yml .github/workflows/upstream-watch.yml` is silent.

- [ ] **Step 2: The watch reads the pins from the files**

In `scripts/upstream-watch`, a function above the `--newest-stable-tag` mode, and a second offline mode beside it:

```bash
# Every action pin in the workflow files, `uses: owner/repo@sha # vX.Y.Z`,
# as `owner/repo sha tag`, one line per distinct pin. The workflow file is
# the desired state; no copy is kept (spec §14).
workflow_pins() {
  grep -hoE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}[[:space:]]*#[[:space:]]*v[0-9]+(\.[0-9]+)*' \
    "$REPO_ROOT"/.github/workflows/*.yml "$REPO_ROOT"/.github/workflows/*.yaml 2>/dev/null \
    | sed -E 's/^uses:[[:space:]]*([^@]+)@([0-9a-f]{40})[[:space:]]*#[[:space:]]*(v[0-9.]+)$/\1 \2 \3/' \
    | sort -u
}

# Exposed so the parse can be tested without the network.
if [ "${1:-}" = "--workflow-pins" ]; then
  workflow_pins
  exit 0
fi
```

and, after section 3 and before the `DRIFT` verdict, section 4:

```bash
# 4. The action pins: each sha against what its tag names. An annotated tag
# is peeled; a lightweight one resolves bare, which is what the four current
# releases are.
report "### action pins"
report ""
while read -r repo sha tag; do
  [ -n "$repo" ] || continue
  resolved="$(git ls-remote --tags "https://github.com/$repo.git" "refs/tags/$tag^{}" | cut -f1)"
  [ -n "$resolved" ] || resolved="$(git ls-remote --tags "https://github.com/$repo.git" "refs/tags/$tag" | cut -f1)"
  [ -n "$resolved" ] || die "could not resolve $repo tag $tag"
  if [ "$resolved" = "$sha" ]; then
    report "- \`$repo@$tag\` is pinned at its tag's commit."
  else
    report "- **\`$repo\` is pinned at \`$sha\`, but \`$tag\` is \`$resolved\`.** Edit the \`uses:\` line in the workflow."
    DRIFT=1
  fi
done < <(workflow_pins)
n_pins="$(workflow_pins | grep -c .)"
[ "$n_pins" -gt 0 ] || die "no action pin was read from the workflow files"
report ""
```

- [ ] **Step 3: The tests**

`tests/test-workflows.sh` line 14 becomes `files="$(checked '.github/workflows/*.yml' '.github/workflows/*.yaml')"` (M15, §15), and after its loop:

```bash
# The watch reads the same pins the guard above checks: one line per
# distinct pin, and every uses: line accounted for.
pins="$(bash "$REPO_ROOT/scripts/upstream-watch" --workflow-pins)" || fail "upstream-watch --workflow-pins failed"
[ "$(printf '%s\n' "$pins" | grep -c .)" -eq 4 ] || fail "expected 4 distinct action pins, got:"$'\n'"$pins"
# shellcheck disable=SC2086  # one path per word, asserted by tests/test-ownership.sh
for line in $(grep -hoE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}' $files | sed -E 's/^uses:[[:space:]]*//'); do
  grep -qF -- "${line%@*} ${line#*@} " <<<"$pins" || fail "the watch does not read the pin $line"
done
```

`tests/test-setup-doctor.sh`, beside the tag-filter assertion: nothing more; the parse's home is the workflows test.

- [ ] **Step 4: Suite and commit**

`bash tests/test-workflows.sh` (needs actionlint and shellcheck): `workflows: 2 workflow(s) linted, …`. `bash scripts/upstream-watch | sed -n '/action pins/,$p'` (network): four `pinned at its tag's commit` lines. `shellcheck -e SC1091 -e SC2016 scripts/upstream-watch tests/test-workflows.sh`, `shfmt -d -i 2 -ci -bn scripts/upstream-watch tests/test-workflows.sh`, `prettier --check .github/workflows/*.yml`, `bash tests/run.sh`. Expected: silent, green.

```bash
git add .github/workflows/validate.yml .github/workflows/upstream-watch.yml scripts/upstream-watch tests/test-workflows.sh
git commit -m "Pin the four actions at their node24 releases and let the watch read the pins from the workflows" -m "Bumped once by hand to the current releases (v7); from here the watch reads every uses: line and reports a sha that is not what its tag names, so no copy of the pins is kept (names-and-surface spec §14, #6). The workflow guard globs *.yaml too (#61 M15). ubuntu-latest stays." -- .github/workflows/validate.yml .github/workflows/upstream-watch.yml scripts/upstream-watch tests/test-workflows.sh
```

### Task 10: The ownership derivation's remainder (§16: M4, M8, M17)

**Files:**

- Modify: `tests/lib.sh` (`checked_shell`, lines 133–144), `tests/test-ownership.sh` (lines 25, 51–52, 55, 67)

**Interfaces:**

- Produces: `checked_shell()` failing by name on a tracked file absent from the working tree; every `producer | grep -q && fail` in the ownership test a here-string over a captured list.

- [ ] **Step 1: M4, red first**

In a scratch clone, remove a tracked shell file from the working tree without unstaging it and run the derivation:

```bash
rm -rf /tmp/m4 && git clone -q --local . /tmp/m4 && rm /tmp/m4/tests/test-hook.sh && (cd /tmp/m4 && bash -c '. tests/lib.sh; checked_shell | grep -c .; echo "exit=$?"')
```

Expected today: one fewer shell file than `tests/test-ownership.sh` reports, exit 0, no word about the missing file. Then `checked_shell` becomes:

```bash
# The shell files: every checked file whose first line is the bash shebang.
# By shebang, not extension: the two commands under bin/, the three scripts
# and the hook have none. Arguments narrow the list the same way checked's
# do. A tracked file absent from the working tree is a FAIL by name, not a
# silently shorter list: head's failure is not swallowed (#61 M4).
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
```

(M17: the comment drops its count and keeps its argument.) Re-run the scratch command: `FAIL: tests/test-hook.sh is tracked but absent from the working tree`, exit 1.

- [ ] **Step 2: M8**

In `tests/test-ownership.sh`: line 25's `matches="$(git -C "$REPO_ROOT" ls-files | grep -E "$pat" || true)"` already captures; lines 51–52 become

```bash
odd="$(grep '[[:space:]*?[\\"]' <<<"$list" || true)"
[ -z "$odd" ] \
  || fail "a tracked path carries whitespace, a glob character, or a quoted path; the tool tests expand the list unquoted:"$'\n'"$odd"
```

line 55 becomes `grep -qx 'bin/setup' <<<"$shell" || fail "checked_shell() does not list bin/setup, a shell file with no extension"`, and line 67 becomes `grep -qxF -- "$f" <<<"$shell" || missing="$missing $f"`. The `printf | grep -q && fail` shape is then gone from the file: `grep -c 'grep -q && fail\||grep -q' tests/test-ownership.sh` prints 0. #61 M8's reproduction needs some 450 tracked paths and cannot be staged here; the here-string reads the whole captured list regardless of the pipe buffer, which is the property.

- [ ] **Step 3: Suite and commit**

`bash tests/test-ownership.sh`: `ownership: 6 row(s), each bound to its guard; N checked file(s), M of them shell` with the same counts as before. `shellcheck -e SC1091 -e SC2016 tests/lib.sh tests/test-ownership.sh`, `shfmt -d -i 2 -ci -bn tests/lib.sh tests/test-ownership.sh`, `bash tests/run.sh`. Expected: green and silent.

```bash
git add tests/lib.sh tests/test-ownership.sh
git commit -m "Fail by name on a tracked shell file the working tree lacks, and read the ownership lists whole" -m "checked_shell swallowed head's failure and dropped the file (#61 M4); the ownership test's pipe-into-grep assertions become here-strings over captured lists, the shape M8 asks for; the shebang comment keeps its argument and drops its count (M17). Names-and-surface spec §16." -- tests/lib.sh tests/test-ownership.sh
```

### Task 11: The runner and the fixtures (§17: M10, M11, M6, M12, M1, M5, M16; #63 items 1 to 3)

**Files:**

- Modify: `tests/run.sh` (lines 26–38, 64–66, 160), `tests/test-runner.sh` (a fixture for the duplicate and the mangled registry row), `tests/test-doctor-silence.sh` (`run_case`), `tests/test-codex-validate.sh` (line 20 and the end), `tests/test-doctor-faults.sh` (the two `status` sites #63 names), `tests/test-hook.sh` (after the (1b) block), `tests/test-setup-doctor.sh` (the synthetic README at lines 125–131)

**Interfaces:**

- Produces: `registry_version` taking the first matching row; a registry shape assertion at the gate (`tests/tools.txt: row N is not 'tool version sha256-or-dash'` or `… declares TOOL twice`); `rm -f "$RESULTS"` before the flag parse; `run_case` asserting the failure count equals the `FAIL:` line count; `codex-validate: N plugin(s) validated; both validator files match openai/codex@SHA`; the three hook shape checks.

- [ ] **Step 1: The runner (M10, M11, M6, M12)**

In `tests/run.sh`, move `RESULTS=tests/results.tsv` and `rm -f "$RESULTS"` (lines 36 and 38) above the `case "${1:-}" in` at line 27, so a rejected flag leaves no stale file (M12). `registry_version` (line 65) becomes:

```bash
# The version tests/tools.txt declares for $1, from the first matching row;
# exit 1 when it declares none. First match only: `exit` inside the main
# block still runs END, which is why the earlier `{ print; exit 0 } END
# { exit 1 }` form failed (#61 M11). The registry gate below has already
# refused a duplicate row, so first is also only.
registry_version() {
  awk -v t="$1" '$1 == t { if (!found++) v = $2 } END { if (!found) exit 1; print v }' "$REGISTRY"
}
```

After the `[ -f "$REGISTRY" ]` guard (line 53), the shape assertion (M6):

```bash
# The registry's shape, held at the gate so a duplicate or mangled row is
# loud before any test reads it (#61 M6, M11): every non-comment row is
# `tool version sha256-or-dash`, and no tool appears twice.
n=0
while IFS= read -r row; do
  n=$((n + 1))
  case "$row" in '' | '#'*) continue ;; esac
  printf '%s\n' "$row" | grep -qE '^[a-z0-9-]+[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+([0-9a-f]{64}|-)$' || {
    printf 'FAIL: %s: row %s is not '"'"'tool version sha256-or-dash'"'"': %s\n' "$REGISTRY" "$n" "$row" >&2
    exit 2
  }
done <"$REGISTRY"
dup="$(grep -vE '^[[:space:]]*(#|$)' "$REGISTRY" | awk '{ print $1 }' | sort | uniq -d)"
[ -z "$dup" ] || {
  printf 'FAIL: %s declares a tool twice: %s\n' "$REGISTRY" "$dup" >&2
  exit 2
}
```

and line 160's `log="$(mktemp)"` becomes `log="$(mktemp)" || { printf 'FAIL: could not create a log file (TMPDIR=%s)\n' "${TMPDIR:-/tmp}" >&2; exit 2; }` (M10). In `tests/test-runner.sh`, the fixture PATH (line 37) gains `sort uniq` (the gate's new tools), and after fixture 5 add:

```bash
# 7. A duplicate registry row and a mangled one are refused at the gate,
# exit 2, before any test runs (#61 M6, M11).
cp "$R/tests/tools.txt" "$R/tests/tools.txt.bak" || fail "could not back up the registry"
printf 'shfmt              3.15.0   -\n' >>"$R/tests/tools.txt" || fail "could not duplicate a row"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "a duplicate registry row must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'declares a tool twice: shfmt' || fail "the duplicate row was not named:"$'\n'"$out"
cp "$R/tests/tools.txt.bak" "$R/tests/tools.txt" || fail "could not restore the registry"
printf 'shfmt v3.14.1 -\n' >>"$R/tests/tools.txt" || fail "could not mangle a row"
if out="$(env PATH="$BIN" /bin/bash "$R/tests/run.sh" 2>&1)"; then status=0; else status=$?; fi
[ "$status" -eq 2 ] || fail "a mangled registry row must exit 2, got $status:"$'\n'"$out"
printf '%s\n' "$out" | grep -q "row 8 is not 'tool version sha256-or-dash'" || fail "the mangled row was not named:"$'\n'"$out"
cp "$R/tests/tools.txt.bak" "$R/tests/tools.txt" || fail "could not restore the registry"
```

and one more mutation for M12, appended to fixture 4's block: `env PATH="$BIN" /bin/bash "$R/tests/run.sh" --no-skipp >/dev/null 2>&1; [ ! -e "$RES" ] || fail "a rejected flag left a stale result file"` (placed after a run has written the file and before fixture 5). The five literals in the runner test stay (M6): they are the oracle. Red first: the two new fixtures fail on the old runner with `a duplicate registry row must exit 2, got 1` (the duplicate splits a row instead of refusing); then green.

- [ ] **Step 2: The silence fixture's count (M1)**

In `tests/test-doctor-silence.sh`, `run_case` gains, after the `clean` assertion:

```bash
  # The verdict's count equals the FAIL: lines: bad is the only writer of
  # both, so the bracket's own FAIL is counted, not merely printed (#61 M1).
  local n_fail n_said
  n_fail="$(printf '%s\n' "$OUT" | grep -c '^FAIL:' || true)"
  n_said="$(printf '%s\n' "$OUT" | grep -oE '^[0-9]+ check\(s\) failed$' | grep -oE '^[0-9]+' || true)"
  [ -n "$n_said" ] || fail "$label: no 'N check(s) failed' verdict:"$'\n'"$OUT"
  [ "$n_said" -eq "$n_fail" ] || fail "$label: the verdict says $n_said failed but $n_fail FAIL: lines were printed:"$'\n'"$OUT"
```

and fixture 10's `grep -qE '^[0-9]+ check\(s\) failed$'` assertion goes, subsumed. Red first: the mutation M1 names, in a scratch copy of `bin/setup` where `reported()`'s `bad` becomes `printf 'FAIL: %s\n'`, run through the silence test's `scratch_repo` shape: `36 said, 35 printed` or the reverse; then green.

- [ ] **Step 3: The other fixtures (M5, M16, #63 items 1 to 3)**

`tests/test-codex-validate.sh`: before line 20, `VALIDATOR="$(readlink -f "$VALIDATOR")" || fail "could not resolve $VALIDATOR"` (M16), and its last line becomes `printf 'codex-validate: %s plugin(s) validated; both validator files match openai/codex@%s\n' "$found" "${PIN:0:7}"` (M5). `tests/test-doctor-faults.sh` (#63 item 1): after the npx fixture's run (the `status` capture at line 141), add `printf '%s\n' "$out" | grep -q "OK:   software-dev@eranroseman $sd installed" || fail "the npx fixture's Claude half did not report the seeded registry as installed:"$'\n'"$out"`; after the repair run's `[ "$status" -eq 1 ]` line, add `printf '%s\n' "$out" | grep -q "OK:   software-dev@eranroseman $sd installed" || fail "the repair fixture's Claude half did not report the seeded registry as installed:"$'\n'"$out"` and `printf '%s\n' "$out" | grep -q 'FAIL: claude plugin' && fail "an unexpected claude invocation reached the stub:"$'\n'"$out"`. `tests/test-hook.sh` (#63 item 2, P9): after the (1b) loop, add:

```bash
# The shipped file's own content, three properties the §4.2 oracle once
# subsumed (#63): the worktree rule is present, no stale
# superpowers:brainstorming reference, and exactly one trailing newline.
grep -q 'worktree' "$H/working-rules.md" || fail "working-rules.md lost the worktree rule"
if grep -q 'superpowers:brainstorming' "$H/working-rules.md"; then fail "working-rules.md names superpowers:brainstorming, which the subset entry does not ship"; fi
[ "$(tail -c 1 "$H/working-rules.md" | wc -l)" -eq 1 ] || fail "working-rules.md does not end in a newline"
[ "$(tail -c 2 "$H/working-rules.md" | wc -l)" -eq 1 ] || fail "working-rules.md ends in more than one newline"
```

`tests/test-setup-doctor.sh` (#63 item 3): in the synthetic README at lines 125–128, the first fence under `## Install` gains a language tag, so the self-test covers the tagged fence the real READMEs use; the four words of that block become

````text
'```sh' 'in-install' '# note' '```'
````

and the expected `$got` is unchanged.

- [ ] **Step 4: Suite and commit**

`bash tests/test-runner.sh`, `bash tests/test-doctor-silence.sh`, `bash tests/test-codex-validate.sh` (needs the validator), `bash tests/test-doctor-faults.sh`, `bash tests/test-hook.sh` (network), `bash tests/test-setup-doctor.sh`, then `shellcheck -e SC1091 -e SC2016 tests/run.sh tests/test-*.sh`, `shfmt -d -i 2 -ci -bn tests/run.sh tests/test-*.sh`, `bash tests/run.sh`. Expected: green and silent; `tests/results.tsv`'s codex-validate row now has a fourth field. Also wrap, in the files this task touches, every comment line over 80 columns (`awk 'length > 80 && /^[[:space:]]*#/ { print FILENAME ":" FNR }' tests/run.sh tests/test-*.sh bin/setup` lists them); the gate commit counted thirty across the tree after plan A's renames.

```bash
git add tests/run.sh tests/test-runner.sh tests/test-doctor-silence.sh tests/test-codex-validate.sh tests/test-doctor-faults.sh tests/test-hook.sh tests/test-setup-doctor.sh
git commit -m "Hold the registry's shape at the gate, take the first matching row, and make five fixtures assert what they claimed" -m "A duplicate or mangled tools.txt row is refused before any test reads it (#61 M6, M11); a rejected flag leaves no stale result file (M12); the runner's own mktemp is guarded (M10); the silence fixture's verdict count equals its FAIL lines (M1); codex-validate prints a summary and hashes the file Python imports (M5, M16); the faults fixtures read the status they captured, the hook test regains its three shape checks, and the extractor's self-test covers a tagged fence (#63). Names-and-surface spec §17." -- tests/run.sh tests/test-runner.sh tests/test-doctor-silence.sh tests/test-codex-validate.sh tests/test-doctor-faults.sh tests/test-hook.sh tests/test-setup-doctor.sh
```

### Task 12: The formatter's lists, its regression test, and the spelling pattern (§18: #62, M19, #63 item 4)

**Files:**

- Modify: `tests/lib.sh` (four list functions after `checked_shell`), `scripts/format` (lines 14–19), `tests/test-format-prettier.sh` (lines 10–18), `tests/test-lint-markdown.sh` (line 10), `tests/test-spelling.sh` (lines 12–17), `tests/test-json-wellformed.sh` (line 13), `.markdownlint-cli2.jsonc` (reformatted once), `cspell.config.yaml` (the pattern; two words leave)
- Create: `tests/test-format-apply.sh`; modify `tests/test-links-resolve.sh` (drop its line)

**Interfaces:**

- Produces: `checked_json` (`*.json`, what `jq` reads), `checked_yaml` (`*.yml`, `*.yaml`), `checked_markdown` (`*.md`), `checked_prettier` (`*.json`, `*.jsonc`, `*.yml`, `*.yaml`, `*.md`) in `tests/lib.sh`, each taking further pathspecs the way `checked` does; `scripts/format` and the four check tests calling them; `tests/test-format-apply.sh` proving `scripts/format` restores what the checks check.

- [ ] **Step 1: The lists become functions**

In `tests/lib.sh`, after `checked_shell`:

```bash
# The formatters' lists, spelled once (#62): what jq reads, what prettier
# formats (its jsonc parser covers .markdownlint-cli2.jsonc), what
# markdownlint and cspell read. Each takes further pathspecs the way checked
# does, so a caller can exclude a directory.
checked_json() { checked '*.json' "$@"; }
checked_yaml() { checked '*.yml' '*.yaml' "$@"; }
checked_markdown() { checked '*.md' "$@"; }
checked_prettier() { checked '*.json' '*.jsonc' '*.yml' '*.yaml' '*.md' "$@"; }
```

Then each site: `scripts/format` line 16 `docs="$(checked_prettier)"`, line 18 `md="$(checked_markdown)"`; `tests/test-format-prettier.sh` collapses its three lists into one, `files="$(checked_prettier)"`, non-empty asserted, `prettier --log-level warn --check $files`, and its summary counts that one list (`format-prettier: %s file(s) formatted`); `tests/test-lint-markdown.sh` line 10 `md="$(checked_markdown)"`; `tests/test-spelling.sh` lines 12, 16, 65: `md="$(checked_markdown ':(exclude)docs/superpowers')"`, `yaml="$(checked_yaml)"`, `json="$(checked_json)"`; `tests/test-json-wellformed.sh` line 13 `done < <(checked_json)`. Then `prettier --check .markdownlint-cli2.jsonc` is red on the trailing commas: run `scripts/format` once and the file gains two commas (M19). `bash tests/test-format-prettier.sh` then counts one more file than the three old lists summed.

- [ ] **Step 2: The regression test, red on the mutation**

```bash
#!/usr/bin/env bash
# scripts/format restores what the three format checks check (#62): in a
# scratch clone, one shell, one markdown and one JSON file are un-formatted,
# scripts/format runs, and the checks pass. A clone, not a copy, because
# every list comes from git ls-files; the working tree's scripts/format is
# copied in, so a mutation is seen before it is committed. The mutation this
# exists for is scripts/format reduced to `exit 0`, which the suite could
# not see.
# needs: shfmt prettier markdownlint-cli2
. "$(dirname "$0")/lib.sh"

T="$(mktemp -d)" || fail "mktemp failed"
trap 'rm -rf "$T"' EXIT
git clone -q --local "$REPO_ROOT" "$T/repo" || fail "could not clone the checkout"
R="$T/repo"
# The working tree's formatter and its list helpers, not the committed ones:
# a clone carries HEAD, and the mutation this test exists for is made in the
# working tree before it is committed.
cp "$REPO_ROOT/scripts/format" "$R/scripts/format" || fail "could not copy scripts/format into the clone"
cp "$REPO_ROOT/tests/lib.sh" "$R/tests/lib.sh" || fail "could not copy tests/lib.sh into the clone"

# Three files, each broken in a way its checker names and its formatter
# repairs: four-space indents in a shell file; a heading with no space after
# its hash and three trailing spaces in markdown (MD018 and MD009, both
# fixable); one JSON file collapsed to a line.
printf '#!/usr/bin/env bash\nif true; then\n    echo x\nfi\n' >"$R/tests/scratch-shell.sh" || fail "could not write the shell file"
printf '#Title\n\n- an item   \n- another\n' >"$R/docs/agents/scratch.md" || fail "could not write the markdown file"
jq -c . "$R/skills.json" >"$R/skills.tmp" || fail "could not collapse skills.json"
mv "$R/skills.tmp" "$R/skills.json" || fail "could not replace skills.json"
git -C "$R" add tests/scratch-shell.sh docs/agents/scratch.md || fail "could not stage the scratch files"

for t in test-format-shell test-format-prettier test-lint-markdown; do
  bash "$R/tests/$t.sh" >/dev/null 2>&1 && fail "$t passed on the un-formatted clone; the fixture proves nothing"
done
bash "$R/scripts/format" >/dev/null 2>&1 || fail "scripts/format failed on the clone"
for t in test-format-shell test-format-prettier test-lint-markdown; do
  bash "$R/tests/$t.sh" >/dev/null 2>&1 || fail "$t still fails after scripts/format ran:"$'\n'"$(bash "$R/tests/$t.sh" 2>&1)"
done

printf 'format-apply: scripts/format restores a shell, a markdown and a JSON file the checks rejected\n'
```

Red first: `cp scripts/format /tmp/format.bak && printf '#!/usr/bin/env bash\nexit 0\n' >scripts/format && bash tests/test-format-apply.sh; cp /tmp/format.bak scripts/format` prints `FAIL: test-format-shell still fails after scripts/format ran`. Then green. (`markdownlint-cli2 --fix` retires the missing space and the trailing spaces; prettier lays out `skills.json`; shfmt re-indents.) Remove `'tests/test-format-apply.sh'` from `DECLARED_ABSENT`, stage, `bash tests/test-links-resolve.sh` green.

- [ ] **Step 3: The spelling pattern (#62 item 1), and #63 item 4**

In `cspell.config.yaml`, the pattern becomes `pattern: "/(?<=^|\\s)#.*$/gm"` (YAML-quoted, the backslash doubled), and `insection` and `nosuchtool` leave the word list, since neither is prose. `bash tests/test-spelling.sh`: green with both gone, which proves the pattern no longer reads an awk variable or a `printf` literal as a comment. #63 item 4 asks for no per-file callout for `skills.json`: every checked JSON file is `jq`-read data and formatter-owned alike; nothing to write.

- [ ] **Step 4: Suite and commit**

`bash tests/test-format-shell.sh`, `bash tests/test-format-prettier.sh`, `bash tests/test-lint-markdown.sh`, `bash tests/test-spelling.sh`, `bash tests/test-json-wellformed.sh`, `bash tests/test-format-apply.sh`, `shellcheck -e SC1091 -e SC2016 tests/lib.sh scripts/format tests/test-format-apply.sh tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh tests/test-json-wellformed.sh`, `shfmt -d …` over the same, `bash tests/run.sh`. Expected: green and silent.

```bash
git add tests/lib.sh scripts/format tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh tests/test-json-wellformed.sh tests/test-format-apply.sh .markdownlint-cli2.jsonc cspell.config.yaml tests/test-links-resolve.sh
git commit -m "Spell the formatters' lists once, prove scripts/format restores what the checks check, and anchor the comment pattern" -m "Four list functions in tests/lib.sh replace five spelled-out pathspec lists, which eliminates the dropped-glob class, and the prettier list gains *.jsonc so .markdownlint-cli2.jsonc is formatted once (#62, #61 M19). tests/test-format-apply.sh un-formats three files in a scratch clone and is red when scripts/format is exit 0. cspell's hash-comment pattern anchors to a line start or whitespace, and two words that were never prose leave the dictionary (#62). Names-and-surface spec §18." -- tests/lib.sh scripts/format tests/test-format-prettier.sh tests/test-lint-markdown.sh tests/test-spelling.sh tests/test-json-wellformed.sh tests/test-format-apply.sh .markdownlint-cli2.jsonc cspell.config.yaml tests/test-links-resolve.sh
```

### Task 13: The reference check's hardening (#65, four fixes)

**Files:**

- Modify: `.gitignore` (three lines), `tests/test-links-resolve.sh` (the `git log` calls in `history_tier_walk`; the whole-span and command-word order of the `NAME=` strip and the URL test; the class-5 regex; the header's class 5 sentence)

**Interfaces:**

- Produces: `.gitignore` entries anchored at the root; the history tier reading `git log HEAD`; a URL classified before any `NAME=` prefix is stripped; class 5 accepting `owner/repo`, `owner/repo@ref`, a 7-to-40 hex revision, or `name@name` before the colon, and nothing else.

- [ ] **Step 1: The four fixes**

`.gitignore`: `.worktrees/`, `worktrees/` and `.kilo/` become `/.worktrees/`, `/worktrees/` and `/.kilo/`; `git check-ignore -v .claude/worktrees/x` now names the `.claude/worktrees/` rule, and the same check on a worktrees directory one level below the root exits 1. In `tests/test-links-resolve.sh`: the one `git log --all -1 --format=%h -- "$p"` call in `history_tier_walk` becomes `git log HEAD -1 --format=%h -- "$p"`, and the header's class 8 sentence says `a path git shows deleted on this branch's history`. In the span loop, the `word="${word#*=}"` strips (the command-word one and the whole-span one) move below a URL test: each becomes

```bash
            case "$word" in
              *://* | mailto:*) ;;
              *) word="${word#*=}" ;;
            esac
```

for the command word, and the same shape on `$span` before the whole-span strip. The class-5 test (the `grep -qE '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)?(@[^:]+)?:.+'` block) and the class-4 block after it become one, so `owner/repo` before a colon is held to the same test as a slug, the first segment being no directory here and none git remembers:

```bash
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
```

and the header's class 5 sentence: `a namespaced path: owner/repo:path or owner/repo@ref:path, the other-repository convention CONTEXT.md sets, held like a slug to an owner that is no directory here; a revision before the colon (rev:path); or plugin@marketplace:key`.

- [ ] **Step 2: Prove each, then the tree**

In a scratch clone (`git clone -q --local . /tmp/ref65`), append to `README.md` these four lines, one per fix, and run the test there:

```text
See `https://example.com/a?b=c` and `bin/setpu:main` and `sub/worktrees/x` and `1dd7362:upstream/skills.json`.
```

Expected: exactly two failures, the probe line's second span (class 5 no longer takes it) and third span (no longer ignored); the URL with `=` and the revision-qualified path pass. Before the fixes the same line produced one failure, the URL, and passed the other three. Then on the tree, `bash tests/test-links-resolve.sh`: green, the namespaced count unchanged from Task 12's run (the eighty genuine tokens all match the tighter shape; a scratch run before hand-over printed 80); record the ignored count before and after, since anchoring can only lower it.

- [ ] **Step 3: Suite and commit**

`bash tests/test-hook.sh` (network; the working-rules file round-trips as before), `shellcheck -e SC1091 -e SC2016 tests/test-links-resolve.sh`, `shfmt -d -i 2 -ci -bn tests/test-links-resolve.sh`, `bash tests/run.sh`. Expected: green and silent.

```bash
git add .gitignore tests/test-links-resolve.sh
git commit -m "Anchor the ignored worktree directories, read this branch's history, and tighten two classes of the reference check" -m "Four of #65's findings: unanchored .gitignore entries ignored any depth and class 6 passed anything beneath; git log --all saw stash and other worktrees' refs; a URL with = lost its head to the NAME= strip; class 5 took dir/file:symbol. The other four are declined on the issue (plan B, P8)." -- .gitignore tests/test-links-resolve.sh
```

### Task 14: The version bump (§20, P12)

**Files:**

- Modify: `plugins/software-dev/.claude-plugin/plugin.json`, `plugins/software-dev/.codex-plugin/plugin.json` (`"version": "0.7.1"` to `"0.8.0"`), `plugins/sensemaking/.claude-plugin/plugin.json`, `plugins/sensemaking/.codex-plugin/plugin.json` (`"0.2.1"` to `"0.2.2"`)

- [ ] **Step 1: Bump, and prove the pairs agree**

Edit the four `version` fields. `bash tests/test-references-resolve.sh`: `references-resolve: … 2 manifest pair(s) agree` (check C compares the version across each pair). `bash tests/test-setup-upgrade.sh` (needs `claude`, network): both plugins move to the declared versions. `bash tests/test-setup-apply.sh`, `bash tests/test-doctor-faults.sh` read the declared versions and stay green. `bash tests/run.sh` green.

- [ ] **Step 2: Commit**

```bash
git add plugins/software-dev/.claude-plugin/plugin.json plugins/software-dev/.codex-plugin/plugin.json plugins/sensemaking/.claude-plugin/plugin.json plugins/sensemaking/.codex-plugin/plugin.json
git commit -m "software-dev 0.8.0, sensemaking 0.2.2" -m "A minor for software-dev: the hook directory's files were renamed on this branch. A patch for sensemaking. One commit at the end of plan B (names-and-surface spec §20)." -- plugins/software-dev/.claude-plugin/plugin.json plugins/software-dev/.codex-plugin/plugin.json plugins/sensemaking/.claude-plugin/plugin.json plugins/sensemaking/.codex-plugin/plugin.json
```

### Task 15: This plan's own paths, and the gate commit's leftovers

**Files:**

- Modify: `docs/superpowers/plans/2026-09-24-names-and-surface-b.md` only if the reference check names a line of it; `tests/test-links-resolve.sh` only if a `DECLARED_ABSENT` line this plan added survives

- [ ] **Step 1: Nothing left declared, nothing left red**

`grep -n 'plan B' tests/test-links-resolve.sh` prints nothing: Tasks 3, 4, 5, 6 and 12 each dropped their line. `bash tests/test-links-resolve.sh`: green, and its declared count is back to the six entries plan A left plus `.claude/settings.json`. If a line of this plan is named, edit that line (the ruling permits it: paths current) and commit as `Keep plan B's own paths current`. `bash tests/test-vocabulary.sh`: green; no task introduced a retired form.

### Task 16: Gate 2, the merge and the push (§9, §20)

**Files:**

- None edited unless a check is red.

- [ ] **Step 1: The full suite, cited**

`bash tests/run.sh`, then `head -n 1 tests/results.tsv && grep -c PASS tests/results.tsv && grep -v PASS tests/results.tsv`. Expected: the header names the branch's HEAD without `dirty`; 36 rows `PASS` (thirty from gate 1, plus setup-apply, doctor-report, doctor-cache, doctor-freshness, format-apply, and the runner's own row unchanged), `SKIP` only for a tool this machine lacks. Cite the header line in the execution notes.

- [ ] **Step 2: This plan under the branch's checks**

`scripts/format`, `bash tests/test-lint-markdown.sh`, `bash tests/test-format-prettier.sh`, `bash tests/test-links-resolve.sh`, `bash tests/test-spelling.sh`. Expected: silent and green over this file.

- [ ] **Step 3: Push and watch CI**

`git fetch origin && git log --oneline HEAD..origin/main` prints nothing (if it prints anything, `git rebase origin/main` first, re-run Step 1, and continue). Then:

```bash
git push origin names-and-surface && gh run list --branch names-and-surface --limit 2
```

`gh run watch` on the `validate` run. Expected: `validate` green with `tests/run.sh --no-skip` skipping nothing and every new test among its rows; `setup-e2e` green, its doctor step printing `OK:   the watch ran on schedule N hour(s) ago and succeeded` under the job's token and `OK:   no Claude plugin cache at …` or a walked count over the scratch HOME. A red job is fixed on the branch and the gate re-run.

- [ ] **Step 4: Merge to `main` and push in the same motion**

```bash
git switch main && git merge --ff-only names-and-surface && git push origin main && git log --oneline -1
```

Expected: `main` at the branch's HEAD, `origin/main` the same. `main`'s CI run is the same tree and goes green. No empty gate commit this time: the record of gate 2 is the merge itself plus Task 17's comments on the tracker, which are the durable home AGENTS.md's task-reports rule asks for.

### Task 17: The dispositions on the tracker (§19)

**Files:**

- None in the tree; every action is a `gh issue` command. Run after Task 16's push, from `main`, with `M="$(git rev-parse --short main)"` in hand and each commit's sha from `git log --oneline main`.

- [ ] **Step 1: The closes on their commits**

For each issue below, one `gh issue close N --comment "…"` naming the commit(s) on `main` that landed it and, where the issue asked for acceptance criteria, which test proves each:

- #13: Task 7's commit (the loud tag lookup; the `concurrency:` block landed earlier).
- #14: Task 2's commit.
- #17: Tasks 1, 3 and 4's commits (the `CODEX_LIST` guard, the apply-block fixtures, the sensemaking false OK; the `name` local; the manifest-agreement item is `tests/test-references-resolve.sh` check C, already on `main`).
- #22: plan A's Task 13 commit on `main` (`codex plugin marketplace upgrade eranroseman` at the three live sites; the fourth site is frozen content by §7).
- #25: Task 5's commit, and the answer to its open question: `installed_plugins.json` never referenced the orphaned cache, and the walk deletes it under four guards. Name P1 in the comment: the Codex half reports and never deletes, because Codex's own marketplaces are in no file and no list.
- #26, #37, #59, #58: plan A's commits on `main` (the renames and `CONTEXT.md`; the README items and the SchemaStore URL, with the 301 noted; the reference check).
- #44: item 1 closed on record (the citation this issue resolves stands here); item 2 fixed by Task 4's commit.
- #50: Task 4's commit.
- #53, #54, #56: Tasks 8, 4 and 7's commits.
- #62, #63: Tasks 12 and 11's commits (and Task 11's for #63 items 1 to 3; item 4 recorded as no callout).
- #6: Task 9's commit; items 1 to 4 were already on the tree.
- #65: Task 13's commit for four findings; the other four declined in the same comment with their reasons (P8), then closed.

- [ ] **Step 2: The declines and corrections**

- #57: closed as superseded by §7 item 1 (plan A's Task 13 commit): its tables carry thirty skill names, and the root README names none.
- #64: closed, declined: the launcher keeps its target and two superseded versions (three here: `2.1.261`, `2.1.263`, `2.1.273`), which is that retention working; the 486 MB observed at the cutover was three directories.
- #24: closed with the title corrected by comment: the schedule has run every day since 2026-09-07 (18 completed runs at planning time); what remained was the second half of the issue, an empty drift list being indistinguishable from nothing checked, and Task 6's commit answers it in the doctor.
- #61: one comment listing each M with its commit (M1, M4, M5, M6, M7 in plan A, M8, M9, M10, M11, M12, M13, M14, M15, M16, M17, M19, M20 already fixed by plan A's Task 9, M3 by the floor) and the three declines: M2 and M18 (a spec's content is frozen, §4) and the Task-15 note (recorded, not fixed; the count assertion of M1 is the fix that matters); then closed.
- #35: one comment: the Layout section now carries `.claude-plugin/` (Task 7's commit); the issue stays open for milestone 7.

- [ ] **Step 3: Record**

`gh issue list --state open` prints #21, #35, #52 and whatever else predates this plan and is not §19's; nothing from the list above. The SDD workspace closes only after every disposition above has landed (AGENTS.md, Task reports).
