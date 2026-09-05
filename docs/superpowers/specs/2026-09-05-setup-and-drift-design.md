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
| Where it runs from | The marketplace clone, which is a full clone of this repository at a path recorded in `known_marketplaces.json`. |
| Upstream watch | Scheduled GitHub Actions in this repository. Detects and files one issue; never bumps, never opens a pull request. |
| Claude plugin updates | Marketplace auto-update, enabled for `eranroseman`. It respects the `version` field and never drags upstream past our pinned sha. |
| Repo scaffolding | A thin skill that composes `setup-matt-pocock-skills` and adds the two things it does not write (§8). |
| The two global instruction files | Emptied to one paragraph each, which sub-project 6 then removes (§4). |

## 4. Where a rule lives

The rule that governs everything else in this design.

- True for **every installer** of this plugin, with evidence of the problem, and depending on nothing beyond the plugin and its declared dependencies: the SessionStart hook payload. Claude only, since a Codex plugin manifest has no instructions component and the [hook spec](2026-09-04-session-start-hook-design.md) §6 ships Codex no hook.
- True for **this repository**: the repository's own `AGENTS.md`, written by the setup skill in §8.
- True only for **this machine**: a global instruction file, `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md`.

**Machine facts must never be written to a repository's `AGENTS.md`.** Which plugins are installed is not a repository fact, and that file is checked in. The same reasoning forbids `--scope project` (§7.5).

### 4.1 Disposition of the two global files

Applying the test empties the third category almost entirely.

| Section | Disposition |
| --- | --- |
| Intro, both files | **Delete.** Self-referential, and its one real clause, ask before assuming conventions in a repo with no `AGENTS.md`, self-negates once §8 gives every repository one. |
| Worktree cleanup, Claude | **Delete after the 0.2.0 cutover, not before.** It already ships in `hooks/payload-rules.md`, but the installed plugin is still 0.1.0, so the file is currently the only carrier. |
| Grilling, both | **Delete.** The narrowed `brainstorming` description made the two disjoint, verified 2026-09-05. The Codex copy is additionally stale, still asserting a `skillOverrides` mute that was removed on 2026-09-04. |
| Skill installs, both | **Delete.** Its evidence base is refuted: the rule sits in the file's first commit and no littering incident exists in any history. Once the script owns the skills.sh invocations, no human types the command. |
| Code review, Claude | **Delete four of five claims** as redundant with the plugins' own descriptions. The survivor is an upstream defect, that `Skill(codex:rescue)` re-enters the command and hangs the session; file it against `codex@openai-codex` rather than carrying prose. |
| Security tooling, Codex | **Delete the first clause**, measured false: none of the scan skills carries a `policy` key and the default is true. The survivor, that nothing scans passively on Codex, becomes a repository `AGENTS.md` line where it matters. |
| Task reports, both | **Landed in the payload on Claude** at version 0.3.0, 2026-09-05; the [hook spec](2026-09-04-session-start-hook-design.md) §10 records the reversal of its own decline. Codex has no carrier; the rule's destination half already lives in each repository's tracker declaration. |
| Harness backup, both | **The only genuine survivor.** Stays until sub-project 6 deletes it, after which both files are empty. |

Two costs, accepted knowingly. Codex loses every global carrier, so anything future that is genuinely machine-scoped there will have nowhere to go. And a repository nobody has run §8 in gets no file-borne rules, though the plugin's own skills still load.

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

It reads the declared pins out of the repository, runs `git ls-remote` against each upstream, and compares. For `superpowers` it compares HEAD and the tag list against `source.sha`. For each `upstream/skills.json` source it compares the tag list against `ref`. It files **one issue, updated in place** rather than a new issue per run, and it never bumps a pin or opens a pull request.

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

The path is recorded as `installLocation` in `~/.claude/plugins/known_marketplaces.json`; the script resolves it from there rather than hardcoding it. On a Codex-only machine the equivalent clone is under `~/.codex/.tmp/marketplaces/eranroseman/`, and whether that path is durable is gate S4 (§13).

**The doctor's first check is whether its own clone is behind `origin/main`**, because a stale script silently applies stale pins. This is not hypothetical: on 2026-09-05 the Claude clone sat at `8fb3ca8` while the Codex clone sat at `74e136c`.

### 7.2 Prerequisites it checks and fails on

