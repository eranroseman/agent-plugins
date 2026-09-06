# Roster, Adoption Routes, and the Retirement of Two Repositories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the four authored assets a plugin home, adopt three skills by the route each earns, curate one, drop one duplicated route, teach `bin/doctor` to see one skill name reaching two different skills, prove all of it on this machine, then delete `eranroseman/harness-backup` and `eranroseman/rethink` and empty both global instruction files.

**Architecture:** Nothing new is invented; every change lands in a mechanism sub-project 2 already ships. Skills that must change are vendored into a plugin with a provenance header, a drift test and a LICENSE notice, exactly as `brainstorming` and `setup-repository` are. A skill that needs no change is declared in `upstream/skills.json` (`archify`) or curated as a second `git-subdir` marketplace entry (`writing-clearly-and-concisely`), and `bin/setup` stops being superpowers-specific: it iterates every curated entry for its pinned clone, its symlinks, and its installed version. `bin/doctor` gains one derived, report-only check that hashes every route a harness loads a skill by. The machine is converged by the same `bin/setup`, proved by the same `bin/doctor`, and only then are the two repositories deleted, which is what makes the last paragraph of both global files false and lets them empty.

**Tech Stack:** bash (no `set -e` in the engine), jq, git, `sha256sum`, Claude Code CLI 2.1.263, codex-cli 0.147.0, `npx skills` (skills.sh), shellcheck, `gh`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md`. Section numbers below (§6.1, §10, …) refer to it. Its parent is `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md` §11 (sub-project 5, carrying the former sub-project 6). Sub-project 2's spec, `docs/superpowers/specs/2026-09-05-setup-and-drift-design.md`, is cited as "sub-project 2 §N"; its plan, `docs/superpowers/plans/2026-09-05-setup-and-drift.md`, is the house style this plan follows.

**One plan, not several.** The spec touches four subsystems, but §10's gate runs every one of them through one cutover on one machine, and the two deletions cannot precede the migration. Splitting would put the point of no return in a different document from the work it gates. Tasks 1 to 11 are ordinary repository work on a branch and touch nothing outside scratch directories. Tasks 12 to 15 act on this machine and on GitHub; each says where it stops for the user.

## Global Constraints

Verbatim from the spec unless marked. Every task's requirements implicitly include this section.

- **Versions.** Both `software-dev` manifests move `0.6.0` → `0.7.0`; both `sensemaking` manifests move `0.1.0` → `0.2.0` (Task 11). `tests/test-hook.sh` pins `software-dev`'s version in two assertions and moves with it.
- **Declared pins**, every one read from its source on 2026-09-06. `obra/superpowers` stays at `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`, version `6.3.0`. `mattpocock/skills` stays at tag `v1.2.3`, which peels to commit `6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`. `obra/superpowers-developing-for-claude-code` stays at `v0.3.1`. New: `tt-a1i/archify` at tag `v2.16.0` (tag object `fe2c0da92389bb35e9d71a9c7ae000c1083f2c37`, commit `c826e6c3a7abad19c0f3cd1ca57207d54b1ad8de`, the newest of its nineteen tags, one `SKILL.md` in the tree at `archify/SKILL.md`; the skill's own metadata reads `version: "2.16"`). `softaworks/agent-toolkit` at `3027f20f3181758385a1bb8c022d4041dfb4de84`, which is also its `main`, with an authored version `0.1.0`. `UditAkhourii/adhd` at commit `16dc239ff186b869372e75095cfa58fc0ee89927` (Deviation D2). `obra/superpowers-lab` at `51111f74f24058117752d9aa917cb19859f8ec86`, its `main`, where `finding-duplicate-functions`' two prompt templates are byte-identical to the fork's.
- **Descriptions.** `diagnosing-bugs`: `Use when a bug resists reproduction, or for a performance regression.` — 69 characters, verbatim from §6.1. `adhd`: `Parallel divergent ideation under five isolated cognitive frames, scored, clustered, deepened. Costs 5 to 10x one answer.` — 121 characters (Deviation D12). Codex truncates at 122 (§6.5); every vendored description is asserted under that by its drift test.
- **Paths.** Pinned clones live under `$HOME/.local/share/software-dev/upstream/<entry name>`: `superpowers` (unchanged) and `writing-clearly-and-concisely` (new). The symlink root is `$HOME/.agents/skills`; a curated skill's link target is `<clone>/<source.path>/<skill>`, so `…/upstream/superpowers/skills/writing-plans` and `…/upstream/writing-clearly-and-concisely/dist/plugins/writing-clearly-and-concisely/skills/writing-clearly-and-concisely`.
- **Which plugin holds a skill** (§4.1): `sensemaking` when the skill is shared by more than one product or is not about software development; `software-dev` only when both are false.
- **How a skill is adopted** (§5): skills.sh, then a curated entry, then vendoring; a skill is vendored **only when this marketplace must change it**, and a vendored skill is dropped from `upstream/skills.json` or it installs twice. `test-skills-pin.sh` asserts the negative for every vendored mattpocock skill.
- **When a skill is gated** (§5): when the decision to invoke is inherently the human's; never to paper over a routing failure. `adhd` and `consistency-audit` are gated; `diagnosing-bugs` and `finding-duplicate-functions` are not. A gated skill carries **both** gates: `disable-model-invocation: true` in `SKILL.md` for Claude and `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for Codex (sub-project 2 plan, Deviation D7). `tests/test-plugin-skills.sh` asserts the pair on every plugin skill.
- **Report, never repair** (§6.6). Duplicates and residue are `NOTE:` lines, not `FAIL:` (Deviation D6). Removing another marketplace's plugin is not the script's business.
- **Engine rules inherited from sub-project 2**, all still binding: never `--scope project` (§7.4); never re-run `codex plugin marketplace add` (§7.3); never delete a squatting file or link, move it aside (§7.4); setup never hand-edits a configuration file (§7.6), which is why `ARCHIFY_UPDATE_CHECK_DISABLED` is documented and not set (§6.3, Deviation D1); never chain `git clone … && git checkout …`; never compare `HEAD` against `origin/main`.
- **Codex removal order** (sub-project 2 §7.4): remove the plugin, then the marketplace, never the reverse — `codex plugin marketplace remove` leaves orphaned `[plugins.*]` tables silently. The same order on Claude.
- **Test idiom.** New tests source `tests/lib.sh`, use its `fail`, and are named `tests/test-*.sh`. Plain `grep` patterns only; a pattern that begins with `-` needs `-e`. `tests/lib.sh` is `set -euo pipefail`, so every capture of a deliberately failing command is `if out="$(…)"; then status=0; else status=$?; fi`, or `|| true` inside the substitution. `grep -q X && fail …` is safe under `set -e` (a failing non-final command in a `&&` list does not exit).
- **`shellcheck` must exit 0**, style and info findings included. No `.shellcheckrc`.
- **Every restricted-`PATH` fixture carries every tool the engine calls.** Task 10 adds `sha256sum` to the four lists (`test-doctor-faults.sh` BIN and BIN2, `test-setup-doctor.sh` NOJQ and BIN); the prior plan hit this class with `rm mv ln mkdir`.
- **Branch.** All repository work happens on `roster-and-retirement`, cut from `main`. Task 12 merges it to `main` and pushes before anything touches the machine, because `claude plugin marketplace update eranroseman` clones origin `main`, and auto-update is on for this marketplace, so a session started after the push may pull `0.7.0` on its own.
- **Commits** are plain prose ending with the executing agent's attribution trailer. The commands below carry `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`; substitute your own.
- **Irreversible steps stop for the user.** Every `rm -rf`, every `gh repo delete`, every `claude plugin uninstall` and `codex plugin remove` on this machine, and the emptying of the two global files, is preceded by a step that prints what is about to happen and waits for the user's explicit go. Tasks 1 to 11 run nothing against `$HOME` outside a `mktemp -d`.

### What was executed before this plan was written

None of the expected outputs below are predictions. On 2026-09-06 the whole repository half of this plan — Tasks 1 to 10 minus the READMEs and version bumps — was assembled in a scratch copy of this checkout and `tests/run.sh` passed all eighteen tests there, network on, including the two engine fixtures against the generalised `bin/setup`. The code in the steps below is that code, verbatim.

Measured, and load-bearing:

- **`claude plugin update` does not install a newly declared dependency.** In a scratch `HOME` on claude 2.1.263: install `software-dev` 0.6.0 from a directory marketplace, declare the `writing-clearly-and-concisely` entry and add it to `dependencies`, bump to 0.7.0, `claude plugin marketplace update eranroseman`, `claude plugin update software-dev@eranroseman` → "updated from 0.6.0 to 0.7.0", and `installed_plugins.json` still lists three plugins. `claude plugin install writing-clearly-and-concisely@eranroseman --scope user` then installs it at `0.1.0`, into `cache/eranroseman/writing-clearly-and-concisely/0.1.0/skills/writing-clearly-and-concisely/`, 216 KB, and `claude plugin details` lists one skill. This is why Task 9's `ensure_claude` installs a missing curated entry by name (Deviation D5).
- **`claude plugin update` does move an auto-installed dependency.** Same scratch `HOME`: `sensemaking` was installed as a dependency (`"auto": true` in the registry), the copy's manifest was bumped to `0.2.0`, `marketplace update`, then `claude plugin update sensemaking@eranroseman` → "updated from 0.1.0 to 0.2.0". Task 9's `sensemaking` block rests on this, and the upgrade fixture now exercises it on every run.
- **`claude plugin marketplace remove` leaves the cache behind, every version of it.** Same scratch `HOME`: after `uninstall software-dev@eranroseman` and `marketplace remove eranroseman`, `cache/eranroseman/` still held `sensemaking/0.1.0`, `sensemaking/0.2.0`, `software-dev/0.6.0` and `superpowers/6.3.0`. Issue #25's `superpowers-dev` residue is this mechanism, and Task 12's two marketplace removals will produce two more, which Task 12 removes before the gate.
- **A plugin agent is not reachable by its bare name.** `Agent(subagent_type: "cavecrew-investigator")` on this machine fails with `Agent type 'cavecrew-investigator' not found. Available agents: caveman:cavecrew-builder, caveman:cavecrew-investigator, …`. The inspector becomes `software-dev:consistency-audit-inspector` and the skill dispatches it by that name (Deviation D3).
- **Both validators, run against the assembled plugins.** `claude plugin validate --strict` passes on `software-dev` with an `agents/` directory and on `sensemaking` with `adhd`. Codex's `validate_plugin.py` emits exactly three bullets across both: ``skill `consistency-audit` frontmatter field `disable-model-invocation` must be false``, the same for `setup-repository`, and the same for `adhd`. Task 3 and Task 5 record them.
- **The prototype `bin/doctor` on this machine**, non-OK lines, before any machine change: four `FAIL:` lines that are exactly the not-yet-converged state (the `writing-clearly-and-concisely` clone, its link target, its plugin, and the marketplace clone being behind origin), and these `NOTE:` lines: the telemetry variable, auto-update, the eighteen redundant Codex links, `Claude: skill brainstorming resolves to 2 different trees: …/cache/eranroseman/superpowers/6.3.0/brainstorming (74edf03ea6d2), …/cache/eranroseman/software-dev/0.6.0/skills/brainstorming (4a2033c06acf)`, `Codex: no skill name resolves to more than one tree`, and `plugin cache for an unregistered marketplace: /home/eranr/.claude/plugins/cache/superpowers-dev (left alone; remove it by hand)`. The first cut of the check, pooled across harnesses, also fired seven times on `caveman`, whose Claude copy is a pinned 2026-08-10 cache and whose Codex copy tracks upstream `main`; that is Deviation D7's evidence.
- **The prototype `bin/upstream-watch`**, run live with the third skills.sh source declared: every pin reported current, `tt-a1i/archify` at `v2.16.0` "the newest tag", exit 0. The old filter, fed archify's real tag list plus `v2.17.0-dev.1`, picks the dev tag; the new one picks `v2.16.0`. Through the new filter `mattpocock/skills` → `v1.2.3`, `obra/superpowers-developing-for-claude-code` → `v0.3.1`, `obra/superpowers` → `v6.3.0`.
- **`UditAkhourii/adhd`'s tag `v0.1.4` is not the text the spec read.** The tag dates from 2026-05-30 and its `SKILL.md` carries a nineteen-line "When to trigger (summary)" section that `HEAD` (`16dc239`, 2026-08-29) has dropped; the plugin manifest arrived at `3d9dc48` on 2026-08-05, after the tag. The spec's quotations match `HEAD`.
- **`dist/plugins/writing-clearly-and-concisely/skills/writing-clearly-and-concisely` equals `skills/writing-clearly-and-concisely`** at `3027f20f3181`, `diff -r` clean, eight files. Upstream ships no plugin manifest under `dist/` and no version anywhere.
- **`git ls-remote --tags <repo> 'refs/tags/v1.2.3^{}'`** prints the peeled commit on its own line, so a test can assert a tag still peels to a recorded sha without a fetch.

Three defects were found that way and are already fixed in the text below: `python3 -m py_compile` writes a `__pycache__` into the vendored skill tree, which the same test's file-set assertion then counts on its second run, so the fork test parses with `ast` instead; the fault fixture's `'pinned clone is at'` pattern no longer matches once the line names its entry; and the qualified-reference check has to accept `<plugin>:<agent>` as well as `<plugin>:<skill>`.

### Deviations from the spec, decided while planning

Visible choices, not silent ones. Each names what changes if it is vetoed.

- **D1. `bin/setup` does not set `ARCHIFY_UPDATE_CHECK_DISABLED`.** §10 step 5 says it does; §6.3 rules it out at length, because setting it "contradicts §7.6 of sub-project 2, which deliberately does not set the telemetry variable because a network-behaviour decision belongs to the operator", and lands on a README instruction "chosen knowingly and provisionally". §6.3 is the reasoned section and §10 the summary, so §6.3 wins and Task 1 corrects the §10 line in the spec itself. Veto: keep step 5 as written, which reopens sub-project 2 §7.6.
- **D2. `adhd` is pinned at commit `16dc239ff186b869372e75095cfa58fc0ee89927`, not at tag `v0.1.4`.** The tag predates the text the spec quotes and the plugin manifest the spec describes (see the measurements above). The provenance header says so. Veto: pin the tag and re-vendor its older `SKILL.md`, whose extra trigger section is the collision the gate exists to dissolve.
- **D3. `consistency-audit` changes in three places, not one.** §7.1 names one change, deleting `permissionMode`, and separately requires the skill to "state that degradation in its own text". Two more are forced by measurement: the two dispatch references become `software-dev:consistency-audit-inspector`, because the bare name does not resolve for a plugin agent, and one bullet is added under "Reading the corpus" stating the Codex degradation. `tests/test-plugin-skills.sh` pins all three. Veto on the name: keep the bare name and the skill dispatches nothing on Claude.
- **D4. The two hand-copied agent files are removed at the cutover.** `~/.claude/agents/consistency-audit-inspector.md` and `~/.codex/agents/consistency-audit-inspector.md` are byte-identical copies of the backup's file, not symlinks, so §8.3's blast radius omits them and the deletion leaves them behind. On Claude the copy would sit beside the plugin's agent under two names. Task 12 removes both after the plugin loads, with the user's go. Veto: keep the Codex copy, accepting a hand-maintained file that no declaration describes.
- **D5. `writing-clearly-and-concisely` is a declared dependency of `software-dev`, `bin/setup` installs a missing curated entry by name, and the Codex `agent-toolkit` plugin and marketplace go too.** §6.4 says "curated beside `sensemaking`" and "Codex gains the skill through `bin/setup`'s symlinks or not at all". Beside `sensemaking` means: in `dependencies`, so a fresh install pulls it; and since `claude plugin update` does not install a new dependency (measured), the engine installs it on an existing machine. On Codex the same skill is installed today from the `agent-toolkit` marketplace at an unpinned `local` version; once the pinned symlink exists that copy is the second route the spec's rule forbids, so Task 12 removes it in the documented order. Veto: drop the dependency and install the entry only by hand, or keep the Codex plugin and accept an unpinned duplicate the doctor will report the day upstream moves.
- **D6. Duplicate findings and unregistered caches are `NOTE:` lines.** A `FAIL:` would make "`bin/doctor` reports clean" unreachable: §6.6 itself names the vendored `brainstorming` against upstream's copy as a survivor "by design". So the check reports and the gate in Task 12 enumerates the exact `NOTE:` lines a correct machine prints and rejects any other. Veto: make them `FAIL:` and teach the check to read each marketplace entry's `skills` allowlist so the by-design pair is excluded.
- **D7. Pools are per harness.** §6.6 says "one name resolving to two different trees"; the first implementation pooled both harnesses and fired seven times on `caveman`, whose two copies are different upstream versions — a different, milder thing than the D1 incident, where one session held two skills under one name. The Claude pool is `~/.claude/skills`, `~/.agents/skills` and each Claude plugin's install path; the Codex pool is `~/.codex/skills`, `~/.agents/skills` and each Codex plugin's cache directory. Veto: one pool, and seven standing notes on this machine.
- **D8. The unregistered-cache rule is Claude-only.** §6.6 measured it on Claude. Codex's cache holds `openai-curated-remote`, which no `codex plugin marketplace list` line names and which is the CLI's own; the rule would misfire there on every machine. Veto: extend it to Codex with an allowlist for the built-in pair.
- **D9. `bin/upstream-watch` watches every `git-subdir` entry, and gains a `--newest-stable-tag` mode.** The spec asks only that the prerelease filter widen. A second curated entry is a second declared pin, and sub-project 2 §6 says the watch "compares the declared pins"; leaving one out would be the one silent gap. The stdin mode exists so the filter is asserted in `tests/test-setup-doctor.sh` without the network. Veto: hardcode superpowers and drop the mode.
- **D10. The `setup-matt-pocock-skills` note in `report_only` stays.** §6.6 reads as if the derived check replaces it; it cannot, because that case is a rename and a by-name check never sees it.
- **D11. `harness-backup`'s historical spec is archived to `docs/archive/2026-08-08-harness-update-design.md` in this repository**, with a two-line provenance note, because this repository holds the mechanisms that replaced the detector it designed. §8.2 says "archived" and names no destination. Veto: research-vault's `docs/`.
- **D12. `adhd`'s description is rewritten here.** §6.2 gates it and §6.5 says the truncation is "fixed incidentally" for skills adapted anyway. The text in Global Constraints describes and never triggers: it drops "brainstorm/ideate intents", "open-ended design, architecture" and "fuzzy-debugging decisions", the three claims that collide with `software-dev:brainstorming` and `systematic-debugging`.
- **D13. `diagnosing-bugs`' pin is tied to `upstream/skills.json`'s mattpocock ref by test.** Both come from `mattpocock/skills`; `tests/test-vendored-diagnosing-bugs.sh` fails if the two refs differ, so a bump moves the vendored copy and the installed set together.
- **D14. `tests/lib.sh` gains `fetch_pinned <url> <sha> <dir>`**, and `fetch_upstream` becomes its superpowers caller. Four new tests and one fixture need a shallow fetch of a second, third and fourth repository at a sha; one guarded implementation replaces four copies.

