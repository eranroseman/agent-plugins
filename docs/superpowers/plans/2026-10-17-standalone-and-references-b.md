# software-dev carries what it changes — Implementation Plan B (constraints 10 to 20)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take `standalone-and-references` from plan A's gate through §18's constraints 10 to 20: retire `bin/setup`, skills.sh and `sensemaking`, land the `mattpocock` entry at `v1.3.1` and the `elements-of-style` rename, send superpowers to obra's own marketplace, rename the glossary, qualify every cross-plugin reference, bump the version, pass the gate with the cleanup run, merge to `main`, push, and dispose of every issue the branch touches.

**Architecture:** One commit swaps skills.sh for the mattpocock entry and deletes the engine with its tests, so no commit leaves the mattpocock skills unheld. Then `sensemaking`'s two skills move into `software-dev`, superpowers leaves for obra's marketplace with the install job's new check of every `superpowers:` reference, the softaworks entry takes obra's plugin name, and the glossary follows upstream's rename with the fork's port. The README is rewritten once, in the retirement commit, and each later commit changes the sentences and blocks whose facts it changes. The gate runs the cleanup block for the first time over a machine `bin/setup` converged.

**Tech Stack:** as plan A, plus `git http-backend` for the gate's served marketplace, `gh` for the dispositions.

**Spec:** `docs/superpowers/specs/2026-09-27-standalone-and-references-design.md`. Section numbers refer to it. Plan A, `2026-10-17-standalone-and-references-a.md` beside this file, is the house style this plan follows, and its Task 10 is the gate this plan starts from.

**This is plan B of two, one branch.** Written against `main` at `bb596b0` on 2026-10-17, for the branch as plan A leaves it. Anchors, never line numbers (§18).

## What was verified while planning

Plan A's _What was verified_ section holds the measurements; the ones this plan rests on:

- **The mattpocock entry's exclusions at `v1.3.1`:** 37 skill directories under `skills`, 15 listed, so 22 excluded: `diagnosing-bugs` and `setup-matt-pocock-skills` (copied and forked), `to-spec`, `to-tickets`, `implement`, `tdd`, `code-review` (superpowers' slot), `grill-me` (an alias), `ask-matt`, `claude-handoff`, `git-guardrails-claude-code`, `loop-me`, `migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape` (never evaluated), and `implement-spec`, `pr`, `retro` (new at `v1.3.0`, Q85). `resolving-merge-conflicts` is gone upstream.
- **The sibling-name check at `v1.3.1`, with the fork renamed:** the one undelivered name in this repository's files is `pr`, in the fork's `issue-tracker-gitlab.md` (`` `mr` in place of `pr` ``); Task 1 rewords it. `wayfinder`'s and `triage`'s `/setup-matt-pocock-skills` resolve to the fork.
- **Upstream's `v1.2.3..v1.3.1` diff of `setup-matt-pocock-skills`:** the description's em dash becomes a colon and the whole is quoted; every `CONTEXT.md` and `CONTEXT-MAP.md` becomes `GLOSSARY.md` and `GLOSSARY-MAP.md`; em dashes in bullets and sentences become colons, periods or commas; nothing else. The same diff of `diagnosing-bugs`: the rename, the punctuation, and Phase 6 losing its post-mortem paragraph and its `/improve-codebase-architecture` handoff; `hitl-loop.template.sh` changes one comment.
- **adhd:** `main` is `7b91ce601ed951c1a9658c63f6f9550d2486525b` and `skills/adhd` there is byte-identical to the pin.
- **The cleanup block spelled against `cspell.config.yaml`:** one unknown word, `lname`; Task 1 lists it.
- **Closed issues the branch reverses or makes false,** found by `gh issue list --state closed --search` for the SessionStart hook, `using-superpowers`, `working-rules`, `bump-superpowers` and the superpowers entry, beyond the ones §20 names: #43 (the hook test's rules-file check), #14 (`bump-superpowers`' temporaries), #15 (`test-vendored-scaffolder.sh`'s assertions), #2 (`fetch_upstream`'s messages), #63 (the hook test's shape checks), #6 (the hook test's trap), #17 (the engine's coverage), #3 (the validator's two sources).
- **Private vulnerability reporting** is `enabled: false` on 2026-10-17; Task 9 waits for the maintainer.

## Deviations decided while planning