`git`, `jq`, `node`, `npx`, the `claude` binary, the `codex` binary. It does **not** require `gh` authentication or an SSH key: a keyless machine falls back from SSH to HTTPS automatically, measured.

### 7.3 What it applies

**Claude.** `claude plugin marketplace add`, then `claude plugin install software-development@eranroseman -y --scope user`, which installs and enables `sensemaking` and `superpowers` as dependencies. Both commands are clean no-ops on re-run. Then enable auto-update for the marketplace (§9, gate S3).

**Codex.** `codex plugin marketplace add` once, then `codex plugin add` for **both** plugins, because Codex has no dependency concept. Then the environment key (§7.4). **Never re-run `codex plugin marketplace add`:** it prints "already added" and silently deletes `last_revision`. Use `codex plugin marketplace upgrade`, which is a true no-op when upstream is unchanged.

**The pinned clone.** Read `source.sha` from the marketplace manifest beside the script. If the clone directory does not exist, clone and check out. If it exists, fetch and check out; do not chain with `&&` after a clone that may fail. The README's current recipe leaves a clone at the wrong revision silently, because `git clone … && git checkout …` short-circuits when the clone fails, exit 128.

**The symlinks.** For each of the thirteen names read from the marketplace entry, link into `~/.agents/skills/`, which is Codex's current documented user skill root; `$CODEX_HOME/skills` carries a deprecation comment in the installed build. Namespacing is preserved from either root, verified: a superpowers skill symlinked from `~/.agents/skills` still resolves as `superpowers:writing-plans`.

Four failure modes the README's `[ -e ]` guard does not cover, all measured:

1. A **dangling** link makes `[ -e ]` false, so the guard passes and `ln -s` then fails "File exists"; under `set -e` the loop dies mid-way.
2. An **existing directory symlink** with an unguarded `ln -s` nests a link inside the target and exits 0.
3. A **regular file** where a link belongs is reported as already existing and never repaired.
4. Twenty of the links the recipe creates in `~/.codex/skills` are **redundant**, because Codex already reads `~/.agents/skills` and dedupes by resolved path.

The script therefore compares `readlink -f` against the intended target, moves anything unexpected aside rather than deleting it, and creates the link only when it is absent or wrong. It does not mirror these thirteen into `~/.claude/skills`: Claude receives them from the plugin, and a personal-skill copy would duplicate them.

**The skills.sh set.** For each source in `upstream/skills.json`, `npx skills add "<repo>#<ref>" --skill <name> -g -y`. This writes `ref` into the lockfile, installs content identical to that ref, upgrades an already-unpinned entry in place, and survives `skills update -g` untouched.

### 7.4 The environment key

The Visual Companion in the vendored `brainstorming` skill fetches an external logo unless one of `SUPERPOWERS_DISABLE_TELEMETRY`, `DISABLE_TELEMETRY` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is truthy. None is set on this machine and none appears in any shell profile.

`~/.bashrc` is the wrong channel: it returns early for non-interactive shells, and a hook launched from a non-interactive parent never sees its exports, measured. Two channels work:

- **Claude:** the `env` key in `~/.claude/settings.json`, proven to reach a SessionStart hook subprocess. The script must **merge with `jq`, never template the file**, because `enabledPlugins` and `extraKnownMarketplaces` in the same file are CLI-owned.
- **Codex:** `[shell_environment_policy].set` in `config.toml`. Codex edits that file surgically, preserving comments and ordering, so the script appends a guarded subtable rather than rewriting. Guard with `tomllib`, never with `grep`: if an inline `set = {…}` already exists, appending a subtable is a TOML redefinition error. `tomllib` is read-only and is the only TOML library present, which is why the design never needs a writer.

### 7.5 What the script must not do

Never `--scope project`. Measured: it writes a checked-in `.claude/settings.json` carrying both `enabledPlugins` and `extraKnownMarketplaces`, which commits machine configuration into a repository.

Never treat `config.toml` as an installation check. `codex plugin marketplace remove` leaves orphaned `[plugins.*]` tables with no warning, after which `codex plugin list` reports no plugins while the entries remain. Verify with `codex plugin list` status.

Never delete a squatting file or link. Move it aside and report.

### 7.6 What it cannot do