---

## File Structure

```text
plugins/sensemaking/
├── README.md                                Tasks 1, 5, 11: the §4.1 rule and §4.2 table; the skill list
├── .claude-plugin/plugin.json               Task 11: 0.2.0
├── .codex-plugin/plugin.json                Task 11: 0.2.0
├── LICENSE                                  Task 5: an adhd provenance block
├── skills/rethink-audit/SKILL.md            Task 2: one reference repointed
└── skills/adhd/                             Task 5: vendored, SKILL.md + agents/openai.yaml
plugins/software-dev/
├── README.md                                Tasks 7, 11: the archify variable; what it ships
├── .claude-plugin/plugin.json               Tasks 8, 11: a third dependency; 0.7.0
├── .codex-plugin/plugin.json                Task 11: 0.7.0
├── LICENSE                                  Tasks 4, 6: two provenance blocks
├── agents/consistency-audit-inspector.md    Task 3: the inspector, minus permissionMode
├── skills/consistency-audit/                Task 3: SKILL.md (three edits) + agents/openai.yaml
├── skills/finding-duplicate-functions/      Task 4: the fork, six files, header added
└── skills/diagnosing-bugs/                  Task 6: vendored, three files, description rewritten
.claude-plugin/marketplace.json              Tasks 8, 11: the curated writing entry; descriptions
upstream/skills.json                         Task 7: a third source, archify
bin/setup                                    Tasks 9, 10: curated-entry loops; the duplicate check
bin/upstream-watch                           Task 7: the stable-tag filter; every curated entry
README.md                                    Task 11: four entries, the Checks list
docs/superpowers/specs/2026-09-06-…-design.md  Tasks 1, 12, 15: §10 step 5; gate results
docs/archive/2026-08-08-harness-update-design.md  Task 14: archived from harness-backup
tests/lib.sh                                 Task 4: fetch_pinned
tests/test-plugin-skills.sh                  Tasks 2, 3: cross-cutting invariants over every plugin skill
tests/test-vendored-duplicates.sh            Task 4
tests/test-vendored-adhd.sh                  Task 5
tests/test-vendored-diagnosing-bugs.sh       Task 6
tests/test-curated-writing.sh                Task 8
tests/test-doctor-duplicates.sh              Task 10
tests/test-codex-validate.sh                 Tasks 3, 5: the known-bullet set
tests/test-skills-pin.sh                     Tasks 6, 7: the negative for diagnosing-bugs; 19
tests/test-doctor-faults.sh                  Tasks 9, 10: a seeded second clone; sha256sum
tests/test-setup-doctor.sh                   Tasks 7, 9, 10: the filter assertion; the seeded clone; sha256sum
tests/test-hook.sh                           Task 11: 0.7.0
```

---

### Task 1: Cut the branch, state the placement rule, and correct the spec's own contradiction

**Files:**
- Modify: `plugins/sensemaking/README.md`
- Modify: `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` (§10 step 5)

**Interfaces:**
- Consumes: nothing.
- Produces: the branch every later task commits to; the README section Task 5 and Task 11 extend.

- [ ] **Step 1: Cut the branch and confirm the suite is green**

```bash
cd /home/eranr/agent-plugins
git checkout main && git pull --ff-only origin main
git checkout -b roster-and-retirement
bash tests/run.sh
```

Expected: twelve `PASS` lines, exit 0. If not, stop and report; nothing below assumes a red suite.

- [ ] **Step 2: Write the rule and the standing classification into the sensemaking README**

Replace the whole of `plugins/sensemaking/README.md` with:

```markdown
# sensemaking

Skills shared by `software-dev` and, later, `research-vault`.

## Which plugin holds a skill

A skill belongs to `sensemaking` when **either** is true: it is **shared** by
more than one product, or it is **not about software development**. It goes
to `software-dev` only when both are false — its subject is software, and
only that product needs it.

Sensemaking is the organisational and information-science term: turning a
confused situation into one people can act on together — noticing what does
not fit, naming it, and closing the gap between what someone knows and what
they need to know. **It is not a synonym for reading, analysis, or
documentation.** `consistency-audit` reads a repository's corpus and its
configuration from `docs/agents/`; `setup-repository` declares a
repository's conventions. Both are about software and both live in
`software-dev`, whatever a "reading versus building" split would suggest.

The rule is applied in advance to every skill `upstream/skills.json`
declares, so the day one of them needs a change its placement is already
settled and is not relitigated under deadline. Nothing moves on this table
until a skill must change; a skill is copied into a plugin only then.

| Plugin | Skills |
| --- | --- |
| **sensemaking** | `grilling` · `research` · `wayfinder` · `handoff` · `teach` · `to-questionnaire` · `wait-what` · `writing-for-agents` |
| **software-dev** | `codebase-design` · `domain-modeling` · `grill-with-docs` · `improve-codebase-architecture` · `prototype` · `resolving-merge-conflicts` · `triage` · `wizard` · `developing-claude-code-plugins` · `working-with-claude-code` |

`grill-with-docs` and `domain-modeling` sit with the code because both
maintain ADRs and a glossary — project artifacts, not general ones.
`writing-for-agents` is product-neutral.

## Skills

- `rethink-audit`: clean-slate redesign audit of an existing module, service,
  or feature. Design and architecture only; it applies no changes.

## Install

Claude Code: installing `software-dev@eranroseman` pulls this plugin
in as a dependency. To install it alone:

    claude plugin marketplace add eranroseman/agent-plugins
    claude plugin install sensemaking@eranroseman

Codex has no dependency concept, so install it explicitly:

    codex plugin marketplace add https://github.com/eranroseman/agent-plugins.git
    codex plugin add sensemaking@eranroseman

## License

MIT. See `LICENSE`.
```

- [ ] **Step 3: Correct §10 step 5 in the spec**

In `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md`, the line beginning `5. `diagnosing-bugs` vendored into `software-dev`` contains the clause `` `ARCHIFY_UPDATE_CHECK_DISABLED=1` set by `bin/setup` ``. Replace that clause with:

```
`ARCHIFY_UPDATE_CHECK_DISABLED` documented in the plugin README and not set by `bin/setup` (§6.3)
```

so the step reads `…; `archify` declared in `upstream/skills.json` at `v2.16.0`; `ARCHIFY_UPDATE_CHECK_DISABLED` documented in the plugin README and not set by `bin/setup` (§6.3); `test-skills-pin.sh` count to 19; …`.

- [ ] **Step 4: Verify**

```bash
grep -c 'A skill belongs to `sensemaking` when \*\*either\*\* is true' plugins/sensemaking/README.md
grep -c 'set by `bin/setup`' docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md
grep -c 'documented in the plugin README and not set by `bin/setup` (§6.3)' docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md
```

Expected: `1`, `0`, `1`.

- [ ] **Step 5: Commit**

```bash
git add plugins/sensemaking/README.md docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md
git commit -m "$(cat <<'EOF'
State which plugin holds a skill, and fix the spec's step 5

The sensemaking README carries the rule from spec section 4.1 and the
standing classification from 4.2, because an earlier pass placed two skills
wrongly for want of the rule being written anywhere.

Spec section 10 step 5 said bin/setup sets ARCHIFY_UPDATE_CHECK_DISABLED;
section 6.3 rules that out and lands on a README instruction. The reasoned
section wins.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Repoint rethink-audit, and add the cross-cutting plugin-skills test

**Files:**
- Modify: `plugins/sensemaking/skills/rethink-audit/SKILL.md:82`
- Create: `tests/test-plugin-skills.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `tests/test-plugin-skills.sh`, which every later task that adds a plugin skill must keep green. Task 3 appends its consistency-audit block. Its qualified-reference check resolves `superpowers:<s>` against the curated list, and `software-dev:<s>` / `sensemaking:<s>` against `plugins/<p>/skills/<s>/SKILL.md` **or** `plugins/<p>/agents/<s>.md`.

- [ ] **Step 1: Write the failing test**

Create `tests/test-plugin-skills.sh`:

```bash
#!/usr/bin/env bash
# Invariants over every skill the two plugins ship, plus the shape of the
# authored assets that have no upstream to drift from. Each is a mechanism
# for a rule that would otherwise live in prose:
#   - a gated skill carries both gates, the field Claude reads and the yaml
#     policy Codex reads, never one without the other;
#   - every <plugin>:<skill> reference in a SKILL.md resolves to something an
#     install actually gets, so a repointed or vendored skill cannot leave a
#     dangling name behind (the class of superpowers:brainstorming, which the
#     curated entry excludes);
#   - the rethink stub exists in neither plugin.
# Needs no network.
. "$(dirname "$0")/lib.sh"

curated="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
checked=0

for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
  plugin="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$skill")"
  md="$skill/SKILL.md"
  [ -f "$md" ] || fail "$plugin/skills/$name has no SKILL.md"
  checked=$((checked + 1))

  # Gates travel as a pair.
  claude_gated=false; codex_gated=false
  grep -qx 'disable-model-invocation: true' "$md" && claude_gated=true
  [ -f "$skill/agents/openai.yaml" ] && grep -qx '  allow_implicit_invocation: false' "$skill/agents/openai.yaml" && codex_gated=true
  [ "$claude_gated" = "$codex_gated" ] \
    || fail "$plugin:$name is gated on one harness only (Claude $claude_gated, Codex $codex_gated); each gated skill carries both"

  # Qualified references resolve.
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    p="${ref%%:*}"; s="${ref#*:}"
    case "$p" in
      superpowers)
        printf '%s\n' "$curated" | grep -qxF -- "$s" \
          || fail "$plugin:$name names $ref, which the curated superpowers entry does not list" ;;
      software-dev|sensemaking)
        # A skill, or a plugin agent, which resolves by the same prefix.
        [ -f "$REPO_ROOT/plugins/$p/skills/$s/SKILL.md" ] || [ -f "$REPO_ROOT/plugins/$p/agents/$s.md" ] \
          || fail "$plugin:$name names $ref, which $p ships neither as a skill nor as an agent" ;;
    esac
  done < <(grep -o '\b\(superpowers\|software-dev\|sensemaking\):[a-z][a-z0-9-]*' "$md" | sort -u)
done
[ "$checked" -ge 3 ] || fail "expected at least 3 plugin skills, found $checked"

[ ! -e "$REPO_ROOT/plugins/sensemaking/skills/rethink" ] || fail "the rethink stub must not ship in sensemaking"
[ ! -e "$REPO_ROOT/plugins/software-dev/skills/rethink" ] || fail "the rethink stub must not ship in software-dev"

# rethink-audit: the one repointed reference.
RA="$REPO_ROOT/plugins/sensemaking/skills/rethink-audit/SKILL.md"
grep -q 'software-dev:brainstorming' "$RA" || fail "rethink-audit does not name software-dev:brainstorming"

printf 'plugin-skills: %s skills checked; gates paired, references resolve, rethink absent\n' "$checked"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-plugin-skills.sh`
Expected: `FAIL: sensemaking:rethink-audit names superpowers:brainstorming, which the curated superpowers entry does not list`, exit 1. (Line 82 of the skill names the excluded skill; the SessionStart hook makes the same repoint at `using-superpowers:30`.)

- [ ] **Step 3: Repoint the one reference**

```bash
sed -i 's/`superpowers:brainstorming`/`software-dev:brainstorming`/' plugins/sensemaking/skills/rethink-audit/SKILL.md
grep -n 'brainstorming' plugins/sensemaking/skills/rethink-audit/SKILL.md
```

Expected: exactly one line, `82:  known job — `software-dev:brainstorming` elicits them in dialogue first, and`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-plugin-skills.sh`
Expected: `plugin-skills: 3 skills checked; gates paired, references resolve, rethink absent`, exit 0. The three are `brainstorming`, `setup-repository` and `rethink-audit`; `setup-repository` is the one gated skill and carries both gates already.

- [ ] **Step 5: Commit**

```bash
git add plugins/sensemaking/skills/rethink-audit/SKILL.md tests/test-plugin-skills.sh
git commit -m "$(cat <<'EOF'
Repoint rethink-audit at software-dev:brainstorming

The curated superpowers entry excludes brainstorming, so
superpowers:brainstorming resolves to nothing in this marketplace; the
narrowed copy ships as software-dev:brainstorming. Same class of dangling
reference the SessionStart hook already repairs at using-superpowers:30.

The new test makes the class mechanical: every qualified reference in every
plugin skill must resolve, and every gated skill must carry both harnesses'
gates, not one.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: consistency-audit and its inspector, into software-dev

**Files:**
- Create: `plugins/software-dev/skills/consistency-audit/SKILL.md` (from `~/harness-backup/claude/skills/consistency-audit/SKILL.md`, three edits)
- Create: `plugins/software-dev/skills/consistency-audit/agents/openai.yaml`
- Create: `plugins/software-dev/agents/consistency-audit-inspector.md` (from `~/harness-backup/claude/agents/consistency-audit-inspector.md`, one line removed)
- Modify: `tests/test-plugin-skills.sh` (append one block)
- Modify: `tests/test-codex-validate.sh` (the known-bullet set)

**Interfaces:**
- Consumes: Task 2's test.
- Produces: the agent at `plugins/software-dev/agents/`, which Claude discovers from that directory with no manifest key and exposes as `software-dev:consistency-audit-inspector`.

- [ ] **Step 1: Append the failing assertions to the plugin-skills test**

Insert this block into `tests/test-plugin-skills.sh` immediately before its final `printf 'plugin-skills: …'` line, and change that line's text to `'plugin-skills: %s skills checked; gates paired, references resolve, rethink absent, inspector shipped\n'`:

```bash
# consistency-audit and its inspector.
CA="$REPO_ROOT/plugins/software-dev/skills/consistency-audit/SKILL.md"
AG="$REPO_ROOT/plugins/software-dev/agents/consistency-audit-inspector.md"
[ -f "$CA" ] || fail "missing $CA"
[ -f "$AG" ] || fail "missing $AG"
grep -qx 'disable-model-invocation: true' "$CA" || fail "consistency-audit must be user-invoked on Claude"
[ "$(sed -n 2p "$AG")" = "name: consistency-audit-inspector" ] || fail "the inspector's name changed"
grep -qx 'tools: Read, Bash, WebFetch, WebSearch' "$AG" || fail "the inspector's tool grant changed"
if grep -q 'permissionMode' "$AG"; then fail "the inspector must not carry permissionMode (spec section 7.1)"; fi
# A plugin agent resolves as <plugin>:<agent>, measured 2026-09-06: the Agent
# tool rejects the bare name and lists caveman:cavecrew-investigator and its
# siblings. The skill must dispatch by the name that resolves.
[ "$(grep -c 'software-dev:consistency-audit-inspector' "$CA")" -ge 2 ] \
  || fail "consistency-audit must dispatch software-dev:consistency-audit-inspector, at least twice"
if grep -q '`consistency-audit-inspector`' "$CA"; then fail "consistency-audit still names the inspector bare"; fi
grep -q 'On Codex, where a plugin cannot ship a subagent' "$CA" \
  || fail "consistency-audit must state its Codex degradation in its own text (spec section 7.1)"
```

Also extend the header comment's bullet list with a fourth item, after the rethink bullet:

```
#   - consistency-audit ships with its inspector, the inspector carries no
#     permissionMode, and the skill names the inspector by the name a plugin
#     agent actually resolves to.
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-plugin-skills.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/software-dev/skills/consistency-audit/SKILL.md`, exit 1.

- [ ] **Step 3: Copy the skill, the inspector, and write the Codex gate**

```bash
mkdir -p plugins/software-dev/agents plugins/software-dev/skills/consistency-audit/agents
# The inspector, minus permissionMode: the tool grant has no write tool for
# plan mode to block, and the body forbids every mutation; the field guards
# nothing (spec section 7.1).
grep -v '^permissionMode:' ~/harness-backup/claude/agents/consistency-audit-inspector.md \
  > plugins/software-dev/agents/consistency-audit-inspector.md
# The skill, dispatching the inspector by the name a plugin agent resolves to.
sed 's/`consistency-audit-inspector`/`software-dev:consistency-audit-inspector`/g' \
  ~/harness-backup/claude/skills/consistency-audit/SKILL.md \
  > plugins/software-dev/skills/consistency-audit/SKILL.md
cat > plugins/software-dev/skills/consistency-audit/agents/openai.yaml <<'EOF'
interface:
  display_name: "Consistency Audit"
  short_description: "Refuted-before-reported repository audit"
policy:
  allow_implicit_invocation: false
EOF
```

Then add the Codex degradation bullet. In `plugins/software-dev/skills/consistency-audit/SKILL.md`, directly after the line

```
- Never substitute a general-purpose agent — the read-only contract is what makes "the audit changed nothing" true rather than promised
```

insert:

```
- On Codex, where a plugin cannot ship a subagent, the inspector does not exist: the audit degrades to one reader and one pass, and the scope line says so. Do not recover the second reader with a general-purpose agent
```

Check the result:

```bash
grep -c 'software-dev:consistency-audit-inspector' plugins/software-dev/skills/consistency-audit/SKILL.md
grep -c 'permissionMode' plugins/software-dev/agents/consistency-audit-inspector.md
sed -n '1,7p' plugins/software-dev/agents/consistency-audit-inspector.md
```

Expected: `2`; `0`; the frontmatter `name`, `description`, `tools: Read, Bash, WebFetch, WebSearch`, `model: inherit` between two fences.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-plugin-skills.sh`
Expected: `plugin-skills: 4 skills checked; gates paired, references resolve, rethink absent, inspector shipped`, exit 0.

- [ ] **Step 5: Record the Codex validator's bullet, and run both validators**

`consistency-audit` is gated on Claude by `disable-model-invocation: true`, which Codex's validator rejects on principle (sub-project 2 plan, Deviation D7: Codex never reads the field; its runtime reads only the yaml). In `tests/test-codex-validate.sh`, replace

```bash
  known='- skill `setup-repository` frontmatter field `disable-model-invocation` must be false'
```

with

```bash
  # Three gated skills, each carrying the field Claude reads beside the yaml
  # policy Codex reads: the vendored scaffolder, the authored consistency
  # audit, and the vendored adhd. tests/test-plugin-skills.sh asserts the pair.
  known="$(printf '%s\n' \
    '- skill `setup-repository` frontmatter field `disable-model-invocation` must be false' \
    '- skill `consistency-audit` frontmatter field `disable-model-invocation` must be false' \
    '- skill `adhd` frontmatter field `disable-model-invocation` must be false')"
```

and replace

```bash
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -e "$known" || true)"
```

with

```bash
    others="$(printf '%s\n' "$out" | grep '^- ' | grep -vxF -f <(printf '%s\n' "$known") || true)"
