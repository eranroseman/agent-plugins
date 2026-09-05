# software-development: SessionStart hook payload and Codex posture

**Status:** approved design, 2026-09-04. Sub-project 3 of 7 in the [layout and tracer spec](2026-09-04-software-development-layout-and-tracer-design.md) §11.
**Scope:** what `software-development`'s SessionStart hook injects on Claude Code, how the payload is assembled and tested, and whether Codex gets a hook at all.
**Not in scope:** setup automation and the user-file templates (sub-project 2), drift monitoring (sub-project 4), the skill roster (sub-project 5), any change to `~/.codex/AGENTS.md`.

## 1. Evidence standard

Same as the parent spec. A claim below counts as a fact only when it rests on a primary source read on 2026-09-04: a documentation page, a CLI `--help`, a file on this machine, source fetched from GitHub at a named sha or tag, or a session log. §12 lists each mechanism claim with its source. Knowledge-harness map #53 and ticket #61 were read as input; nothing on them binds, and §10 records where this design departs from them.

## 2. Purpose

The hook exists for one reason: to bring Claude Code's skill-following up to the level Codex reaches without help. The author's finding, stated 2026-09-04: Codex without superpowers installed followed superpowers' discipline better than Claude Code with superpowers and its hook. That is why superpowers was installed at all, and it decides both halves of this design.

- Claude Code keeps an injection. The text that G3 proved is the base, unchanged.
- Codex gets none. Session logs show it never had one (§12), and the author had no problem in that state.

No misfire of the current injection is on record. Nothing here rests on one.

## 3. Decisions

| Decision | Choice |
| --- | --- |
| Payload base | Upstream `skills/using-superpowers/SKILL.md` at the pinned sha, in upstream's `<EXTREMELY_IMPORTANT>` frame, with the one line-30 edit. Byte-identical to today's `hooks/payload.md`. |
| Payload appendix | One rule, worktree cleanup, moved out of the author's `~/.claude/CLAUDE.md`. Nothing else. Task reports was admitted on 2026-09-05 and withdrawn the same day; §10 records both moves. |
| What was not admitted | The lean router, the two bridge rules and the three Iron Laws proposed on #61, and the task-reports rule. Reason in §10. |
| Admission rule for future additions | A rule enters the payload only when it solves a problem for which there is evidence that it exists. Where an admitted rule lives follows from what it depends on: a rule that holds for every installer, depending on nothing beyond this plugin and its declared dependencies, goes in the payload; one that holds only on this machine goes in the user file. |
| Assembly | Two files. `hooks/payload.md` is regenerated from the pinned clone and tested byte-equal. `hooks/payload-rules.md` is authored. `hooks/session-start` concatenates them. |
| Codex | No hook, by construction: no file exists at the path Codex's fallback reads. |
| Claude hook file | `hooks/hooks.json` becomes `hooks/claude-hooks.json`, declared in the Claude manifest. Content and matcher unchanged. |
| Versions | `software-development` 0.1.0 to 0.2.0 in both manifests, so installed copies refresh. `sensemaking` unchanged. |

## 4. The payload

### 4.1 Composition

`hooks/session-start` emits one `additionalContext` string:

```text
<contents of hooks/payload.md>
<one empty line>
<contents of hooks/payload-rules.md>
```

Exactly: `cat payload.md; printf '\n'; cat payload-rules.md`. `payload.md` already ends with a newline, so the empty line separates the closing `</EXTREMELY_IMPORTANT>` from the appendix heading. The script reads through command substitution, which strips the final newline, so the emitted string is this concatenation less its last newline, exactly as today's string is `payload.md` less its last newline. The test in §7 compares through `jq -r`, which restores it.

`payload.md` does not change. Its content is upstream's `using-superpowers` skill at `b36e0829` inside upstream's frame, with `superpowers:brainstorming` on line 30 replaced by `software-development:brainstorming`. `tests/test-hook.sh` regenerates it from the pinned clone and diffs.

### 4.2 `hooks/payload-rules.md`, in full

```markdown
# software-development: working rules

**Worktree cleanup.** `EnterWorktree` places worktrees under `.claude/worktrees/`. `superpowers:finishing-a-development-branch` recognises only `.worktrees/` and `worktrees/` as its own and declines to remove anything else. Once the branch is merged or abandoned, run `git worktree remove <path>` from the main checkout, then `git worktree prune`.
```

