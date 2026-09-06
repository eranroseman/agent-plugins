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
{{FILE:snips/test-plugin-skills-t2.sh}}
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
{{FILE:snips/plugin-skills-ca-block.sh}}
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
{{FILE:tests/test-vendored-duplicates.sh}}
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