```

and change the header comment's `except for one recorded bullet on one skill (Deviation D7, below) — any` / `other failure, bullet-shaped or not, fails the test.` to `except for one recorded bullet on each gated skill (Deviation D7, below) —` / `any other failure, bullet-shaped or not, fails the test.`. The `adhd` line is listed now so Task 5 does not reopen this file; `grep -f` with a bullet that never appears is harmless.

Run: `bash tests/test-codex-validate.sh && bash tests/test-claude-validate.sh`
Expected: no output from the first (it has no summary line), `✔ Validation passed` three times from the second, exit 0.

- [ ] **Step 6: Commit**

```bash
git add plugins/software-dev/agents plugins/software-dev/skills/consistency-audit tests/test-plugin-skills.sh tests/test-codex-validate.sh
git commit -m "$(cat <<'EOF'
Ship consistency-audit and its inspector in software-dev

Authored, so no upstream and no drift test: after harness-backup is deleted
this is the only copy. Three changes from the backup's text. permissionMode
is deleted from the inspector: its tool grant has no write tool for plan
mode to block, and its body forbids every mutation, so the field guarded
nothing. The two dispatch references name
software-dev:consistency-audit-inspector, because a plugin agent does not
resolve by its bare name (measured: the Agent tool lists
caveman:cavecrew-investigator and rejects cavecrew-investigator). And one
bullet states the Codex degradation the spec prices in section 7.1: a Codex
plugin cannot ship a subagent, so the audit runs as one reader and says so.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: finding-duplicate-functions, into software-dev

**Files:**
- Create: `plugins/software-dev/skills/finding-duplicate-functions/` (six files from `~/harness-backup/claude/skills/finding-duplicate-functions/`, one header added, one file amended)
- Modify: `plugins/software-dev/LICENSE` (append one block)
- Modify: `tests/lib.sh` (`fetch_pinned`)
- Create: `tests/test-vendored-duplicates.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `fetch_pinned <url> <sha> <dir>` in `tests/lib.sh`, printing the checkout path; Tasks 5, 6, 8 and 9 call it. `fetch_upstream` keeps its signature.

- [ ] **Step 1: Generalise the fetch helper**

In `tests/lib.sh`, replace everything from the comment `# Shallow-fetch obra/superpowers at the pinned sha and print the checkout path.` to the end of the file with:

```bash
# Shallow-fetch $1 (a git URL) at commit $2 into $3 and print the path.
# Reuses an existing checkout whose HEAD already matches. Every git command is
# guarded here rather than at the call sites. A caller writing
# `UP="$(fetch_pinned ...)" || fail ...` suspends set -e inside this function,
# so an unguarded mid-function failure would fall through to the closing
# printf and return 0, making that `|| fail` dead code.
fetch_pinned() {
  local url="$1" sha="$2" dir="$3"
  [ "${#sha}" -eq 40 ] || fail "fetch_pinned needs a 40-char sha (got '$sha')"
  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD)" = "$sha" ]; then
    printf '%s\n' "$dir"
    return
  fi
  rm -rf "$dir"
  mkdir -p "$dir" || fail "could not create $dir"
  git -C "$dir" init -q || fail "git init failed in $dir"
  git -C "$dir" remote add origin "$url" || fail "git remote add failed in $dir"
  git -C "$dir" fetch -q --depth 1 origin "$sha" \
    || fail "could not fetch $url at $sha into $dir (no network, or the pinned sha is gone)"
  git -C "$dir" checkout -q FETCH_HEAD || fail "could not check out FETCH_HEAD in $dir"
  printf '%s\n' "$dir"
}

# obra/superpowers at the pinned sha. Override the location with UPSTREAM_DIR.
fetch_upstream() {
  local sha
  sha="$(upstream_sha)" || fail "could not read the pinned sha from $MARKETPLACE"
  [ "${#sha}" -eq 40 ] || fail "no 40-char pinned sha in $MARKETPLACE (got '$sha')"
  fetch_pinned https://github.com/obra/superpowers.git "$sha" \
    "${UPSTREAM_DIR:-${TMPDIR:-/tmp}/software-dev-upstream-superpowers}"
}
```

Run: `bash tests/test-vendored-brainstorming.sh && bash tests/test-hook.sh`
Expected: both summary lines as before, exit 0. Nothing that calls `fetch_upstream` changes behaviour.

- [ ] **Step 2: Write the failing drift test**

Create `tests/test-vendored-duplicates.sh`:

```bash
#!/usr/bin/env bash
# finding-duplicate-functions is a rewritten fork of obra/superpowers-lab, not
# a copy: only its two prompt templates are upstream's and those must stay
# byte-identical at the recorded commit, so a drift there is visible rather
# than silent. The rest is authored here and is checked for shape, not
# content. Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-dev/skills/finding-duplicate-functions"
[ -d "$V" ] || fail "missing $V"

SHA="51111f74f24058117752d9aa917cb19859f8ec86"
UP="$(fetch_pinned https://github.com/obra/superpowers-lab.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-superpowers-lab")"
U="$UP/skills/finding-duplicate-functions"
[ -d "$U" ] || fail "upstream has no skills/finding-duplicate-functions at $SHA"

# The two templates carried unchanged.
for f in scripts/categorize-prompt.md scripts/find-duplicates-prompt.md; do
  [ -f "$U/$f" ] || fail "upstream has no $f at $SHA"
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream at $SHA; PROVENANCE.md says it is carried unchanged"
done

# The six files the fork ships, and the two executables.
diff <(printf '%s\n' ./PROVENANCE.md ./SKILL.md ./scripts/categorize-prompt.md ./scripts/cluster.py \
                     ./scripts/extract-functions.py ./scripts/find-duplicates-prompt.md) \
     <(cd "$V" && find . -type f | sort) \
  || fail "file set is not the six the fork ships"
[ -x "$V/scripts/cluster.py" ] || fail "scripts/cluster.py lost its executable bit"
[ -x "$V/scripts/extract-functions.py" ] || fail "scripts/extract-functions.py lost its executable bit"
# Parsed, not compiled: py_compile writes a __pycache__ into the skill tree,
# which the file-set assertion above would then count on the next run.
python3 -c 'import ast, sys
for path in sys.argv[1:]:
    ast.parse(open(path).read(), path)' "$V/scripts/cluster.py" "$V/scripts/extract-functions.py" \
  || fail "a script does not parse"

# Frontmatter untouched in shape; lines 5-10 are the provenance header, verbatim.
[ "$(sed -n 2p "$V/SKILL.md")" = "name: finding-duplicate-functions" ] || fail "name changed"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"
expected_header="$(printf '%s\n' \
  "<!-- Forked from https://github.com/obra/superpowers-lab at commit $SHA" \
  "     path: skills/finding-duplicate-functions/" \
  "     MIT, (c) 2025 Jesse Vincent. A rewritten fork, not a copy: scripts/categorize-prompt.md and" \
  "     scripts/find-duplicates-prompt.md are upstream's, byte for byte; everything else is authored here." \
  "     PROVENANCE.md records what changed and why. Edit this skill here; there is nothing to re-vendor." \
  "-->")"
[ "$(sed -n 5,10p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-10 are not the provenance header"

# PROVENANCE.md and the LICENSE name the same commit.
grep -q "$SHA" "$V/PROVENANCE.md" || fail "PROVENANCE.md does not name commit $SHA"
grep -q "^$SHA); its two prompt templates" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE carries no provenance notice naming commit $SHA for the fork"

printf 'vendored-duplicates: two templates match obra/superpowers-lab %s; six files, two executables\n' "$SHA"
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash tests/test-vendored-duplicates.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/software-dev/skills/finding-duplicate-functions`, exit 1.

- [ ] **Step 4: Copy the fork, add the header, amend PROVENANCE.md, append the LICENSE block**

```bash
cp -a ~/harness-backup/claude/skills/finding-duplicate-functions plugins/software-dev/skills/
ls -l plugins/software-dev/skills/finding-duplicate-functions/scripts/
```

Expected: `cluster.py` and `extract-functions.py` are `-rwxr-xr-x`; the two `.md` files are not. `cp -a` keeps the bits.

Insert the provenance header into `plugins/software-dev/skills/finding-duplicate-functions/SKILL.md` directly after line 4 (the closing `---`), so it occupies lines 5 to 10:

```
<!-- Forked from https://github.com/obra/superpowers-lab at commit 51111f74f24058117752d9aa917cb19859f8ec86
     path: skills/finding-duplicate-functions/
     MIT, (c) 2025 Jesse Vincent. A rewritten fork, not a copy: scripts/categorize-prompt.md and
     scripts/find-duplicates-prompt.md are upstream's, byte for byte; everything else is authored here.
     PROVENANCE.md records what changed and why. Edit this skill here; there is nothing to re-vendor.
-->
```

In `plugins/software-dev/skills/finding-duplicate-functions/PROVENANCE.md`, make two edits. First, the sentence `Upstream's tip when this file was written was` `` `51111f7` (2026-06-01); …`` gains the full sha: replace `` `51111f7` (2026-06-01) `` with `` `51111f7` (`51111f74f24058117752d9aa917cb19859f8ec86`, 2026-06-01) ``. Second, replace the whole `## Why it lives in this repository` section (its heading and the three paragraphs under it, to the end of the file) with:

```markdown
## Where it lives

In `software-dev`, since 2026-09-06: its subject is software and only that
product needs it (the placement rule in `plugins/sensemaking/README.md`).
It was custodied in `harness-backup` before that, under that repository's
rule of holding what no installer reproduces; that repository is retired.

`tests/test-vendored-duplicates.sh` holds the two carried templates
byte-identical to upstream at the commit above, so a drift there is a
failing test rather than a note nobody re-reads. Nothing watches upstream
for changes to the parts that were rewritten; that is the cost of a fork,
and it was taken because the upstream extractor returns nothing for Python.
```

Append to `plugins/software-dev/LICENSE`:

```

----------------------------------------------------------------------

skills/finding-duplicate-functions/ is a rewritten fork of
https://github.com/obra/superpowers-lab (directory
skills/finding-duplicate-functions/, at commit
51111f74f24058117752d9aa917cb19859f8ec86); its two prompt templates under
scripts/ are upstream's, byte for byte, and remain under their original
license:

MIT License

Copyright (c) 2025 Jesse Vincent

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

The LICENSE block's third line must end exactly `at commit` and its fourth begin with the sha followed by `); its two prompt templates`, because the test greps `^<sha>); its two prompt templates` on one line.

- [ ] **Step 5: Run the test to verify it passes, twice**

Run: `bash tests/test-vendored-duplicates.sh && bash tests/test-vendored-duplicates.sh && bash tests/test-plugin-skills.sh`
Expected: `vendored-duplicates: two templates match obra/superpowers-lab 51111f74f24058117752d9aa917cb19859f8ec86; six files, two executables` twice, then `plugin-skills: 5 skills checked; …`, exit 0. Twice, because the first cut of this test compiled the scripts and left a `__pycache__` that made the second run fail; `find plugins -name __pycache__` must print nothing.

- [ ] **Step 6: Commit**

```bash
git add tests/lib.sh tests/test-vendored-duplicates.sh plugins/software-dev/skills/finding-duplicate-functions plugins/software-dev/LICENSE
git commit -m "$(cat <<'EOF'
Ship finding-duplicate-functions in software-dev, with its fork provenance

The only one of the four authored assets that has an upstream: a rewritten
fork of obra/superpowers-lab's skill, whose extractor reads TypeScript and
returns nothing for Python. Its two prompt templates are still upstream's,
byte for byte at 51111f7, and the drift test holds them there; the rest is
authored and carries a header saying so.

tests/lib.sh gains fetch_pinned, the shallow fetch fetch_upstream already
did, for any repository at any sha; four more tests need it.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---
### Task 5: adhd, vendored and gated, into sensemaking

**Files:**
- Create: `plugins/sensemaking/skills/adhd/SKILL.md` (from `UditAkhourii/adhd` at `16dc239…`, three edits)
- Create: `plugins/sensemaking/skills/adhd/agents/openai.yaml`
- Modify: `plugins/sensemaking/LICENSE` (append one block)
- Modify: `plugins/sensemaking/README.md` (the Skills list)
- Create: `tests/test-vendored-adhd.sh`

**Interfaces:**
- Consumes: `fetch_pinned` from Task 4; the `adhd` bullet Task 3 already recorded in `tests/test-codex-validate.sh`.
- Produces: `sensemaking:adhd`, user-invoked on both harnesses.

- [ ] **Step 1: Write the failing drift test**

Create `tests/test-vendored-adhd.sh`:

```bash
#!/usr/bin/env bash
# The vendored adhd skill must equal UditAkhourii/adhd at the pinned commit
# except: a provenance header right after the frontmatter, line 3 (the
# description, shortened so Codex shows it whole), an added line 5 carrying
# Claude's invocation gate, and an added agents/openai.yaml carrying Codex's.
# Gated on both harnesses because its cost is the operator's call (spec
# section 6.2). Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/sensemaking/skills/adhd"
[ -d "$V" ] || fail "missing $V"

# The repository's HEAD on 2026-09-06. Its only tag, v0.1.4, dates from
# 2026-05-30 and predates both this SKILL.md text and the plugin manifest,
# so the pin is a commit.
SHA="16dc239ff186b869372e75095cfa58fc0ee89927"
UP="$(fetch_pinned https://github.com/UditAkhourii/adhd.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-adhd")"
U="$UP/skills/adhd"
[ -f "$U/SKILL.md" ] || fail "upstream has no skills/adhd/SKILL.md at $SHA"

# Upstream ships one file; ours adds the Codex policy file and nothing else.
diff <(cd "$U" && find . -type f | sort; printf './agents/openai.yaml\n' | sort) \
     <(cd "$V" && find . -type f | sort) \
  || fail "file set is not upstream's plus agents/openai.yaml"

# Frontmatter: lines 1, 2 and 4 are upstream's; 3 is ours; 5 is the gate; 6 closes.
diff <(sed -n '1,2p;4p' "$U/SKILL.md") <(sed -n '1,2p;4p' "$V/SKILL.md") \
  || fail "the frontmatter fences, name or license line were edited"
[ "$(sed -n 4p "$U/SKILL.md")" = "license: MIT" ] || fail "upstream frontmatter shape changed; re-audit the vendoring"
want='description: Parallel divergent ideation under five isolated cognitive frames, scored, clustered, deepened. Costs 5 to 10x one answer.'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the shortened description, verbatim"
desc="${want#description: }"
[ "${#desc}" -le 122 ] || fail "the description is ${#desc} characters; Codex truncates at 122"
[ "$(sed -n 5p "$V/SKILL.md")" = "disable-model-invocation: true" ] \
  || fail "line 5 must carry Claude's gate, disable-model-invocation: true"
[ "$(sed -n 6p "$V/SKILL.md")" = "---" ] || fail "line 6 is not the closing frontmatter fence"
grep -qx '  allow_implicit_invocation: false' "$V/agents/openai.yaml" \
  || fail "agents/openai.yaml must carry Codex's gate, allow_implicit_invocation: false"

# Lines 7-12: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/UditAkhourii/adhd at commit $SHA" \
  "     path: skills/adhd/ (the repository's only skill; its tag v0.1.4 predates this text and the plugin manifest)" \
  "     MIT, (c) 2026 ADHD contributors. Local changes: the description above, shortened to 121 characters so" \
  "     Codex shows it whole, and the invocation gate, disable-model-invocation: true, paired with" \
  "     policy.allow_implicit_invocation: false in agents/openai.yaml. Nothing else is edited." \
  "-->")"
[ "$(sed -n 7,12p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 7-12 are not the provenance header"

# Body: upstream minus its line 3 equals ours minus lines 3, 5 and 7-12.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5d' -e '7,12d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header, the description and the gate"

# The LICENSE's provenance notice names the same commit.
grep -q "at commit $SHA)" "$REPO_ROOT/plugins/sensemaking/LICENSE" \
  || fail "LICENSE provenance does not name commit $SHA"
grep -q "Copyright (c) 2026 ADHD contributors" "$REPO_ROOT/plugins/sensemaking/LICENSE" \
  || fail "LICENSE lacks upstream's copyright line"

printf 'vendored-adhd: matches UditAkhourii/adhd %s except header, description (%s chars) and the two gates\n' "$SHA" "${#desc}"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-vendored-adhd.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/sensemaking/skills/adhd`, exit 1.

- [ ] **Step 3: Vendor the skill with the two gates and the shortened description**

The upstream frontmatter is five lines: `---`, `name: adhd`, `description: …`, `license: MIT`, `---`. Ours keeps lines 1, 2 and 4, replaces 3, inserts the Claude gate as line 5, closes at 6, and carries the header at 7 to 12.

```bash
. tests/lib.sh
UP="$(fetch_pinned https://github.com/UditAkhourii/adhd.git 16dc239ff186b869372e75095cfa58fc0ee89927 /tmp/software-dev-upstream-adhd)"
U="$UP/skills/adhd"; V="plugins/sensemaking/skills/adhd"
[ "$(sed -n 4p "$U/SKILL.md")" = "license: MIT" ] || echo "STOP: upstream frontmatter shape changed"
mkdir -p "$V/agents"
{
  sed -n '1,2p' "$U/SKILL.md"
  printf '%s\n' 'description: Parallel divergent ideation under five isolated cognitive frames, scored, clustered, deepened. Costs 5 to 10x one answer.'
  sed -n '4p' "$U/SKILL.md"
  printf '%s\n' 'disable-model-invocation: true'
  sed -n '5p' "$U/SKILL.md"
  printf '%s\n' \
    "<!-- Vendored from https://github.com/UditAkhourii/adhd at commit 16dc239ff186b869372e75095cfa58fc0ee89927" \
    "     path: skills/adhd/ (the repository's only skill; its tag v0.1.4 predates this text and the plugin manifest)" \
    "     MIT, (c) 2026 ADHD contributors. Local changes: the description above, shortened to 121 characters so" \
    "     Codex shows it whole, and the invocation gate, disable-model-invocation: true, paired with" \
    "     policy.allow_implicit_invocation: false in agents/openai.yaml. Nothing else is edited." \
    "-->"
  sed -n '6,$p' "$U/SKILL.md"
} > "$V/SKILL.md"
cat > "$V/agents/openai.yaml" <<'EOF'
interface:
  display_name: "ADHD"
  short_description: "Parallel divergent ideation, five frames"
policy:
  allow_implicit_invocation: false
EOF
sed -n '1,12p' "$V/SKILL.md" | cut -c1-100
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5d' -e '7,12d' "$V/SKILL.md") && echo "body identical"
```