Codex's per-project `trust_level` comes from an interactive onboarding prompt, not from any command; a fresh clone is prompted once. And on Claude the plugins load on the next launch or after `/reload-plugins`, because the CLI running the script is the one that must restart.

## 8. Repository scaffolding

Evidence, from the author 2026-09-05: without a declared issue tracker, agents do not file issues and findings are lost in chat while a plan is executing. Confirmed here in the positive: yesterday's build filed [issues #1 through #6](https://github.com/eranroseman/agent-plugins/issues/1) for its declined minors, which it could do because `docs/agents/issue-tracker.md` exists in this repository.

`setup-matt-pocock-skills` writes that layout and is repo-level where everything else here is machine-level. It has two gaps for this design:

1. **No git convention.** `superpowers:finishing-a-development-branch` instructs "merge back to base locally" and says to follow the repository's conventions, but nothing writes them. The Git section in this repository's `AGENTS.md` is hand-added.
2. **It picks one instruction file.** Its rule is never to create `AGENTS.md` when `CLAUDE.md` exists. Applied to a repository holding only `CLAUDE.md`, that leaves Codex reading nothing, because Codex reads `AGENTS.md` natively. The shape that works on both is the one this repository uses: content in `AGENTS.md`, and `CLAUDE.md` as a one-line `@AGENTS.md` import.

**The plugin composes rather than forks.** It ships a thin skill whose body invokes `setup-matt-pocock-skills` and then adds those two things. The precedent is in the roster already: `grill-with-docs` is a six-line skill whose entire body is "Call the Skill tool twice." Upstream keeps flowing and this repository owns about twenty lines.

Gate S5: `setup-matt-pocock-skills` carries `disable-model-invocation: true`, which removes it from the catalog entirely, so whether a model-invoked skill can reach it through the Skill tool is untested. If it cannot, the fallback is to vendor and adapt it, and the author's convenience argument carries that decision.

## 9. Updating an installation

**Claude, once auto-update is enabled: nothing to run.** Claude Code refreshes the marketplace and updates installed plugins on disk after a session starts, with a random delay of up to ten minutes, then either prompts for `/reload-plugins` or loads the new versions at the next launch. Third-party marketplaces default to auto-update off, which is why this has never happened; the `eranroseman` entry has no `autoUpdate` key today.

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

For `superpowers` the sha appears in four coupled artifacts, and three existing tests fail until all four move: `source.sha` and `version` in the marketplace entry, the vendored `brainstorming` tree and its provenance header, `hooks/payload.md`, and the sha in the plugin's `LICENSE`. `bin/bump-superpowers <sha>` rewrites all four and leaves the diff for review; the part that deserves reading is the vendored `brainstorming` body, because that is where upstream can change behaviour.

For a skills.sh source it is one `ref` edit in `upstream/skills.json`.

**One hole this design closes**, because the update path is where it bites: `tests/test-hook.sh` transcribes upstream's `<EXTREMELY_IMPORTANT>` frame rather than reading it from the clone, so a bump that changed that frame would leave the suite green while the injection diverged. Both existing specs carry it as an open item. §11 makes the test read the frame from the clone.

## 11. Static checks

New tests, run by the existing `tests/run.sh`:

- `upstream/skills.json` is well-formed, every `repo` resolves, every `ref` exists as a tag, and every listed skill has a `SKILL.md` at that ref. This is the skills.sh twin of `test-upstream-pin.sh`, and it exists because a mistyped name is otherwise silent.
- `bin/setup` and `bin/doctor` pass `shellcheck`, and `bin/doctor` run against a fixture directory reports the seeded faults: a wrong sha, a dangling link, a nested link, a squatting regular file, a missing lockfile ref.
- `test-hook.sh` reads upstream's frame from the pinned clone rather than transcribing it (§10).
- The README's install and update instructions match the commands the script runs, asserted by extracting the fenced blocks and comparing against the script's own command list.

`bin/doctor` itself is the local half of the former sub-project 4. It compares the machine against §5's declarations: the clone at the declared sha, each of the thirteen links resolving to its intended target, the lockfile's `ref` per source matching the declaration, the installed plugin version matching the manifest, and the marketplace clone not behind `origin/main`. It reports and, in `bin/setup` mode, repairs.

## 12. mattpocock: why the curated route was not taken

Measured 2026-09-05, the curated `git-subdir` route works end to end on both harnesses. It was declined on the standard in §1.