- **P12. The README is rewritten whole in Task 1 and patched by Tasks 2 to 5.** §17 wants each sentence changed in the commit that changes its fact; the retirement commit changes most of them, so it carries the rewrite, and the four commits after it change their own blocks and bullets, each version written out in full in its task. Veto: one README commit at the end.
- **P13. The adhd bump is its own task, before the version bump.** §9 says the sha moves "re-read at the bump", so it is read then, not copied from this plan. Veto: fold into Task 2.
- **P14. `fetch_upstream` and `upstream_sha obra/superpowers` go in Task 1,** with `tests/test-setup-upgrade.sh`, their last caller, rather than in Task 3 with the entry. Veto: Task 3.
- **P15. The `pr` reword lands in Task 1, not Task 5,** because the sibling-name check holds from the commit the entry lands in; the fork's other port lines wait for the glossary task, where upstream's rename gives them their reason. Veto: port the whole diff in Task 1.
- **P17. The Codex validator's cache moves under the user's cache directory.** §15.2 names `${TMPDIR:-/tmp}`, a world-writable, predictable path another local user can pre-create with a planted module beside the two hashed files (#73). Task 3 moves it to `${XDG_CACHE_HOME:-$HOME/.cache}/software-dev` and refuses a cache it does not own. Veto: keep `/tmp` with an ownership check only.
- **P18. Plan A's audit left two plan B defects in the plan text itself**, the clone-before-commit red-firsts and the `cd` into the main checkout; both are corrected in this revision rather than carried as issues.
- **P16. The gate's cleanup run uses this machine's CLIs,** Claude Code 2.1.273 and codex-cli 0.147.0, the releases the migration was measured on, and the install job's run on the newest stable releases stands beside it. Veto: install the newest releases locally first.

## Carried forward from plan A's final review

Plan A's whole-branch review (its fix wave is `bb4e5f0`) left these for plan B; each lands in the task named, so plan A's workspace closes on this plan's commit.

1. The Codex manifest's `defaultPrompt` names two skills Codex hides from the model, the scaffolder and the audit: Task 2 points it at `diagnosing-bugs` and `finding-duplicate-functions`.
2. The `allow_implicit_invocation: false` grep is copied in three tests: Task 3 moves it into `tests/lib.sh` as `user_invocable_only`.
3. The offline watch test's pinless record carries no fork, so the path plan B's mattpocock record takes is unasserted: Task 1 gives it one and asserts both lines.
4. `tests/test-upstream.sh` accepts a `DECLARED` row of any kind or path and an `EXCLUSIONS` key naming no entry: Task 1 guards the rows, Task 3 the keys.
5. The `strict: false` and `version` checks have not been seen red: Task 10 mutates both.
6. `CONTEXT.md`'s `additional context` entry is vestigial since the hook left, and Q83 freezes the file's content: a spec-owner call, filed by the planner as #71; plan B carries the file over unedited, as Q83 says, and Task 11 leaves #71 open.

## Global Constraints

Plan A's Global Constraints hold, and:

- **Every task runs in the worktree** `.claude/worktrees/standalone-and-references`, where the branch is checked out; the main checkout stays on `main` until Task 10's merge, which runs there.
- **Human steps**, marked in their tasks: the maintainer enables private vulnerability reporting before `SECURITY.md` (Task 9), makes T17's observation at the gate, and approves the push (T30).
- **Every bump re-reads its pin at the bump:** adhd's tip in Task 7, mattpocock's newest stable tag in Task 1 (expected `v1.3.1`; if a newer stable tag exists, the entry lands on it and Task 1 re-measures the exclusions).
- **The version bump is last among shipped-file changes** (T43): `software-dev` 0.8.0 to 0.9.0, both manifests, one commit, after Task 7.
- **The README's marked blocks** are the one wording a check depends on; the source string `eranroseman/agent-plugins` appears in the install blocks exactly as a user types it.

## Names used across tasks

Plan A's name table holds. This plan adds:

| Name                       | Where                    | Defined in | Shape                                                                                                                                                   |
| -------------------------- | ------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `EXCLUSIONS["mattpocock"]` | `tests/test-upstream.sh` | Task 1     | twenty-two lines of `skill<TAB>reason`; keys quoted, as plan A's test has them                                                                          |
| `cleanup` block            | `README.md`              | Task 1     | the fenced block `sh cleanup`; Tasks 2, 3 and 4 add lines                                                                                               |
| `superpowers_references`   | `tests/install-check.sh` | Task 3     | asserts each `superpowers:<s>` token of `shipped_texts` against the installed superpowers on both agent CLIs (T47)                                      |
| `whole_machine`            | `tests/install-check.sh` | Task 3     | `claude plugin list` names exactly the marketplace's entries at `eranroseman` plus `superpowers@superpowers-marketplace`; no catalogue name twice (T53) |
| `GLOSSARY.md`              | repository root          | Task 5     | `CONTEXT.md` moved by `git mv`, content unchanged                                                                                                       |

---

### Task 1: The retirement and the mattpocock entry, in one commit (§13, §6.2, §7.3; constraint 10; Q48, Q58, Q73, Q75, Q82, Q84, T5, T36, T40, T44)

**Files:**

- Delete: `bin/setup`, `bin/doctor`, `tests/test-setup-apply.sh`, `tests/test-setup-doctor.sh`, `tests/test-setup-upgrade.sh`, `tests/test-doctor-cache.sh`, `tests/test-doctor-duplicates.sh`, `tests/test-doctor-faults.sh`, `tests/test-doctor-freshness.sh`, `tests/test-doctor-report.sh`, `tests/test-doctor-silence.sh`, `skills.json`, `tests/test-skills-pin.sh`, `plugins/software-dev/README.md`
- Modify: `.claude-plugin/marketplace.json` (the `mattpocock` entry), `plugins/software-dev/.claude-plugin/plugin.json` (dependencies), `vendored.json` (the mattpocock record's pin), `plugins/software-dev/skills/diagnosing-bugs/` (re-copied at `v1.3.1`), the fork's `issue-tracker-gitlab.md` (one span)
- Modify: `tests/lib.sh` (`saw`, `skill`, `seed_clones`, `seed_lockfile`, `fetch_upstream` go; `checked_shell`'s comment), `tests/test-upstream.sh` (`EXCLUSIONS[mattpocock]`), `tests/test-ownership.sh` (the `bin/setup` line), `tests/test-links-resolve.sh` (`DECLARED_ABSENT`), `tests/test-upstream-watch.sh` and `tests/test-workflows.sh` (their `skills.json` fixtures), `tests/run.sh` (one comment)
- Modify: `scripts/upstream-watch` (the skills.sh section), `.github/workflows/validate.yml` (the `setup-e2e` job goes), `AGENTS.md`, `cspell.config.yaml`, `README.md` (rewritten whole)

**Interfaces:**

- Produces: the `mattpocock` entry and its skills `mattpocock:<name>`; `EXCLUSIONS[mattpocock]`; the README's final structure with the `cleanup` block; the install job's Codex block adding `mattpocock`.
- Consumes: plan A's `tests/test-upstream.sh`, `tests/install-check.sh`, the README's marked blocks, `record_rows`.

- [ ] **Step 1: Re-read the pin**

```bash
cd /home/eranr/agent-plugins/.claude/worktrees/standalone-and-references
git ls-remote --tags --refs https://github.com/mattpocock/skills.git | awk -F/ '{print $NF}' | grep -E '^v?[0-9]+(\.[0-9]+)+$' | sort -V | tail -1
git ls-remote --tags https://github.com/mattpocock/skills.git 'refs/tags/v1.3.1^{}'
```

Expected: `v1.3.1`, peeling to `24fe0ef7737efae15c87225755e9f6f5965e4888`. If a newer stable tag exists, the entry lands on it: substitute its tag and peeled sha below, fetch it, list its skill directories under `skills` with `find skills -name SKILL.md`, and re-derive the exclusions as the difference between that list and the fifteen, each new name excluded with the reason `never evaluated; surfaced by the complement check on <today>` and recorded as a candidate on #48 in Task 11.

- [ ] **Step 2: The entry, the dependency, the record**

In `.claude-plugin/marketplace.json`, add after the `writing-clearly-and-concisely` entry:

```json
    {
      "name": "mattpocock",
      "description": "mattpocock/skills, a subset entry: fifteen of Matt Pocock's skills, grilling, research, wayfinder and their siblings, at a release tag.",
      "category": "productivity",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/mattpocock/skills.git",
        "path": "skills",
        "ref": "v1.3.1",
        "sha": "24fe0ef7737efae15c87225755e9f6f5965e4888"
      },
      "version": "1.3.1",
      "strict": false,
      "skills": [
        "./productivity/grilling",
        "./productivity/handoff",
        "./productivity/teach",
        "./productivity/to-questionnaire",
        "./productivity/wait-what",
        "./productivity/writing-for-agents",
        "./engineering/research",
        "./engineering/wayfinder",
        "./engineering/wizard",
        "./engineering/codebase-design",
        "./engineering/domain-modeling",
        "./engineering/grill-with-docs",
        "./engineering/improve-codebase-architecture",
        "./engineering/prototype",
        "./engineering/triage"
      ]
    }
```

`plugins/software-dev/.claude-plugin/plugin.json`: `dependencies` becomes `["sensemaking", "superpowers", "writing-clearly-and-concisely", "mattpocock"]`.

`vendored.json`: the mattpocock record loses its `ref` and `sha` lines; its pin is the entry's (T40).

Run: `claude plugin validate --strict .claude-plugin/marketplace.json && bash tests/test-references-resolve.sh`
Expected: PASS.

- [ ] **Step 3: `diagnosing-bugs` re-copied at the pin, its declared change kept**

```bash
D="${TMPDIR:-/tmp}/software-dev-upstream-mattpocock-skills"
rm -rf "$D" && mkdir -p "$D" && git -C "$D" init -q && git -C "$D" remote add origin https://github.com/mattpocock/skills.git
git -C "$D" fetch -q --depth 1 origin 24fe0ef7737efae15c87225755e9f6f5965e4888 && git -C "$D" checkout -q FETCH_HEAD
git rm -rq plugins/software-dev/skills/diagnosing-bugs
cp -R "$D/skills/engineering/diagnosing-bugs" plugins/software-dev/skills/diagnosing-bugs
sed -i '3s/.*/description: Use when a bug resists reproduction, or for a performance regression./' plugins/software-dev/skills/diagnosing-bugs/SKILL.md
git add plugins/software-dev/skills/diagnosing-bugs
git ls-files -s plugins/software-dev/skills/diagnosing-bugs
```

Expected: three files, each `100644`; line 2 `name: diagnosing-bugs`, line 3 ours, the body upstream's at `v1.3.1` (it reads `GLOSSARY.md`, and Phase 6 has no post-mortem paragraph).

- [ ] **Step 4: The twenty-two exclusions and the fork's one span**

In `tests/test-upstream.sh`'s `EXCLUSIONS`, add:

```bash
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
```

In the fork's `issue-tracker-gitlab.md`, the span `` `mr` in place of `pr` `` becomes `` `glab mr` in place of `gh pr` ``: `pr` is a mattpocock skill the entry excludes, and the sibling-name check reads every markdown file of the fork (plan A's P4).

Also in `tests/test-upstream.sh`, the loop `# Every declared row names a path under a copy` gains two guards, so a stale or mistyped row fails by name before any fetch:

```bash
  kind="$(cut -f2 <<<"$r")"
  case "$kind" in
    line | added) ;;
    *) fail "the declared change for $p has the kind '$kind'; the kinds are line and added" ;;
  esac
  git -C "$REPO_ROOT" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 \
    || fail "the declared change for $p names a path that is not a tracked file"
```

Red first: a row of kind `token`, then a row naming `plugins/software-dev/skills/diagnosing-bugs/nowhere.md`; each fails as named. Revert.

Two more edits to `tests/test-upstream.sh` from plan A's audit. `compare_file` reads both sides with `$(cat ...)`, which strips end-of-file newlines, so a copy that gained or lost a final newline passed; after its `diff`, add:

```bash
  [ "$(tail -c 2 "$lf" | od -An -tx1)" = "$(tail -c 2 "$uf" | od -An -tx1)" ] \
    || fail "$key: the last bytes differ from upstream's at the pin (an end-of-file newline)"
```

Red first: a second newline appended to `plugins/software-dev/skills/adhd/SKILL.md`. Expected FAIL `the last bytes differ`. Revert. And the sibling-name check must not go vacuous once a record resolves through an entry: after the entries loop, add

```bash
if jq -e '[.records[] | has("sha") | not] | any' "$VENDORED_JSON" >/dev/null 2>&1; then
  [ "$SIBLINGS" -gt 0 ] || fail "a record resolves through an entry, yet no sibling name was checked"
fi
```

and the header's sentence `Before such a record exists the check is vacuous, and the summary line says so.` becomes `Before such a record exists the check does not run; once one does, it must check at least one name.`

Red first (T44), in the working tree, since a clone of HEAD would not hold the pinless record: `git mv plugins/software-dev/skills/setup-matt-pocock-skills plugins/software-dev/skills/setup-repository` and change `vendored.json`'s forks key to match; run `bash tests/test-upstream.sh`. Expected FAIL naming `wayfinder/SKILL.md` or `triage/SKILL.md` and `setup-matt-pocock-skills, a mattpocock/skills skill no marketplace entry delivers`. Move the fork back and restore the key. Then, with the gitlab span still reading `` `pr` ``: Expected FAIL naming `issue-tracker-gitlab.md` and `pr`. Reword, run again.

Run: `bash tests/test-upstream.sh`
Expected: PASS: the mattpocock entry at its pin with twenty-two exclusions, the copy held, the fork's upstream path present, and sibling names resolving (the summary's last count is now above zero).

- [ ] **Step 5: The engine, its tests and skills.sh go**

```bash
git rm -rq bin tests/test-setup-apply.sh tests/test-setup-doctor.sh tests/test-setup-upgrade.sh tests/test-doctor-cache.sh tests/test-doctor-duplicates.sh tests/test-doctor-faults.sh tests/test-doctor-freshness.sh tests/test-doctor-report.sh tests/test-doctor-silence.sh skills.json tests/test-skills-pin.sh plugins/software-dev/README.md
```

`tests/lib.sh`: delete `saw`, `skill`, `seed_clones` and `seed_lockfile` with their comments, and `fetch_upstream` with its comment (its last caller was `tests/test-setup-upgrade.sh`; `upstream_sha` stays, as `record_rows`' resolver); in `checked_shell`'s comment, `the two commands under bin/ and the two scripts have none` becomes `the two scripts have none`. `link_tools` stays for `tests/test-runner.sh`.

`tests/test-ownership.sh`: delete the line `grep -qx 'bin/setup' <<<"$shell" || fail "checked_shell() does not list bin/setup, a shell file with no extension"`; the derived shebang check below it holds the property.

`tests/run.sh`: the comment `# The hard prerequisites, refused as one list in the shape bin/setup uses.` becomes `# The hard prerequisites, refused as one list.` `tests/test-runner.sh`: the comment `# from fixture 2's run, above.` becomes `# from fixture 4's run, above.`, the fixture that wrote the result file last (#68, spec §16.1).

`scripts/upstream-watch`: delete `SKILLS_JSON="$REPO_ROOT/skills.json"`, the line `[ -f "$SKILLS_JSON" ] || die "missing $SKILLS_JSON"`, and section 2 whole, from `# 2. Each skills.sh source` through its `report ""`. Without this edit the watch exits 2 on `main` after the merge and #60 goes stale (§12.2).

`tests/test-upstream-watch.sh`: delete the `printf '{"sources":...}' >"$W/skills.json"` line, `SKILLS_URL` and its answer line in `write_answers`. Give the fixture's pinless record a fork, `"forks": { "plugins/p/skills/seven": "skills/seven" }`, and in case 1's first run assert that the `tagged` entry's own line names `skills/seven` (anchored, since the name also appears on the record's line: `grep -F '`tagged`' <<<"$out" | grep -qF 'skills/seven'`) and that the pinless record's line carries `forks to re-read`: this is the path the mattpocock record takes from this commit on. Red first: with the fork added and the assertions in place, drop `skills/seven` from the watch's entry-line suffix in the scratch copy; the test fails. Revert. `tests/test-workflows.sh`: `cp "$REPO_ROOT/skills.json" "$REPO_ROOT/vendored.json" "$W/"` becomes `cp "$REPO_ROOT/vendored.json" "$W/"`.

`.github/workflows/validate.yml`: delete the `setup-e2e` job whole, from its `setup-e2e:` key to the line before the `install:` key. No job lists it under `needs:`, and `main` has no branch protection (§13.1).

`AGENTS.md`, `### Security scanning`: the last sentence becomes:

```text
This repository ships its workflows and the scripts they run, so run a scan yourself on a diff that touches `scripts/` or a workflow.
```

`cspell.config.yaml`: delete the override filename `"bin/*"`; add `lname` to the word list.

`tests/test-links-resolve.sh`: `DECLARED_ABSENT` gains `'bin/setup' # retired by the standalone spec (§13); the README's cleanup names the script it undoes`.

Run: `bash tests/test-upstream-watch.sh && bash tests/test-workflows.sh && bash tests/test-ownership.sh && bash tests/test-runner.sh`
Expected: PASS.

- [ ] **Step 6: The README, rewritten whole**

Replace `README.md` whole. The two marks `(Task 2 adds rethink-audit and adhd)` and `(Task 6 names the skills consistency-audit uses)` are placeholders later tasks replace; nothing else is.

````markdown
# agent-plugins

One repository states the skills a machine should have on Claude Code and
Codex, delivers them as plugins each agent CLI installs with its own commands,
and watches the upstreams it takes skills from.

## Why

A skill reaches an agent from an upstream that moves, through an agent CLI
that installs plugins its own way. Done by hand that is a pin per upstream, a
copy per change, and two install procedures to keep in step, on every machine.
This repository states the set once: the skills it writes or changes ship in
one plugin, the skills it takes as they are come from subset entries that pin
part of an upstream at one commit, and a daily watch says when an upstream has
moved past a pin. Every pin is written once, in the marketplace manifest or in
`vendored.json`, and a test holds every copy to its upstream.

## What it ships

Marketplace entries in `.claude-plugin/marketplace.json`, the one file both
agent CLIs read. On Claude Code, installing `software-dev` brings the rest as
dependencies; on Codex, each is installed by name.

- `software-dev`: the plugin this repository writes or changes.
  - `setup-matt-pocock-skills`: a fork of mattpocock/skills' repository
    scaffolder, first-party since the fork. It writes the `## Agent skills`
    block to `AGENTS.md` and leaves `CLAUDE.md` as a one-line `@AGENTS.md`
    import, asks which git convention the repo uses, and carries that
    convention, the design ladder and the task-reports rule. User-invocable
    only.
  - `consistency-audit` and its agent `consistency-audit-inspector`: a
    first-party audit, user-invocable only, that reads a repository whole for
    contradictions, duplication, drifted terms and stale claims, and refutes
    every candidate before reporting it. On Codex, where a plugin cannot ship
    a subagent, it runs as one reader and says so. (Task 6 names the skills
    consistency-audit uses)
  - `diagnosing-bugs`: a copy of mattpocock/skills' reproduction-first
    debugging loop at the `mattpocock` entry's pin, with one declared change,
    a description that shares no trigger word with
    `superpowers:systematic-debugging`. Model-invoked.
  - `finding-duplicate-functions`: a rewritten fork of obra/superpowers-lab's
    skill, for Python; the plugin LICENSE records what changed.
  - (Task 2 adds rethink-audit and adhd)
- `sensemaking`: `rethink-audit` and `adhd`.
- `superpowers`: obra/superpowers at a pinned commit, a subset entry.
- `writing-clearly-and-concisely`: softaworks/agent-toolkit's skill of that
  name, a subset entry at a pinned commit.
- `mattpocock`: fifteen of mattpocock/skills' skills at a release tag, a
  subset entry: `grilling`, `handoff`, `teach`, `to-questionnaire`,
  `wait-what`, `writing-for-agents`, `research`, `wayfinder`, `wizard`,
  `codebase-design`, `domain-modeling`, `grill-with-docs`,
  `improve-codebase-architecture`, `prototype` and `triage`. The skills read
  `mattpocock:<name>` on both agent CLIs.

Every skill a subset entry delivers is upstream's as written; a copy is made
only where this repository changes something, and the change is declared in
the upstream test. A fork is first-party and held to nothing.

## What it depends on

`software-dev` depends on the entries beside it, so one install on Claude
Code brings them all. Each entry is pinned at one upstream commit, and the
watch reports when the upstream moves.

## Install

Claude Code:

```sh install-claude
claude plugin marketplace add eranroseman/agent-plugins
claude plugin install software-dev@eranroseman
```

The second command brings the dependencies with it, at user scope by default.

Codex, which has no dependency concept, so each plugin is added by name:

```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev sensemaking superpowers writing-clearly-and-concisely mattpocock; do codex plugin add "$p@eranroseman"; done
```

Codex takes the `owner/repo` shorthand, and neither agent CLI needs a login
for any command here.

## Update

Claude Code, one update per plugin, since a parent's update leaves its
dependencies at their old versions:

```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update sensemaking@eranroseman
claude plugin update superpowers@eranroseman
claude plugin update writing-clearly-and-concisely@eranroseman
claude plugin update mattpocock@eranroseman
```

The `install` after `software-dev`'s update installs any dependency the new
release adds; on an installed plugin whose dependencies are present it
changes nothing. `claude plugin list` names a missing dependency and the
install command for it. Claude Code loads new versions at the next launch or
after `/reload-plugins`.

Codex:

```sh update-codex
codex plugin marketplace upgrade eranroseman
```

The line re-clones the marketplace when its source moved and reinstalls
every installed plugin from the new commit. Never run `codex plugin
marketplace add` again for an update: on a marketplace already added it
reports it as such, exits 0 and refreshes nothing. A plugin the marketplace
gains later needs its own `codex plugin add`, as `mattpocock` does on this
release; the cleanup below covers it.

## One-time cleanup

For a machine the retired script `bin/setup` converged before this release.
Run it once, before the update blocks:

```sh cleanup
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
npx --yes skills remove codebase-design domain-modeling grill-with-docs grilling handoff improve-codebase-architecture prototype research resolving-merge-conflicts teach to-questionnaire triage wait-what wayfinder wizard working-with-claude-code writing-for-agents -g -y
find ~/.agents/skills -maxdepth 1 -type l -lname "$HOME/.local/share/software-dev/*" -delete
rm -rf ~/.local/share/software-dev
ls -d ~/.agents/skills/*.aside.* 2>/dev/null || true
codex plugin marketplace upgrade eranroseman
codex plugin add mattpocock@eranroseman
```

- The first three lines move `software-dev` to this release, which installs
  the dependencies it adds.
- The skills.sh `remove` takes the seventeen skills the script installed that
  the `mattpocock` entry now brings or this release drops;
  `resolving-merge-conflicts` is named because the old install had it, though
  upstream has since removed it. `archify` and `developing-claude-code-plugins`
  stay installed and become your own, as does any other skills.sh install
  (`npx skills list -g` shows them; the same `remove` takes any you no longer
  want). The line needs `npx`, as the install it undoes did.
- The `find` removes the script's symlinks into its clones, and the `rm` the
  clones.
- The `ls` lists what the script moved aside inside the skill root, where
  Codex loads each as a bare skill; review each by hand, since it may be
  yours.
- The Codex `upgrade` is the update block's own first line, so the `add` after
  it finds the new entry.
- Without the cleanup, both agent CLIs load each mattpocock skill twice, bare
  beside `mattpocock:<name>`, and Codex lists every superpowers skill twice.

## Notes

- `archify` is not shipped. [tt-a1i/archify](https://github.com/tt-a1i/archify)
  gives its own install instructions; this repository neither pins nor
  watches it.
- `developing-claude-code-plugins` is not shipped either. Each agent CLI's own
  documentation is current: [Claude Code's documentation map](https://code.claude.com/docs/en/claude_code_docs_map.md)
  and [Codex's plugin build page](https://developers.openai.com/plugins/build/plugins).
  Anyone who wants the skill can install obra's own,
  `superpowers-developing-for-claude-code@superpowers-marketplace` from
  `obra/superpowers-marketplace`, on either agent CLI, which brings
  `working-with-claude-code` with it; this repository neither pins nor
  watches it.
- Claude Code's auto-update is off by default for a third-party marketplace.
  Turning it on is your choice, made once in `/plugin` under Marketplaces:
  select `eranroseman` and turn auto-update on. With it on, Claude Code
  refreshes the marketplace and updates installed plugins after a session
  starts, then prompts for `/reload-plugins` or loads the new version at the
  next launch. The marketplace pins its subset entries at a fixed commit, so
  auto-update delivers this repository's releases and never an upstream's
  HEAD.

## Checks

`tests/run.sh` runs every check under `tests/`. It needs `bash` 4.4 or later,
`jq` and `git`, and refuses with the list otherwise. Some checks need a tool
this machine may lack: each such check is skipped with a line naming the
tool, and the run ends by summing what it did not verify. The versions those
checks are held to are declared in `tests/tools.txt`; the three npm tools
install with `npm install -g <tool>@<version>`, the three binaries from their
release pages. The Codex manifest check needs `python3` with `pyyaml` and
fetches Codex's validator from GitHub at a pinned commit, as the upstream
test fetches each pin; offline, they fail rather than skip.

Every run writes `tests/results.tsv`, one row per check under a header naming
the commit; a report cites that file rather than pasting output.
`scripts/format` rewrites what the format checks check. CI runs the same
script with `--no-skip`, so nothing is skipped there, uploads the result file
as an artifact, and, in a second job that also runs daily, installs the plugin
and its entries through the install blocks above on the newest stable
release of each agent CLI and asserts that each loads the skills it declares.

## Layout

```text
scripts/           what CI and the maintainer run: the upstream watch and the formatter
plugins/           the plugins, each with its own README
vendored.json      one record per upstream repository copied or forked from: its pin, its copies and its forks
.claude-plugin/    the marketplace manifest both agent CLIs read: the plugins and the subset entries, with their pins
.github/           the CI workflows, and dependabot.yml, which moves their action pins
tests/             every check; tests/run.sh runs them, tests/install-check.sh is the install job's, and tests/tools.txt pins the tools
docs/agents/       the conventions the agents read: issue tracker, triage labels, domain docs
docs/Professional-Editorial-Standards-2024.md   the editorial reference
docs/superpowers/  historical artifacts: specs and plans, each read as of its commit
CONTEXT.md         the vocabulary: contested terms with their retired forms, and the leading words
AGENTS.md          the agents' instruction file; CLAUDE.md imports it
```

## License

MIT. See `LICENSE`. Each upstream this repository copies or forks from is
credited in the plugin's own LICENSE.
````

Before the commit, re-read the two documentation links the README carries (spec §23): `curl -sIL -o /dev/null -w '%{http_code}\n' https://code.claude.com/docs/en/claude_code_docs_map.md` and the same for `https://developers.openai.com/plugins/build/plugins`. Expected: `200` each (both answered 200 on 2026-10-23); a redirect's final address replaces the link.

Run: `bash tests/test-links-resolve.sh && bash tests/test-spelling.sh && bash tests/test-vocabulary.sh`
Expected: PASS; `bin/setup` is declared absent; `lname` is listed.

- [ ] **Step 7: Install locally, run the suite, commit**

Run: `bash tests/install-check.sh`
Expected: PASS on this machine: `software-dev` brings four dependencies on Claude Code, `mattpocock`'s fifteen skills on Claude Code and seven model-visible ones on Codex.

Run: `bash scripts/format && bash tests/run.sh`
Expected: green; the nine engine tests and `tests/test-skills-pin.sh` gone from the result file. Cite `tests/results.tsv`.

```bash
git add -A
git commit -m "Retire bin/setup and skills.sh: the mattpocock entry at v1.3.1 brings the skills, and the README carries each agent CLI's own commands"
```

Then push and watch CI as in plan A's gate: `git push && gh run watch ...`. Expected: `validate` and `install` green, `setup-e2e` gone.

### Task 2: `sensemaking` retires into `software-dev` (§5.2, constraint 11; Q70, Q74, T42)

**Files:**

- Rename: `plugins/sensemaking/skills/adhd/` and `plugins/sensemaking/skills/rethink-audit/` under `plugins/software-dev/skills/`
- Delete: `plugins/sensemaking/.claude-plugin/plugin.json`, `plugins/sensemaking/.codex-plugin/plugin.json`, `plugins/sensemaking/README.md`, `plugins/sensemaking/LICENSE`
- Modify: `.claude-plugin/marketplace.json` (the `sensemaking` entry goes; `software-dev`'s description), `plugins/software-dev/.claude-plugin/plugin.json` (dependencies, description), `plugins/software-dev/.codex-plugin/plugin.json` (descriptions), `plugins/software-dev/LICENSE` (adhd's section), `vendored.json` (adhd's key), `tests/test-upstream.sh` (adhd's `DECLARED` paths), `README.md` (What it ships; the `install-codex`, `update-claude` and `cleanup` blocks)

**Interfaces:**

- Produces: `software-dev` carries `adhd` and `rethink-audit`; the `cleanup` block's two `sensemaking` lines.
- Consumes: Task 1's README and blocks.

- [ ] **Step 1: Move the two skills and delete the plugin**

```bash
cd /home/eranr/agent-plugins/.claude/worktrees/standalone-and-references
git mv plugins/sensemaking/skills/adhd plugins/software-dev/skills/adhd
git mv plugins/sensemaking/skills/rethink-audit plugins/software-dev/skills/rethink-audit
git rm -rq plugins/sensemaking
```

A move changes the path and no byte (§5.2).

- [ ] **Step 2: The records, the declared rows and the LICENSE section follow**

`vendored.json`: the adhd record's `trees` key becomes `"plugins/software-dev/skills/adhd": "skills/adhd"`.

`tests/test-upstream.sh`: the two adhd rows of `DECLARED` name `plugins/software-dev/skills/adhd/SKILL.md` and `plugins/software-dev/skills/adhd/agents/openai.yaml`.

`plugins/software-dev/LICENSE`: insert adhd's section after the superpowers-lab section, before the final line of dashes that precedes the shared MIT permission text:

```text
----------------------------------------------------------------------
https://github.com/UditAkhourii/adhd
skills/adhd: copied, with two declared changes, the invocation gate in its frontmatter and the Codex policy file agents/openai.yaml

Copyright (c) 2026 ADHD contributors

```

Run: `bash tests/test-upstream.sh && bash tests/test-ownership.sh`
Expected: PASS: three records, the adhd copy under `software-dev`, and the summary's section count 3 (the owner's MIT block above the first dashes is no section).

- [ ] **Step 3: The marketplace and the manifests**

`.claude-plugin/marketplace.json`: delete the `sensemaking` entry whole; `software-dev`'s description becomes `The repository scaffolder, the consistency audit and its inspector, diagnosing-bugs, finding-duplicate-functions, rethink-audit and adhd.`

`plugins/software-dev/.claude-plugin/plugin.json`: `dependencies` loses `"sensemaking"`; the description becomes `The repository scaffolder, the consistency audit and its inspector, diagnosing-bugs, finding-duplicate-functions, rethink-audit and adhd, for Claude Code and Codex.`

`plugins/software-dev/.codex-plugin/plugin.json`: the description becomes `The repository scaffolder, the consistency audit, diagnosing-bugs, finding-duplicate-functions, rethink-audit and adhd, for Claude Code and Codex.`; `longDescription` becomes `The repository scaffolder for mattpocock's engineering skills, a refuted-before-reported consistency audit, a reproduction-first debugging loop, a Python duplicate-function finder, a clean-slate redesign audit, and parallel divergent ideation under five frames.`; `keywords` gains `"design-audit"`; `defaultPrompt` becomes `["Diagnose this bug; it does not reproduce.", "Find the duplicate functions in this Python package."]`, two skills Codex shows the model (plan A's prompts named the scaffolder and the audit, which its policy files hide).

Run: `bash tests/test-references-resolve.sh && bash tests/test-plugin-skills.sh && bash tests/test-codex-validate.sh`
Expected: PASS: the scan resolves `software-dev:consistency-audit-inspector` and finds `rethink-audit`'s `superpowers:` tokens carved out; the validator excepts `adhd`, `consistency-audit` and `setup-matt-pocock-skills`.

- [ ] **Step 4: The README**

`## What it ships`: delete the `sensemaking` bullet, and replace the mark `(Task 2 adds rethink-audit and adhd)` in the `software-dev` bullet with these two sub-bullets:

```text
  - `rethink-audit`: a first-party clean-slate redesign audit of a module,
    service or feature; design only, applying no changes. Held for a redesign.
  - `adhd`: parallel divergent ideation under five isolated cognitive frames,
    scored, clustered and deepened, about ten agent calls. A copy of
    UditAkhourii/adhd at the pin `vendored.json` records, with two declared
    changes, the invocation gate in its frontmatter and the Codex policy file,
    so it is user-invocable only on both agent CLIs: `/adhd <problem>`.
```

The `install-codex` block becomes:

````markdown
```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev superpowers writing-clearly-and-concisely mattpocock; do codex plugin add "$p@eranroseman"; done
```
````

The `update-claude` block loses `claude plugin update sensemaking@eranroseman`:

````markdown
```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update superpowers@eranroseman
claude plugin update writing-clearly-and-concisely@eranroseman
claude plugin update mattpocock@eranroseman
```
````

The `cleanup` block gains `claude plugin uninstall sensemaking@eranroseman` after `claude plugin install software-dev@eranroseman`, and `codex plugin remove sensemaking@eranroseman` after `codex plugin marketplace upgrade eranroseman`:

````markdown
```sh cleanup
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin uninstall sensemaking@eranroseman
npx --yes skills remove codebase-design domain-modeling grill-with-docs grilling handoff improve-codebase-architecture prototype research resolving-merge-conflicts teach to-questionnaire triage wait-what wayfinder wizard working-with-claude-code writing-for-agents -g -y
find ~/.agents/skills -maxdepth 1 -type l -lname "$HOME/.local/share/software-dev/*" -delete
rm -rf ~/.local/share/software-dev
ls -d ~/.agents/skills/*.aside.* 2>/dev/null || true
codex plugin marketplace upgrade eranroseman
codex plugin remove sensemaking@eranroseman
codex plugin add mattpocock@eranroseman
```
````

In the cleanup's explanation, the bullet on the uninstall lines becomes:

```text
- The uninstall removes `sensemaking` from Claude Code, whose two skills ship
  in `software-dev` now; the Codex `remove` does the same there.
```

In `## Layout`, the `plugins/` line's description becomes `the one plugin, software-dev`.

Run: `bash tests/install-check.sh`
Expected: PASS locally: `software-dev`'s skills now include `adhd` and `rethink-audit`, and Codex's model-visible set excludes `adhd`.

- [ ] **Step 5: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green; the vocabulary scan passes (no retired form in the moved files). Cite `tests/results.tsv`.

```bash
git add -A plugins .claude-plugin/marketplace.json vendored.json tests/test-upstream.sh README.md
git commit -m "Retire sensemaking: adhd and rethink-audit move into software-dev, the one plugin"
```

### Task 3: Superpowers leaves for obra's marketplace (§6.1, constraint 12; Q78, Q87, T47, T48, T51, T52, T53)

**Files:**

- Modify: `.claude-plugin/marketplace.json` (the `superpowers` entry goes), `plugins/software-dev/.claude-plugin/plugin.json` (dependencies), `tests/test-upstream.sh` (`EXCLUSIONS[superpowers]`), `tests/install-check.sh` (`superpowers_references`, `whole_machine`), `README.md` (What it ships; every block; the note on a machine that already has obra's superpowers)

**Interfaces:**

- Produces: `superpowers_references` and `whole_machine` in `tests/install-check.sh`; the README's obra lines in every block.
- Consumes: Task 2's blocks.

- [ ] **Step 1: The entry and the dependency go**

`.claude-plugin/marketplace.json`: delete the `superpowers` entry whole. `plugins/software-dev/.claude-plugin/plugin.json`: `dependencies` loses `"superpowers"`, leaving `["writing-clearly-and-concisely", "mattpocock"]`. `tests/test-upstream.sh`: delete the `["superpowers"]=...` line of `EXCLUSIONS`, and add, before the entries loop, a guard that every key names an entry:

```bash
for k in "${!EXCLUSIONS[@]}"; do
  entry_rows | cut -f1 | grep -qxF -- "$k" || fail "EXCLUSIONS names $k, which is no subset entry of the marketplace; retire it"
done
```

Red first: run the test with the guard in and the `["superpowers"]` line still present. Expected FAIL `EXCLUSIONS names superpowers`. Then delete the line.

Run: `bash tests/test-upstream.sh && bash tests/test-plugin-skills.sh && bash tests/test-references-resolve.sh`
Expected: PASS: two entries; the scan still carves `superpowers:` tokens out.

- [ ] **Step 2: The README's blocks, obra's lines in each**

Replace the four marked blocks and the cleanup block with these:

````markdown
```sh install-claude
claude plugin marketplace add eranroseman/agent-plugins
claude plugin install software-dev@eranroseman
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
```
````

````markdown
```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev writing-clearly-and-concisely mattpocock; do codex plugin add "$p@eranroseman"; done
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```
````

````markdown
```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update writing-clearly-and-concisely@eranroseman
claude plugin update mattpocock@eranroseman
claude plugin marketplace update superpowers-marketplace
claude plugin update superpowers@superpowers-marketplace
```
````

````markdown
```sh update-codex
codex plugin marketplace upgrade eranroseman
codex plugin marketplace upgrade superpowers-dev
```
````

````markdown
```sh cleanup
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin uninstall sensemaking@eranroseman
claude plugin uninstall superpowers@eranroseman
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
npx --yes skills remove codebase-design domain-modeling grill-with-docs grilling handoff improve-codebase-architecture prototype research resolving-merge-conflicts teach to-questionnaire triage wait-what wayfinder wizard working-with-claude-code writing-for-agents -g -y
find ~/.agents/skills -maxdepth 1 -type l -lname "$HOME/.local/share/software-dev/*" -delete
rm -rf ~/.local/share/software-dev
ls -d ~/.agents/skills/*.aside.* 2>/dev/null || true
codex plugin marketplace upgrade eranroseman
codex plugin remove sensemaking@eranroseman
codex plugin add mattpocock@eranroseman
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```
````

Prose, each in place of the sentence it names:

- After the `install-claude` block, the paragraph ends:

  ```text
  The last two commands install obra's superpowers from obra's own marketplace,
  the route obra's README gives beside the official one; it brings upstream's
  own SessionStart hook.
  ```

- After the `install-codex` block:

  ```text
  The second line adds obra's repository as a marketplace, which serves one
  named `superpowers-dev`, and installs superpowers from it.
  ```

- After the `update-claude` block, add: `The last two lines refresh obra's marketplace and update superpowers from it.`
- After the `update-codex` block, the first sentence becomes: `Each line re-clones its marketplace when its source moved and reinstalls every installed plugin from the new commit.`
- The cleanup's uninstall bullet becomes:

  ```text
  - The uninstalls remove from Claude Code the plugins whose entries left the
    marketplace: `sensemaking`, whose two skills ship in `software-dev` now,
    and `superpowers@eranroseman`, since superpowers now comes from obra's
    marketplace; the next two lines install it from there, as the install
    block does. On Codex no line removes `superpowers`: it reached a converged
    machine through the script's links, which the `find` and `rm` remove,
    never as a plugin.
  ```

- `## What it ships` gains, after the entries' list:

  ```text
  Superpowers is not an entry here. The blocks below install obra's own plugin
  from obra's marketplace on each agent CLI; nothing in this repository pins,
  copies or watches it, and a user's superpowers moves with obra's releases. A
  machine that already has superpowers from another marketplace,
  `superpowers@claude-plugins-official` among them, would get a second one
  beside it, every skill twice; install from one.
  ```

Spelling: the blocks and prose carry no new word beyond Task 1's.

- [ ] **Step 3: One helper for the Codex gate**

Three tests grep the same policy line. Add to `tests/lib.sh`, after `skill_name_matches`:

```bash
# True when the Codex policy file $1 keeps its skill out of the model's
# catalogue: the skill is user-invocable only on Codex.
user_invocable_only() { [ -f "$1" ] && grep -qx '  allow_implicit_invocation: false' "$1"; }
```

In the same commit, two fixes from plan A's audit. `tests/test-codex-validate.sh`: the cache leaves `/tmp` (P17). Its `CACHE=` line becomes `CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/software-dev/codex-validator-${PIN:0:7}"`, the `mkdir -p "$CACHE"` keeps its guard, and the reuse condition `if ! pinned_copy "$VDIR"; then` becomes `if ! { [ -O "$CACHE" ] && pinned_copy "$VDIR"; }; then`, so a cache this user does not own is replaced rather than trusted; the header comment's `/tmp` sentence says `under the user's cache directory`. `tests/install-check.sh`: `details_names` captures the command and fails on a non-zero exit before filtering, so a failing `claude plugin details` cannot pass the Agents check as an empty set:

```bash
details_names() {
  local out
  out="$(claude plugin details "$1")" || fail "claude plugin details $1 failed"
  sed -n "s/^  $2 ([0-9]*) *//p" <<<"$out" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep . | sort || true
}
```

and the entry cache lookup uses `find` rather than a glob, so zero caches fail as such: `cache="$(find "$CODEX_HOME/plugins/cache/eranroseman/$name" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"`, with the message `expected one installed cache for $name, found:` unchanged.

Then `tests/install-check.sh` deletes its own definition of that function and keeps its calls; `tests/test-codex-validate.sh`'s `grep -qx '  allow_implicit_invocation: false' "$y" || continue` becomes `user_invocable_only "$y" || continue`; and `tests/test-plugin-skills.sh`'s gate pairing reads `user_invocable_only "$skill/agents/openai.yaml" && codex_gate=true`.

Run: `bash tests/test-codex-validate.sh && bash tests/test-plugin-skills.sh`
Expected: PASS, the same three skills excepted.

- [ ] **Step 4: The install job checks the `superpowers:` references and the whole machine**

In `tests/install-check.sh`, before the final `printf`, add:

```bash
# ---- superpowers: references (Q87, T47) --------------------------------------
# Each superpowers:<name> token in the shipped texts names a skill the
# installed superpowers lists on Claude Code and shows in Codex's catalogue.
# No fixed superpowers set is asserted: obra's install is unpinned.
superpowers_references() {
  local tokens claude_sp t s
  tokens="$(while IFS= read -r f; do
    grep -ohE '(^|[^A-Za-z0-9_/-])superpowers:[a-z][a-z0-9-]*' "$REPO_ROOT/$f" | sed -E 's/^.*superpowers:/superpowers:/'
  done < <(shipped_texts) | sort -u)"
  [ -n "$tokens" ] || fail "no superpowers: token in the shipped texts; the check went vacuous"
  claude_sp="$(details_names superpowers@superpowers-marketplace Skills)"
  [ -n "$claude_sp" ] || fail "claude plugin details superpowers@superpowers-marketplace lists no skill"
  while IFS= read -r t; do
    s="${t#superpowers:}"
    grep -qxF -- "$s" <<<"$claude_sp" || fail "claude: $t names a skill the installed superpowers does not list"
    grep -qxF -- "$t" <<<"$catalogue" || fail "codex: $t is not in the installed superpowers' model-visible catalogue"
  done <<<"$tokens"
  printf 'superpowers: %s reference(s) resolve on both agent CLIs\n' "$(grep -c . <<<"$tokens")"
}
superpowers_references

# ---- The whole machine (T53) -------------------------------------------------
# Exactly the marketplace's entries from eranroseman and superpowers from
# superpowers-marketplace are installed on Claude Code, and no skill name is
# listed twice in Codex's catalogue. A fresh install meets both; they are here
# for the gate's run over a machine the old script converged.
whole_machine() {
  local want installed dup
  want="$({ jq -r '.plugins[].name' "$MARKETPLACE" | sed 's/$/@eranroseman/'; printf 'superpowers@superpowers-marketplace\n'; } | sort)"
  installed="$(claude plugin list | sed -n 's/^  ❯ //p' | sort)"
  expect_equal "claude: the installed plugins" "$want" "$installed"
  dup="$(uniq -d <<<"$catalogue")"
  [ -z "$dup" ] || fail "codex: a skill name is listed twice in the catalogue; the cleanup block removes the old installs:"$'\n'"$dup"
}
whole_machine
```

Red first (T47), in the working tree, since a clone of HEAD would lack `superpowers_references`: append `superpowers:no-such-skill` to `plugins/software-dev/skills/consistency-audit/SKILL.md`, then run `bash tests/install-check.sh --assert` over the `HOME` and `CODEX_HOME` a passing run printed as its first lines. Expected FAIL `claude: superpowers:no-such-skill names a skill the installed superpowers does not list`. Red first (T53): over the scratch `HOME` a passing run printed as its first lines, `HOME=<that home> CODEX_HOME=<its .codex> claude plugin install elements-of-style@superpowers-marketplace` (obra's marketplace is already added there), then `HOME=<that home> CODEX_HOME=<its .codex> bash tests/install-check.sh --assert`. Expected FAIL `claude: the installed plugins: the sets differ`.

Run: `bash tests/install-check.sh`
Expected: PASS: obra's two lines install superpowers on both agent CLIs (7.0.0, fifteen skills on 2026-10-17), every `superpowers:` token found (`superpowers:brainstorming` and `superpowers:writing-plans` in `rethink-audit`, `superpowers:systematic-debugging` in the upstream test's reason is not a shipped text; `consistency-audit`'s `superpowers:writing-plans` arrives in Task 6), and `claude plugin list` names exactly `software-dev`, `writing-clearly-and-concisely` and `mattpocock` from `eranroseman` and `superpowers` from `superpowers-marketplace`.

- [ ] **Step 5: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green. Cite `tests/results.tsv`.

```bash
git add .claude-plugin/marketplace.json plugins/software-dev/.claude-plugin/plugin.json tests/lib.sh tests/test-upstream.sh tests/test-codex-validate.sh tests/test-plugin-skills.sh tests/install-check.sh README.md
git commit -m "Install obra's superpowers from obra's marketplace, and check every superpowers: reference against what it installs"
```

### Task 4: `elements-of-style` (§6.3, §10.1; constraint 13; Q79)

**Files:**

- Modify: `.claude-plugin/marketplace.json` (the entry's name and description), `plugins/software-dev/.claude-plugin/plugin.json` (dependencies), `tests/test-upstream.sh` (the `EXCLUSIONS` key), `plugins/software-dev/skills/consistency-audit/SKILL.md` (one line), `README.md` (What it ships, What it depends on, the blocks)

**Interfaces:**

- Produces: the entry name `elements-of-style`; the skill `elements-of-style:writing-clearly-and-concisely` on both agent CLIs.
- Consumes: Task 3's blocks.

- [ ] **Step 1: The rename**

`.claude-plugin/marketplace.json`: the `writing-clearly-and-concisely` entry's `name` becomes `elements-of-style` and its description `softaworks/agent-toolkit's writing-clearly-and-concisely, one skill, under obra's plugin name so that upstream brainstorming's pointer resolves: Strunk's rules for prose humans read.` Its source, version, `strict` and `skills` stay.

`plugins/software-dev/.claude-plugin/plugin.json`: `dependencies` becomes `["elements-of-style", "mattpocock"]`.

`tests/test-upstream.sh`: the `["writing-clearly-and-concisely"]=''` line of `EXCLUSIONS` becomes `["elements-of-style"]=''` (the keys are quoted, since shfmt splits an unquoted hyphenated key).

`plugins/software-dev/skills/consistency-audit/SKILL.md`, under `**Documentation:**`: `- Use writing-clearly-and-concisely skill if available` becomes `- Use the elements-of-style:writing-clearly-and-concisely skill`.

Run: `claude plugin validate --strict .claude-plugin/marketplace.json && bash tests/test-plugin-skills.sh && bash tests/test-upstream.sh`
Expected: PASS: the scan resolves `elements-of-style:writing-clearly-and-concisely` through the entry's list.

- [ ] **Step 2: The README**

In `## What it ships`, the `writing-clearly-and-concisely` bullet becomes:

```text
- `elements-of-style`: softaworks/agent-toolkit's `writing-clearly-and-concisely`,
  one skill, a subset entry at a pinned commit. The entry carries obra's plugin
  name so that upstream `brainstorming`'s line, _Use
  elements-of-style:writing-clearly-and-concisely skill if available_, names the
  skill this marketplace delivers. Installing obra's own `elements-of-style`
  beside it would give two skills of that name; the blocks here never install
  it.
```

`## What it depends on` becomes:

```text
`software-dev` depends on `mattpocock` and `elements-of-style`, so one install
on Claude Code brings all three. Each entry is pinned at one upstream commit,
and the watch reports when the upstream moves.
```

The blocks:

````markdown
```sh install-codex
codex plugin marketplace add eranroseman/agent-plugins && for p in software-dev mattpocock elements-of-style; do codex plugin add "$p@eranroseman"; done
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```
````

````markdown
```sh update-claude
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin update mattpocock@eranroseman
claude plugin update elements-of-style@eranroseman
claude plugin marketplace update superpowers-marketplace
claude plugin update superpowers@superpowers-marketplace
```
````

````markdown
```sh cleanup
claude plugin marketplace update eranroseman
claude plugin update software-dev@eranroseman
claude plugin install software-dev@eranroseman
claude plugin uninstall sensemaking@eranroseman
claude plugin uninstall superpowers@eranroseman
claude plugin uninstall writing-clearly-and-concisely@eranroseman
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
npx --yes skills remove codebase-design domain-modeling grill-with-docs grilling handoff improve-codebase-architecture prototype research resolving-merge-conflicts teach to-questionnaire triage wait-what wayfinder wizard working-with-claude-code writing-for-agents -g -y
find ~/.agents/skills -maxdepth 1 -type l -lname "$HOME/.local/share/software-dev/*" -delete
rm -rf ~/.local/share/software-dev
ls -d ~/.agents/skills/*.aside.* 2>/dev/null || true
codex plugin marketplace upgrade eranroseman
codex plugin remove sensemaking@eranroseman
for p in mattpocock elements-of-style; do codex plugin add "$p@eranroseman"; done
codex plugin marketplace add obra/superpowers && codex plugin add superpowers@superpowers-dev
```
````

The cleanup's uninstall bullet gains `writing-clearly-and-concisely@eranroseman`:

```text
- The uninstalls remove from Claude Code the plugins whose entries left the
  marketplace: `sensemaking`, whose two skills ship in `software-dev` now;
  `superpowers@eranroseman`, since superpowers now comes from obra's
  marketplace, which the next two lines install it from; and
  `writing-clearly-and-concisely@eranroseman`, whose skill `software-dev`'s
  update has just installed under the entry's new name, `elements-of-style`.
  On Codex no line removes `superpowers` or `writing-clearly-and-concisely`:
  both reached a converged machine through the script's links, which the
  `find` and `rm` remove, never as plugins.
```

The Codex bullet becomes:

```text
- The Codex `upgrade` is the update block's own first line, so the adds after
  it find the new entries; then `sensemaking` is removed there, the two entries
  are added, `mattpocock` new to the marketplace and `elements-of-style` under
  its new name, and the last line adds obra's superpowers, as the install
  block does.
```

In the Update prose, the sentence on a plugin the marketplace gains later names both entries, `mattpocock` and `elements-of-style`, as the ones this release adds.

Run: `bash tests/install-check.sh`
Expected: PASS: `claude plugin list` names `software-dev`, `mattpocock`, `elements-of-style` and `superpowers@superpowers-marketplace`; Codex shows `elements-of-style:writing-clearly-and-concisely`.

- [ ] **Step 3: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green. Cite `tests/results.tsv`.

```bash
git add .claude-plugin/marketplace.json plugins/software-dev/.claude-plugin/plugin.json tests/test-upstream.sh plugins/software-dev/skills/consistency-audit/SKILL.md README.md
git commit -m "Name the softaworks entry elements-of-style, so upstream brainstorming's pointer resolves"
```

### Task 5: `GLOSSARY.md`, the fork's port, and its qualified names (§17, §8.1; constraint 14; Q82, Q83, T11, T37, Q28)

**Files:**

- Rename: `CONTEXT.md` to `GLOSSARY.md`
- Modify: `AGENTS.md`, `docs/agents/domain.md`, `tests/test-vocabulary.sh`, `README.md` (Layout; the note for a scaffolded repository)
- Modify: the fork's `SKILL.md`, `domain.md`, `issue-tracker-github.md`, `issue-tracker-gitlab.md`, `issue-tracker-local.md`

**Interfaces:**

- Produces: `GLOSSARY.md`; the fork writes `GLOSSARY.md`; the fork's calls read `mattpocock:<name>`.
- Consumes: the `mattpocock` entry (Task 1).

- [ ] **Step 1: The rename, and every live reference**

```bash
cd /home/eranr/agent-plugins/.claude/worktrees/standalone-and-references
git mv CONTEXT.md GLOSSARY.md
```

No content edit (Q83). `AGENTS.md`, `### Domain docs`: the line's `CONTEXT.md` becomes `GLOSSARY.md`. `docs/agents/domain.md`: every `CONTEXT.md` becomes `GLOSSARY.md` and every `CONTEXT-MAP.md` becomes `GLOSSARY-MAP.md`, in the bullets, the two tree diagrams and the prose (ten occurrences). `README.md`'s Layout line becomes `GLOSSARY.md        the vocabulary: contested terms with their retired forms, and the leading words`. After the cleanup section's bullets, add a paragraph:

```markdown
A repository scaffolded before this release keeps its glossary as
`CONTEXT.md`, which upstream's `domain-modeling` no longer reads: it writes
`GLOSSARY.md` and would start a second glossary beside the old file. In each
such repository, run `git mv CONTEXT.md GLOSSARY.md`.
```

- [ ] **Step 2: The glossary joins the vocabulary scan (Q28)**

In `tests/test-vocabulary.sh`: `CONTEXT="$REPO_ROOT/CONTEXT.md"` becomes `GLOSSARY="$REPO_ROOT/GLOSSARY.md"`, and every `$CONTEXT` and `CONTEXT.md` in the file follows. The header's `Outside the scan: CONTEXT.md, whose subject is the retired forms, and docs/superpowers/` becomes `The glossary itself is scanned with its _Avoid_: lines left out, since their subject is the retired forms; outside the scan is docs/superpowers/`. `files="$(checked ':(exclude)CONTEXT.md' ':(exclude)docs/superpowers')"` becomes `files="$(checked ':(exclude)GLOSSARY.md' ':(exclude)docs/superpowers')"`, and inside the loop, after the `found=...` line, add:

```bash
  glossary_hits="$(grep -n -i -E "(^|[^[:alnum:]-])$form([^[:alnum:]-]|$)" "$GLOSSARY" | grep -v ':_Avoid_:' | sed 's#^#GLOSSARY.md:#' || true)"
  [ -z "$glossary_hits" ] || hits="$hits"$'\n'"$(printf '%s\n' "$glossary_hits" | sed "s/\$/  [$form]/")"
```

Red first: in the working tree, append the word payload to the definition line under `**additional context**:` of `GLOSSARY.md`. Expected FAIL `GLOSSARY.md:<line>: ... [payload]`. Revert.

Run: `bash tests/test-vocabulary.sh`
Expected: PASS, the count of owned files one higher.

- [ ] **Step 3: The fork's port of upstream's `v1.2.3..v1.3.1` diff (Q82)**

Each pair below is a line as it stands in the fork, then the line that replaces it; the fork's own sentences (its title, its explainer's skill list, its Section B rule, its file-pick rule, Section D, the block it writes) are not upstream's and stay. In the fork's `SKILL.md`:

```text
description: Configure this repo for the engineering skills — set up its issue tracker, triage label vocabulary, domain doc layout, and git convention. Run once before first use of the other engineering skills.
description: "Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, domain doc layout, and git convention. Run once before first use of the other engineering skills."
```

```text
- **Issue tracker** — where issues live (GitHub by default; local markdown is also supported out of the box)
- **Issue tracker**: where issues live (GitHub by default; local markdown is also supported out of the box)
```

```text
- **Triage labels** — the strings used for the five canonical triage roles
- **Triage labels**: the strings used for the five canonical triage roles
```

```text
- **Domain docs** — where `CONTEXT.md` and ADRs live, and the consumer rules for reading them
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the consumer rules for reading them
```

```text
- `git remote -v` and `.git/config` — is this a GitHub repo? Which one?
- `git remote -v` and `.git/config`: is this a GitHub repo? Which one?
```

```text
- `AGENTS.md` and `CLAUDE.md` at the repo root — does either exist? Is there already an `## Agent skills` section in either?
- `AGENTS.md` and `CLAUDE.md` at the repo root: does either exist? Is there already an `## Agent skills` section in either?
```

```text
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `GLOSSARY.md` and `GLOSSARY-MAP.md` at the repo root
```

```text
- `docs/agents/` — does this skill's prior output already exist?
- `docs/agents/`: does this skill's prior output already exist?
```

```text
- `.scratch` — sign that a local-markdown issue tracker convention is already in use
- `.scratch`: a sign that a local-markdown issue tracker convention is already in use
```

```text
- Monorepo signals — a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src`. Present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src`. These are present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.
```

```text
Summarize what's present and what's missing. Then take the sections in order — one section, one answer, then the next.
Summarize what's present and what's missing. Then take the sections in order. One section, one answer, then the next.
```

```text
**Section A — Issue tracker.**
**Section A: Issue tracker.**
```

```text
> Explainer: The "issue tracker" is where issues live for this repo. `triage` reads from and writes to it — it needs to know whether to call `gh issue create`, write a markdown file under `.scratch`, or follow some other workflow you describe. Pick the place you actually track work for this repo.
> Explainer: The "issue tracker" is where issues live for this repo. `triage` reads from and writes to it. It needs to know whether to call `gh issue create`, write a markdown file under `.scratch`, or follow some other workflow you describe. Pick the place you actually track work for this repo.
```

```text
- **GitHub** — issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitHub**: issues live in the repo's GitHub Issues (uses the `gh` CLI)
```

```text
- **GitLab** — issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **GitLab**: issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
```

```text
- **Local markdown** — issues live as files under `.scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Local markdown**: issues live as files under `.scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
```

```text
- **Other** (Jira, Linear, etc.) — ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose
- **Other** (Jira, Linear, etc.): ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose
```

```text
Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off** — leave it off and don't raise it; a user who wants external PRs in the triage queue can flip the flag in the file later.
Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off**. Leave it off and don't raise it: a user who wants external PRs in the triage queue can flip the flag in the file later.
```

```text
**Section B — Triage label vocabulary.** Section B always runs.
**Section B: Triage label vocabulary.** Section B always runs.
```

```text
The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is. Only if the user says no — usually because their tracker already uses other names (e.g. `bug:triage` for `needs-triage`) — collect the overrides so `triage` applies existing labels instead of creating duplicates.
The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is. Only if the user says no, usually because their tracker already uses other names (e.g. `bug:triage` for `needs-triage`), collect the overrides so `triage` applies existing labels instead of creating duplicates.
```

```text
**Section C — Domain docs.** Default to **single-context** — one `CONTEXT.md` + `docs/adr/` at the repo root. This fits almost every repo; write it without asking.
**Section C: Domain docs.** Default to **single-context** (one `GLOSSARY.md` + `docs/adr/` at the repo root). This fits almost every repo; write it without asking.
```

```text
Offer **multi-context** — a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files — only when exploration found monorepo signals. Then confirm which layout they want.
Offer **multi-context** (a root `GLOSSARY-MAP.md` pointing to per-context `GLOSSARY.md` files) only when exploration found monorepo signals. Then confirm which layout they want.
```

```text
**Section D — Git convention.** Default to **merge locally**. Ask which of the three this repo uses:
**Section D: Git convention.** Default to **merge locally**. Ask which of the three this repo uses:
```

```text
[one-line summary of layout — "single-context" or "multi-context"]. See `docs/agents/domain.md`.
[one-line summary of layout: "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

```text
- [issue-tracker-github.md](./issue-tracker-github.md) — GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md) — GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md) — local-markdown issue tracker
- [triage-labels.md](./triage-labels.md) — label mapping
- [domain.md](./domain.md) — domain doc consumer rules + layout
- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [triage-labels.md](./triage-labels.md): label mapping
- [domain.md](./domain.md): domain doc consumer rules + layout
```

```text
Tell the user the setup is complete and which engineering skills will now read from these files. Mention they can edit `docs/agents/*.md` directly later — re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.
Tell the user the setup is complete and which engineering skills will now read from these files. Mention they can edit `docs/agents/*.md` directly later; re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.
```

In the fork's `domain.md`, every `CONTEXT.md` becomes `GLOSSARY.md` and every `CONTEXT-MAP.md` becomes `GLOSSARY-MAP.md` (the two bullets, the two tree diagrams, the multi-context caption and the vocabulary paragraph), and four lines change punctuation:

```text
- **`CONTEXT-MAP.md`** at the repo root if it exists — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`GLOSSARY-MAP.md`** at the repo root if it exists: it points at one `GLOSSARY.md` per context. Read each one relevant to the topic.
```

```text
- **`docs/adr/`** — read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.
```

```text
If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).
If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).
```

```text
> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
```

In `issue-tracker-github.md`:

```text
Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.
Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone.
```

```text
GitHub shares one number space across issues and PRs, so a bare `#42` may be either — resolve with `gh pr view 42` and fall back to `gh issue view 42`.
GitHub shares one number space across issues and PRs, so a bare `#42` may be either: resolve with `gh pr view 42` and fall back to `gh issue view 42`.
```

and in its `**Blocking**` bullet the em dash after `**native issue dependencies**` becomes a comma and `(open blockers only — the live gate)` becomes `(open blockers only, the live gate)`; in its `**Claim**` bullet the em dash before `the session's first write` becomes a comma.

In `issue-tracker-gitlab.md`: in the `**Merge requests**` bullet, `etc. — the same shape as` becomes `etc., the same shape as`; the `Infer the repo` line takes a semicolon as github's does; in the `**Blocking**` bullet the em dash after `**native blocking link**` becomes a comma; in the `**Frontier query**` bullet the two em dashes around the parenthetical become a colon before it and a comma after it; in the `**Claim**` bullet the em dash becomes a comma as github's does.

In `issue-tracker-local.md`:

```text
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` — never a single combined tickets file
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
```

```text
- **Map**: `.scratch/<effort>/map.md` — the Notes / Decisions-so-far / Fog body.
- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
```

Upstream's `v1.3.1` explainer also names `to-spec` and `to-tickets`; the fork's names `triage` alone and stays, since the entry excludes both and the sibling-name check holds it.

- [ ] **Step 4: The fork's calls name the entry's skills (T11, T37)**

In each of the three issue-tracker templates, the first sentence of `## Wayfinding operations`:

```text
Used by `/wayfinder`.
Used by `mattpocock:wayfinder`.
```

In `issue-tracker-github.md` and `issue-tracker-gitlab.md`, the request-surface flag's note:

```text
`/triage` reads this flag.
`mattpocock:triage` reads this flag.
```

In the fork's `domain.md`:

```text
The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.
The `mattpocock:domain-modeling` skill (reached via `mattpocock:grill-with-docs` and `mattpocock:improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.
```

```text
(note it for `/domain-modeling`).
(note it for `mattpocock:domain-modeling`).
```

The backticked `triage` in `SKILL.md` names the skill rather than calling it and stays. The repository's own `docs/agents/domain.md` is a scaffolded copy, not a shipped text; it takes the glossary rename in Step 1 and keeps its bare calls.

Run: `bash tests/test-plugin-skills.sh && bash tests/test-upstream.sh && bash tests/test-links-resolve.sh && bash tests/test-vocabulary.sh && bash tests/test-spelling.sh`
Expected: PASS: every `mattpocock:` token resolves through the entry's list.

- [ ] **Step 5: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green. Cite `tests/results.tsv`.

```bash
git add -A GLOSSARY.md AGENTS.md docs/agents/domain.md tests/test-vocabulary.sh README.md plugins/software-dev/skills/setup-matt-pocock-skills
git commit -m "Follow upstream's GLOSSARY.md rename, port the scaffolder's upstream diff, and qualify its calls"
```

### Task 6: `consistency-audit`'s hedges and qualified names (§10.3; constraint 15; Q15, T12)

**Files:**

- Modify: `plugins/software-dev/skills/consistency-audit/SKILL.md`, `README.md` (one mark)

**Interfaces:**

- Produces: `consistency-audit` names `mattpocock:grilling`, `mattpocock:domain-modeling`, `superpowers:writing-plans` (six times) and, from Task 4, `elements-of-style:writing-clearly-and-concisely`; no `if available` outside `rethink-audit`'s hold.
- Consumes: Tasks 1, 3 and 4.

- [ ] **Step 1: The edits**

In `plugins/software-dev/skills/consistency-audit/SKILL.md`, each pair a line as it stands, then its replacement:

```text
9. **Transition to implementation** — invoke writing-plans
9. **Transition to implementation** — invoke superpowers:writing-plans
```

```text
- Run the `grilling` skill, if available — it owns the rounds method. Its question glyphs are optional; some agent CLIs reject them
- Run the `mattpocock:grilling` skill; it owns the rounds method. Its question glyphs are optional; some agent CLIs reject them
```

```text
Side effects happen inline as each answer lands — run the domain-modeling skill, if available, to keep the domain model current as you go:
Side effects happen inline as each answer lands — run the `mattpocock:domain-modeling` skill to keep the domain model current as you go:
```

```text
- Invoke the writing-plans skill to create a detailed implementation plan
- Invoke the superpowers:writing-plans skill to create a detailed implementation plan
```

```text
- Do NOT invoke any other skill. writing-plans is the next step — the execution skill it hands off to owns the worktree, the reviews, the gate, and finishing the branch
- Do NOT invoke any other skill. superpowers:writing-plans is the next step — the execution skill it hands off to owns the worktree, the reviews, the gate, and finishing the branch
```

In the `dot` graph under `## After the Audit`, the node label `"Invoke writing-plans skill"` becomes `"Invoke superpowers:writing-plans skill"` in all three places it appears.

`grep -c 'if available' plugins/software-dev/skills/consistency-audit/SKILL.md` prints 0; `rethink-audit`'s two hedges stay with its hold (§10.3). No test holds the rule (Q20).

`README.md`: the mark `(Task 6 names the skills consistency-audit uses)` becomes:

```text
It uses `elements-of-style:writing-clearly-and-concisely` for its report,
`mattpocock:grilling` for its question round and `mattpocock:domain-modeling`
for the rulings that land in the glossary.
```

Run: `bash tests/test-plugin-skills.sh && bash tests/install-check.sh`
Expected: PASS: the scan resolves the two `mattpocock:` names and the `elements-of-style:` name through the entries, and carves the `superpowers:` tokens out; the install job's `superpowers_references` finds `superpowers:writing-plans` in obra's installed set.

- [ ] **Step 2: Run the suite and commit**

Run: `bash scripts/format && bash tests/run.sh`
Expected: green. Cite `tests/results.tsv`.

```bash
git add plugins/software-dev/skills/consistency-audit/SKILL.md README.md
git commit -m "Qualify consistency-audit's cross-plugin references and drop its hedges"
```

### Task 7: The adhd bump (§9, #60)

**Files:**

- Modify: `vendored.json` (the adhd record's `sha`)

- [ ] **Step 1: Re-read the tip and compare the copy**

```bash
cd /home/eranr/agent-plugins/.claude/worktrees/standalone-and-references
tip="$(git ls-remote https://github.com/UditAkhourii/adhd.git refs/heads/main | cut -f1)"
D="${TMPDIR:-/tmp}/software-dev-upstream-UditAkhourii-adhd-tip"
rm -rf "$D" && mkdir -p "$D" && git -C "$D" init -q && git -C "$D" remote add origin https://github.com/UditAkhourii/adhd.git
git -C "$D" fetch -q --depth 1 origin "$tip" && git -C "$D" fetch -q --depth 1 origin 16dc239ff186b869372e75095cfa58fc0ee89927
git -C "$D" diff --stat 16dc239ff186b869372e75095cfa58fc0ee89927 "$tip" -- skills/adhd
printf '%s\n' "$tip"
```

Expected: an empty diff (`skills/adhd` was byte-identical at `7b91ce60` on 2026-10-17) and the tip's sha. If the diff is not empty, the bump is a copy as §12.3 says: re-copy `skills/adhd` into the plugin from the tip, restore the gate line as line 5 of `SKILL.md`, and keep the Codex policy file.

- [ ] **Step 2: Move the pin**

In `vendored.json`, the adhd record's `"sha"` becomes the tip printed above.

Run: `bash tests/test-upstream.sh && bash scripts/upstream-watch; echo "exit $?"`
Expected: the upstream test PASS; the watch exits 0 with `Everything matches. No action.`, every entry and record current (if mattpocock has cut a newer stable tag since Task 1, the watch exits 1 naming it, and Task 1's Step 1 is repeated for the new tag before the gate).

- [ ] **Step 3: Commit**

```bash
git add vendored.json
git commit -m "Move the adhd pin to main's tip; the copy is unchanged"
```

### Task 8: The version bump (§18 constraint 17; T43)

**Files:**

- Modify: `plugins/software-dev/.claude-plugin/plugin.json`, `plugins/software-dev/.codex-plugin/plugin.json`

- [ ] **Step 1: 0.8.0 to 0.9.0, both manifests**

In both manifests, `"version": "0.8.0"` becomes `"version": "0.9.0"`. A minor: the plugin loses `brainstorming` and the hook, takes `adhd` and `rethink-audit`, renames and fixes the scaffolder, fixes `finding-duplicate-functions`, re-copies `diagnosing-bugs` at `v1.3.1`, and edits `consistency-audit` and one line of `rethink-audit`. `sensemaking` takes no bump: its manifests are gone.

Run: `bash tests/test-references-resolve.sh && claude plugin validate --strict plugins/software-dev`
Expected: PASS.

- [ ] **Step 2: Commit**

```bash
git add plugins/software-dev/.claude-plugin/plugin.json plugins/software-dev/.codex-plugin/plugin.json
git commit -m "software-dev 0.9.0

Drops the brainstorming copy and the SessionStart hook, which obra's own
superpowers now provides; takes adhd and rethink-audit from the retired
sensemaking; renames the scaffolder to setup-matt-pocock-skills and fixes
its three recorded defects; fixes finding-duplicate-functions' run line;
re-copies diagnosing-bugs at mattpocock v1.3.1; qualifies
consistency-audit's cross-plugin references and repoints rethink-audit's
one dead pointer. Depends on mattpocock and elements-of-style."
```

A gate-time fix under `plugins/` moves this commit after it (§19).

### Task 9: `SECURITY.md` (§16.3; constraint 18; Q23)

**Human step first:** the maintainer enables private vulnerability reporting in the repository's Settings, under Security. The executor asks for it and waits; the file's first line is false until then.

**Files:**

- Create: `SECURITY.md`
- Modify: `README.md` (one Layout line)

- [ ] **Step 1: Read reporting back as enabled**

```bash
gh api repos/eranroseman/agent-plugins/private-vulnerability-reporting --jq .enabled
```

Expected: `true`. On `false`, stop and ask the maintainer; do not write the file.

- [ ] **Step 2: Write the file**

Create `SECURITY.md`:

```markdown
# Security

Report a vulnerability privately through this repository's Security tab, GitHub's private vulnerability reporting; never in a public issue.

A defect in a copied skill belongs to its upstream, which the plugin's LICENSE names. The upstream pins are declared in `vendored.json` and `.claude-plugin/marketplace.json`, and nowhere else.
```

In `README.md`'s Layout block, after the `AGENTS.md` line, add `SECURITY.md        how to report a vulnerability privately`.

```bash
git add SECURITY.md README.md
```

Staged first, since every check reads tracked files only: an unstaged new file is not linted, spelled or reference-checked, and the run would be green for the wrong reason.

Run: `bash scripts/format && bash tests/run.sh`
Expected: green (the new file is linted, spelled and reference-checked). Cite `tests/results.tsv`.

- [ ] **Step 3: Commit**

```bash
git add SECURITY.md README.md
git commit -m "Add SECURITY.md: report privately; a copied skill's defect belongs to its upstream"
```

### Task 10: The gate, the merge and the push (§19; constraint 19; T17, T30, Q17)

**Files:** none changed on the branch except by a gate-time fix. Three human steps: T17's observation, the push approval, and nothing else.

- [ ] **Step 1: The suite and CI**

The checks of `tests/test-upstream.sh` and `tests/lib.sh` that have never been seen red, each mutated in a scratch clone of the branch (every commit is in by now, so the clone holds the code under test), each run with `bash tests/test-upstream.sh` there, and the clone reset between them with `git checkout -- . && git clean -fdq`:

1. `strict`: the `mattpocock` entry's `strict` set to `true`. Expected FAIL `strict must be false`.
2. `version`: the entry's `version` set to `1.3.0`. Expected FAIL `version 1.3.0 is not upstream's 1.3.1`.
3. The tag peel: the entry's `sha` set to `24fe0ef7737efae15c87225755e9f6f5965e4888` with its last character changed. Expected FAIL `the tag v1.3.1 names 24fe0ef7737efae15c87225755e9f6f5965e4888, not the pinned ...`.
4. `fetch_pinned`'s HEAD assertion: the entry's `ref` left and its `sha` set to the tag object `0b6cee10f260a2e048279cf737bfd3e37b1fce0b` (`git ls-remote --tags https://github.com/mattpocock/skills.git refs/tags/v1.3.1` prints it). Expected FAIL from `fetch_pinned` naming the checkout's HEAD and `an annotated tag's object`, or from the peel check if the fetch itself is refused; either is red for the right reason.
5. The `added` rule: the `disable-model-invocation: true` line removed from `plugins/software-dev/skills/adhd/SKILL.md`. Expected FAIL `the declared addition 'disable-model-invocation: true' appears 0 times locally`.
6. The layout check's manifest half: the synthetic upstream of plan A's Task 8 Step 5 item 6, with a `pkg/.claude-plugin/plugin.json` added. Expected FAIL `a plugin manifest sits under pkg`. Its hooks half: `pkg/hooks/hooks.json` added instead. Expected FAIL `pkg/hooks/hooks.json exists at the pin`.
7. The duplicate basename: the synthetic upstream with `pkg/a/one/SKILL.md` and `pkg/b/one/SKILL.md`, both named `one`, and the entry listing `./a/one`. Expected FAIL `a basename holds more than one SKILL.md`.
8. The fork path: the superpowers-lab record's `forks` value set to `skills/nowhere`. Expected FAIL `began from skills/nowhere, which the pin no longer has`.
9. An exclusion without a reason: a line `nosuch` with an empty reason field added to `EXCLUSIONS["mattpocock"]`. Expected FAIL `the exclusion nosuch carries no reason`.
10. Listed and excluded: `grilling` added to `EXCLUSIONS["mattpocock"]` with a reason. Expected FAIL `grilling is both listed and excluded`.
11. `record_rows`' error branches (T24): a record `{"repo": "example/none", "trees": {}, "forks": {}}` added. Expected FAIL `0 subset entries pin example/none`. Then the `elements-of-style` entry's `source.url` set to mattpocock's. Expected FAIL `2 subset entries pin mattpocock/skills`. Then the adhd record's `sha` line deleted. Expected FAIL `carries one of ref and sha without the other`.
12. The sibling floor (added in Task 1): the mattpocock record given back a `ref` and `sha` (`v1.3.1`, `24fe0ef7737efae15c87225755e9f6f5965e4888`). Expected FAIL `no sibling name was checked`.

Record each red in the gate's notes, then discard the clone.

Run: `bash tests/run.sh`
Expected: `0 failed`, `tests/test-codex-validate.sh` run rather than skipped. Cite `tests/results.tsv`.

```bash
git push
gh run watch "$(gh run list --branch standalone-and-references --workflow validate --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: `validate` and `install` green; record the run id.

- [ ] **Step 2: The cleanup run over a machine the old script converged**

A scratch `HOME` converged by `eeed758`'s `bin/setup`, then moved to the branch tip with the README's `cleanup`, `update-claude` and `update-codex` blocks, as a user would, each extracted as the install job extracts its own. This is the first run of the cleanup block as written and of every removal line (§13.3).

````bash
cd /home/eranr/agent-plugins/.claude/worktrees/standalone-and-references
G="$(mktemp -d)"
export HOME="$G/home" CODEX_HOME="$G/home/.codex"
unset CLAUDE_CONFIG_DIR
mkdir -p "$CODEX_HOME"

# 1. Converge with eeed758's bin/setup: its Claude half from a directory
#    marketplace holding eeed758's tree, its Codex half from GitHub, whose
#    main still carries eeed758's bin/setup and marketplace files.
git worktree add -q "$G/old" eeed758
SD_MARKETPLACE_SOURCE="$G/old" bash "$G/old/bin/setup"
bash "$G/old/bin/doctor" # expected: clean but for the SKIP its staleness check prints for a directory marketplace

# 2. The directory marketplace now holds the branch tip.
git -C "$G/old" checkout -q --detach standalone-and-references

# 3. A bare clone of the branch tip, served over local smart-HTTP by
#    git http-backend, since `codex plugin marketplace upgrade` refuses a
#    local-path marketplace; the scratch config.toml is pointed at it.
git clone -q --bare . "$G/serve/agent-plugins.git"
git -C "$G/serve/agent-plugins.git" symbolic-ref HEAD refs/heads/standalone-and-references
mkdir -p "$G/cgi/cgi-bin"
cat >"$G/cgi/cgi-bin/git" <<EOF
#!/usr/bin/env bash
export GIT_PROJECT_ROOT="$G/serve" GIT_HTTP_EXPORT_ALL=1
exec "\$(git --exec-path)/git-http-backend"
EOF
chmod +x "$G/cgi/cgi-bin/git"
(cd "$G/cgi" && python3 -m http.server --cgi --bind 127.0.0.1 8418 >"$G/http.log" 2>&1 &)
sleep 1
git ls-remote http://127.0.0.1:8418/cgi-bin/git/agent-plugins.git refs/heads/standalone-and-references
python3 - "$CODEX_HOME/config.toml" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'(\[marketplaces\.eranroseman\][^\[]*?)source_type = "[^"]*"', r'\1source_type = "git"', s, flags=re.S)
s = re.sub(r'(\[marketplaces\.eranroseman\][^\[]*?)source = "[^"]*"', r'\1source = "http://127.0.0.1:8418/cgi-bin/git/agent-plugins.git"', s, flags=re.S)
open(p, 'w').write(s)
PY
grep -A4 '^\[marketplaces.eranroseman\]' "$CODEX_HOME/config.toml"

# 4. The README's blocks, in the order the README gives a converged machine.
for b in cleanup update-claude update-codex; do
  awk -v want="$b" '/^```/ { if (inblock) { inblock = 0; name = ""; next } inblock = 1; split($0, w, " "); name = w[2]; next } inblock && name == want { print }' README.md >"$G/$b.sh"
  printf '== %s ==\n' "$b"
  bash -euo pipefail "$G/$b.sh"
done

# 5. The assertions over that HOME.
bash tests/install-check.sh --assert
````

Expected: every block exits 0; `install-check.sh --assert` passes: the full skill sets of §14 on both agent CLIs, the two entries and obra's superpowers present on Codex, every `superpowers:` reference found, no catalogue name twice, and `claude plugin list` naming exactly `software-dev`, `mattpocock`, `elements-of-style` from `eranroseman` and `superpowers` from `superpowers-marketplace`. Record the output's summary lines. Then `kill %1` or the `http.server` process, `git worktree remove "$G/old"`, and `rm -rf "$G"`.

If a block's line fails, the failure is new information about a removal line no measurement has run (§13.3): fix the README's block on the branch, re-run from step 1, and move the version bump after the fix if a file under `plugins/` changed.

- [ ] **Step 3: #52's bare name (T17), the maintainer's observation**

The maintainer, in a signed-in scratch session with `software-dev` installed, tries a bare `/grilling` and a Skill-tool call by the bare name `grilling`, and a bare `/setup-matt-pocock-skills`, and records on #52 whether each reached `mattpocock:grilling` and `software-dev:setup-matt-pocock-skills`. The result does not stop the branch (Q42).

- [ ] **Step 4: #70's pre-check (Q17)**

```bash
git switch -c ubuntu-26-precheck standalone-and-references
sed -i 's/runs-on: ubuntu-latest/runs-on: ubuntu-26.04/' .github/workflows/validate.yml
printf 'self-hosted-runner:\n  labels:\n    - ubuntu-26.04\n' >.github/actionlint.yaml
git add .github/workflows/validate.yml .github/actionlint.yaml
git commit -m "Pre-check: run the validate workflow on ubuntu-26.04 (#70)"
git push -u origin ubuntu-26-precheck
gh run watch "$(gh run list --branch ubuntu-26-precheck --workflow validate --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Record the run id and any new annotation; then `git push origin --delete ubuntu-26-precheck && git switch standalone-and-references && git branch -D ubuntu-26-precheck`. Nothing from it merges; `ubuntu-latest` stays. A small failure is fixed on the branch; a large one is filed on #70.

- [ ] **Step 5: Merge and push, in one motion (human approval)**

With the maintainer's approval of the push:

```bash
git switch main
git fetch origin
git merge --ff-only standalone-and-references
git push origin main
```

Expected: a fast-forward (`main` has not moved; if it has, rebase the branch onto `main`, re-run `bash tests/run.sh`, and merge again). Record `main`'s new sha for the dispositions. The maintainer's own machine, cleaned up with the README's block after the push, is the first live run (§23).

### Task 11: The dispositions (§20; constraint 20)

**Files:** none. Every comment cites a commit on `main`; `M` below is `main`'s sha after Task 10, written as its short form, and `TAG` the mattpocock tag the entry landed on.

- [ ] **Step 1: Issues that close**

```bash
gh issue close 52 --comment "Closed by M: sensemaking retires into software-dev, the one plugin. What it was to share arrives through subset entries: the mattpocock skills through one entry, mattpocock, at TAG, named mattpocock:<skill> on both agent CLIs; writing-clearly-and-concisely through the entry it already had, renamed elements-of-style; adhd and rethink-audit move into software-dev. Overrides of this brief: no sensemaking to install on its own and no mp-* entry; superpowers no longer from this marketplace but from obra's own, which the README's blocks install; the bare-name criterion overridden (Q42), with the gate's observation recorded below; the update-path criterion met by the update block's install line, which installs the dependencies a release adds; wayfinder's and triage's /setup-matt-pocock-skills resolve, since the fork carries that name again; rethink-audit's bare research and codebase-design stay with its hold; the one-time cleanup for a machine converged before this release is the README's cleanup block, run at the gate; a repository scaffolded before this release runs git mv CONTEXT.md GLOSSARY.md, as the README says."
gh issue close 55 --comment "Moot at M: the placement table is deleted (Q44), a test for it is declined under the suite rule, archify is gone, and sensemaking and its placement rule retire (Q70)."
gh issue close 46 --comment "Resolved by naming at M (Q79). Correction to the brief: elements-of-style is obra's plugin, built from obra/the-elements-of-style. The entry that delivers softaworks' writing-clearly-and-concisely is now named elements-of-style, so upstream's line, in obra's own brainstorming, names a skill this marketplace delivers, with no copy and no declared change. Installing obra's own elements-of-style beside it is an accepted collision; the README's blocks never install it. The committed failure capture is declined: tests/results.tsv, gitignored and cited, is the proof, and the scan's permanent negative fixture is the durable one."
gh issue close 33 --comment "Declined at M under the suite rule: a test holds upstream drift or installability, never this repository's own wording or lengths. The 122 bound this would enforce is void: Codex's cut is a catalogue budget share, not a limit (#49)."
gh issue close 49 --comment "Closed at M. Correction to the brief: the allocator is openai/codex:codex-rs/ext/skills/src/render.rs, and skills.max_context_tokens arrives after 0.147.0. Every 122-character assertion and every 'so Codex shows it whole' clause is gone; adhd's description is upstream's again."
gh issue close 69 --comment "Closed at M: the watch's Codex section is deleted (Q80), and its pipe with it, unfixed. The install job holds the one thing the section held, that Codex finds the marketplace at .claude-plugin/marketplace.json; the hooks path and the manifest order are moot, since software-dev ships no hook."
gh issue close 68 --comment "Closed at M. Taken: the glossary joins the vocabulary scan (as GLOSSARY.md, its _Avoid_ lines left out); tests/test-runner.sh asserts the result file exists before reading it and credits fixture 4; the comment fixes landed with their files' rewrites. Moot, their files deleted: the saw() here-string, the lockfile wording, the grep -c captures, the duplicate-basename message, the node PATH comment, the doctor tests' comments, every ensure_cache, ensure_watch_fresh and report_only item, the kind check, fixture 11 and the freshness fixtures. Declined (spec §21): the registry shape guard, the empty CLI-version wording, the unit-separator rows, the --workflow-pins fixture (the mode is gone), the slashed-ref slug and the =1 fixture; the quoted uses: form (not valid Actions syntax); and the suite-authoring hazard of a capture without || true that ends a test with no FAIL line, whose bin/doctor instance left with that file and whose class is the ERR-trap decline's (spec §21)."
gh issue close 67 --comment "Moot at M: the freshness check, the token's one reader, is removed (Q3); the two steps that carried GITHUB_TOKEN left with setup-e2e; nothing reads it now, so neither option is needed."
gh issue close 30 --comment "Closed at M on the decision: no re-vendor script. The watch reports drift and every bump is manual, by the steps the drift line names. Its table of trees has become one record per upstream repository in vendored.json, three of them, and the skills taken as-is come from subset entries."
gh issue close 35 --comment "Closed at M: the root README has a License section. The two plugin-README items are moot, the file deleted (Q80) and its content under headings in the root README. The third item was fixed in 49fa7c7."
gh issue close 23 --comment "Closed at M, in the fork renamed setup-matt-pocock-skills: defect 1's six clauses deleted, defect 2's Design discipline paragraph hard-wrapped in the block and in AGENTS.md, defect 3's sentence added to step 4 with why it stays prose. No repository was re-passed. Corrections to the plan here: upstream v1.2.3 has no ### Git, so the fixed default it names is this repository's own; defect 1 has six sites, not five; the comment of 2026-09-06T17:00 argues diagnosing-bugs' wording from the 122 this branch voids."
gh issue close 36 --comment "Closed at M: SECURITY.md, three lines, after private vulnerability reporting was enabled. The issue's premise, a script run against a user's home directory, left with bin/setup; the workflows and the scripts the skills ship still justify the private channel."
gh issue close 47 --comment "Closed at M (Q21): no eval suite and no catalogue check. Where its four debts stand: #46's pointer resolves by naming; a dead qualified reference in shipped text is caught statically by tests/test-plugin-skills.sh, or for superpowers: by the install job; the 122 limit is void; #23's omission is fixed as text; diagnosing-bugs' overlap is accepted. A question that needs a measured run is answered in scratch and cited on its issue."
gh issue close 34 --comment "Closed at M, declined (Q22): no release tags and no version-bump detector. A bump commit's body says what changed, as 0.9.0's does."
gh issue close 73 --comment "Closed at M: tests/test-codex-validate.sh caches the validator under the user's cache directory, \${XDG_CACHE_HOME:-\$HOME/.cache}/software-dev, and refuses a cache the running user does not own (plan B, P17). The spec's /tmp wording was a location detail of the mechanism it rules; the maintainer may still move it."
```

- [ ] **Step 2: Issues that stay open, with a comment**

```bash
gh issue comment 60 --body "At M the one drifted pin left, adhd's, moved to main's tip, and superpowers' drift left with its entry: nothing here pins superpowers now. The watch closes this issue on its first clean run after the merge; nobody closes it by hand."
gh issue comment 70 --body "Pre-check run: <run id of Task 10 Step 4>, on ubuntu-26.04, <any new annotation, or none>. The install job replaced setup-e2e; the watch was not pre-checked. Every scheduled watch run from 2026-10-19 to 2026-10-23 ran on ubuntu-24.04 (image 20261012.334.1), so the close condition is the first scheduled runs whose log shows Image: ubuntu-26.04, not a date."
NEW_URL="$(gh issue create --title "Working habits for the agent: record on the tracker, resolve or incorporate, grill, ADRs, codebase-design" --label needs-triage --body "The asks 2 to 6 of #21's comment of 2026-09-08, moved here at M: record on the tracker every issue met beyond the current session; resolve an issue directly or incorporate it into a spec; use grilling when the user must supply more than a question or two, especially within brainstorming and writing-plans; record big decisions as ADRs, small accepted ones in the product design, and declined ones in the out-of-scope directory; use codebase-design while brainstorming and writing specs.")"
NEW="${NEW_URL##*/}"
gh issue edit 21 --title "The content of the block setup-matt-pocock-skills writes"
gh issue comment 21 --body "Retitled at M to Q38's follow-up. The surface table is stale: working-rules.md and using-superpowers.md left with the hook (Q78), and the 122 method note is void. The block and AGENTS.md are now kept in step by hand. The first of the asks of 2026-09-08 is answered by the glossary's 'historical artifact'; asks 2 to 6 move to #$NEW. Whether the rewrite keeps a test-first method is not ruled and stays here."
gh issue comment 48 --body "At M: route 1, skills.sh, is gone (Q58); a pick taken as-is comes from a subset entry, a route on both agent CLIs now, and a pick this repository changes is copied flat into software-dev under a record and test-upstream.sh (Q71); the recurring reason for changing a pick, 122 characters, is void; writing-clearly-and-concisely stays the subset entry it is, as elements-of-style (Q79); superpowers is no longer in this marketplace (Q78); mattpocock's pr and retro, new at v1.3.0 and never evaluated, join the candidates (Q85)."
gh issue comment 45 --body "Redirected to software-dev at M: its skill lands there, since sensemaking retires. Criteria 3 (a length-bound test), 6 (a test for the Codex-split sentence) and the last (committed transcripts) are dropped; the halt rule is decided here. Both target skills arrive through software-dev's dependencies, as elements-of-style:writing-clearly-and-concisely and mattpocock:writing-for-agents, named alike on both agent CLIs, so the brief's dependency is software-dev's already; the Codex naming split and its sentence go, as do the bin/setup prerequisite, the 122-character bound and the dated amendment to the layout spec. sensemaking 0.3.0 never ships; this targets the software-dev minor after 0.9.0."
gh issue comment 11 --body "Re-scoped at M (Q25, Q72): research-vault depends on software-dev, not sensemaking, and software-dev brings neither the SessionStart hook nor the superpowers process skills; research-vault's users install obra's superpowers themselves if they want it. What this repository owes is nothing beyond a README line there, 'install software-dev@eranroseman first'. The choice between a plugin listed in this marketplace and research-vault's own marketplace with a cross-marketplace dependency stays here. The question of 2026-09-06, which shared skills research-vault needs, is moot: software-dev's dependencies bring all eight the amendment named, beside wizard and writing-clearly-and-concisely; Codex still needs one codex plugin add per plugin."
```

- [ ] **Step 3: Closed issues whose record the branch reverses**

```bash
gh issue comment 24 --body "At M the freshness check this closed on (bd7fc25, hardened in fb9a216) is removed (Q3); the maintainer accepts GitHub's disabling of a schedule after 60 days without activity. An empty gh issue list --label upstream-drift again proves nothing; gh run list --workflow=upstream-watch.yml is the check."
gh issue comment 25 --body "At M the guarded deletion of orphaned Claude caches (51b5c37) is gone with bin/setup (Q48), after being reduced to a report-only NOTE (Q4). Measured 2026-09-28 on 2.1.273: a clean git-subdir install or update leaves no temporary clone; a killed install leaves a temp_subdir_*.clone of 136 to 280 KB that nothing sweeps; Claude Code marks replaced versions and removed marketplaces' caches .orphaned_at itself. The README's cleanup uninstalls the retired sensemaking, whose cache Claude Code then marks .orphaned_at."
gh issue comment 50 --body "At M the archify NOTE (14b9e96) left with bin/doctor, and archify left the repository (Q58), with the plugin README's paragraph on its variable."
gh issue comment 53 --body "At M the complement (75ed0ba) moved from skills.json and tests/test-skills-pin.sh into tests/test-upstream.sh, beside the mattpocock entry's list: twenty-two exclusions at TAG, twenty of them not adopted, each with its reason; adhd keeps none and the softaworks entry none, each with a reason; the obra-dev records went with the skill (Q67)."
gh issue comment 54 --body "At M the undeclared-install NOTE (14b9e96) left with bin/doctor, and skills.sh left the repository (Q58). The README's cleanup removes the seventeen skills.sh installs of skills the mattpocock entry now brings or this release drops, and leaves archify, developing-claude-code-plugins and any other alone (Q67)."
gh issue comment 56 --body "At M the outcome c70711f recorded changes shape: one record per upstream repository, three of them, with trees and forks and no kind (Q39, Q62, Q12); no header, PROVENANCE.md or LICENSE repeats the sha (Q1, Q47), and tests/test-upstream.sh compares every Copyright line of each upstream's LICENSE at the pin with the plugin LICENSE's section. 'Watch both' still stands, through the watch's branch-tip comparison."
gh issue comment 22 --body "At M: the closing record here cites a README-equals-usage test that 9725c8d had already removed, so nothing held the Codex update form. The README now states it: codex plugin marketplace upgrade eranroseman, and never a second marketplace add."
gh issue comment 62 --body "At M item 2's fix, tests/test-format-apply.sh, is removed: the format checks fail loudly when the formatter breaks, two of them naming scripts/format. Item 1 stands."
gh issue comment 43 --body "At M tests/test-hook.sh and the hook it held are deleted (Q78): software-dev ships no SessionStart hook, and upstream's own comes with obra's superpowers on Claude Code."
gh issue comment 14 --body "At M scripts/bump-superpowers is deleted (Q78): nothing here pins superpowers, so there is nothing to bump."
gh issue comment 15 --body "At M tests/test-vendored-scaffolder.sh is deleted: the scaffolder is a fork, held to upstream by nothing (Q32); its check that every upstream skill the files name is one an install delivers lives, widened, in tests/test-upstream.sh (T44)."
gh issue comment 2 --body "At M fetch_upstream is deleted with its last caller; fetch_pinned, which guards every git command and now asserts the checkout's HEAD, is what every pin is fetched with."
gh issue comment 63 --body "At M the hook test's shape checks left with the hook (Q78), and the duplicate check with bin/setup; the uniqueness check in tests/test-plugin-skills.sh holds the repository's own layout instead."
gh issue comment 6 --body "At M the hook test and its trap are gone with the hook (Q78); the permissions block, the marketplace line and the CLAUDE_PLUGIN_ROOT comment stand or went with their files."
gh issue comment 17 --body "At M bin/setup and its nine tests are deleted (Q48); the paths this named no longer exist. Installability is held by the install job, tests/install-check.sh, on both agent CLIs."
gh issue comment 59 --body "At M the reference check no longer scans documents under docs/superpowers (Q18): a spec or plan is a historical artifact, read as of its commit, and git history is its archive. The history tier this closed on still serves class 4, a two-segment path a move removed. Spec §4 records the supersession."
gh issue comment 41 --body "At M bin/setup is deleted (Q48), and the reported() brackets this closed on with it; the install job, tests/install-check.sh, fails on the first assertion that does not hold, never silently."
gh issue comment 16 --body "At M bin/setup and tests/test-setup-doctor.sh are deleted (Q48); the refusal this closed on has no script left to run."
gh issue comment 38 --body "At M tests/test-doctor-faults.sh is deleted with bin/setup (Q48); the fixture comment this closed on is gone."
gh issue comment 66 --body "At M bin/setup's ensure_cache is deleted with the script (Q48); the cache walk this closed on no longer exists, and Claude Code marks orphaned caches itself."
gh issue comment 31 --body "At M tests/test-vendored-adhd.sh is folded into tests/test-upstream.sh (T45); the wrap this closed on is in a deleted file."
gh issue comment 3 --body "At M tests/test-codex-validate.sh fetches both validator files itself from openai/codex at the pinned sha and checks their sha256 (Q69); CI's fetch step and the ~/.codex/skills/.system default are gone, so there is one source."
```

- [ ] **Step 4: Record the run**

Note on #52 the gate's T17 observation (Task 10, Step 3) and the cleanup run's summary lines (Task 10, Step 2). The branch is done when every command above has run and `gh issue list --state open` shows #70, #21, #48, #45, #11, #20, #19, #71, #72, #74, #75 and #60 (until the watch's first clean run), and the new issue.

## Self-review

- **Spec coverage, constraints 10 to 20 of §18:** 10 (Task 1), 11 (Task 2), 12 (Task 3), 13 (Task 4), 14 (Task 5), 15 (Tasks 4, 5 and 6; the carve-out was plan A's), 16 (the sibling-name check reads the entry from Task 1; uniqueness, named scripts and the name helper were plan A's), 17 (Task 8), 18 (Task 9), 19 (Task 10), 20 (Task 11). §9's adhd bump is Task 7. §16.2's License section and §16.3's file are Tasks 1 and 9. §17's documentation edits land in Tasks 1 to 6 and 9. §20's dispositions, open and closed, are Task 11, with the closed issues the search found.
- **Red-first list of §15.3, this plan's share:** the sibling-name check (Task 1), the vocabulary scan over the glossary (Task 5), the install job's superpowers check and whole-machine assertions (Task 3).
- **The README's blocks**, each version written in full: Task 1 (five entries, no obra lines), Task 2 (`sensemaking` gone, its two removal lines), Task 3 (superpowers gone, obra's lines in every block, the `superpowers@eranroseman` uninstall), Task 4 (`elements-of-style`, the `writing-clearly-and-concisely@eranroseman` uninstall), Task 5 (the glossary note). The final blocks equal §13.2's.
- **Names:** `EXCLUSIONS[mattpocock]` (Task 1), `superpowers_references` and `whole_machine` (Task 3), the `cleanup` block (Task 1, extended by 2, 3, 4), `GLOSSARY.md` (Task 5): each used under its defining task's name.
- **Human steps:** reporting enabled before Task 9; T17's observation and the push approval in Task 10.