Expected: the twelve lines as described, then `body identical`. (`. tests/lib.sh` turns on `set -e` in your shell for the rest of this session; open a fresh shell if a later command's non-zero exit surprises you.)

- [ ] **Step 4: Append the LICENSE block and list the skill**

Append to `plugins/sensemaking/LICENSE`:

```

----------------------------------------------------------------------

skills/adhd/ is vendored from https://github.com/UditAkhourii/adhd (directory
skills/adhd/, at commit 16dc239ff186b869372e75095cfa58fc0ee89927) and remains
under its original license:

MIT License

Copyright (c) 2026 ADHD contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

In `plugins/sensemaking/README.md`, under `## Skills`, add after the `rethink-audit` bullet:

```markdown
- `adhd`: parallel divergent ideation under five isolated cognitive frames,
  scored, clustered and deepened. About ten agent calls and five to ten times
  the cost of one answer, so it is user-invoked on both harnesses: `/adhd
  <problem>`. Vendored from `UditAkhourii/adhd` at a pinned commit; the
  provenance header at the top of `SKILL.md` names it and the two local
  changes.
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/test-vendored-adhd.sh && bash tests/test-plugin-skills.sh && bash tests/test-codex-validate.sh && bash tests/test-claude-validate.sh`
Expected: `vendored-adhd: matches UditAkhourii/adhd 16dc239ff186b869372e75095cfa58fc0ee89927 except header, description (121 chars) and the two gates`; `plugin-skills: 6 skills checked; …`; nothing; `✔ Validation passed` three times; exit 0.

- [ ] **Step 6: Commit**

```bash
git add plugins/sensemaking/skills/adhd plugins/sensemaking/LICENSE plugins/sensemaking/README.md tests/test-vendored-adhd.sh
git commit -m "$(cat <<'EOF'
Vendor adhd into sensemaking, gated on both harnesses

Its own body says it costs five to ten times a single answer and asks the
model to talk itself out of running; the gate makes that structural, and
places it with the five gated escalation skills already on the roster. Gating
also dissolves its two description collisions, with brainstorming and with
systematic-debugging, without a second rewrite. The description is shortened
to 121 characters so Codex shows it whole.

Pinned at commit 16dc239, the repository's HEAD on 2026-09-06: its only tag,
v0.1.4, dates from May and predates both this text and the plugin manifest.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: diagnosing-bugs, vendored and not gated, into software-dev

**Files:**
- Create: `plugins/software-dev/skills/diagnosing-bugs/` (three files from `mattpocock/skills` at `v1.2.3`, one line rewritten)
- Modify: `plugins/software-dev/LICENSE` (append one block)
- Modify: `tests/test-skills-pin.sh` (one negative assertion)
- Create: `tests/test-vendored-diagnosing-bugs.sh`

**Interfaces:**
- Consumes: `fetch_pinned`.
- Produces: `software-dev:diagnosing-bugs`, model-invocable, with the 69-character description from §6.1.

- [ ] **Step 1: Write the failing drift test**

Create `tests/test-vendored-diagnosing-bugs.sh`:

```bash
#!/usr/bin/env bash
# The vendored diagnosing-bugs skill must equal mattpocock/skills at the ref
# upstream/skills.json declares, in every byte and file mode, except: a
# provenance header right after the frontmatter, and line 3, the description,
# rewritten so Codex shows it whole and it shares no trigger word with
# systematic-debugging (spec section 6.1). It must not be gated, and it must
# not also be declared for skills.sh. Needs network access.
. "$(dirname "$0")/lib.sh"

V="$REPO_ROOT/plugins/software-dev/skills/diagnosing-bugs"
[ -d "$V" ] || fail "missing $V"

REF="v1.2.3"
SHA="6acc160e4e0cd062dbbbd7a1b26ae92855edf07e"   # the commit v1.2.3 peels to
# One upstream state for the whole mattpocock set: the vendored copy and the
# skills.sh install must come from the same tag, or a bump moves one without
# the other.
declared="$(jq -r '.sources[] | select(.repo == "mattpocock/skills") | .ref' "$REPO_ROOT/upstream/skills.json")"
[ "$declared" = "$REF" ] \
  || fail "upstream/skills.json pins mattpocock/skills at $declared and this test at $REF; move them together"
git ls-remote --tags https://github.com/mattpocock/skills.git "refs/tags/$REF^{}" | grep -q "^$SHA" \
  || fail "tag $REF no longer peels to $SHA"

UP="$(fetch_pinned https://github.com/mattpocock/skills.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-mattpocock")"
U="$UP/skills/engineering/diagnosing-bugs"
[ -d "$U" ] || fail "upstream has no skills/engineering/diagnosing-bugs at $SHA"

# Same file set: SKILL.md, agents/openai.yaml, scripts/hitl-loop.template.sh.
diff <(cd "$U" && find . -type f | sort) <(cd "$V" && find . -type f | sort) \
  || fail "file set differs from upstream"
[ "$(cd "$V" && find . -type f | wc -l)" -eq 3 ] || fail "expected 3 vendored files"

# Every file: identical executable bit. Every file but SKILL.md: identical bytes.
while IFS= read -r f; do
  if [ -x "$U/$f" ] && [ ! -x "$V/$f" ]; then fail "$f lost its executable bit"; fi
  if [ ! -x "$U/$f" ] && [ -x "$V/$f" ]; then fail "$f gained an executable bit"; fi
  [ "$f" = "./SKILL.md" ] && continue
  cmp -s "$U/$f" "$V/$f" || fail "$f differs from upstream"
done < <(cd "$V" && find . -type f | sort)

# Frontmatter: name untouched, line 3 is the rewritten description, verbatim.
[ "$(sed -n 1p "$V/SKILL.md")" = "---" ] || fail "line 1 is not a frontmatter fence"
[ "$(sed -n 2p "$V/SKILL.md")" = "name: diagnosing-bugs" ] || fail "name changed"
want='description: Use when a bug resists reproduction, or for a performance regression.'
[ "$(sed -n 3p "$V/SKILL.md")" = "$want" ] || fail "line 3 is not the rewritten description, verbatim"
[ "$(sed -n 4p "$V/SKILL.md")" = "---" ] || fail "line 4 is not the closing frontmatter fence"
desc="${want#description: }"
[ "${#desc}" -le 122 ] || fail "the description is ${#desc} characters; Codex truncates at 122"

# Lines 5-10: the whole provenance header, verbatim.
expected_header="$(printf '%s\n' \
  "<!-- Vendored from https://github.com/mattpocock/skills at tag $REF, commit $SHA" \
  "     path: skills/engineering/diagnosing-bugs/" \
  "     MIT, (c) 2026 Matt Pocock. The only local change is the description in the frontmatter above:" \
  "     69 characters, so Codex shows it whole, and disjoint from systematic-debugging's triggers." \
  "     Do not hand-edit below this line; re-vendor from upstream to update." \
  "-->")"
[ "$(sed -n 5,10p "$V/SKILL.md")" = "$expected_header" ] || fail "lines 5-10 are not the provenance header"

# Body: drop line 3 and lines 5-10; rest must equal upstream minus line 3.
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5,10d' "$V/SKILL.md") \
  || fail "SKILL.md changed beyond the header and the description"

# Not gated, on either harness: an agent reaches for it unprompted when a bug
# resists reproduction (spec section 6.1).
if grep -q 'disable-model-invocation' "$V/SKILL.md"; then fail "diagnosing-bugs must not be gated on Claude"; fi
if grep -q 'allow_implicit_invocation: false' "$V/agents/openai.yaml"; then fail "diagnosing-bugs must not be gated on Codex"; fi

# Vendored means not also installed bare, or the unadapted copy sits beside it.
if jq -e '[.sources[].skills[]] | index("diagnosing-bugs")' "$REPO_ROOT/upstream/skills.json" >/dev/null 2>&1; then
  fail "diagnosing-bugs is vendored here and must not also be declared in upstream/skills.json"
fi

# The LICENSE's provenance notice names the same tag and commit.
grep -q "skills/engineering/diagnosing-bugs/, at tag $REF, commit" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE carries no provenance notice for skills/diagnosing-bugs/"
grep -q "^$SHA)" "$REPO_ROOT/plugins/software-dev/LICENSE" \
  || fail "LICENSE provenance for diagnosing-bugs does not name commit $SHA"

printf 'vendored-diagnosing-bugs: matches mattpocock/skills %s except header + description (%s chars)\n' "$REF" "${#desc}"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-vendored-diagnosing-bugs.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/software-dev/skills/diagnosing-bugs`, exit 1.

- [ ] **Step 3: Vendor the skill with the rewritten description**

```bash
. tests/lib.sh
UP="$(fetch_pinned https://github.com/mattpocock/skills.git 6acc160e4e0cd062dbbbd7a1b26ae92855edf07e /tmp/software-dev-upstream-mattpocock)"
U="$UP/skills/engineering/diagnosing-bugs"; V="plugins/software-dev/skills/diagnosing-bugs"
rm -rf "$V" && cp -R "$U" "$V"
[ "$(sed -n 4p "$U/SKILL.md")" = "---" ] || echo "STOP: upstream frontmatter is no longer three lines"
{
  sed -n '1,2p' "$U/SKILL.md"
  printf '%s\n' 'description: Use when a bug resists reproduction, or for a performance regression.'
  sed -n '4p' "$U/SKILL.md"
  printf '%s\n' \
    "<!-- Vendored from https://github.com/mattpocock/skills at tag v1.2.3, commit 6acc160e4e0cd062dbbbd7a1b26ae92855edf07e" \
    "     path: skills/engineering/diagnosing-bugs/" \
    "     MIT, (c) 2026 Matt Pocock. The only local change is the description in the frontmatter above:" \
    "     69 characters, so Codex shows it whole, and disjoint from systematic-debugging's triggers." \
    "     Do not hand-edit below this line; re-vendor from upstream to update." \
    "-->"
  sed -n '5,$p' "$U/SKILL.md"
} > "$V/SKILL.md.new" && mv "$V/SKILL.md.new" "$V/SKILL.md"
find "$V" -type f | sort
diff <(sed '3d' "$U/SKILL.md") <(sed -e '3d' -e '5,10d' "$V/SKILL.md") && echo "body identical"
```

Expected: `./SKILL.md`, `./agents/openai.yaml`, `./scripts/hitl-loop.template.sh` (upstream ships the template without an executable bit; `cp -R` keeps that), then `body identical`.

- [ ] **Step 4: Append the LICENSE block, and keep it out of skills.sh**

Append to `plugins/software-dev/LICENSE`:

```

----------------------------------------------------------------------

skills/diagnosing-bugs/ is vendored from https://github.com/mattpocock/skills
(directory skills/engineering/diagnosing-bugs/, at tag v1.2.3, commit
6acc160e4e0cd062dbbbd7a1b26ae92855edf07e) and remains under the MIT license
reproduced above for skills/setup-repository/, Copyright (c) 2026 Matt Pocock.
```

The second line must end `at tag v1.2.3, commit` and the third begin with the sha and `)`: the test greps both on their own lines.

In `tests/test-skills-pin.sh`, directly after the `setup-matt-pocock-skills` block (the `fi` that closes it), insert:

```bash
# diagnosing-bugs is vendored with a rewritten description (spec section 6.1);
# declaring it here too would install the unadapted one beside it.
if jq -e '[.sources[].skills[]] | index("diagnosing-bugs")' "$S" >/dev/null 2>&1; then
  fail "diagnosing-bugs is vendored by software-dev with a rewritten description; declaring it here too would install the unadapted one beside it"
fi
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/test-vendored-diagnosing-bugs.sh && bash tests/test-plugin-skills.sh && bash tests/test-skills-pin.sh && bash tests/test-codex-validate.sh`
Expected: `vendored-diagnosing-bugs: matches mattpocock/skills v1.2.3 except header + description (69 chars)`; `plugin-skills: 7 skills checked; …`; `skills-pin: 18 declared skills, every ref a real tag, every name resolving once`; nothing; exit 0.

- [ ] **Step 6: Commit**

```bash
git add plugins/software-dev/skills/diagnosing-bugs plugins/software-dev/LICENSE tests/test-skills-pin.sh tests/test-vendored-diagnosing-bugs.sh
git commit -m "$(cat <<'EOF'
Vendor diagnosing-bugs into software-dev with a routing description

The capability gap is real: it makes the reproduction loop its whole first
phase, adds minimisation, ranked falsifiable hypotheses, a measure-first
performance branch and tagged instrumentation, none of which
systematic-debugging carries. Its description was the problem: 156
characters, cut mid-list on Codex, and the bare word "diagnose" pulled it
onto reproducible bugs five times in five. The rewrite measured 0 false
positives in 35 negative trials and 25 of 25 on recall (spec section 6.1).

Not gated: an agent should reach for it unprompted when a bug resists
reproduction, and a gate would charge the operator's attention on every hard
bug for the outcome rejection gives free.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: archify through skills.sh, and a watch that survives its tag series

**Files:**
- Modify: `upstream/skills.json` (a third source)
- Modify: `tests/test-skills-pin.sh` (18 → 19)
- Modify: `bin/upstream-watch` (the stable-tag filter, the `--newest-stable-tag` mode, every curated entry)
- Modify: `tests/test-setup-doctor.sh` (the filter assertion)
- Modify: `plugins/software-dev/README.md` (the `## Environment` section)

**Interfaces:**
- Consumes: nothing.
- Produces: `bin/upstream-watch --newest-stable-tag` reading tag names on stdin and printing the newest stable one; the curated-entry loop Task 8's second entry will be picked up by.

- [ ] **Step 1: Make the pin test demand nineteen**

In `tests/test-skills-pin.sh` change

```bash
[ "$total" -eq 18 ] || fail "expected 18 declared skills, got $total"
```

to

```bash
[ "$total" -eq 19 ] || fail "expected 19 declared skills, got $total"
```

Run: `bash tests/test-skills-pin.sh`
Expected: `FAIL: expected 19 declared skills, got 18`, exit 1.

- [ ] **Step 2: Declare the source**

In `upstream/skills.json`, after the `obra/superpowers-developing-for-claude-code` object, add a third source so the array reads:

```json
    {
      "repo": "obra/superpowers-developing-for-claude-code",
      "ref": "v0.3.1",
      "skills": [
        "developing-claude-code-plugins",
        "working-with-claude-code"
      ]
    },
    {
      "repo": "tt-a1i/archify",
      "ref": "v2.16.0",
      "skills": [
        "archify"
      ]
    }
```

Run: `bash tests/test-skills-pin.sh`
Expected: `skills-pin: 19 declared skills, every ref a real tag, every name resolving once`, exit 0. The name resolves by directory basename: the repository holds one `SKILL.md`, at `archify/SKILL.md`.

- [ ] **Step 3: Write the failing filter assertion**

In `tests/test-setup-doctor.sh`, inside the `if command -v shellcheck` branch, directly after the `|| fail "shellcheck reported problems in bin/"` line, insert:

```bash
  # upstream-watch's tag filter, with no network: the newest stable release
  # wins over a prerelease, a -dev build, and a parallel tag series.
  got="$(printf '%s\n' archify-dsh-v0.1.0 v2.16.0 v2.17.0-dev.1 v2.16.1-rc.1 v2.16.0-beta v2.15.0 \
    | bash "$REPO_ROOT/bin/upstream-watch" --newest-stable-tag)"
  [ "$got" = "v2.16.0" ] || fail "upstream-watch --newest-stable-tag picked '$got', expected v2.16.0"
```

Run: `bash tests/test-setup-doctor.sh`
Expected: `FAIL: upstream-watch --newest-stable-tag picked '<the last line of a full watch report>', expected v2.16.0`, exit 1. The old script ignores its argument and runs the whole network watch, so `got` is that report's closing line, typically `Everything matches. No action.`; either way not `v2.16.0`.

- [ ] **Step 4: Widen the filter and watch every curated entry**

In `bin/upstream-watch`, directly after the line `report() { printf '%s\n' "$*"; }`, insert:

```bash
# Stable release tags only, from tag names on stdin: v1.2.3 or 1.2.3 with
# nothing after the digits. Excludes -alpha, -beta, -rc, -dev.N, and any
# parallel series with its own prefix (archify publishes archify-dsh-v0.1.0
# beside its releases), all of which `sort -V` would otherwise rank above the
# newest release and report as drift indefinitely.
newest_stable_tag() { grep -E '^v?[0-9]+(\.[0-9]+)+$' | sort -V | tail -1; }

# Exposed so the filter can be tested without the network.
if [ "${1:-}" = "--newest-stable-tag" ]; then
  newest_stable_tag
  exit 0
fi
```

Then replace the whole section that begins `# 1. obra/superpowers: the pinned sha against HEAD, and the tag list.` and ends with the `report ""` before `# 2. Each skills.sh source` with:

```bash
# 1. Each curated entry: the pinned sha against the tip of its declared ref.
# superpowers also lists its newest tag and names its bump script; the other
# entries have no version to mirror, so a bump edits sha and version together
# by hand (spec section 6.4).
while IFS="$(printf '\t')" read -r name url ref sha; do
  [ -n "$name" ] || continue
  [ "${#sha}" -eq 40 ] || die "no 40-character sha for $name in $MARKETPLACE"
  head_sha="$(git ls-remote "$url" "refs/heads/$ref" | cut -f1)"
  [ -n "$head_sha" ] || die "could not resolve $url $ref"
  report "### $name ($url)"
  report ""
  if [ "$head_sha" = "$sha" ]; then
    report "- Pinned at \`$sha\`, which is $ref. Nothing to do."
  else
    report "- Pinned at \`$sha\`; $ref is \`$head_sha\`."
    if [ "$name" = superpowers ]; then
      report "- Bump with \`bin/bump-superpowers $head_sha\`, then read the diff to"
      report "  \`hooks/payload.md\` and \`skills/brainstorming/\` before merging."
    else
      report "- Bump by editing \`.claude-plugin/marketplace.json\`: move \`sha\` and \`version\` together, then update the pinned pair in \`tests/test-curated-$name.sh\`."
    fi
    DRIFT=1
  fi
  if [ "$name" = superpowers ]; then
    latest_tag="$(git ls-remote --tags --refs "$url" | awk -F/ '{print $NF}' | newest_stable_tag)"
    [ -n "$latest_tag" ] && report "- Latest upstream tag: \`$latest_tag\`."
  fi
  report ""
done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir")
                | [.name, .source.url, .source.ref, .source.sha] | @tsv' "$MARKETPLACE")
```

And in section 2, replace

```bash
  newest="$(git ls-remote --tags --refs "https://github.com/$repo.git" \
    | awk -F/ '{print $NF}' | grep -v -- '-alpha' | grep -v -- '-beta' | sort -V | tail -1)"
```

with

```bash
  newest="$(git ls-remote --tags --refs "https://github.com/$repo.git" \
    | awk -F/ '{print $NF}' | newest_stable_tag)"
```

The `openai/codex` section keeps its own `rust-v0.*` pattern and filter; its tag shape is different and was not the problem.

Run: `shellcheck bin/upstream-watch && bash tests/test-setup-doctor.sh && bash bin/upstream-watch`
Expected: shellcheck silent; `setup-doctor: two entry points, lint clean, prerequisites split as documented`; then a report whose `### superpowers (https://github.com/obra/superpowers.git)` section reads `Pinned at … which is main. Nothing to do.` and `Latest upstream tag: `v6.3.0`.`, whose skills.sh section lists all three sources `pinned at …, the newest tag.` including `` `tt-a1i/archify` pinned at `v2.16.0`, the newest tag. ``, and which ends `Everything matches. No action.`, exit 0.