That is the whole file, ending in exactly one newline, which §7 asserts. It carries the one rule that survived the placement test, and it holds for every installer: `EnterWorktree` is Claude Code's, and `finishing-a-development-branch` arrives through the curated `superpowers` dependency.

### 4.3 Size

`payload.md` is 3,343 bytes and the appendix 387, so the emitted string is 3,730 bytes, 3,718 code points. That is near upstream's own size, which G3 proved injects once at startup, `/clear`, and `/compact`. The test in §7 caps the total at 8,000 code points, measured with `jq '.hookSpecificOutput.additionalContext | length'`, as a tripwire against growth, not as a documented limit.

### 4.4 Matcher

`startup|clear|compact`, unchanged from upstream. `resume` is left out on purpose: a resumed session already holds the injection in its transcript.

## 5. Files and wiring

```text
plugins/software-development/
├── .claude-plugin/plugin.json         version 0.2.0; gains "hooks": "./hooks/claude-hooks.json"
├── .codex-plugin/plugin.json          version 0.2.0; no hooks key; capabilities drop "Lifecycle hooks"
├── hooks/
│   ├── claude-hooks.json              renamed from hooks.json, content unchanged
│   ├── session-start                  reads payload.md and payload-rules.md
│   ├── payload.md                     unchanged
│   └── payload-rules.md               new, §4.2
└── README.md                          hook and Codex paragraphs rewritten
```

- `hooks/hooks.json` must not exist after the rename. That absence is the Codex mechanism (§6).
- Claude Code loads the hook from the declared path. Declared paths supplement the default `hooks/hooks.json`; with no default file present, the declared file is the only one loaded.
- `session-start` keeps its JSON encoder and envelope. The changes are the two-file read, the join in §4.1, and its header comment, which drops the claim that Codex requires the envelope.
- Two catalog strings still advertise "bridge rules" and must not: `interface.longDescription` in the Codex manifest becomes "Narrowed brainstorming front door over the superpowers spine and mattpocock's engineering skills.", and the `software-development` entry's `description` in `.claude-plugin/marketplace.json` becomes "Glue over superpowers and mattpocock/skills: narrowed brainstorming, plus a SessionStart hook on Claude Code."
- `interface.capabilities` in the Codex manifest becomes `["Instructions"]`. `"Lifecycle hooks"` would be a false claim on Codex's catalog surface.
- The plugin README replaces the paragraph that says Codex does not load the hook with the posture in §6. The repository README's line 7 ("plus a SessionStart hook") gains "on Claude Code".
- The parent spec's §13 gets one line closing "why the `loader.rs` fallback did not fire": the question is moot, the plugin no longer offers Codex a hook, see this spec. Its §6.1 sentence "Hooks load from the default path `hooks/hooks.json`" and its §8 `hooks/hooks.json` listing each get a one-line note pointing here, since that file no longer exists.
- `~/.claude/CLAUDE.md` loses its **Worktree cleanup** paragraph, which now arrives by injection. The harness-backup copy is refreshed per that repository's README. No other user-file line moves; sub-project 2 owns the rest.

## 6. Codex

### 6.1 Posture