Only one candidate problem survived as measured: no version pin, with sixteen of eighteen skills already drifted. That problem is fixable in place with a tag fragment (§7.3), verified including the in-place upgrade of an already-unpinned entry. The curated route's one genuine advantage is a forty-character sha rather than a mutable tag, since `skills add` rejects a sha; but a force-moved upstream tag is a hypothetical with no evidence behind it, while the migration's costs are certain: eighteen renames to `mattpocock-skills:<name>` on both harnesses, a namespace hostage to a field in upstream's Claude manifest, the loss of the `skillOverrides` lever sub-project 5 needs, a whole-repository clone on Codex, and forty-four symlinks removed rather than added.

The `-g` rule's premise was also refuted: it appears in `~/.claude/CLAUDE.md`'s first commit and no littering incident exists in any repository's history.

## 13. Gates

Checked on this machine after the first `bin/setup` run. Gate labels are `S`-prefixed so they cannot be confused with the `G`-labels of the [layout spec](2026-09-04-software-development-layout-and-tracer-design.md) §10.2 or the [hook spec](2026-09-04-session-start-hook-design.md) §8.

| Gate | Passes when | If it fails |
| --- | --- | --- |
| S1 Fresh install | `bin/setup` against a scratch `HOME` and `CODEX_HOME` produces the whole target state, and `bin/doctor` then reports clean. Verified with the real machine untouched | Defect, fix in place |
| S2 Doctor detects | `bin/doctor` against a fixture seeded with a wrong-sha clone, a dangling link, a nested link, a squatting regular file, and a lockfile entry missing its `ref` reports all five and repairs all five under `bin/setup` | Defect, fix in place |
| S3 Auto-update | `autoUpdate: true` on the user-scope `extraKnownMarketplaces` entry causes a published release to reach the machine without an explicit update command, observed within one session plus the documented delay | Setup stops trying to write it and instead prints the `/plugin` toggle steps; §9 gains a manual step for Claude and the README says so |
| S4 Codex bootstrap | `~/.codex/.tmp/marketplaces/eranroseman/` still holds a usable clone after a Codex restart and a `marketplace upgrade`, so a Codex-only machine can bootstrap from it | The README documents a plain `git clone` as the Codex-only bootstrap instead |
| S5 Skill reach | A model-invoked skill reaches `setup-matt-pocock-skills` through the Skill tool despite its `disable-model-invocation: true` | Vendor and adapt it instead of composing (§8), and record the rung change |
| S6 Pin application | Re-running `skills add "<repo>#<ref>" --skill <name> -g -y` across all twenty declared skills on the real machine leaves every lockfile entry carrying the declared `ref`, and `skills update -g` then reports everything up to date | Investigate before the pin is declared; the fallback is to pin only the sources that apply cleanly and record the rest |

Fresh-machine reproducibility is gate S1 and is in scope here, unlike in the layout spec where it was explicitly deferred to this sub-project.

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

- Whether `autoUpdate: true` in a **user-scope** `extraKnownMarketplaces` entry is honoured, or only in managed settings. `claude plugin marketplace list --json` does not report the flag (gate S3).
- Whether `~/.codex/.tmp/marketplaces/` is durable enough to bootstrap from on a Codex-only machine (gate S4).
- Whether a model-invoked skill can reach `setup-matt-pocock-skills` through the Skill tool given its `disable-model-invocation: true` (gate S5).
- Whether re-running `skills add` with a ref across all twenty skills is clean on a real machine; verified for one skill in a scratch home.
- Which upstream tag corresponds to the currently installed content. It is almost certainly between tags, so no tag reproduces today's exact bytes; the first pin is a deliberate content move.
- The two `obra/superpowers-developing-for-claude-code` skills are duplicated on Claude today (plugin and skills.sh). Sub-project 5 decides ([issue #10](https://github.com/eranroseman/agent-plugins/issues/10)).
- The `Skill(codex:rescue)` hang loses its prose home under §4.1 and should be filed upstream against `codex@openai-codex`.
- Whether the `env` key or the plugin's own SessionStart hook writing to `$CLAUDE_ENV_FILE` is the better Claude channel for the telemetry variable. The hook option would mean setup writes nothing at all on Claude, but it is a repository change rather than a setup change.