- [ ] **Step 5: Document the update check and the variable**

In `plugins/software-dev/README.md`, under `## Environment`, after the paragraph beginning `Setting it prevents exactly one thing:`, add:

```markdown
`archify`, installed through skills.sh at a pinned tag, runs a version check
once per authoring session: after the first candidate diagram it runs its
packaged `scripts/check-update.mjs`, which fetches a small manifest from
`https://tt-a1i.github.io/archify/skill-updates/archify/stable.json`, and if
a newer release exists it shows one notice and continues. The skill's own
text rules the rest: if the command cannot run it continues without a word,
it never downloads, installs or executes an update, and silence is never
consent. To turn the check off, set `ARCHIFY_UPDATE_CHECK_DISABLED=1` in the
same place as the telemetry variable above; `check-update.mjs` tests exactly
that value. No setup step sets it for you, for the same reason as the
telemetry variable: a network-behaviour decision belongs to you. This is a
README instruction rather than a mechanism, chosen knowingly; if it proves
insufficient, the next rung is a `bin/doctor` line reporting the variable's
state.
```

This sits under `## Environment`, not `## Install` or `## Updates`, so `tests/test-setup-doctor.sh`'s fenced-block assertion does not demand it in `--help`.

Run: `bash tests/test-setup-doctor.sh`
Expected: passes as before.

- [ ] **Step 6: Commit**

```bash
git add upstream/skills.json tests/test-skills-pin.sh bin/upstream-watch tests/test-setup-doctor.sh plugins/software-dev/README.md
git commit -m "$(cat <<'EOF'
Adopt archify through skills.sh, pinned at v2.16.0

The ticket that called it unpinnable reasoned from the wrong sigil: # is the
ref selector, and bin/setup has used it since 2026-09-05. So it is an
ordinary third source in upstream/skills.json, and the trilemma of a moving
branch, a release zip or a fork dissolves.

Its tag series would have broken the watch: it publishes -dev.N tags and a
parallel archify-dsh-* series, and sort -V ranks both above the newest
release. The filter now admits stable semver only, and is exposed as
--newest-stable-tag so the test asserts it without the network. The watch
also iterates every curated marketplace entry rather than naming superpowers,
since a second entry arrives in the next commit.

Its per-invocation update check is documented with the variable that turns
it off; setup does not set it, on the reasoning that already governs the
telemetry variable.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Curate writing-clearly-and-concisely

**Files:**
- Modify: `.claude-plugin/marketplace.json` (a fourth entry)
- Modify: `plugins/software-dev/.claude-plugin/plugin.json` (a third dependency)
- Create: `tests/test-curated-writing.sh`

**Interfaces:**
- Consumes: `fetch_pinned`.
- Produces: the `writing-clearly-and-concisely` entry, `git-subdir` at `3027f20f…`, version `0.1.0`, path `dist/plugins/writing-clearly-and-concisely`, one skill. Task 9's engine reads it through `curated_entries`.

- [ ] **Step 1: Write the failing test**

Create `tests/test-curated-writing.sh`:

```bash
#!/usr/bin/env bash
# The curated writing-clearly-and-concisely entry points at a real
# softaworks/agent-toolkit sha, uses upstream's own published plugin shape
# under dist/ rather than the whole skills/ tree, lists exactly its one skill,
# and carries a version this repository authors, since upstream ships none.
# The dist copy must equal the source tree at the pin, or the entry serves
# something other than what the source repository shows. Needs network.
. "$(dirname "$0")/lib.sh"

NAME="writing-clearly-and-concisely"
entry() { jq -r --arg n "$NAME" ".plugins[] | select(.name == \$n) | $1" "$MARKETPLACE"; }

[ "$(entry '.source.source')" = "git-subdir" ] || fail "source.source must be git-subdir"
[ "$(entry '.source.url')" = "https://github.com/softaworks/agent-toolkit.git" ] || fail "source.url"
[ "$(entry '.source.path')" = "dist/plugins/$NAME" ] \
  || fail "source.path must be upstream's published plugin directory, not the whole skills tree"
[ "$(entry '.strict')" = "false" ] || fail "strict must be false"
[ "$(entry '.skills | length')" -eq 1 ] || fail "the entry must list exactly one skill"
[ "$(entry '.skills[0]')" = "./skills/$NAME" ] || fail "the listed skill must be ./skills/$NAME"

# The sha and the version move together (spec section 6.4): upstream has no
# version to mirror, so the pair is pinned here, and a bump edits both this
# test and the manifest in one change.
SHA="3027f20f3181758385a1bb8c022d4041dfb4de84"
VERSION="0.1.0"
[ "$(entry '.source.sha')" = "$SHA" ] \
  || fail "the entry's sha moved without this test: bump sha and version together, then update SHA and VERSION here"
[ "$(entry '.version')" = "$VERSION" ] \
  || fail "the entry's version is not $VERSION; a sha bump must move the version with it"

# software-dev pulls it in as a dependency, the way it pulls superpowers.
jq -e '.dependencies | index("writing-clearly-and-concisely")' \
  "$REPO_ROOT/plugins/software-dev/.claude-plugin/plugin.json" >/dev/null \
  || fail "software-dev must declare $NAME as a dependency"

UP="$(fetch_pinned https://github.com/softaworks/agent-toolkit.git "$SHA" \
  "${TMPDIR:-/tmp}/software-dev-upstream-agent-toolkit")"
[ -f "$UP/dist/plugins/$NAME/skills/$NAME/SKILL.md" ] || fail "no dist plugin at $SHA"
[ -f "$UP/skills/$NAME/SKILL.md" ] || fail "no source skill at $SHA"
diff -r "$UP/dist/plugins/$NAME/skills/$NAME" "$UP/skills/$NAME" \
  || fail "dist and source trees differ at $SHA; the entry would serve something the source does not show"
[ "$(sed -n 2p "$UP/skills/$NAME/SKILL.md")" = "name: $NAME" ] || fail "upstream skill name changed"
grep -q 'Copyright (c) 2026 Leonardo Flores' "$UP/LICENSE" || fail "upstream LICENSE holder changed; re-check the marketplace description"

printf 'curated-writing: dist == source at %s, version %s, one skill, a software-dev dependency\n' "$SHA" "$VERSION"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-curated-writing.sh`
Expected: `FAIL: source.source must be git-subdir`, exit 1 (the entry does not exist, so every `jq` selection is empty).

- [ ] **Step 3: Declare the entry and the dependency**

Edit `.claude-plugin/marketplace.json` by hand, not with `jq`, which would reflow the file: after the `superpowers` object's closing `}` (the last element of `plugins`), add a comma and this object:

```json
    {
      "name": "writing-clearly-and-concisely",
      "description": "softaworks/agent-toolkit, curated: one skill, Strunk's rules for prose humans read.",
      "category": "documentation",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/softaworks/agent-toolkit.git",
        "path": "dist/plugins/writing-clearly-and-concisely",
        "ref": "main",
        "sha": "3027f20f3181758385a1bb8c022d4041dfb4de84"
      },
      "version": "0.1.0",
      "strict": false,
      "skills": ["./skills/writing-clearly-and-concisely"]
    }
```

`path` is upstream's own published plugin directory: `git-subdir` copies the whole subdirectory regardless of the `skills` allowlist (proven: `brainstorming` sits in this machine's `superpowers` cache despite being excluded), so `path: "skills"` would land every agent-toolkit skill on disk to load one. `version` is authored here; upstream ships no manifest and no version, so `0.1.0` means only "this marketplace's first release of this entry", and a sha bump must move it too (§6.4).

In `plugins/software-dev/.claude-plugin/plugin.json`, change

```json
  "dependencies": ["sensemaking", "superpowers"],
```

to

```json
  "dependencies": ["sensemaking", "superpowers", "writing-clearly-and-concisely"],
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test-curated-writing.sh && bash tests/test-references-resolve.sh && bash tests/test-claude-validate.sh && bash tests/test-codex-marketplace.sh && bash tests/test-json-wellformed.sh`
Expected: `curated-writing: dist == source at 3027f20f3181758385a1bb8c022d4041dfb4de84, version 0.1.0, one skill, a software-dev dependency`; `references-resolve: 2 string-source path(s) resolve, 3 dependency name(s) resolve`; `✔ Validation passed` three times; `codex-marketplace: 2 local plugins, manifests match, no superpowers entry` (the new entry has an object source, so the Codex side stays at two); `json: … files well-formed`; exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json plugins/software-dev/.claude-plugin/plugin.json tests/test-curated-writing.sh
git commit -m "$(cat <<'EOF'
Curate writing-clearly-and-concisely at a pinned sha

Route 2: it needs no change, so no copy and no drift test. The entry uses
upstream's published shape under dist/, because git-subdir copies a whole
subdirectory and path: "skills" would land all of agent-toolkit's skills to
load one. The version is authored, since upstream has none to mirror, and the
test pins sha and version as a pair so a bump cannot move one without the
other.

A dependency of software-dev, the way superpowers is. This is a migration:
the same skill is installed on this machine from the agent-toolkit
marketplace at the identical sha, and the cutover removes that copy.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---
### Task 9: One engine for every curated entry

**Files:**
- Modify: `bin/setup` (header comment; `UPSTREAM_ROOT`; `curated_entries`, `clone_dir`; `ensure_clones` replacing `ensure_clone`; `ensure_links`; `ensure_claude`; `main`)
- Modify: `tests/test-doctor-faults.sh` (a seeded second clone; one pattern)
- Modify: `tests/test-setup-doctor.sh` (the upgrade fixture seeds the second clone)

**Interfaces:**
- Consumes: Task 8's entry; `fetch_pinned`.
- Produces: `curated_entries` (tab-separated `name url ref sha path version`, one line per `git-subdir` entry) and `clone_dir <name>`; both used by Task 10. `ensure_clones`, `ensure_links` and `ensure_claude` report `pinned clone <name> is at …`, `link <name>`, `<name>@eranroseman <version> installed`.

- [ ] **Step 1: Make the fault fixture demand the generalised messages and seed the second clone**

In `tests/test-doctor-faults.sh`, replace

```bash
CLONE="$H/.local/share/software-dev/upstream/superpowers"
SKILLS="$H/.agents/skills"
mkdir -p "$CLONE" "$SKILLS" || fail "could not seed $H"
```

with

```bash
UPSTREAM="$H/.local/share/software-dev/upstream"
CLONE="$UPSTREAM/superpowers"
SKILLS="$H/.agents/skills"
mkdir -p "$CLONE" "$SKILLS" || fail "could not seed $H"
```

Directly after the first `done < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' …)` loop (the one that seeds `$CLONE/skills/$s`), insert:

```bash
# Every other curated entry gets the same treatment: a clone with no origin,
# at a sha that cannot be the declared one, carrying its skill directories so
# the links have targets. Without it, apply mode would clone the real upstream
# over the network into this scratch HOME on every run.
seed_other_clones() {
  local name path skill dir
  while IFS="$(printf '\t')" read -r name path skill; do
    [ -n "$name" ] && [ "$name" != superpowers ] || continue
    dir="$UPSTREAM/$name"
    if [ ! -d "$dir/.git" ]; then
      mkdir -p "$dir" || fail "could not seed $dir"
      git -C "$dir" init -q || fail "git init failed in $dir"
      git -C "$dir" -c user.email=t@example.com -c user.name=t \
        commit -q --allow-empty -m seed || fail "could not seed a commit in $dir"
    fi
    mkdir -p "$dir/$path/$skill"
  done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                  | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
}
seed_other_clones
```

Change the assertion pattern `'pinned clone is at'` to `'pinned clone superpowers is at'`.

And in the second fixture (`H2`), directly after its own `done < <(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' …)` loop, insert:

```bash
UPSTREAM="$H2/.local/share/software-dev/upstream" seed_other_clones
```

Run: `bash tests/test-doctor-faults.sh`
Expected: `FAIL: doctor did not report: pinned clone superpowers is at`, exit 1. The old engine names no entry.

- [ ] **Step 2: Seed the second clone in the upgrade fixture**

In `tests/test-setup-doctor.sh`, directly after `cp -a "$(fetch_upstream)" "$CLONE" || fail "could not seed the pinned clone"`, insert:

```bash
  # Every other curated entry's clone, the same way, so bin/setup has nothing
  # to fetch: the CI end-to-end job is where the real clone is exercised.
  while IFS="$(printf '\t')" read -r name url sha; do
    [ -n "$name" ] && [ "$name" != superpowers ] || continue
    cp -a "$(fetch_pinned "$url" "$sha" "${TMPDIR:-/tmp}/software-dev-upstream-$name")" \
      "$(dirname "$CLONE")/$name" || fail "could not seed the $name clone"
  done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir")
                  | [.name, .source.url, .source.sha] | @tsv' "$MARKETPLACE")
```

Then make the same fixture exercise the dependency-update path, which nothing did before. Three edits in the same `if command -v claude` block:

Replace

```bash
  PJ="plugins/software-dev/.claude-plugin/plugin.json"
  cp -a "$REPO_ROOT" "$W/repo" || fail "could not copy the checkout into $W"
  jq '.version = "0.0.1"' "$REPO_ROOT/$PJ" > "$W/lowered" || fail "could not lower the version"
  cp "$W/lowered" "$W/repo/$PJ"
```

with

```bash
  PJ="plugins/software-dev/.claude-plugin/plugin.json"
  # sensemaking too: it installs as a dependency, and a parent's update does
  # not carry it, so its own update path is exercised here on every run.
  PJS="plugins/sensemaking/.claude-plugin/plugin.json"
  cp -a "$REPO_ROOT" "$W/repo" || fail "could not copy the checkout into $W"
  jq '.version = "0.0.1"' "$REPO_ROOT/$PJ" > "$W/lowered" || fail "could not lower the version"
  cp "$W/lowered" "$W/repo/$PJ"
  jq '.version = "0.0.1"' "$REPO_ROOT/$PJS" > "$W/lowered-s" || fail "could not lower sensemaking's version"
  cp "$W/lowered-s" "$W/repo/$PJS"
```

Directly after `cp "$REPO_ROOT/$PJ" "$W/repo/$PJ"` add the line `cp "$REPO_ROOT/$PJS" "$W/repo/$PJS"`.

And directly after the four lines that read `got` and assert `bin/setup left software-dev at $got, declared $want`, add:

```bash
  want_s="$(jq -r .version "$REPO_ROOT/$PJS")"
  got_s="$(jq -r '.plugins["sensemaking@eranroseman"][0].version' \
    "$W/home/.claude/plugins/installed_plugins.json")"
  [ "$got_s" = "$want_s" ] \
    || fail "bin/setup left sensemaking at $got_s, declared $want_s; a dependency does not move with its parent:"$'\n'"$out"
```

Run: `bash tests/test-setup-doctor.sh`
Expected: `FAIL: bin/setup left sensemaking at 0.0.1, declared 0.1.0; a dependency does not move with its parent:` followed by the run's output, exit 1. The current engine verifies `sensemaking` is present and never compares its version.

- [ ] **Step 3: Generalise the engine**

Six edits to `bin/setup`, top to bottom.

(a) In the header comment, replace

```
#   .claude-plugin/marketplace.json   the curated superpowers entry: sha,
#                                     version, and the thirteen skill names
```

with

```
#   .claude-plugin/marketplace.json   every curated (git-subdir) entry: url,
#                                     sha, version, and its skill names
```

(b) Replace the line `CLONE_DIR="$HOME/.local/share/software-dev/upstream/superpowers"` with

```bash
# One pinned clone per curated (git-subdir) marketplace entry, named after it:
#   $UPSTREAM_ROOT/superpowers, $UPSTREAM_ROOT/writing-clearly-and-concisely
UPSTREAM_ROOT="$HOME/.local/share/software-dev/upstream"
```

(c) Replace the two helpers `declared_sha()` and `curated_skills()` (both bodies, from `declared_sha() {` to the closing `}` of `curated_skills`) with

```bash
# Every curated entry: a git-subdir source pinned by sha. One line each,
# tab-separated: name, url, ref, sha, path, version.
curated_entries() {
  jq -r '.plugins[] | select(.source.source? == "git-subdir")
         | [.name, .source.url, .source.ref, .source.sha, .source.path, .version] | @tsv' "$MARKETPLACE"
}

clone_dir() { printf '%s/%s' "$UPSTREAM_ROOT" "$1"; }
```

(d) Replace the whole of `ensure_clone()` with

```bash
ensure_clones() {
  local name url sha dir have
  needs jq "the curated entries cannot be read, so no pinned clone is checked" || return
  while IFS="$(printf '\t')" read -r name url _ sha _ _; do
    [ -n "$name" ] || continue
    dir="$(clone_dir "$name")"
    if [ "${#sha}" -ne 40 ]; then
      bad "the $name entry carries no 40-character sha"
      continue
    fi
    if [ ! -d "$dir/.git" ]; then
      if ! applying; then
        bad "the pinned clone for $name is missing: $dir"
        continue
      fi
      mkdir -p "$(dirname "$dir")" || { bad "could not create $(dirname "$dir")"; continue; }
      # Never chained with &&: a failed clone would short-circuit the checkout
      # and leave the directory at whatever it happened to be.
      if git clone -q "$url" "$dir"; then
        did "cloned $url into $dir"
      else
        bad "could not clone $url into $dir"
        continue
      fi
    fi

    have="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    if [ "$have" = "$sha" ]; then
      ok "pinned clone $name is at $sha"
      continue
    fi
    if ! applying; then
      bad "pinned clone $name is at ${have:-an unknown revision}, declared $sha"
      continue
    fi
    git -C "$dir" fetch -q origin || { bad "could not fetch in $dir"; continue; }
    if git -C "$dir" checkout -q "$sha"; then
      did "checked out $sha in $dir"
    else
      bad "could not check out $sha in $dir"
      continue
    fi
    have="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    if [ "$have" = "$sha" ]; then
      ok "pinned clone $name is at $sha"
    else
      bad "pinned clone $name is at ${have:-an unknown revision}, declared $sha"
    fi
  done < <(curated_entries)
}
```

(e) Replace the whole of `ensure_links()` with