No hook. Codex installs the plugin for its skills, including `software-development:brainstorming`, and follows them without a session-start injection. That matches upstream, which removed its Codex hook in v6.1.0 with the commit message "Codex reliably triggers skills on its own, and the SessionStart hook made the UX worse rather than better", and it matches this machine's history: every superpowers version ever installed on Codex here either carried upstream's `"hooks": {}` suppression (6.1.1 and 6.2.0; upstream added it in v6.1.1 after finding that v6.1.0's removal alone left the Claude `hooks/hooks.json` loadable by the fallback) or shipped no `hooks/` directory at all (the openai-curated 5.1.3 snapshot). See §12.

### 6.2 Mechanism

Codex loads plugin hooks from the manifest's `hooks` entry when present, and otherwise from `hooks/hooks.json` at the plugin root. The validator that `tests/test-codex-validate.sh` runs rejects any `hooks` key, including `{}`, so upstream's suppression trick is closed to a plugin that wants to pass validation. The remaining lever is the file name. With no `hooks/hooks.json`, the fallback finds nothing. Verified at tag `rust-v0.147.0`, the installed codex-cli, and at HEAD on 2026-09-04. It holds on any later build that keeps `DEFAULT_HOOKS_CONFIG_FILE` and the `.codex-plugin`-first manifest order, two constants for sub-project 4 to watch (§11).

The Claude manifest's new `hooks` key cannot leak to Codex. Codex resolves a plugin's manifest in a fixed order: a root `plugin.json` carrying an `agent-plugins.org` schema, then `.codex-plugin/plugin.json`, then `.claude-plugin/plugin.json`, then `.cursor-plugin/plugin.json`. This plugin ships `.codex-plugin/plugin.json`, so the Claude manifest is never read on Codex.

### 6.3 What this closes

Gate G4 of the parent spec recorded IGNORED and left open why the source-level fallback did not fire on codex-cli 0.147.0. The fallback code is the same at tag `rust-v0.147.0` as at HEAD, and the plugin's `hooks.json` parses under Codex's schema, so the cause was not settled statically. It no longer needs to be: nothing is offered for the fallback to load. The parent spec's open item closes as "no longer offered".

## 7. Static checks

`tests/test-hook.sh` is rewritten. Every other test is untouched, and `tests/test-json-wellformed.sh` already discovers `*.json`, so `claude-hooks.json` stays covered.

1. `payload.md` byte-equal to upstream's `using-superpowers` inside upstream's frame with the line-30 edit, regenerated from the pinned clone. As today.
2. `payload-rules.md` exists, is non-empty, and ends with exactly one newline. Every `superpowers:<name>` it mentions is one of the thirteen skill names listed for the curated `superpowers` entry in `.claude-plugin/marketplace.json`. It does not mention `superpowers:brainstorming`.
3. The script's output is the SessionStart envelope with no extra top-level keys, and its `additionalContext`, read back with `jq -r`, diffs equal to `cat payload.md; printf '\n'; cat payload-rules.md`, the comparison form today's test uses. `jq -r` restores the one newline that command substitution strips; `jq -j` with `cmp` would fail by that byte. Its length, `jq '.hookSpecificOutput.additionalContext | length'`, is under 8,000.
4. Wiring: `hooks/claude-hooks.json` has matcher `startup|clear|compact`, one command hook running `"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"`, and only `hooks` at top level. `hooks/hooks.json` does not exist. `.claude-plugin/plugin.json` has `hooks` equal to `./hooks/claude-hooks.json`. `.codex-plugin/plugin.json` has no `hooks` key and its `interface.capabilities` does not contain `Lifecycle hooks`.
5. The encoder escapes every C0 control character, not just the common five. As today, except that the temporary directory also gets an empty `payload-rules.md` beside the copied script, since the script now reads it. The expectation stays the sample alone: the appended newline is stripped by command substitution.

`claude plugin validate --strict` and the Codex validator must keep passing on both plugins; the existing tests assert that.

## 8. Gates

Checked live on this machine after cutover (§9).

| Gate | Passes when | If it fails |
| --- | --- | --- |
| G3 rerun | Standalone-line count of `You have superpowers.` is 1 at startup, after `/clear`, and after a real `/compact`; the injected text read back at startup contains the worktree rule, which the 0.1.0 payload lacked | Defect, fix in place. A count of 1 without the rule means the old cached plugin is still loaded: check `claude plugin details` shows 0.2.0 |
| G6 Codex | After the refresh, `~/.codex/plugins/cache/eranroseman/software-development/0.2.0/hooks/` contains no `hooks.json`; `/hooks` in a Codex session lists nothing for the plugin; `[hooks.state]` in `~/.codex/config.toml` has no entry for it. "No injection in a session" is recorded but does not discriminate: an untrusted hook never runs either, so 0.1.0 already showed none | Defect, fix in place |
| G7 baseline | Two cold Claude sessions. "Let's build X" invokes `software-development:brainstorming` before any other action. "Fix this bug" invokes `superpowers:systematic-debugging` first. Each result recorded | None. This measures the purpose in §2 with upstream's own text; a failure is a finding about Claude Code or upstream, recorded for the roster and drift sub-projects, not a defect in this design |

## 9. Cutover and rollback

On this machine, after the change is merged to `main` and pushed:

Claude Code:

1. `claude plugin marketplace update eranroseman`
2. `claude plugin update software-development@eranroseman`, then restart Claude Code. `claude plugin details software-development@eranroseman` shows version 0.2.0 and one SessionStart hook.
3. Delete the **Worktree cleanup** paragraph from `~/.claude/CLAUDE.md`. Refresh the harness-backup copy and commit there.

Codex:

1. `codex plugin marketplace upgrade` (refreshes Git marketplace snapshots).
2. `codex plugin remove software-development@eranroseman`, then `codex plugin add software-development@eranroseman`, so the cache holds 0.2.0 and no `hooks.json`.

Rollback: revert the commit on `main`, push, and repeat the same refresh steps; the 0.1.0 tree returns. Restore the CLAUDE.md paragraph from harness-backup.

## 10. Positions on the map and #61 not adopted

Each was proposed by AI triage on the knowledge-harness tracker and never accepted. The author ruled on them 2026-09-04: besides worktree cleanup, none addresses a problem with evidence behind it, and each repeats a rule superpowers already carries.

| Proposal | Disposition | Reason |
| --- | --- | --- |
| Replace upstream's text with a lean router | Not adopted | The text G3 proved is kept whole. No misfire is on record, and the persuasion in it is the only enforcement superpowers has. |
| Bridge rule: a `ready-for-agent` issue is the spec, execution enters only via `writing-plans` | Not adopted | Restates `brainstorming`'s gate through the tracker, and as worded would force a plan document on bounded work that the vendored `brainstorming` sends straight to TDD. No evidence that the problem it addresses exists. |
| Iron Laws in the payload | Not adopted | Restate lines owned by `test-driven-development`, `systematic-debugging`, and `verification-before-completion`. No evidence that the problem exists. |
| Task-reports rule in the payload | **Not adopted**, after being adopted and withdrawn on 2026-09-05 | The original decline read the problem as unevidenced. Sub-project 2 established the evidence, that findings from plan execution are lost in chat without a declared destination, and the rule briefly entered the payload. The author then placed it better: its destination clause is repository-specific, and the tracker declaration that names where issues go is already repository-level, so the rule belongs beside it in each repository's `AGENTS.md`. That drops two carriers for one, and the objection defeats itself, since a repository with no declared tracker has nothing for the rule to point at. See the [setup and drift spec](2026-09-05-setup-and-drift-design.md) §8. |
| Content classes and the "true for every installer" admission test | Adopted in part | The installer test decides where an admitted rule lives (§3). Admission itself needs evidence that the problem exists, which #61's test never asked for. |
| Codex hook posture "designed against IGNORED" | Superseded | No hook is offered at all; §6. |

## 11. Open items carried forward

- ~~Whether the task-reports paragraph and the rest of the author's `~/.claude/CLAUDE.md` tool-routing section survive as user-file templates, and in what form (sub-project 2).~~ Closed 2026-09-05: task reports goes into each repository's `AGENTS.md`, written by the scaffolding skill, and the [setup and drift spec](2026-09-05-setup-and-drift-design.md) §4.1 dispositions every remaining section of both global files.
- `using-superpowers/SKILL.md:30` still names `superpowers:brainstorming` when the skill file is read directly rather than through this hook; on Codex, where no hook runs, the reference dangles unmitigated (roster, sub-project 5).
- `tests/test-hook.sh` transcribes upstream's frame rather than reading it from the clone, so a pin bump that changed the frame would pass green while the injection diverged (parent spec §12; sub-project 4).
- An upstream change to `finishing-a-development-branch` accepting `.claude/worktrees/` would delete the one appended rule. Upstream states a 94% PR rejection rate; not pursued here.
- The Codex mechanism rests on two constants: `DEFAULT_HOOKS_CONFIG_FILE` in `codex-rs/core-plugins/src/loader.rs` and the order of `DISCOVERABLE_PLUGIN_MANIFEST_PATHS` in `codex-rs/exec-server-protocol/src/protocol.rs`. Sub-project 4's upstream watch reads both on each Codex release.
- G7's result. If Claude Code does not reach the first-skill behaviour on upstream's own text, the escalation #61 recorded, a real `PreToolUse` gate, is the next design, not more prose.

## 12. Mechanism claims and their sources

| Claim | Source, read 2026-09-04 |
| --- | --- |
| Claude plugin manifest `hooks` accepts a path; custom paths supplement default directories | `working-with-claude-code/references/plugins-reference.md` lines 198, 227, 232 |
| Claude concatenates every matching SessionStart hook's `additionalContext`; matching hooks run in parallel | `working-with-claude-code/references/hooks.md` lines 520, 776 |
| Codex loads plugin hooks only for legacy-format manifests, from the manifest `hooks` entry or else `hooks/hooks.json`; parse failures become warnings, not registrations | `codex-rs/core-plugins/src/loader.rs` at HEAD (`a97cf1b7`), lines 954–964 and 1190–1244; byte-identical functions at tag `rust-v0.147.0` (commit `be6e8eac`), lines 939–948 and 1236–1290 |
| Codex manifest discovery order: root `plugin.json` with an `agent-plugins.org` schema, then `.codex-plugin`, `.claude-plugin`, `.cursor-plugin` | `codex-rs/utils/plugins/src/plugin_namespace.rs` lines 11–79; `codex-rs/exec-server-protocol/src/protocol.rs` lines 47–51 |
| Codex's hook-file schema: top level rejects unknown keys; command hooks accept `command`, `commandWindows`, `timeout`, `async`, `statusMessage`, `additionalContextLimit`, and ignore others such as `shell`; `SessionStart` matcher values are `startup`, `resume`, `clear`, `compact` | `codex-rs/config/src/hook_config.rs` lines 9–185; `codex-rs/hooks/src/events/session_start.rs` lines 24–38 |
| Codex's validator rejects a `hooks` key whether `{}` or a path | `~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py` run against both variants: "plugin.json field `hooks` is not accepted by plugin validation" |
| Codex also reads user (`~/.codex/hooks.json`, `[hooks]` in config.toml) and project (`.codex/hooks.json`) hook layers, and requires trust before a non-managed hook runs | `codex-rs/hooks/src/engine/discovery.rs` lines 129–206 and 339–380 (layers), 713–719 and 794–811 (an untrusted handler is never run); learn.chatgpt.com/docs/hooks |
| Upstream removed its Codex hook in v6.1.0 | obra/superpowers commit `640ce6c`, 2026-06-24, "Remove Codex hooks"; first tag containing it v6.1.0 (2026-06-30); the hook first shipped in v6.0.0 (commit `1e7cd98`, 2026-05-14); `7d8d3d4` (2026-06-30, first in v6.1.1) then set the Codex manifest to `"hooks": {}` because the removal alone left `hooks/hooks.json` loadable by the fallback |
| No superpowers hook ever ran on Codex on this machine | `~/.codex/sessions`: 215 of 2,729 rollouts carry ponytail's SessionStart developer message, all between 2026-06-21 and 07-08 on codex-cli 0.142.x, and none carries a superpowers one; from 0.144.0-alpha.4 (2026-07-10) on, rollouts record no plugin hook injection of any kind although ponytail stays enabled and trusted, so the log leg bounds only that window; all 11 `codex/config.toml` snapshots in harness-backup since 2026-08-07 list only ponytail under `[hooks.state]` |
| Codex superpowers versions here were 5.1.3 (`openai-curated`, 2026-07-05 to 07-08; openai/plugins' own patch bump of upstream v5.1.0, snapshots `d6169bef` and `2f1a8948`, neither carrying a `hooks/` directory), 6.1.1 (2026-07-08 on), 6.2.0 (2026-08-06 to 09-03) | Plugin cache paths in `~/.codex/sessions` rollouts; `gh api repos/openai/plugins/contents/plugins/superpowers?ref=<sha>` for both snapshots; harness-backup `codex/config.toml` history |
| Current `hooks/payload.md` is 3,343 bytes and equals upstream's text in upstream's frame with one edit | `wc -c`; `tests/test-hook.sh` section 1 |
| Refresh commands on both CLIs | `claude plugin update --help`, `claude plugin marketplace update --help`, `codex plugin marketplace --help`, `codex plugin add --help` |
