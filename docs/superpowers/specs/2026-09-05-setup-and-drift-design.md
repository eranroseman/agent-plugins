# software-development: setup, drift, and the placement of rules

**Status:** approved design, 2026-09-05. Sub-project 2 of 7 in the [layout and tracer spec](2026-09-04-software-development-layout-and-tracer-design.md) §11, **merged with the former sub-project 4** on 2026-09-05.
**Scope:** how a machine reaches the intended state and stays there. The declarations this repository carries, the script that applies and verifies them, the scheduled job that watches upstream, the skill that scaffolds a repository, and the emptying of the two global instruction files.
**Not in scope:** `harness-backup` retirement (sub-project 6, [issue #12](https://github.com/eranroseman/agent-plugins/issues/12)), the skill roster (sub-project 5, [issue #10](https://github.com/eranroseman/agent-plugins/issues/10)), research-vault ([issue #11](https://github.com/eranroseman/agent-plugins/issues/11)).

## 1. Evidence standard

Same as the parent spec, with one addition inherited from the hook spec: **a rule enters any always-on carrier only when it solves a problem for which there is evidence that it exists.** A claim below counts as a fact only when it rests on a primary source read on 2026-09-04 or 2026-09-05: a documentation page, a CLI `--help`, a file on this machine, source fetched from GitHub at a named ref, or an empirical test in a scratch `HOME` or `CODEX_HOME`. §15 lists each mechanism claim with its source and marks which were settled by test rather than by reading.

Where this design departs from knowledge-harness #62, #63 and #78, §14 records it. Those tickets are input, not authority.

## 2. Purpose

Three problems, each with evidence.

**Nothing watches either upstream.** `harness-backup/bin/harness-drift-check.py` compares each local marketplace clone against its remote, so since the 2026-09-04 cutover it watches this repository rather than `obra/superpowers`. Its skill check only diffs the two local skill directories against each other. Measured consequence: **16 of the 18 mattpocock skills differ byte-for-byte from upstream HEAD**, with no signal.

**Nothing pins the mattpocock set.** `~/.agents/.skill-lock.json` records a `skillFolderHash` and no ref, so a fresh machine reproduces a different skill set than this one.

**Nothing recreates or verifies the machine.** The pinned superpowers clone and its thirteen symlinks were created by hand from a README recipe that fails in four ways (§7.3). Two cutovers in two days were hand-run from plan files.

## 3. Decisions

| Decision | Choice |
| --- | --- |
| Sub-projects 2 and 4 | Merged. Setup and the doctor act on one set of declarations and are one engine; the doctor is setup's dry run. |
| mattpocock adoption | **Keep skills.sh.** Add a tag fragment to the install so the lockfile records a ref. The curated `git-subdir` route works but buys a hypothetical at the cost of eighteen renames (§12). |
| Where declarations live | This repository. `superpowers` in `.claude-plugin/marketplace.json` as today; a new `upstream/skills.json` for the skills.sh set. |
| Setup and doctor form | One bash script in this repository, two modes. Not a skill: convergence must be deterministic, and a sampled process has no fixed point. |
| Where it runs from | The Claude marketplace clone, which is a full clone of this repository at a path recorded in `known_marketplaces.json`. |
| Harness requirement | `bin/setup` requires Claude Code and treats Codex as optional; `bin/doctor` requires neither. Claude is structural: the script lives in the clone `claude plugin marketplace add` creates and reads its declarations from it (§7.2). |
| Upstream watch | Scheduled GitHub Actions in this repository. Detects and files one issue; never bumps, never opens a pull request. |
| Claude plugin updates | Marketplace auto-update, which respects the `version` field and never drags upstream past our pinned sha. **The user enables it, not setup** (§9). |
| Repo scaffolding | **Vendor and adapt** `setup-matt-pocock-skills`. Composition was tried on paper and fails: its file-pick rule cannot be overridden from outside (§8). |
| The telemetry variable | **Setup does not set it.** `bin/doctor` reports whether it is set and the README documents what it prevents; the user decides. Reasoning in §7.6. |
| Config files | **Setup never hand-edits one.** Every `settings.json` and `config.toml` write is the CLI's own, made by a command setup runs (§7.6). |
| The two global instruction files | Emptied to one paragraph each, which sub-project 6 then removes (§4). |

## 4. Whether a rule should exist, and where it lives

### 4.0 The prior question

**Eliminate the problem > add a mechanism > add a rule; prose is the last resort.** This repository's `AGENTS.md` carries it; it is a root line in `research-vault`'s, where it has been applied repeatedly. It runs *before* the placement test below, because the cheapest rule is the one that never has to exist.

This design is mostly the rule working. The `-g` rule was **eliminated**: once `bin/setup` owns the skills.sh invocations, no human types the command, so the rule has no audience (§4.1). Codex's hook is prevented by a **mechanism**, moving the file off the fallback path, rather than by a rule asking nobody to load it (§6). The README and `bin/setup --help` are held together by a **test**, not by an instruction to keep them in sync (§11). The `grilling` collision was **eliminated** at its cause, by narrowing a description, after which both the prose rule and the `skillOverrides` mute were deleted.

Two rules did ship as prose, and the climb is recorded here so a later reader can re-attempt it rather than assume it was skipped.

- **Worktree cleanup**, in the hook payload. *Eliminate* would mean `superpowers:finishing-a-development-branch` accepting `.claude/worktrees/` in its allowlist, or `EnterWorktree` writing somewhere it already accepts. Both are other people's repositories, and upstream states a 94% pull-request rejection rate. Configuration is not available either: measured 2026-09-06, `.claude/worktrees` is a hardcoded literal in 24 places in the Claude Code binary, `worktreeRoot` is a computed local rather than a setting, and the path appears in neither the settings nor the CLI reference. *Mechanism* would mean vendoring that skill to patch one line, which trades a rung on this ladder for a worse rung on the adoption ladder and breaks the property that all thirteen curated skills are taken straight from upstream. Prose is genuinely last here.
- **Task reports**, in each repository's `AGENTS.md`. *Eliminate* would mean `superpowers:subagent-driven-development` not deleting its workspace at Finish, or writing its reports somewhere durable by default. Upstream again. *Mechanism* would mean a hook blocking that deletion until each Concern has landed, which is both invasive and fragile, since it would have to understand what "landed" means. Prose, placed beside the tracker declaration it depends on.

### The placement test

Once a rule survives §4.0, this decides its home.

- True for **every installer** of this plugin, with evidence of the problem, and depending on nothing beyond the plugin and its declared dependencies: the SessionStart hook payload. Claude only, since a Codex plugin manifest has no instructions component and the [hook spec](2026-09-04-session-start-hook-design.md) §6 ships Codex no hook.
- True for **this repository**: the repository's own `AGENTS.md`, written by the setup skill in §8.
- True only for **this machine**: a global instruction file, `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md`.

**Machine facts must never be written to a repository's `AGENTS.md`.** Which plugins are installed is not a repository fact, and that file is checked in. The same reasoning forbids `--scope project` (§7.4).

### 4.1 Disposition of the two global files

Applying the test empties the third category almost entirely.

| Section | Disposition |
| --- | --- |
| Intro, both files | **Delete.** Self-referential, and its one real clause, ask before assuming conventions in a repo with no `AGENTS.md`, self-negates once §8 gives every repository one. |
| Worktree cleanup, Claude | **Delete after the cutover, not before.** It already ships in `hooks/payload-rules.md`, but the installed plugin is still 0.1.0, so the file is currently the only carrier. |
| Grilling, both | **Delete.** The narrowed `brainstorming` description made the two disjoint, verified 2026-09-05. The Codex copy is additionally stale, still asserting a `skillOverrides` mute that was removed on 2026-09-04. |
| Skill installs, both | **Delete.** Its evidence base is refuted: the rule sits in the file's first commit and no littering incident exists in any history. Once the script owns the skills.sh invocations, no human types the command. |
| Code review, Claude | **Delete all five claims.** Four are redundant with the plugins' own descriptions. The fifth, that `Skill(codex:rescue)` re-enters the command and hangs the session, needs no upstream filing: verified 2026-09-05, `codex@openai-codex` 1.0.6 already carries that exact warning in `commands/rescue.md` itself, at the point of use. The prose duplicates its source. |
| Security tooling, Codex | **Delete the first clause**, measured false: none of the scan skills carries a `policy` key and the default is true. The survivor, that nothing scans passively on Codex, becomes a repository `AGENTS.md` line where it matters. |
| Task reports, both | **To each repository's `AGENTS.md`**, written by the scaffolding skill (§8), beside the tracker declaration it depends on. Delete from both global files after the cutover. It briefly entered the Claude payload on 2026-09-05 and was withdrawn the same day: its destination clause is repository-specific, so one repository-level carrier replaces a payload rule and a Codex global paragraph. A repository with no declared tracker gets no rule, which costs nothing, since it has nothing for the rule to point at. |
| Harness backup, both | Stays until sub-project 6 deletes it. |

The end state is symmetric after all. Both files hold one paragraph, Harness backup, until sub-project 6 deletes it, after which both are empty. Moving task reports to the repository layer is what removed the asymmetry an earlier draft had.

Two costs, accepted knowingly. Codex loses every carrier this repository controls, so anything future that is genuinely machine-scoped there stays in a hand-edited file. And a repository nobody has run §8 in gets no file-borne rules, though the plugin's own skills still load.

## 5. What this repository declares

Setup and the doctor read only from here. Nothing is inferred from the machine.

**`superpowers`**: the existing curated entry in `.claude-plugin/marketplace.json` carries `source.sha`, `source.ref`, `version`, and the thirteen skill names. That entry is already the single source of truth for the Codex symlink list, per the parent spec §9.2.

**`upstream/skills.json`**, new:

```json
{
  "$comment": "Skills installed through the skills.sh CLI. setup applies these; bin/doctor verifies them.",
  "sources": [
    {
      "repo": "mattpocock/skills",
      "ref": "v1.2.3",
      "skills": ["codebase-design", "domain-modeling", "grill-with-docs", "grilling",
                 "handoff", "improve-codebase-architecture", "prototype", "research",
                 "resolving-merge-conflicts", "setup-matt-pocock-skills", "teach",
                 "to-questionnaire", "to-tickets", "triage", "wait-what", "wayfinder",
                 "wizard", "writing-for-agents"]
    },
    {
      "repo": "obra/superpowers-developing-for-claude-code",
      "ref": "v0.3.1",
      "skills": ["developing-claude-code-plugins", "working-with-claude-code"]
    }
  ]
}
```

The second source is recorded with a caveat: both of its skills are **already installed as a Claude plugin** at user scope, so skills.sh supplies only their Codex copy. Whether to drop them from this file is sub-project 5's call ([issue #10](https://github.com/eranroseman/agent-plugins/issues/10)); until then setup installs them and the doctor checks them.

The exact `ref` values above are placeholders for the first bump: pinning is a one-time content move, not a freeze of today, and pinning to the latest tag changes sixteen of the eighteen mattpocock skills. Task 1 of the plan chooses them by reading the upstream tag lists.

## 6. Detecting an upstream change

A scheduled GitHub Actions workflow in this repository, `.github/workflows/upstream-watch.yml`.

It reads the declared pins out of the repository, runs `git ls-remote` against each upstream, and compares. For `superpowers` it compares HEAD and the tag list against `source.sha`. For each `upstream/skills.json` source it compares the tag list against `ref`. It also watches `openai/codex`: on each run it fetches `codex-rs/core-plugins/src/loader.rs` and `codex-rs/exec-server-protocol/src/protocol.rs` at the latest release tag and asserts two literals, that `DEFAULT_HOOKS_CONFIG_FILE` is still `hooks/hooks.json` and that `.codex-plugin/plugin.json` is still first in `DISCOVERABLE_PLUGIN_MANIFEST_PATHS`. Those are the constants the [hook spec](2026-09-04-session-start-hook-design.md) §6.2 rests on, and a change to either would start offering Codex a hook through the Claude manifest's declared path, silently reversing a shipped decision. It files **one issue, updated in place** rather than a new issue per run, and it never bumps a pin or opens a pull request.

Three properties are inherited from `harness-backup/bin/harness-drift-check.py`, each earned from a real failure there: use `git ls-remote` rather than comparing `HEAD` against `origin/*`, because shallow clones with stale tracking refs report "current" forever; update one issue in place; and make a failed run loud, so a dead detector does not look like a healthy repository.

It runs in CI rather than on a local cron because it needs no machine state and fires whether or not any machine is on. This replaces the upstream half of the existing detector; §11 covers the local half.

## 7. `bin/setup` and `bin/doctor`

One script, two entry points. `bin/doctor` checks and reports; `bin/setup` checks, applies, and re-checks, exiting non-zero if anything remains. Both are safely re-runnable.

### 7.1 Where it runs from

The marketplace clone is a full clone of this repository, verified on both harnesses. Bootstrap is therefore one command before the script exists locally:

```bash
claude plugin marketplace add eranroseman/agent-plugins
bash ~/.claude/plugins/marketplaces/eranroseman/bin/setup
```

The path is recorded as `installLocation` in `~/.claude/plugins/known_marketplaces.json`; the script resolves it from there rather than hardcoding it. Codex keeps an equivalent clone under `~/.codex/.tmp/marketplaces/eranroseman/`, but nothing in this design bootstraps from it, so its durability is not a question this repository has to answer.

**The doctor's first check is whether its own clone is behind upstream's `main`**, because a stale script silently applies stale pins. It resolves the tip with `git ls-remote origin refs/heads/main`, the same rule §6 inherits, and **must never compare `HEAD` against `origin/main`**. On neither harness does any CLI operation move that tracking ref independently of `HEAD`: `claude plugin marketplace update` deletes the directory and re-clones at depth 1 rather than fetching, and `codex plugin marketplace upgrade` moves both together. Measured 2026-09-05: in the Claude clone `HEAD`, `refs/heads/main` and `refs/remotes/origin/main` all read `8fb3ca8` while this repository's `main` was 22 commits ahead, so the comparison reports "up to date" on a clone three weeks of work behind.

### 7.2 Prerequisites

The two entry points have different requirements, because they answer to different failures. A setup run that cannot complete should refuse; a doctor should always be able to describe whatever is there.

| | Fatal if missing | Gated, skipped and reported |
| --- | --- | --- |
| `bin/setup` | `git`, `jq`, `node`, `npx`, `claude` | `codex` |
| `bin/doctor` | none | `claude`, `codex` |

**Claude is required for setup, and the reason is structural rather than a preference.** The script lives in the clone that `claude plugin marketplace add` creates, and reads its declarations from `.claude-plugin/marketplace.json` inside it (§5, §7.1). Requiring Claude is requiring the script's own delivery mechanism. Codex is a consumer of those declarations, so the whole Codex half of §7.3 and §9 runs only when the binary is on `PATH`, and is reported as skipped otherwise.

The four always-fatal tools each earn their place: `git` for the pinned clone, `jq` for the manifests and the settings merge, `node` for the Visual Companion server at runtime, `npx` for the skills.sh set in §5, which is harness-neutral and installs the same either way.

Two consequences worth naming. A Claude-only machine is fully supported, which matters because this is a public marketplace. And `bin/setup` becomes testable in CI, where the Claude CLI is installed and Codex is not (§11).

It does **not** require `gh` authentication or an SSH key: a keyless machine falls back from SSH to HTTPS automatically, measured.

### 7.3 What it applies

**Claude.** `claude plugin marketplace add`, then `claude plugin install software-development@eranroseman -y --scope user`, which installs and enables `sensemaking` and `superpowers` as dependencies. Both commands are clean no-ops on re-run. That is the whole Claude half: setup does not enable auto-update, which is the user's call (§9).

**Codex.** `codex plugin marketplace add` once, then `codex plugin add` for **both** plugins, because Codex has no dependency concept. **Never re-run `codex plugin marketplace add`:** it prints "already added" and silently deletes `last_revision`. Use `codex plugin marketplace upgrade`, which is a true no-op when upstream is unchanged.

**The pinned clone.** Read `source.sha` from the marketplace manifest beside the script. If the clone directory does not exist, clone and check out. If it exists, fetch and check out; do not chain with `&&` after a clone that may fail. The README's current recipe leaves a clone at the wrong revision silently, because `git clone … && git checkout …` short-circuits when the clone fails, exit 128.

**The symlinks.** For each of the thirteen names read from the marketplace entry, link into `~/.agents/skills/`, which is Codex's current documented user skill root; `$CODEX_HOME/skills` carries a deprecation comment in the installed build. Namespacing is preserved from either root, verified: a superpowers skill symlinked from `~/.agents/skills` still resolves as `superpowers:writing-plans`.

Three failure modes the README's `[ -e ]` guard does not cover, all measured:

1. A **dangling** link makes `[ -e ]` false, so the guard passes and `ln -s` then fails "File exists"; under `set -e` the loop dies mid-way.
2. An **existing directory symlink** with an unguarded `ln -s` nests a link inside the target and exits 0.
3. A **regular file** where a link belongs is reported as already existing and never repaired.

The script therefore compares `readlink -f` against the intended target, moves anything unexpected aside rather than deleting it, and creates the link only when it is absent or wrong.

**D8, decided during implementation 2026-09-05: the thirteen links are created on every machine, not only where `codex` is present.** `ensure_links` is dispatched unconditionally, unlike `ensure_codex`, which returns early when the binary is absent. The spec pulled two ways on this: §7.3 says to link into `~/.agents/skills` without qualification, while §11's CI bullet and gate S1 both describe the symlinks as part of the Codex half. §7.3 wins, for two reasons found while building. The doctor has to describe those links whatever is installed, and setup and doctor are one body of code, so gating the apply half would split behaviour the two modes are supposed to share. And a machine that installs Codex later converges without re-running setup, because the links are already correct. The cost is that a Claude-only machine carries thirteen links it does not read, which is inert: Claude reads no `.agents` path at any level.

Recorded here rather than in the plan's own deviations list, because inserting lines there would have shifted every line number the review record anchors to, and that record was the artifact the executor still needed.

**Separately, the links already on this machine, none of them this recipe's.** `~/.codex/skills` holds 37 links: the 13 into the pinned clone, 20 that chain through `~/.claude/skills` into `~/.agents/skills`, and 4 into `~/harness-backup/claude/skills`. The 20 are **redundant**, because Codex reads `~/.agents/skills` directly and dedupes by resolved path, and removing them is a cleanup this sub-project may do. The 4 are not redundant: three of them are their skill's only Codex carrier and the fourth duplicates `sensemaking:rethink-audit`. Their disposition is sub-project 5's ([issue #10](https://github.com/eranroseman/agent-plugins/issues/10)), so the script reports them and changes nothing. It does not mirror these thirteen into `~/.claude/skills`: Claude receives them from the plugin, and a personal-skill copy would duplicate them.

**The skills.sh set.** For each source in `upstream/skills.json`, `npx skills add "<repo>#<ref>" --skill <name> -g -y`. This writes `ref` into the lockfile, installs content identical to that ref, upgrades an already-unpinned entry in place, and survives `skills update -g` untouched.

### 7.4 What the script must not do

Never `--scope project`. Measured: it writes a checked-in `.claude/settings.json` carrying both `enabledPlugins` and `extraKnownMarketplaces`, which commits machine configuration into a repository.

Never treat `config.toml` as an installation check. `codex plugin marketplace remove` leaves orphaned `[plugins.*]` tables with no warning, after which `codex plugin list` reports no plugins while the entries remain. Verify with `codex plugin list` status.

Never delete a squatting file or link. Move it aside and report.

### 7.5 What it cannot do

Codex's per-project `trust_level` comes from an interactive onboarding prompt, not from any command; a fresh clone is prompted once. And on Claude the plugins load on the next launch or after `/reload-plugins`, because the CLI running the script is the one that must restart.

### 7.6 What it deliberately does not set: the telemetry variable

An earlier draft had setup write `SUPERPOWERS_DISABLE_TELEMETRY` into `~/.claude/settings.json` and `~/.profile`. It no longer does, and the reasoning is worth keeping because the variable will be proposed again.

Read from `brandMarkup()` in the vendored skill's `scripts/server.cjs`: unset, the Visual Companion's page renders one `<img>` at `https://primeradiant.com/brand/superpowers-visual-brainstorming-logo.png?v=<superpowers version>`, with `referrerpolicy="no-referrer"`. Set, there is no `<img>` and the caption changes. That URL is the only external address in the whole eight-file skill. So the exposure is one browser request per companion page load, carrying an address, a user agent, a timestamp, and the superpowers version in the query string.

The companion is opt-in and offered just-in-time, and it has never been used on the reference machine, so no such request has ever fired. Against that, setting it costs a `jq` merge into `~/.claude/settings.json`, a file the Claude CLI rewrites wholesale and owns two keys in, plus a `~/.profile` line, a doctor check, and a README paragraph. The riskiest write in the whole script would exist for a beacon that has never fired.

So: `bin/doctor` reports whether any of the three accepted names is set, because a doctor describes what is there without imposing anything, and the plugin README documents the variable and what it prevents so a user who accepts the companion offer can decide then. This also settles a question §16 used to carry, whether the `env` key or a hook writing to `$CLAUDE_ENV_FILE` was the better channel: neither, because setup writes nothing.

**The same reasoning removed the last hand-edit, and left a property worth stating.** An earlier draft also had setup write `autoUpdate` into `settings.json`. Auto-update means the plugin changes itself without asking, which is a consent decision rather than a configuration detail, so it moved to the user too (§9). With both gone, **setup never hand-edits a configuration file on either harness.** Every `settings.json` and `config.toml` write is the CLI's own, made by a command setup runs, which is why nothing here has to reason about merge order or TOML redefinition.

## 8. Repository scaffolding

Evidence, from the author 2026-09-05: without a declared issue tracker, agents do not file issues and findings are lost in chat while a plan is executing. Confirmed here in the positive: yesterday's build filed [issues #1 through #6](https://github.com/eranroseman/agent-plugins/issues/1) for its declined minors, which it could do because `docs/agents/issue-tracker.md` exists in this repository.

`setup-matt-pocock-skills` writes that layout and is repo-level where everything else here is machine-level. It has two gaps for this design:

1. **No git convention.** `superpowers:finishing-a-development-branch` instructs "merge back to base locally" and says to follow the repository's conventions, but nothing writes them. The Git section in this repository's `AGENTS.md` is hand-added.
2. **It picks one instruction file.** Its rule is never to create `AGENTS.md` when `CLAUDE.md` exists. Applied to a repository holding only `CLAUDE.md`, that leaves Codex reading nothing, because Codex reads `AGENTS.md` natively. The shape that works on both is the one this repository uses: content in `AGENTS.md`, and `CLAUDE.md` as a one-line `@AGENTS.md` import.

It also writes a third thing this design needs: the **task-reports rule**, beside the tracker declaration it depends on (§4.1).

**The plugin vendors and adapts rather than composing.** Composition was the first design and it fails on paper, which is why the reasoning is recorded rather than the conclusion alone. `grill-with-docs` is the precedent for composing, but it only has to *call* two skills that each do their own job; this case has to make `setup-matt-pocock-skills` do something it explicitly refuses. Its file-pick rule is absolute: "If `CLAUDE.md` exists, edit it. Else if `AGENTS.md` exists, edit it... Never create `AGENTS.md` when `CLAUDE.md` already exists." A wrapper cannot reorder that check, so in any repository that has a `CLAUDE.md`, the skill writes its block there and the wrapper would have to move that content into `AGENTS.md` and rewrite `CLAUDE.md` as the import. That is undoing its work, not adding to it, and it holds for two of the four possible starting states.

So the skill is vendored into `software-development` at a pinned upstream ref, with a provenance header naming it, exactly as `brainstorming` is.

**The adaptation is smaller than the vendoring, because only one of its six files changes.** The skill ships five seed templates beside its `SKILL.md`: `issue-tracker-github.md`, `issue-tracker-gitlab.md`, `issue-tracker-local.md`, `triage-labels.md` and `domain.md`. All five are taken byte-for-byte, since this design changes where the block is written and what else goes in it, not what a tracker or label or domain-doc file says. Only `SKILL.md` is edited, and only in three places: the file-pick rule becomes "write `AGENTS.md`, and make `CLAUDE.md` a one-line `@AGENTS.md` import"; a Git section is added; and the task-reports rule is added.

The drift test therefore asserts two different things. The five templates must be byte-identical to upstream at the pin, which is a strict equality like `test-vendored-brainstorming.sh` uses. `SKILL.md` must differ only in those three regions, which is the looser assertion the same test already makes for `brainstorming`'s description and header. Keeping the templates strict is what makes a re-vendor cheap: an upstream change to a template is a clean overwrite, and only a change to `SKILL.md` needs judgement.

Shipping it bumps `software-development` to **0.4.0** in both manifests. §9's `version` field is the sole update gate, so without a bump the skill never reaches an installed copy, and `bin/doctor`'s version check would compare 0.3.0 against 0.3.0 and report clean. `tests/test-hook.sh` pins the version in two assertions and moves with it.

## 9. Updating an installation

**Claude, once the user enables auto-update: nothing to run.** Claude Code refreshes the marketplace and updates installed plugins on disk after a session starts, with a random delay of up to ten minutes, then either prompts for `/reload-plugins` or loads the new versions at the next launch. Third-party marketplaces default to auto-update off, which is why this has never happened; the `eranroseman` entry has no `autoUpdate` key today.

**Setup does not turn it on.** Auto-update means the plugin changes itself without asking, which is the user's decision, made once in `/plugin` under Marketplaces. The README documents the four steps and `bin/doctor` reports the current state. Without it, Claude updates the same way Codex does, through step 1 below.

**Auto-update and the pin are complementary.** Auto-update refreshes the marketplace catalog, and the catalog names `superpowers` at a fixed sha, so it delivers this repository's releases and never drags in upstream's HEAD. The `version` field still gates each release, which is why a bump must move both `sha` and `version`.

**Everywhere else the script runs, in this order**, because the marketplace clone carries both the new declarations and the new copy of the script:

1. `claude plugin marketplace update eranroseman` and `codex plugin marketplace upgrade`.
2. Re-run `bin/setup` **from the refreshed clone**.
3. It re-adds both Codex plugins, since Codex has no update verb.
4. It re-fetches the pinned clone to the new sha and re-verifies the thirteen links.
5. It re-runs `skills add` per declared skill at the declared ref.
6. `bin/doctor` proves the result.

## 10. Bumping a pin

Triggered by the issue from §6, done by a human and an agent on a branch. **No machine changes at this step.**

For `superpowers` a bump moves four coupled artifacts by three different mechanisms, and three existing tests fail until all four move.

- **Substituted**, because they carry the sha as a literal: `source.sha` in `.claude-plugin/marketplace.json`, and the `at commit <sha>` line in `plugins/software-development/LICENSE`.
- **Regenerated from the new clone**, because they carry no sha and are coupled by content: `hooks/payload.md`, which contains no 40-character string at all and whose only build recipe currently lives inside `tests/test-hook.sh`; and `skills/brainstorming/`, re-vendored, where the sha appears only in the provenance header.
- **Read, not written**: `version` in the marketplace entry is copied from upstream's own `.claude-plugin/plugin.json` at the new sha, which is what `test-upstream-pin.sh` already asserts.

`bin/bump-superpowers <sha>` performs all three and leaves the diff for review. Two parts deserve reading rather than skimming: the vendored `brainstorming` body, because that is where upstream can change behaviour, and any change to `payload.md`, because it is the text injected into every session. Extracting the payload build recipe out of the test and into the script is part of this work, so the two cannot diverge.

For a skills.sh source it is one `ref` edit in `upstream/skills.json`.

**One hole this design closes**, because the update path is where it bites: `tests/test-hook.sh` transcribes upstream's `<EXTREMELY_IMPORTANT>` frame rather than reading it from the clone, so a bump that changed that frame would leave the suite green while the injection diverged. Both existing specs carry it as an open item. §11 makes the test read the frame from the clone.

## 11. Static checks

New tests, run by the existing `tests/run.sh`:

- `upstream/skills.json` is well-formed, every `repo` resolves, every `ref` exists as a tag, and every listed skill name resolves to exactly one `SKILL.md` at that ref. It is the skills.sh twin of `test-upstream-pin.sh` in role but not in path idiom: that test hardcodes a flat `skills/<name>/SKILL.md`, and the two declared sources differ, since `obra/superpowers-developing-for-claude-code` is flat while `mattpocock/skills` nests a category level (`skills/engineering/`, `skills/productivity/`) that a name does not reveal. The test resolves each name the way `skills add --skill <name>` does, by searching the fetched ref for a `SKILL.md` whose parent directory basename equals the name, and asserting exactly one match, so a mistyped name and a duplicated one both fail loudly.
- `bin/setup` runs end to end against a scratch `HOME` in CI and exits 0, then a `bin/doctor` run over the same `HOME` reports clean. The runner has the Claude CLI and no Codex, so this exercises the Claude install, the pinned clone, and the skills.sh set, with the Codex half reported as skipped. It is the automated half of gate S1, which stays manual only for the parts a scratch `HOME` cannot reach.
- `bin/setup` and `bin/doctor` pass `shellcheck`, and `bin/doctor` reports the five seeded faults when pointed at a scratch `HOME` carrying a wrong-sha clone, a dangling link, a nested link, a squatting regular file, and a lockfile entry missing its `ref`. The doctor takes no path argument; it reads the machine through `HOME` and `CODEX_HOME`, the same overrides gate S1 uses. The test asserts those five lines appear, not that they are the only ones, and its two CLI-dependent checks report SKIPPED on a runner with no Codex (§7.2). All five faults are filesystem and git state, so the fixture detects every one with neither CLI present.
- The vendored scaffolding skill matches upstream at its pinned ref except for the three changes §8 names, asserted the way `test-vendored-brainstorming.sh` already asserts the vendored `brainstorming` tree.
- `test-hook.sh` reads upstream's frame from the pinned clone rather than transcribing it (§10).
- **README.md is rewritten in this sub-project**, which no other section names as a deliverable. Its Codex section loses the four-ways-broken clone-and-symlink recipe in favour of §7.1's two-line bootstrap; its Claude section gains the same; and it gains an Update section carrying §9's steps 1 and 2, the only two commands a human types, since steps 3 through 6 are the script's internals. The plugin README's Environment section gains what the variable actually prevents, per §7.6, rather than only naming it, and the Update section names the `/plugin` auto-update toggle as an optional four-step choice the user makes rather than something setup does. Both blocks become fenced rather than indented, because the README currently has none and a test cannot extract what does not exist. The test then asserts that each fenced block in those sections appears verbatim in the usage text `bin/setup --help` prints, so the instructions and the script cannot drift.

`bin/doctor` itself is the local half of the former sub-project 4. It compares the machine against §5's declarations: the clone at the declared sha, each of the thirteen links resolving to its intended target, the lockfile's `ref` per source matching the declaration, the installed plugin version matching the manifest, and the marketplace clone not behind upstream's `main` as resolved by `git ls-remote` (§7.1). It also reports, without repairing, whether any of the three telemetry-disabling variables is set (§7.6) and whether the twenty redundant Codex links are still present (§7.3). It repairs only what §5 declares.

## 12. mattpocock: why the curated route was not taken

Measured 2026-09-05, the curated `git-subdir` route works end to end on both harnesses. It was declined on the standard in §1.

Only one candidate problem survived as measured: no version pin, with sixteen of eighteen skills already drifted. That problem is fixable in place with a tag fragment (§7.3), verified including the in-place upgrade of an already-unpinned entry. The curated route's one genuine advantage is a forty-character sha rather than a mutable tag, since `skills add` rejects a sha; but a force-moved upstream tag is a hypothetical with no evidence behind it, while the migration's costs are certain: eighteen renames to `mattpocock-skills:<name>` on both harnesses, a namespace hostage to a field in upstream's Claude manifest, the loss of the `skillOverrides` lever sub-project 5 needs, a whole-repository clone on Codex, and forty-four symlinks removed rather than added.

The `-g` rule's premise was also refuted: it appears in `~/.claude/CLAUDE.md`'s first commit and no littering incident exists in any repository's history.

## 13. Gates

Checked on this machine after the first `bin/setup` run. Gate labels are `S`-prefixed so they cannot be confused with the `G`-labels of the [layout spec](2026-09-04-software-development-layout-and-tracer-design.md) §10.2 or the [hook spec](2026-09-04-session-start-hook-design.md) §8.

| Gate | Passes when | If it fails |
| --- | --- | --- |
| S1 Fresh install | `bin/setup` against a scratch `HOME` and `CODEX_HOME` produces the whole target state, and `bin/doctor` then reports clean. Verified with the real machine untouched. Its Claude-only half runs in CI on every push (§11); this gate covers what a runner cannot reach, namely the Codex install and the thirteen symlinks | Defect, fix in place |
| S2 Doctor detects | `bin/doctor` against a scratch `HOME` seeded with a wrong-sha clone, a dangling link, a nested link, a squatting regular file, and a lockfile entry missing its `ref` reports all five, and `bin/setup` repairs all five. Its CLI-dependent checks report SKIPPED where a binary is absent (§7.2) | Defect, fix in place |
| S3 Auto-update | After the user toggles auto-update on in `/plugin`, a published release reaches the machine without an explicit update command, observed within one session plus the documented delay. The 0.3.0 to 0.4.0 bump this sub-project ships is the natural experiment | §9's "nothing to run" becomes step 1 for Claude as well, and the README says so. Nothing in setup changes either way, since it never writes the key |
| S4 Vendored scaffolder | The adapted skill, run in a scratch repository in each of the four starting states (neither file, `AGENTS.md` only, `CLAUDE.md` only, both), leaves `AGENTS.md` holding the content and `CLAUDE.md` holding exactly `@AGENTS.md`, and its drift test shows only the three intended changes against upstream at the pin | Defect, fix in place. Composition is already ruled out on paper (§8), so there is no fallback to fall back to |
| S5 Pin application | Re-running `skills add "<repo>#<ref>" --skill <name> -g -y` across all twenty declared skills on the real machine leaves every lockfile entry carrying the declared `ref`, and `skills update -g` then reports everything up to date | Investigate before the pin is declared; the fallback is to pin only the sources that apply cleanly and record the rest |

Fresh-machine reproducibility is gate S1 and is in scope here, unlike in the layout spec where it was explicitly deferred to this sub-project. There is no gate for a Codex-only machine, because §7.2 does not support one.

### Results, 2026-09-06

Measured during the cutover. Every figure is from a run, not a prediction; a gate recorded without its numbers is worth nothing to the sub-projects that read this.

| Gate | Result |
| --- | --- |
| S1 Fresh install | **Pass.** `bin/setup` into a scratch `HOME`/`CODEX_HOME`: exit 0, 38 `DID:` lines. `bin/doctor` over the same pair: exit 0, `clean`. Thirteen links under the scratch `~/.agents/skills`; both Codex plugins installed there. The real machine was verified unaffected afterwards. Run from the repository checkout rather than the marketplace clone, which carried no `bin/` until it refreshed. |
| S2 Doctor detects | **Pass.** `tests/test-doctor-faults.sh` prints `doctor-faults: five seeded faults reported and the local ones repaired`, exit 0. On a minimal `PATH` the doctor emitted two `SKIP:` lines; the Codex one did not appear because `codex` lives at `/usr/bin/codex` and survives that `PATH`. |
| S3 Auto-update | **Pass, with a qualification that changes §9.** Toggled 06:36:32 UTC: 0.3.0 installed, 0.4.0 declared, catalog at `f24bb5d`, marketplace `lastUpdated` 2026-09-05T22:58:12Z. A **headless** trigger (`claude -p`) moved nothing in 773 s — version, catalog and `lastUpdated` all unchanged. A fresh **interactive** session delivered at **t+301 s**: 0.3.0 → 0.4.0, catalog → `54dbf0a`, `lastUpdated` → 2026-09-06T06:58:30Z, with no command typed. Auto-update therefore refreshes the catalog *and* installs, but only an interactive session start triggers it. §9's "nothing to run on Claude" holds for interactive starts only; a headless-only workflow never receives a release. |
| S4 Vendored scaffolder | **Pass, four of four states**, each confirmed to have run the vendored copy by the presence of its `### Task reports` section. `none`: five sections, `CLAUDE.md` exactly `@AGENTS.md` (11 bytes). `AGENTS.md` only: five sections, the pre-existing heading and body preserved at lines 1-3 with `## Agent skills` beginning at line 5. `CLAUDE.md` only — the migration case the two edited regions exist for: five sections, the pre-existing heading *and* body moved into `AGENTS.md`, `CLAUDE.md` reduced to `@AGENTS.md`. Both files: merge correct, both seeded texts preserved including the second heading, but four sections — `### Triage labels` and its seed template were not written. Not attributed to the edited regions: the skill is prompt-driven, and its `### Git` text also varied in that run, adapting to the absence of a remote. |
| S5 Pin application | **Pass**, on the second reading. Eighteen `OK: skills.sh <name> at <ref>` lines before *and* after `npx skills update -g`, thirteen links before and after, and `update -g` reporting nothing to update because every declared entry is pinned. The lockfile went from zero entries carrying a `ref` to eighteen. |

Three corrections the runs forced on the table above.

**S5's denominator is eighteen, not twenty.** The declaration lost `setup-matt-pocock-skills` to Deviation D1 and `to-tickets` to the not-adopted set. An earlier reading of this gate measured nineteen against a nineteen-skill declaration and was superseded when the declaration moved during the cutover.

**S5's failure rule as written is wrong.** "`skills update -g` then reports everything up to date" fired falsely on the first reading: `update -g` reported one update, and it was the lockfile's twentieth entry, unpinned *by design* under D1. The correct rule is that every **declared** entry reports `OK` before and after; an undeclared entry is expected to move. Both undeclared entries were then removed, taking the lockfile to eighteen against eighteen declared.

**The pin is a move between unrecorded points, not a rollback from the tip.** Measured before the run: eight of the seventeen mattpocock skills then declared changed bytes, not the sixteen of eighteen the plan claimed. The installed `triage` matched neither `v1.2.3` nor `main`'s tip, so the machine held an unreproducible mid-branch snapshot — which is the drift the pin ends, and the strongest argument for it.

One hazard surfaced that the gate text does not anticipate. While both an adapted and an unadapted `setup-matt-pocock-skills` were installed, a bare invocation reached the **unadapted** one, which wrote its block into `CLAUDE.md` and created no `AGENTS.md` — the exact failure S4 exists to detect, arriving from the wrong skill rather than from a defect. It was diagnosed by section count (three, and no `### Task reports`) and eliminated by removing the skills.sh copy, per the `eliminate > mechanism > rule` ladder in §4.0 rather than by relying on operators typing the namespaced form.

## 14. Positions from knowledge-harness not adopted

| Proposal | Disposition | Reason |
| --- | --- | --- |
| A prompt-driven wizard modelled on `setup-matt-pocock-skills` (#62) | Not adopted for the machine layer | "Idempotent" and "prompt-driven" conflict at the definition, and a model must not author `permissions.allow` or hook definitions. Its shape is adopted for the **repository** layer instead (§8), which is what it was built for. |
| A `--capture` mode back-importing live state into templates (#62) | Not adopted | Recorded on [issue #12](https://github.com/eranroseman/agent-plugins/issues/12) as an investigation candidate if strict edit-in-repo proves too costly. |
| A separate local deploy-drift doctor (#78) | Merged into this design | It is `bin/doctor`, the check mode of the same engine. |
| A separate upstream-drift monitor (#63) | Merged into this design | It is §6. |
| A full manifest-driven convergence engine over ~60 assertions | Not adopted | The CLIs own nearly every key (§15). The residue is small enough that a script suffices. |

## 15. Mechanism claims and their sources

Marked **[test]** where settled empirically rather than by reading.

| Claim | Source |
| --- | --- |
| Marketplace auto-update refreshes the marketplace and updates installed plugins after session start with a random delay up to ten minutes; third-party marketplaces default to off; toggled in `/plugin` or by `autoUpdate` on an `extraKnownMarketplaces` entry in managed settings | code.claude.com/docs/en/discover-plugins, "Configure auto-updates" |
| `version` pins a plugin: users receive updates only when the string changes; omitting it for a git source means every commit updates | code.claude.com/docs/en/plugin-marketplaces |
| The Claude CLI writes `extraKnownMarketplaces` and `enabledPlugins` into `settings.json`, plus `known_marketplaces.json` and `installed_plugins.json`; dependencies auto-install and auto-enable with `"auto": true` | **[test]** scratch `HOME`, before/after diffs of every file |
| `claude plugin install` rewrites `settings.json` wholesale while preserving hand-authored keys | **[test]** same |
| `claude plugin marketplace add`, `install`, `update` are clean no-ops on re-run; `plugin init` is the only command that refuses | **[test]** same |
| A keyless machine falls back from SSH to HTTPS on marketplace add | **[test]** `GIT_SSH_COMMAND=/bin/false` in a scratch `HOME` |
| The `env` key in `settings.json` reaches a SessionStart hook subprocess | **[test]** hook dumping its environment printed the variable |
| `~/.bashrc` exports never reach a hook on a non-interactive launch | **[test]** `env -i … bash --noprofile --norc -c 'claude -p …'` |
| Codex edits `config.toml` surgically, preserving comments, ordering and formatting, across nine commands | **[test]** instrumented seed file |
| Re-running `codex plugin marketplace add` deletes `last_revision`; `marketplace upgrade` is a true no-op; `marketplace remove` orphans `[plugins.*]` silently | **[test]** scratch `CODEX_HOME` |
| Codex does not auto-install dependencies | **[test]** same |
| `[shell_environment_policy]` both filters inherited variables and sets new ones via a `set` table | `codex-rs/protocol/src/shell_environment.rs` at tag `rust-v0.147.0`; **[test]** via `-c` override |
| `$HOME/.agents/skills` is Codex's current documented user root; `$CODEX_HOME/skills` is marked deprecated | `codex-rs/ext/skills/src/host_roots.rs:111` at `rust-v0.147.0`; learn.chatgpt.com/docs/build-skills |
| A superpowers skill symlinked from `~/.agents/skills` still resolves as `superpowers:writing-plans`; Codex follows a symlinked skills root and dedupes by resolved path | **[test]** scratch `HOME` and `CODEX_HOME` |
| Twenty of the thirty-six links in `~/.codex/skills` are redundant | `readlink -f` over the directory |
| The README recipe fails four ways: wrong-sha clone, dangling link, nested link, squatting file | **[test]** each reproduced |
| `skills add "<repo>#<ref>"` records `ref`, installs that ref's content, upgrades an unpinned entry in place, and survives `update -g`; a sha is rejected | **[test]** scratch `HOME`; `cli.mjs` `cloneRepo` uses `--branch` |
| 16 of 18 mattpocock skills differ from upstream HEAD; the lockfile records no ref | `diff -rq` against a HEAD clone; `grep -c '"ref"'` returns 0 |
| The marketplace clone is a full clone of this repository on both harnesses, at `installLocation` | live file read |
| `--scope project` writes a checked-in `.claude/settings.json` with `enabledPlugins` and `extraKnownMarketplaces` | **[test]** scratch project |
| Codex `[projects.*] trust_level` comes from interactive onboarding, not from any command | **[test]** `codex exec` in an untrusted directory wrote no entry |
| Both harnesses proceed silently with their global instruction file absent or zero-byte | **[test]** scratch homes with sentinel files |
| `setup-matt-pocock-skills` writes no git convention and picks one instruction file | its `SKILL.md`, read in full |
| The existing detector no longer watches either upstream | `harness-drift-check.py` `skill_asymmetry()` and its marketplace check, read against `.drift-state.json` |

## 16. Open items carried forward

- ~~Whether `autoUpdate: true` in a **user-scope** `extraKnownMarketplaces` entry is honoured, or only in managed settings.~~ Moot for setup, which never writes the key. ~~What remains is whether the `/plugin` toggle delivers a release without an explicit command, which gate S3 measures on the 0.3.0 to 0.4.0 bump.~~ Answered 2026-09-06 by S3: it does, in 301 seconds, but only from an **interactive** session start — a headless `claude -p` moved nothing in 773 seconds. See §13's results.
- ~~Whether a model-invoked skill can reach `setup-matt-pocock-skills` through the Skill tool given its `disable-model-invocation: true`.~~ Closed 2026-09-05 as moot: reaching it would not help, because its file-pick rule cannot be overridden from outside (§8). The skill is vendored instead.
- ~~Whether re-running `skills add` with a ref across all twenty skills is clean on a real machine; verified for one skill in a scratch home.~~ Answered 2026-09-06: clean across all eighteen declared skills on the reference machine, in 49 seconds, taking the lockfile from zero entries carrying a `ref` to eighteen. The count is eighteen rather than twenty because D1 excludes `setup-matt-pocock-skills` and `to-tickets` is not adopted.
- ~~Which upstream tag corresponds to the currently installed content. It is almost certainly between tags, so no tag reproduces today's exact bytes; the first pin is a deliberate content move.~~ Answered 2026-09-06 by measurement: none. The installed `triage` matched neither `v1.2.3` nor `main`'s tip, confirming a mid-branch snapshot. Eight of the seventeen mattpocock skills then declared changed bytes on pinning — not the sixteen of eighteen the plan claimed.
- Whether the task-reports rule can leave the two global instruction files. Held there at the cutover: seven repositories on this machine carry an `AGENTS.md` without it and two carry none at all, so its per-repo home does not yet exist. Delete once the §8 scaffolder has been through them.
- Whether `### Triage labels` is reliably written when both `AGENTS.md` and `CLAUDE.md` already exist. One S4 state omitted it and its seed template; the skill is prompt-driven, so this may be run variation rather than a block defect.
- The two `obra/superpowers-developing-for-claude-code` skills are duplicated on Claude today (plugin and skills.sh). Sub-project 5 decides ([issue #10](https://github.com/eranroseman/agent-plugins/issues/10)).
- ~~The `Skill(codex:rescue)` hang loses its prose home under §4.1 and should be filed upstream against `codex@openai-codex`.~~ Closed 2026-09-05: upstream already documents it in `commands/rescue.md`, so the prose deletes with nothing to file.
- ~~Whether the `env` key or the plugin's own SessionStart hook writing to `$CLAUDE_ENV_FILE` is the better Claude channel for the telemetry variable.~~ Closed 2026-09-05: setup sets neither (§7.6).