```bash
ensure_links() {
  local entry epath skill name target link actual aside
  if applying; then
    mkdir -p "$SKILL_ROOT" || { bad "could not create $SKILL_ROOT"; return; }
  elif [ ! -d "$SKILL_ROOT" ]; then
    bad "the skill root is missing: $SKILL_ROOT"
    return
  fi
  # After the skill root, which needs no jq: without the curated list the loop
  # below iterates nothing and reports nothing at all.
  needs jq "the curated skill list cannot be read, so no link is checked" || return

  # Every skill of every curated entry: the link target is the skill directory
  # inside that entry's pinned clone, under the entry's source.path, and the
  # link is named after the directory's basename.
  while IFS="$(printf '\t')" read -r entry epath skill; do
    [ -n "$skill" ] || continue
    name="$(basename "$skill")"
    target="$(clone_dir "$entry")/$epath/$skill"
    link="$SKILL_ROOT/$name"

    # The target first: moving a squatter aside before knowing the link can be
    # created leaves the user with neither their file nor a link. In check mode
    # this is the root cause of every other verdict below it.
    if [ ! -e "$target" ]; then
      bad "link target missing: $target"
      continue
    fi

    if [ -L "$link" ]; then
      # Dangling first, and by `[ -e ]` on the link rather than by an empty
      # readlink: `readlink -f` canonicalises a path whose last component does
      # not exist and returns it, so a dangling link reports a target here, not
      # the empty string. `[ -e ]` follows the link and is false exactly when
      # the target is missing -- which is also why the README's guard passed on
      # a dangling link and let `ln -s` fail with "File exists".
      if [ ! -e "$link" ]; then
        if ! applying; then bad "dangling link: $link"; continue; fi
        # Moved aside like every other squatter, never deleted: the target may
        # be a volume that is merely unmounted. Plain readlink rather than -f,
        # because what the link stores is the only record of where it pointed
        # and -f canonicalises a missing target into something else.
        actual="$(readlink "$link" 2>/dev/null)"
        aside="$(aside_path "$link")"
        mv "$link" "$aside" || { bad "could not move the dangling $link aside"; continue; }
        did "moved $link aside to $aside (it pointed at $actual)"
      else
        actual="$(readlink -f "$link" 2>/dev/null)"
        if [ "$actual" = "$target" ]; then
          ok "link $name"
          continue
        fi
        if ! applying; then bad "link $name points at $actual, not $target"; continue; fi
        aside="$(aside_path "$link")"
        mv "$link" "$aside" || { bad "could not move $link aside"; continue; }
        did "moved $link aside to $aside (it pointed at $actual)"
      fi
    elif [ -e "$link" ]; then
      # A directory or a regular file where a link belongs. Never deleted.
      if ! applying; then bad "$name exists and is not a symlink: $link"; continue; fi
      aside="$(aside_path "$link")"
      mv "$link" "$aside" || { bad "could not move $link aside"; continue; }
      did "moved $link aside to $aside (not a symlink)"
    fi

    if ! applying; then
      bad "missing link: $link"
      continue
    fi
    if ln -s "$target" "$link"; then
      did "linked $name"
      ok "link $name"
    else
      bad "could not create $link"
    fi
  done < <(jq -r '.plugins[] | select(.source.source? == "git-subdir") as $p
                  | $p.skills[] | [$p.name, $p.source.path, (. | sub("^\\./"; ""))] | @tsv' "$MARKETPLACE")
}
```

(f) In `ensure_claude()`, replace everything from the comment `# The two dependencies install and enable themselves; verify rather than act.` to the function's closing `}` with the two blocks below, in this order. The first moves `sensemaking` to its declared version, which nothing did before: a parent's update does not carry a dependency (sub-project 2's plan, B2), so without it the `0.2.0` bump in Task 11 would never reach a Claude that already holds `0.1.0`, and `adhd` would never load. The second handles every curated entry.

```bash
  # sensemaking installs itself as a dependency of the first install, but a
  # parent's update does not carry it (sub-project 2's plan, B2), so a copy
  # behind its manifest moves under its own update. `[ -n "$have" ]` first:
  # update fails against a plugin that is not installed, and a missing
  # dependency is the parent install's business.
  want="$(jq -r '.version' "$REPO_ROOT/plugins/sensemaking/.claude-plugin/plugin.json")"
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
  # Every curated entry, by its declared version. superpowers arrives as a
  # dependency of the first install; an entry declared after a machine was set
  # up does not -- measured 2026-09-06 on claude 2.1.263, `claude plugin update
  # software-dev` moved the parent from 0.6.0 to 0.7.0 and left its new
  # dependency uninstalled -- so a missing entry is installed by name. An
  # installed one at the wrong version only moves under `update`.
  while IFS="$(printf '\t')" read -r name _ _ _ _ want; do
    [ -n "$name" ] || continue
    have="$(installed_version "$name")"
    if [ "$have" != "$want" ] && applying; then
      if [ -z "$have" ]; then
        if claude plugin install "$name@eranroseman" --scope user >/dev/null 2>&1; then
          did "installed $name@eranroseman"
        else
          bad "claude plugin install $name@eranroseman failed"
        fi
      else
        claude plugin update "$name@eranroseman" >/dev/null 2>&1 \
          || bad "claude plugin update $name@eranroseman failed"
      fi
      have="$(installed_version "$name")"
      [ "$have" = "$want" ] && [ -n "$have" ] && did "$name@eranroseman is now $want"
    fi
    if [ "$have" = "$want" ]; then
      ok "$name@eranroseman $want installed"
    else
      bad "$name@eranroseman is ${have:-not installed}, declared $want"
    fi
  done < <(curated_entries)
}
```

(g) In `main()`, change `ensure_clone` to `ensure_clones`.

Then:

```bash
bash -n bin/setup && shellcheck bin/setup && echo lint-clean
grep -n 'CLONE_DIR\|declared_sha\|curated_skills\|ensure_clone$' bin/setup
```

Expected: `lint-clean`, and no matches: nothing refers to the old names.

- [ ] **Step 4: Run the fixtures and the doctor**

Run: `bash tests/test-doctor-faults.sh && bash tests/test-setup-doctor.sh`
Expected: `doctor-faults: five seeded faults reported and the local ones repaired`; `setup-doctor: two entry points, lint clean, prerequisites split as documented` (with a `NOTE: codex is on the minimal PATH` line on this machine); exit 0. The upgrade fixture now seeds both clones, so `bin/setup` fetches nothing; on CI the end-to-end job is where the real `git clone` of `softaworks/agent-toolkit` happens.

Run: `bin/doctor 2>&1 | grep -v '^OK:'`
Expected, on this machine, before the cutover: four `FAIL:` lines and nothing else new — `the pinned clone for writing-clearly-and-concisely is missing: /home/eranr/.local/share/software-dev/upstream/writing-clearly-and-concisely`, `link target missing: …/dist/plugins/writing-clearly-and-concisely/skills/writing-clearly-and-concisely`, `writing-clearly-and-concisely@eranroseman is not installed, declared 0.1.0`, and the marketplace-clone-behind line if the local marketplace clone is stale. That is the declared state the machine has not been converged to; Task 12 converges it. **Do not run `bin/setup` against this machine here.**

- [ ] **Step 5: Commit**

```bash
git add bin/setup tests/test-doctor-faults.sh tests/test-setup-doctor.sh
git commit -m "$(cat <<'EOF'
Drive the engine from every curated entry, not from superpowers by name

ensure_clones, ensure_links and ensure_claude iterate the git-subdir entries
of the marketplace: one pinned clone per entry under the upstream root, a
link per listed skill into that entry's clone under its source.path, and an
installed version per entry. A missing entry is installed by name: measured
on claude 2.1.263, `claude plugin update software-dev` moves the parent and
leaves a newly declared dependency uninstalled. sensemaking is moved to its
declared version for the same reason; nothing did that before.

The two fixtures seed a second clone with no origin, so apply mode has
nothing to fetch and the tests stay off the network.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: The doctor sees one name reaching two skills

**Files:**
- Modify: `bin/setup` (`report_only` item 4's comment, a `report_duplicates` call, and two new functions)
- Modify: `tests/test-doctor-faults.sh`, `tests/test-setup-doctor.sh` (`sha256sum` in the four restricted-`PATH` lists)
- Create: `tests/test-doctor-duplicates.sh`

**Interfaces:**
- Consumes: `CODEX_LIST`, set by `ensure_codex`; `INSTALLED_PLUGINS`, `KNOWN_MARKETPLACES`, `SKILL_ROOT`, `CODEX_SKILLS`.
- Produces: `NOTE: <Claude|Codex>: skill <name> resolves to N different trees: <dir> (<hash12>), …`, `NOTE: <harness>: no skill name resolves to more than one tree`, and `NOTE: plugin cache for an unregistered marketplace: <dir> (left alone; remove it by hand)`. Task 12's gate enumerates them.

- [ ] **Step 1: Write the failing fixture test**

Create `tests/test-doctor-duplicates.sh`:

```bash
#!/usr/bin/env bash
# bin/doctor must report one skill name reaching two different trees on one
# harness, and a Claude plugin cache whose marketplace is not registered, and
# must stay quiet on the three false positives spec section 6.6 measured: the
# same content under two paths, a superseded plugin version, and the same
# name differing only across harnesses. Needs no network and no CLI: every
# route is filesystem state plus the two registry files.
. "$(dirname "$0")/lib.sh"

DOCTOR="$REPO_ROOT/bin/doctor"
H="$(mktemp -d)"
trap 'rm -rf "$H"' EXIT
A="$H/.agents/skills"; C="$H/.claude/skills"; X="$H/.codex/skills"
mkdir -p "$A" "$C" "$X" "$H/.claude/plugins" || fail "could not seed $H"

skill() { mkdir -p "$1" && printf -- '---\nname: %s\n---\n%s\n' "$(basename "$1")" "$2" > "$1/SKILL.md"; }

# alpha: one tree, two paths. Same content, so not a finding.
skill "$A/alpha" "alpha body"
ln -s "$A/alpha" "$C/alpha"

# beta: two trees on Claude. The finding.
skill "$A/beta" "beta as skills.sh installs it"
skill "$H/.claude/plugins/cache/mkt/plug/2.0.0/skills/beta" "beta as the plugin ships it"

# gamma: differs only in a superseded plugin version, which is not current.
skill "$A/gamma" "gamma current"
skill "$H/.claude/plugins/cache/mkt/plug/1.0.0/skills/gamma" "gamma old"

# delta: differs only across harnesses. Not a finding on either.
skill "$C/delta" "delta on claude"
skill "$X/delta" "delta on codex"

# A git-subdir cache whose skills sit at the plugin root, not under skills/.
skill "$H/.claude/plugins/cache/mkt/subdir/1.0.0/epsilon" "epsilon from the curated entry"
skill "$C/epsilon" "epsilon from a user copy"

cat > "$H/.claude/plugins/installed_plugins.json" <<JSON
{"version":2,"plugins":{
  "plug@mkt":[{"scope":"user","version":"2.0.0","installPath":"$H/.claude/plugins/cache/mkt/plug/2.0.0"}],
  "subdir@mkt":[{"scope":"user","version":"1.0.0","installPath":"$H/.claude/plugins/cache/mkt/subdir/1.0.0"}]}}
JSON
cat > "$H/.claude/plugins/known_marketplaces.json" <<'JSON'
{"mkt":{"source":{"source":"github","repo":"x/y"},"installLocation":"/nowhere"}}
JSON
# Residue: a cache directory for a marketplace the registry no longer names.
mkdir -p "$H/.claude/plugins/cache/gone/old/1.0.0/skills/zeta"

# No codex on this PATH: the Codex pool is not reported, and nothing is added
# to a marketplace over the network.
BIN="$H/bin"
mkdir -p "$BIN"
for t in bash git jq sed awk grep find date readlink basename dirname \
         mv ln mkdir cp cat sha256sum; do
  p="$(command -v "$t" 2>/dev/null)" || fail "the fixture needs $t on PATH"
  ln -sf "$p" "$BIN/$t"
done
out="$(env HOME="$H" CODEX_HOME="$H/.codex" PATH="$BIN" /bin/bash "$DOCTOR" 2>&1 || true)"

printf '%s\n' "$out" | grep -q 'NOTE: Claude: skill beta resolves to 2 different trees' \
  || fail "the doctor did not report beta:"$'\n'"$out"
printf '%s\n' "$out" | grep -q 'NOTE: Claude: skill epsilon resolves to 2 different trees' \
  || fail "the doctor did not see a git-subdir cache whose skills sit at its root:"$'\n'"$out"
for quiet in alpha gamma delta; do
  printf '%s\n' "$out" | grep -q "skill $quiet resolves" \
    && fail "the doctor reported $quiet, a measured false positive:"$'\n'"$out"
done
printf '%s\n' "$out" | grep -q "NOTE: plugin cache for an unregistered marketplace: $H/.claude/plugins/cache/gone" \
  || fail "the doctor did not report the unregistered cache:"$'\n'"$out"
printf '%s\n' "$out" | grep -q "unregistered marketplace: $H/.claude/plugins/cache/mkt" \
  && fail "the doctor reported a registered marketplace's cache as unregistered"
printf '%s\n' "$out" | grep -q 'NOTE: Codex:' \
  && fail "the Codex pool was reported with no codex on PATH"

printf 'doctor-duplicates: one Claude duplicate and one residue reported; three false positives quiet\n'
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/test-doctor-duplicates.sh`
Expected: `FAIL: the doctor did not report beta:` followed by the doctor's output, exit 1.

- [ ] **Step 3: Add the check**

In `bin/setup`, replace everything from the comment `# 4. A skills.sh copy of a skill this plugin vendors.` to the closing `}` of `report_only()` with:

```bash
  # 4. A skills.sh copy of a skill this plugin vendors under another name. A
  # rename is invisible to the by-name check below, so this one stays declared.
  if [ -f "$LOCKFILE" ] \
     && jq -e '.skills["setup-matt-pocock-skills"]' "$LOCKFILE" >/dev/null 2>&1; then
    note "setup-matt-pocock-skills is installed through skills.sh, but this plugin vendors an adapted copy as setup-repository; remove the unadapted one with 'npx skills remove setup-matt-pocock-skills -g'"
  fi

  report_duplicates
}

# 5. One skill name reaching two different trees on one harness. Derived
# from every route that harness loads a skill by, never from a declared list:
# its user skill root, the shared root, and the install path of each of its
# plugins. Three rules, each earned from a measured false positive on a clean
# machine (spec section 6.6): compare content, not path, so the thirteen
# curated links into the pinned clone are not thirteen findings; take only
# the current version of each installed plugin, which the install registry
# names, so a plugin bump does not manufacture duplicates of its own skills;
# and report a Claude plugin cache whose marketplace is no longer registered
# as its own finding rather than filtering it away. Per harness, because the
# hazard is one name reaching two skills in one session; the two harnesses
# running different versions of a third-party plugin is a different, milder
# thing and is not reported here. Reported, never repaired.
report_duplicates() {
  local -a claude_dirs=() codex_dirs=()
  local root dir path mkt name version

  # A plugin's skills sit under skills/, or at its root when a git-subdir
  # entry's path already is the skills directory, as the superpowers entry's
  # is. Both are listed; a directory without SKILL.md is skipped below.
  plugin_skill_dirs() {
    local path="$1" dir
    for dir in "$path"/skills/*/ "$path"/*/; do
      [ -f "$dir/SKILL.md" ] && printf '%s\n' "${dir%/}"
    done
  }

  for root in "$HOME/.claude/skills" "$SKILL_ROOT"; do
    [ -d "$root" ] || continue
    for dir in "$root"/*/; do [ -f "$dir/SKILL.md" ] && claude_dirs+=("${dir%/}"); done
  done
  if [ -f "$INSTALLED_PLUGINS" ]; then
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      while IFS= read -r dir; do claude_dirs+=("$dir"); done < <(plugin_skill_dirs "$path")
    done < <(jq -r '.plugins[]?[]?.installPath // empty' "$INSTALLED_PLUGINS" 2>/dev/null)
  fi
  report_pool Claude "${claude_dirs[@]}"

  for root in "$CODEX_SKILLS" "$SKILL_ROOT"; do
    [ -d "$root" ] || continue
    for dir in "$root"/*/; do [ -f "$dir/SKILL.md" ] && codex_dirs+=("${dir%/}"); done
  done
  # Codex loads an installed plugin from its cache, keyed by marketplace,
  # name and installed version; `codex plugin list --json` names all three.
  if [ -n "$CODEX_LIST" ]; then
    while IFS="$(printf '\t')" read -r mkt name version; do
      [ -n "$name" ] || continue
      path="${CODEX_HOME:-$HOME/.codex}/plugins/cache/$mkt/$name/$version"
      while IFS= read -r dir; do codex_dirs+=("$dir"); done < <(plugin_skill_dirs "$path")
    done < <(printf '%s' "$CODEX_LIST" \
      | jq -r '.installed[]? | select(.enabled) | [.marketplaceName, .name, .version] | @tsv')
  fi
  if have codex; then report_pool Codex "${codex_dirs[@]}"; fi

  # A Claude plugin cache whose marketplace is not registered: residue of a
  # removal, and not this script's to delete.
  if [ -d "$HOME/.claude/plugins/cache" ]; then
    for dir in "$HOME/.claude/plugins/cache"/*/; do
      name="$(basename "$dir")"
      jq -e --arg m "$name" '.[$m]' "$KNOWN_MARKETPLACES" >/dev/null 2>&1 \
        || note "plugin cache for an unregistered marketplace: ${dir%/} (left alone; remove it by hand)"
    done
  fi
}

# $1 the harness name, then every skill directory that harness can load.
# Hashing SKILL.md is the content identity: two paths with one hash are the
# same skill, and a name with two hashes is the finding.
report_pool() {
  local harness="$1" dir name h found=0
  local -A hashes=() places=()
  local -a distinct
  shift
  for dir in "$@"; do
    name="$(basename "$dir")"
    h="$(sha256sum "$dir/SKILL.md" 2>/dev/null)" || continue
    h="${h%% *}"
    case " ${hashes[$name]:-} " in
      *" $h "*) ;;
      *) hashes[$name]="${hashes[$name]:-} $h"
         places[$name]="${places[$name]:-}${places[$name]:+, }$dir (${h:0:12})" ;;
    esac
  done
  for name in "${!hashes[@]}"; do
    read -r -a distinct <<<"${hashes[$name]}"
    [ "${#distinct[@]}" -gt 1 ] || continue
    found=$((found + 1))
    note "$harness: skill $name resolves to ${#distinct[@]} different trees: ${places[$name]}"
  done
  [ "$found" -eq 0 ] && note "$harness: no skill name resolves to more than one tree"
}
```

Then add `sha256sum` to all four restricted-`PATH` tool lists: in `tests/test-doctor-faults.sh` the `BIN2` list (`… rm mv ln mkdir cp cat` → `… rm mv ln mkdir cp cat sha256sum`) and the `BIN` list (same change); in `tests/test-setup-doctor.sh` the `NOJQ` list (`… mv ln mkdir cp cat` → `… mv ln mkdir cp cat sha256sum`) and the `BIN` list. Without it a hash silently fails and the check reports nothing, which is the class of quiet failure the prior plan's `rm mv ln mkdir` finding was about.

```bash
bash -n bin/setup && shellcheck bin/setup && echo lint-clean
grep -c sha256sum tests/test-doctor-faults.sh tests/test-setup-doctor.sh
```

Expected: `lint-clean`; `2` and `2`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test-doctor-duplicates.sh && bash tests/test-doctor-faults.sh && bash tests/test-setup-doctor.sh`
Expected: `doctor-duplicates: one Claude duplicate and one residue reported; three false positives quiet`; the two fixture summary lines; exit 0.

Run: `bin/doctor 2>&1 | grep '^NOTE:'`
Expected, on this machine: the telemetry and auto-update notes, the redundant-links note, then

```
NOTE: Claude: skill brainstorming resolves to 2 different trees: /home/eranr/.claude/plugins/cache/eranroseman/superpowers/6.3.0/brainstorming (74edf03ea6d2), /home/eranr/.claude/plugins/cache/eranroseman/software-dev/0.6.0/skills/brainstorming (4a2033c06acf)
NOTE: Codex: no skill name resolves to more than one tree
NOTE: plugin cache for an unregistered marketplace: /home/eranr/.claude/plugins/cache/superpowers-dev (left alone; remove it by hand)
```

The `brainstorming` pair is the survivor §6.6 names as by design: the curated `superpowers` cache holds upstream's copy on disk because `git-subdir` copies the whole subdirectory, and the vendored one differs by exactly the narrowed description. The `superpowers-dev` residue is issue #25; Task 12 removes it.

- [ ] **Step 5: Commit**

```bash
git add bin/setup tests/test-doctor-duplicates.sh tests/test-doctor-faults.sh tests/test-setup-doctor.sh
git commit -m "$(cat <<'EOF'
Report one skill name reaching two different trees

Derived from every route a harness loads a skill by, never from a declared
list: a hand-maintained conflict table can only know what someone remembered
to add. Three rules, each earned from a measured false positive on a clean
machine: compare content, not path, so thirteen curated links into one clone
are not thirteen findings; take only the current version of each installed
plugin; and report a Claude plugin cache whose marketplace is no longer
registered as its own finding rather than filtering it away. Per harness,
because the hazard is one session holding two skills under one name.

Reported, never repaired. The setup-matt-pocock-skills note stays: a rename
is invisible to a by-name check.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: Release 0.7.0 and 0.2.0, and say what the marketplace now carries

**Files:**
- Modify: `plugins/software-dev/.claude-plugin/plugin.json`, `plugins/software-dev/.codex-plugin/plugin.json` (`0.7.0`, descriptions)
- Modify: `plugins/sensemaking/.claude-plugin/plugin.json`, `plugins/sensemaking/.codex-plugin/plugin.json` (`0.2.0`, descriptions)
- Modify: `.claude-plugin/marketplace.json` (two descriptions)
- Modify: `tests/test-hook.sh` (two version assertions)
- Modify: `README.md`, `plugins/software-dev/README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: the release the cutover installs.

- [ ] **Step 1: Move the version assertions first**

In `tests/test-hook.sh`, change both `'0.6.0'` literals to `'0.7.0'` (the lines asserting `Claude manifest version must be 0.7.0` and `Codex manifest version must be 0.7.0`).

Run: `bash tests/test-hook.sh`
Expected: `FAIL: Claude manifest version must be 0.7.0`, exit 1.

- [ ] **Step 2: Bump the four manifests and refresh their descriptions**

By hand, preserving each file's formatting:

- `plugins/software-dev/.claude-plugin/plugin.json`: `"version": "0.7.0"`; `"description": "Glue over superpowers and mattpocock/skills for Claude Code and Codex: narrowed brainstorming, the repository scaffolder, the consistency audit and its inspector, diagnosing-bugs, and finding-duplicate-functions."`.
- `plugins/software-dev/.codex-plugin/plugin.json`: the same `version` and `description`; `"longDescription": "Narrowed brainstorming front door over the superpowers spine and mattpocock's engineering skills, plus the repository scaffolder, a refuted-before-reported consistency audit, a reproduction-first debugging loop, and a Python duplicate-function finder."`.
- `plugins/sensemaking/.claude-plugin/plugin.json`: `"version": "0.2.0"`; `"description": "Skills shared by software-dev and research-vault: rethink-audit and adhd."`.
- `plugins/sensemaking/.codex-plugin/plugin.json`: the same `version` and `description`; `"longDescription": "Clean-slate redesign audits and parallel divergent ideation, shared by `software-dev` and `research-vault`."`.
- `.claude-plugin/marketplace.json`: the `software-dev` entry's description becomes `"Glue over superpowers and mattpocock/skills: narrowed brainstorming, the repository scaffolder, the consistency audit, diagnosing-bugs, finding-duplicate-functions, plus a SessionStart hook on Claude Code."`; the `sensemaking` entry's becomes `"Skills shared by software-dev and research-vault: rethink-audit and adhd."`.

- [ ] **Step 3: Rewrite the two READMEs' inventories**

In `README.md`, replace the intro list (from `The source repository for the` to the end of the `superpowers` bullet) with:

```markdown
The source repository for the `eranroseman` plugin marketplace, which serves
both Claude Code and Codex. It hosts four entries:

- `software-dev`: the glue plugin. obra/superpowers' `brainstorming`
  skill vendored with a narrowed description, the repository scaffolder,
  the authored `consistency-audit` with its inspector agent, a vendored
  `diagnosing-bugs`, a forked `finding-duplicate-functions`, plus a
  SessionStart hook on Claude Code (Codex is offered none, by design).
  Depends on the three entries below.
- `sensemaking`: skills shared with `research-vault`: `rethink-audit` and
  `adhd`. Its README states which plugin holds a skill, and why.
- `superpowers`: obra/superpowers taken straight from upstream at a pinned
  commit, 13 of its 14 skills. `brainstorming` is the one left out. This entry
  is Claude Code only; Codex gets the same skills by symlink, created by
  `bin/setup` as described in Install below.
- `writing-clearly-and-concisely`: softaworks/agent-toolkit's one skill of
  that name, curated at a pinned commit from upstream's published plugin
  directory. Claude Code only, by the same mechanism and with the same Codex
  symlink.
```

In the `## Install` section, replace the sentence beginning `What the run leaves behind:` with:

```markdown
What the run leaves behind: both plugins installed on each harness present, a
pinned clone per curated entry — obra/superpowers and softaworks/agent-toolkit
— fourteen symlinks into them under `~/.agents/skills` (Codex's documented
user skill root, created whether or not Codex is present), and the declared
skills.sh set installed at its declared refs.
```

In the `## Update` section, change `re-verifying the thirteen links` to `re-verifying the fourteen links`.

Replace the `## Checks` section's first paragraph with:

```markdown
`tests/run.sh` runs every static check: manifest schema on both harnesses, the
upstream pin, the skills.sh pins, the curated writing entry, drift on the five
vendored or forked skills, the invariants every plugin skill must hold, hook
output, the engine's shape, the doctor's fault detection, and the doctor's
duplicate detection. Ten of them touch the network: the three pin checks, the
five drift checks, the hook payload check, and the engine's own test, whose
upgrade-path assertion fetches the pinned upstream trees when `claude` is on
`PATH`. CI runs the same script, plus an end-to-end `bin/setup` run against a
scratch `HOME`.
```

In `plugins/software-dev/README.md`, in the `What it ships:` list, add after the `skills/setup-repository/` bullet:

```markdown
- `skills/consistency-audit/` and `agents/consistency-audit-inspector.md`:
  an authored, user-invoked audit that reads a repository whole for
  contradictions, duplication, drifted terms and stale claims, refutes every
  candidate before reporting it, and dispatches the read-only inspector as
  two independent readers per slice. On Codex, where a plugin cannot ship a
  subagent, it runs as one reader and says so.
- `skills/diagnosing-bugs/`: mattpocock/skills' reproduction-first debugging
  loop, vendored at tag `v1.2.3` with one change, a 69-character description
  that Codex shows whole and that no longer shares a trigger word with
  `superpowers:systematic-debugging`. Model-invoked: it should fire unprompted
  when a bug resists reproduction.
- `skills/finding-duplicate-functions/`: a rewritten fork of
  obra/superpowers-lab's skill, for Python. Its `PROVENANCE.md` records what
  changed; only its two prompt templates are upstream's, and the drift test
  holds them there.
```

In the `What it depends on` list, add:

```markdown
- `writing-clearly-and-concisely@eranroseman`: softaworks/agent-toolkit's
  skill of that name, curated at a pinned commit. `consistency-audit` uses it
  for its report when present.
```

And in `## License`, replace the sentence with: ``MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent; `skills/setup-repository/` and `skills/diagnosing-bugs/` are MIT, © 2026 Matt Pocock; the two templates under `skills/finding-duplicate-functions/scripts/` are MIT, © 2025 Jesse Vincent. See `LICENSE`.``

- [ ] **Step 4: Run the whole suite**

Run: `bash tests/run.sh`
Expected: eighteen `PASS` lines — `test-claude-validate`, `test-codex-marketplace`, `test-codex-validate`, `test-curated-writing`, `test-doctor-duplicates`, `test-doctor-faults`, `test-hook`, `test-json-wellformed`, `test-plugin-skills`, `test-references-resolve`, `test-setup-doctor`, `test-skills-pin`, `test-upstream-pin`, `test-vendored-adhd`, `test-vendored-brainstorming`, `test-vendored-diagnosing-bugs`, `test-vendored-duplicates`, `test-vendored-scaffolder` — exit 0.

- [ ] **Step 5: Commit, push the branch, and watch CI**

```bash
git add -A plugins/software-dev plugins/sensemaking .claude-plugin/marketplace.json tests/test-hook.sh README.md
git status --short   # expect: nothing unstaged
git commit -m "$(cat <<'EOF'
Release software-dev 0.7.0 and sensemaking 0.2.0

software-dev gains consistency-audit with its inspector, diagnosing-bugs and
finding-duplicate-functions, and a third dependency; sensemaking gains adhd.
The READMEs and marketplace descriptions say so, and the root README's Checks
list names the ten network tests among the eighteen.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
git push -u origin roster-and-retirement
gh run list --branch roster-and-retirement --limit 2
```

Wait for `validate` to finish: `gh run watch "$(gh run list --branch roster-and-retirement --workflow validate --limit 1 --json databaseId --jq '.[0].databaseId')"`.

Expected: both jobs green. The `setup-e2e` job now installs four plugins from the scratch marketplace, clones `softaworks/agent-toolkit`, and links fourteen skills; its `bin/doctor` step must print `clean`. If `setup-e2e` fails on the agent-toolkit clone or the fourteenth link, the engine is wrong and the cutover must not start: fix on the branch and re-push.

---
### Task 12: Merge, converge this machine, and pass the gate

This task acts on this machine. Every removal below is preceded by showing the user what will go and waiting for their go. Nothing here is on a branch: `main` carries the release, and the results land in the spec.

**Files:**
- Modify: `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` (a `### Results` subsection under §10)

**Interfaces:**
- Consumes: the release on `main`.
- Produces: a machine on which `bin/doctor` prints `clean`, both harnesses hold `software-dev` 0.7.0 and `sensemaking` 0.2.0, and the eight `harness-backup` symlinks are gone — the precondition for Tasks 13 to 15.

- [ ] **Step 1: Merge to main and push, in one motion**

```bash
cd /home/eranr/agent-plugins
git checkout main && git pull --ff-only origin main
git merge --ff-only roster-and-retirement
git push origin main
gh run list --branch main --limit 1
```

Expected: fast-forward, push accepted, a `validate` run on `main`. Wait for it to pass before continuing; the marketplace clone below pulls `main`.

- [ ] **Step 2: Refresh both marketplace clones and converge**

```bash
claude plugin marketplace update eranroseman
codex plugin marketplace upgrade
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup 2>&1 | tee /tmp/roster-setup.log | grep -v '^OK:'
```

Expected `DID:` lines, in this order: `cloned https://github.com/softaworks/agent-toolkit.git into /home/eranr/.local/share/software-dev/upstream/writing-clearly-and-concisely`, `checked out 3027f20f3181758385a1bb8c022d4041dfb4de84 in …`, `linked writing-clearly-and-concisely`, `updated software-dev@eranroseman from 0.6.0 to 0.7.0`, `updated sensemaking@eranroseman to 0.2.0`, `installed writing-clearly-and-concisely@eranroseman`, `writing-clearly-and-concisely@eranroseman is now 0.1.0`, `installed codex plugin software-dev 0.7.0`, `installed codex plugin sensemaking 0.2.0`, `installed archify from tt-a1i/archify#v2.16.0`. Then `--- re-checking ---` and, after it, no `FAIL:` line. Exit 0.

If `installed writing-clearly-and-concisely@eranroseman` does not appear, `claude plugin install writing-clearly-and-concisely@eranroseman --scope user` by hand and re-run the script; that is the path measured on 2026-09-06 and the script's own branch for it.

- [ ] **Step 3: Remove the duplicated routes, in the documented order**

Show the user this list and wait for their go. Each is a plugin or marketplace whose only skill now arrives another way.

```bash
# Claude: writing-clearly-and-concisely@agent-toolkit is the same skill at the same sha as the curated entry.
claude plugin uninstall writing-clearly-and-concisely@agent-toolkit
claude plugin marketplace remove agent-toolkit
# Claude: the obra-dev plugin duplicates two skills.sh skills; skills.sh is Codex's only route, so it stays.
claude plugin uninstall superpowers-developing-for-claude-code@superpowers-developing-for-claude-code-dev
claude plugin marketplace remove superpowers-developing-for-claude-code-dev
# Codex: the same skill, installed unpinned from agent-toolkit; the pinned symlink replaces it. Plugin first, marketplace second.
codex plugin remove writing-clearly-and-concisely@agent-toolkit
codex plugin marketplace remove agent-toolkit
codex plugin list --json | jq -r '.installed[].pluginId'
grep -n 'agent-toolkit' ~/.codex/config.toml
```

Expected: the Claude commands succeed; the Codex list no longer names `writing-clearly-and-concisely@agent-toolkit`; the `grep` prints nothing. Then `ls ~/.claude/plugins/cache/`: expect `agent-toolkit` and `superpowers-developing-for-claude-code-dev` still listed — `marketplace remove` leaves the cache behind (measured; it is how #25's residue came to be) — and Step 4 removes them. If it prints a `[plugins."writing-clearly-and-concisely@agent-toolkit"]` or `[marketplaces.agent-toolkit]` table, that is the orphan sub-project 2 §7.4 warns about: **report it to the user and stop**; the script never hand-edits `config.toml`, and neither does this task.

- [ ] **Step 4: Remove what the deleted repositories will leave dangling, and the residue**

Show the user this list and wait for their go. The eight links point into `~/harness-backup`; the two agent files are hand-made copies of a file the plugin now ships (Deviation D4); the three cache directories are residue — issue #25's, plus the two Step 3 just orphaned — and each would otherwise be a `NOTE:` at the gate.

```bash
for s in consistency-audit finding-duplicate-functions rethink rethink-audit; do
  ls -l ~/.claude/skills/$s ~/.codex/skills/$s
done
ls -l ~/.claude/agents/consistency-audit-inspector.md ~/.codex/agents/consistency-audit-inspector.md
ls ~/.claude/plugins/cache/
# A .in_use/<pid> marker names a session holding the plugin; none may be live.
for d in superpowers-dev agent-toolkit superpowers-developing-for-claude-code-dev; do
  for m in ~/.claude/plugins/cache/$d/*/*/.in_use/*; do
    [ -e "$m" ] || continue
    kill -0 "$(basename "$m")" 2>/dev/null && echo "LIVE: $m"
  done
done
```

Expected: the three names in the listing, and no `LIVE:` line. A `LIVE:` line names a running Claude session that loaded the old plugin; end it (or wait for it) before removing that cache.

Then, after the go:

```bash
for s in consistency-audit finding-duplicate-functions rethink rethink-audit; do
  rm ~/.claude/skills/$s ~/.codex/skills/$s
done
rm ~/.claude/agents/consistency-audit-inspector.md ~/.codex/agents/consistency-audit-inspector.md
rm -rf ~/.claude/plugins/cache/superpowers-dev \
       ~/.claude/plugins/cache/agent-toolkit \
       ~/.claude/plugins/cache/superpowers-developing-for-claude-code-dev
rmdir ~/.codex/plugins/cache/superpowers-dev 2>/dev/null || true   # empty on 2026-09-06
ls -la ~/.claude/skills ~/.codex/skills | grep -c harness-backup
```

Expected: `0`. `rm` on a symlink removes the link, never its target; nothing under `~/harness-backup` changes here.

- [ ] **Step 5: The gate, measured**

```bash
bash ~/.claude/plugins/marketplaces/eranroseman/bin/doctor 2>&1 | tee /tmp/roster-doctor.log | grep -v '^OK:'
```

Expected: exactly this set of non-OK lines, in any order (the registry's order shifts when a plugin is added, and the two paths in the `brainstorming` line may swap), and `clean`, exit 0:

```
NOTE: no telemetry-disabling variable is set; see the plugin README (this script never sets one)
NOTE: marketplace auto-update is on for eranroseman
NOTE: 18 link(s) under /home/eranr/.codex/skills resolve into /home/eranr/.agents/skills, which Codex already reads directly; they are redundant and are left alone
NOTE: Claude: skill brainstorming resolves to 2 different trees: /home/eranr/.claude/plugins/cache/eranroseman/superpowers/6.3.0/brainstorming (74edf03ea6d2), /home/eranr/.claude/plugins/cache/eranroseman/software-dev/0.7.0/skills/brainstorming (4a2033c06acf)
NOTE: Codex: no skill name resolves to more than one tree

clean
```

Any other `NOTE:` — an unregistered cache, a second duplicated name — is a finding to resolve before going on. The count of redundant Codex links stays `18`: the four links removed in Step 4 pointed into `~/harness-backup`, never into `~/.agents/skills`, so they were never counted.

```bash
claude plugin list 2>&1 | grep -A1 '@eranroseman\|@agent-toolkit\|superpowers-developing'
codex plugin list --json | jq -r '.installed[] | "\(.pluginId) \(.version)"'
claude plugin details software-dev@eranroseman | sed -n '/Component inventory/,/MCP/p'
claude plugin details sensemaking@eranroseman | sed -n '/Component inventory/,/MCP/p'
ls ~/.codex/plugins/cache/eranroseman/software-dev/0.7.0/skills ~/.codex/plugins/cache/eranroseman/sensemaking/0.2.0/skills
ls -l ~/.agents/skills/writing-clearly-and-concisely ~/.agents/skills/archify
```

Expected: Claude lists `sensemaking@eranroseman 0.2.0`, `software-dev@eranroseman 0.7.0`, `superpowers@eranroseman 6.3.0`, `writing-clearly-and-concisely@eranroseman 0.1.0`, and nothing from `agent-toolkit` or the obra-dev marketplace. Codex lists `software-dev@eranroseman 0.7.0` and `sensemaking@eranroseman 0.2.0` and nothing from `agent-toolkit`. `software-dev`'s inventory: `Skills (5)` naming `brainstorming consistency-audit diagnosing-bugs finding-duplicate-functions setup-repository`, `Agents (1) consistency-audit-inspector`. `sensemaking`'s: `Skills (2) adhd rethink-audit`. The two Codex cache listings show the same five and two directories. The symlink resolves into the agent-toolkit clone; `archify` is a directory.

- [ ] **Step 6: The live half of the gate, from a fresh session**

Start a new Claude Code session (the plugins load at launch), and in it:

- `/software-dev:consistency-audit`, `/software-dev:diagnosing-bugs`, `/software-dev:finding-duplicate-functions`, `/sensemaking:adhd` and `/sensemaking:rethink-audit` appear in the skill list, and `/writing-clearly-and-concisely:writing-clearly-and-concisely` does; no bare `/consistency-audit`, `/rethink` or `/rethink-audit` does.
- Spawn `Agent(subagent_type: "software-dev:consistency-audit-inspector", prompt: "Reply with the single word: resolved")`. Expected: it resolves and replies.

On Codex:

```bash
codex exec 'List, names only, every skill available to you whose name contains audit, adhd, diagnosing, duplicate, archify or writing-clearly.' 2>/dev/null | tail -12
```

Expected: `consistency-audit`, `rethink-audit`, `adhd`, `diagnosing-bugs`, `finding-duplicate-functions`, `archify`, `writing-clearly-and-concisely`, each once.

- [ ] **Step 7: Record the gate in the spec, and push**

Append to §10 of the spec, after step 11's paragraph `Step 11 is why the order runs this way…`:

```markdown
### Results, <YYYY-MM-DD>

Steps 1 to 7 landed as `software-dev` 0.7.0 and `sensemaking` 0.2.0 (plan:
`docs/superpowers/plans/2026-09-06-roster-and-retirement.md`). Step 8, the
gate, measured on this machine:

- `bin/setup` converged the machine in one run; `bin/doctor` then printed
  `clean` with exactly the five expected `NOTE:` lines (telemetry,
  auto-update, redundant Codex links, the by-design `brainstorming` pair,
  and the Codex all-clear). The `superpowers-dev` residue (#25) was removed by
  hand first.
- `claude plugin list` and `codex plugin list` agree with the manifests:
  <paste the two version lists>.
- Every migrated skill loads from its plugin on both harnesses: <paste the
  two `claude plugin details` inventories and the Codex `codex exec` list>.
  `software-dev:consistency-audit-inspector` resolved from a fresh session.
- The eight `harness-backup` symlinks are gone; so are the two hand-copied
  inspector files (plan Deviation D4).

Removed at this step, in the order sub-project 2 §7.4 requires:
`writing-clearly-and-concisely@agent-toolkit` and the `agent-toolkit`
marketplace on both harnesses; `superpowers-developing-for-claude-code` and
its marketplace on Claude.
```

Fill the placeholders from the measurements, then:

```bash
git add docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md
git commit -m "$(cat <<'EOF'
Record the gate: this machine converged on 0.7.0 and 0.2.0

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
git push origin main
```

---

### Task 13: Retire eranroseman/rethink

Irreversible. §9's obligations, unchanged from research-vault#73: de-register the marketplace, delete the repository, delete the copies (which go with `harness-backup` in Task 14), apply the adaptation (done in Task 2). Nothing is taken from it: the authoritative copies are the authored ones now in the plugins.

**Files:** none in this repository.

- [ ] **Step 1: De-register the marketplace and show what is about to go**

```bash
claude plugin marketplace remove rethink
jq 'has("rethink")' ~/.claude/plugins/known_marketplaces.json
ls -d ~/.claude/plugins/marketplaces/rethink 2>&1
git -C ~/dev/rethink fetch -q origin && git -C ~/dev/rethink status --short && git -C ~/dev/rethink log --oneline origin/main..HEAD
gh repo view eranroseman/rethink --json name,isPrivate,pushedAt
```

Expected: `false`; the marketplace directory is gone (or report what remains); `status` and the unpushed-commit log both empty. The repository is public, last pushed 2026-07-10, plugin 1.0.1, two diverged skill copies and a `hooks/` directory never used (§9).

**Stop and get the user's explicit go to delete `eranroseman/rethink` on GitHub and `~/dev/rethink` on disk.**

- [ ] **Step 2: Delete, after the go**

`gh`'s token has scopes `gist project read:org repo workflow` and no `delete_repo` (measured 2026-09-06), so `gh repo delete` refuses. Either the user runs `gh auth refresh -h github.com -s delete_repo` (a browser round trip) and the command below, or deletes the repository in the GitHub web UI under Settings → Danger Zone; then the directory:

```bash
gh repo delete eranroseman/rethink --yes
rm -rf ~/dev/rethink
gh repo view eranroseman/rethink 2>&1 | head -1
ls ~/dev/rethink 2>&1 | head -1
```

Expected: `GraphQL: Could not resolve to a Repository with the name 'eranroseman/rethink'.` (or similar not-found), and `No such file or directory`.

- [ ] **Step 3: Close the ticket that ruled this**

```bash
gh issue comment 73 -R eranroseman/research-vault --body "$(cat <<'EOF'
The three obligations recorded here in August were executed on <YYYY-MM-DD> by agent-plugins sub-project 5: the `rethink` marketplace is de-registered, `eranroseman/rethink` is deleted, and the two harness-backup copies go with that repository's deletion. The one adaptation, `rethink-audit`'s Boundaries reference repointed to `software-dev:brainstorming`, shipped in `sensemaking` 0.2.0. The `rethink` stub is deleted rather than carried: its whole body was one sentence already inside `rethink-audit`. Spec: https://github.com/eranroseman/agent-plugins/blob/main/docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md §7.3, §7.4, §9.
EOF
)"
```

---

### Task 14: Retire harness-backup

Irreversible. Order, from §10 step 10 and the blast radius in §8.3: the cron line, the out-of-repo drift issue, the archived spec, then the repository, then the directory. The eight symlinks are already gone (Task 12).

**Files:**
- Create: `docs/archive/2026-08-08-harness-update-design.md`

- [ ] **Step 1: Remove the weekly cron and close the drift issue**

```bash
crontab -l
crontab -l | grep -v 'harness-backup/bin/harness-drift-check.py' | crontab -
crontab -l
```

Expected: the first listing is the single `17 9 * * 1 /usr/bin/python3 /home/eranr/harness-backup/bin/harness-drift-check.py …` line; the last prints nothing (or, if the user has other lines, everything but that one).

```bash
gh issue close 1790 -R eranroseman/memoria-vault --comment "$(cat <<'EOF'
Closing: the detector that filed this is retired with `eranroseman/harness-backup`. Its upstream half is now agent-plugins' scheduled `upstream-watch` workflow, which files one issue in place there; its local half is `bin/doctor`. Three of its checks were dropped rather than merged — `cli_drift`, `skill_asymmetry`, `copies_drifted` — and the last dies with its subject, since nothing is copied any more. Record: https://github.com/eranroseman/agent-plugins/blob/main/docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md §8.4.
EOF
)"
```

- [ ] **Step 2: Archive the historical spec**

```bash
git checkout main
mkdir -p docs/archive
{
  printf '%s\n' \
    '> Archived from `eranroseman/harness-backup` (`specs/2026-08-08-harness-update-design.md`) on <YYYY-MM-DD>, when that repository was deleted; see `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` §8.2. The mechanisms that replaced the detector it describes are `bin/doctor` and `.github/workflows/upstream-watch.yml`.' \
    ''
  cat ~/harness-backup/specs/2026-08-08-harness-update-design.md
} > docs/archive/2026-08-08-harness-update-design.md
head -3 docs/archive/2026-08-08-harness-update-design.md
git add docs/archive/2026-08-08-harness-update-design.md
git commit -m "$(cat <<'EOF'
Archive harness-backup's harness-update design

A design for a skill never written, kept because its surface map is
accurate; it moves here because this repository now holds what replaced the
detector it describes.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
git push origin main
```

- [ ] **Step 3: Show what is about to go, and stop**

```bash
git -C ~/harness-backup fetch -q origin
git -C ~/harness-backup status --short
git -C ~/harness-backup log --oneline origin/main..HEAD
git -C ~/harness-backup ls-files | wc -l
ls -la ~/harness-backup/.drift* 2>/dev/null
for l in ~/.claude/skills/* ~/.codex/skills/*; do readlink -f "$l"; done | grep -c harness-backup
gh repo view eranroseman/harness-backup --json name,isPrivate,pushedAt
```

Expected: `status` empty, unpushed log empty, 21 tracked files, the two gitignored state files (`.drift-state.json`, `.drift-cron.log`, plus `.drift-last-run-failed` if a run failed), `0` links resolving into it, and a private repository last pushed 2026-09-06. If `status` or the log is not empty, show the user what is uncommitted or unpushed; it is theirs to keep or discard. What is lost by deleting, stated in §8.2 and worth repeating to the user now: **the restore path** — thirty commits of history behind `~/.claude/settings.json` and `~/.codex/config.toml`, and any way back from a bad hand-edit. The live files are untouched.

**Stop and get the user's explicit go to delete `eranroseman/harness-backup` on GitHub and `~/harness-backup` on disk.**

- [ ] **Step 4: Delete, after the go**

```bash
gh repo delete eranroseman/harness-backup --yes     # needs the delete_repo scope, as in Task 13
rm -rf ~/harness-backup
gh repo view eranroseman/harness-backup 2>&1 | head -1
ls ~/harness-backup 2>&1 | head -1
bash ~/.claude/plugins/marketplaces/eranroseman/bin/doctor | tail -1
```

Expected: not found; `No such file or directory`; `clean`.

---

### Task 15: Empty both global files, and land every disposition

**Files:**
- Modify: `docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md` (extend the Results subsection)

- [ ] **Step 1: Confirm the precondition, then empty the files after the go**

Every surviving repository the scaffolder pass reached carries an `AGENTS.md`, and the two that did not — `harness-backup`, `dev/rethink` — no longer exist, so the intro paragraph's one live clause self-negates (sub-project 2 §4.1):

```bash
ls ~/kh-vault/AGENTS.md ~/memoria-vault/AGENTS.md ~/mispriced/AGENTS.md ~/research-vault/AGENTS.md ~/wit-and-will/AGENTS.md ~/agent-plugins/AGENTS.md
cat ~/.claude/CLAUDE.md; echo ---; cat ~/.codex/AGENTS.md
```

Expected: six files listed; both global files hold only the intro paragraph and the Harness backup paragraph, which now names a deleted repository.

**Stop and get the user's go**, then:

```bash
: > ~/.claude/CLAUDE.md
: > ~/.codex/AGENTS.md
wc -c ~/.claude/CLAUDE.md ~/.codex/AGENTS.md
bash ~/.claude/plugins/marketplaces/eranroseman/bin/doctor | tail -1
```

Expected: `0` and `0`; `clean`. Both harnesses proceed silently with a zero-byte file (measured by sub-project 2).

- [ ] **Step 2: Repair #19's brief**

The spec (§6.7) says the requirements skills are not deferred because the need is not established, and that #19's body "attributes #72's language to #81". Check the attribution before rewriting it:

```bash
gh issue view 72 -R eranroseman/research-vault --comments | grep -n -i 'structural gap'
gh issue view 81 -R eranroseman/research-vault --comments | grep -n -i 'structural gap'
```

Whichever ticket carries the phrase is the one to cite in the first line below. Then replace the whole `## The requirements / PRD step` section of agent-plugins #19 (`gh issue view 19 --json body --jq .body > /tmp/19.md`, edit, `gh issue edit 19 --body-file /tmp/19.md`) with:

```markdown
## The requirements step

**Not deferred: the need is not established.** [kh#<72 or 81, per the grep above>](https://github.com/eranroseman/research-vault/issues/<n>) called the missing PRD step the process spine's one structural gap; two skills were then specified in `research-vault/docs/superpowers/reqs/` on 2026-09-01 and 2026-09-02 — `writing-reqs` (39 requirements) and `sourcing` (19) — and neither is confirmed. The research meant to close a perceived gap widened the frame instead, and left the author unconvinced that a skill is the right answer to it. "Deferred" would invite a later session to treat those specifications as approved work waiting for a slot. They are not.

**The need analysis is the work**, and it precedes any decision about `writing-reqs`, its prior-art phase (R26, which absorbed [kh#82](https://github.com/eranroseman/research-vault/issues/82)), or competitive analysis (folded into [kh#81](https://github.com/eranroseman/research-vault/issues/81)). Until it is done, no requirements skill is built, adopted or scheduled.

Two things are already settled and should not be re-derived if this is picked up:

- The invocation-posture doctrine was **rejected** ([kh#72](https://github.com/eranroseman/research-vault/issues/72)). A PRD skill can be model-invoked exactly as `brainstorming` is; there is no rule that entry points must be user-typed.
- `brainstorming`'s shallow interview is **not** a substitute for what `grilling` and `wayfinder` do, per the same ticket.

**Trigger to revisit:** an effort that needs stated requirements and reaches for `wayfinder` instead — and when it happens, the first question is whether a skill is the answer, not which one.
```

And retitle: `gh issue edit 19 --title "Open, not deferred: neuroarxiv, and whether a requirements skill is needed at all"`.

- [ ] **Step 3: Land the remaining dispositions**

Each comment names the spec section that decided it. Run them all; none is optional, because a ticket left open on a settled question is what a wayfinder frontier query hands to the next session.

```bash
SPEC=https://github.com/eranroseman/agent-plugins/blob/main/docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md

gh issue close 79 -R eranroseman/research-vault --comment "Closed by agent-plugins sub-project 5 ($SPEC §6.7): no adversarial-verification skill exists or is wanted. That design's own surveys ran 143 agents performing adversarial verification on prompt alone and downgraded 61 claims; the capability is reliable on request, and consistency-audit implements the whole method internally. No second party, so no boundary to draw."

gh issue close 82 -R eranroseman/research-vault --comment "Closed as stale on all three premises ($SPEC §6.7): the blocker #81 closed 2026-09-04; prior-art search became R26, a phase inside the specified-but-unbuilt writing-reqs; and the survey omits find-sources, vendored vault-side three days after it was written. Replaced by a narrower item on agent-plugins#19, the durable home #10 hands the requirements step to: the need analysis precedes any prior-art skill, and \`research\` is not one — twelve lines, no corpus routing, citation graph, screening or gate."

gh issue close 84 -R eranroseman/research-vault --comment "Closed against agent-plugins#20, which carries this question ($SPEC §6.7). Nothing is built: sub-project 3's admission standard needs evidence that the problem exists and dependence on nothing beyond the plugin, and this mechanism fails both. #20 lists what would reopen it."

gh issue close 110 -R eranroseman/research-vault --comment "Closed, title premise refuted ($SPEC §6.3): archify is pinnable by the route this repository already uses, \`npx skills add tt-a1i/archify#v2.16.0 --skill archify -g -y\` — \`#\` is the ref selector, \`@\` is not, and bin/setup:441 has used it since 2026-09-05. Declared in upstream/skills.json at v2.16.0. The moving-branch, release-zip and fork trilemma dissolves. The generalisation posted here about the whole installed set is retracted: the lockfile holds nineteen entries and none without a ref. The update check is documented with ARCHIFY_UPDATE_CHECK_DISABLED in the software-dev README; setup does not set it."

gh issue close 111 -R eranroseman/research-vault --comment "Closed ($SPEC §6.2): adhd is vendored into sensemaking 0.2.0, gated on both harnesses (disable-model-invocation: true, and an authored agents/openai.yaml with allow_implicit_invocation: false), with its description shortened to 121 characters. Gating dissolves both collisions, with brainstorming and with systematic-debugging, without a second rewrite. Rung 2, forking, is not adopted: it buys merge flow for one skill file at the price of a repository and permanent merge duty. The claim here that the skills.sh route is closed was wrong — upstream prescribes npx skills add — but the route is foreclosed by the decision to gate. Pinned at commit 16dc239; tag v0.1.4 predates the text and the manifest."

gh issue close 64 -R eranroseman/research-vault --comment "Closed: eranroseman/harness-backup was deleted on <YYYY-MM-DD> ($SPEC §8). Not this ticket's inversion — that mechanism was declined by sub-project 2 §3 and §7.6, which rule that no script hand-writes a configuration file — but a deletion without replacement, argued on its own terms: the four authored assets have plugin homes, the drift detector's two halves are upstream-watch and bin/doctor, the two config copies are personal machine state a public marketplace cannot carry, and the restore path is the loss accepted."

gh issue comment 53 -R eranroseman/research-vault --body "Superseded for every roster, adoption and retirement question by $SPEC (agent-plugins sub-project 5, 2026-09-06). This map is unmaintained; its vocabulary of decided, measured and evidence overstates what it holds, and a survey of its tickets downgraded 61 verified claims on re-check. Read it as background only."

gh issue close 25 --comment "bin/doctor now reports a Claude plugin cache whose marketplace is not registered, as its own NOTE line, derived from the cache directory against known_marketplaces.json ($SPEC §6.6). The superpowers-dev residue was removed by hand at the cutover gate; the doctor reads clean. Whether Claude Code loads from an unregistered cache stays unanswered, and no longer matters here."

gh issue close 12 --comment "Executed as sub-project 5, carrying this one: $SPEC §8 to §10, plan docs/superpowers/plans/2026-09-06-roster-and-retirement.md. harness-backup is deleted, the cron line is gone, memoria-vault#1790 is closed, the historical spec is archived under docs/archive/, and both global files are empty. The declared-asset question this ticket inherited from kh#75 is answered by the doctor's derived duplicate check rather than a table; §13 carries the declared-conflict list forward."

gh issue close 10 --comment "Executed: $SPEC and its plan. Roster: consistency-audit and inspector, finding-duplicate-functions and diagnosing-bugs in software-dev 0.7.0; rethink-audit and adhd in sensemaking 0.2.0; archify through skills.sh at v2.16.0; writing-clearly-and-concisely curated at 3027f20f; the obra-dev plugin dropped for skills.sh; rethink deleted. Open items are §13's, each on its own ticket."
```

- [ ] **Step 4: Extend the results in the spec, and push**

Append to the `### Results` subsection added in Task 12:

```markdown
Steps 9 to 11, <YYYY-MM-DD>: `eranroseman/rethink` and `~/dev/rethink` deleted after
the marketplace was de-registered; the `harness-backup` cron line removed,
memoria-vault#1790 closed, `specs/2026-08-08-harness-update-design.md`
archived to `docs/archive/`, then `eranroseman/harness-backup` and
`~/harness-backup` deleted; `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`
emptied to zero bytes. `bin/doctor` reads `clean` after each. Dispositions
landed on research-vault #53, #64, #73, #79, #82, #84, #110, #111 and on
agent-plugins #10, #12, #19, #25.
```

```bash
git add docs/superpowers/specs/2026-09-06-roster-and-retirement-design.md
git commit -m "$(cat <<'EOF'
Record the two retirements and the emptied global files

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
git push origin main
git branch -d roster-and-retirement
```

Expected: pushed; the branch deleted locally (it was fast-forwarded into `main` in Task 12).
