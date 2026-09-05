# SessionStart Hook Payload and Codex Posture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Append one authored rule to the Claude Code SessionStart injection, move the hook file to a Claude-declared path so Codex is offered no hook, and prove both on this machine.

**Architecture:** `hooks/session-start` concatenates two files, upstream's `payload.md` (unchanged, drift-tested) and a new `payload-rules.md`, into the same JSON envelope. The hook registration moves from `hooks/hooks.json` to `hooks/claude-hooks.json`, declared in `.claude-plugin/plugin.json`; nothing remains at the path Codex's fallback reads. Every static claim is a bash assertion in `tests/test-hook.sh`, run by `tests/run.sh` locally and in CI.

**Tech Stack:** bash, jq, Claude Code CLI (`claude plugin validate --strict`), codex-cli 0.147.0's `validate_plugin.py`, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-04-session-start-hook-design.md`. Section numbers below (§4.1, §7, …) refer to it. Its parent is `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`.

## Global Constraints

- `hooks/payload.md` does not change by a single byte. Its drift test (upstream text inside upstream's frame with the one line-30 edit) stays as it is.
- `hooks/payload-rules.md` content is exactly the §4.2 text, ending in exactly one newline.
- Emitted `additionalContext` is `cat payload.md; printf '\n'; cat payload-rules.md` less its final newline (command substitution strips it). The test compares `jq -r` output with `diff` against that command's output, never `jq -j` with `cmp`.
- After Task 1 no file named `hooks/hooks.json` exists anywhere under `plugins/`. The Claude manifest declares `"hooks": "./hooks/claude-hooks.json"` with the leading `./`; `claude plugin validate --strict` rejects the path without it.
- The Codex manifest never gains a `hooks` key in any form. Its `interface.capabilities` is `["Instructions"]`.
- Matcher stays `startup|clear|compact`.
- Both `software-development` manifests move from `0.1.0` to `0.2.0`. `sensemaking` stays `0.1.0`. *(Tasks 1 to 5 shipped 0.2.0 and the references below record that. A later change, the task-reports rule, moved the shipped version to **0.3.0** before the cutover ran; Tasks 6 to 8 are written against 0.3.0.)*
- The strings `bridge rules` and `Lifecycle hooks` appear in neither `software-development` manifest nor `.claude-plugin/marketplace.json` after Task 3.
- `additionalContext` length, `jq '.hookSpecificOutput.additionalContext | length'`, stays under 8,000.
- Test scripts call `grep` with plain patterns only (no `.{0,n}` quantifiers); `grep` on this machine may resolve to ugrep.
- All work happens on branch `session-start-hook` cut from `main`. Tasks 6 to 8 run only after that branch is merged and pushed.
- Commit messages are plain prose and end with the executing agent's attribution trailer, `Co-Authored-By: <agent name> <noreply@anthropic.com>`. The commit commands below show the plan author's trailer; substitute your own.

## File Structure

```text
plugins/software-development/
├── .claude-plugin/plugin.json      Task 1: version 0.2.0, "hooks": "./hooks/claude-hooks.json"
├── .codex-plugin/plugin.json       Task 1: version 0.2.0, capabilities ["Instructions"]; Task 3: longDescription
├── hooks/claude-hooks.json         Task 1: renamed from hooks.json, content unchanged
├── hooks/session-start             Task 2: two-file read, header comment
├── hooks/payload.md                unchanged
├── hooks/payload-rules.md          Task 2: new, §4.2 text
└── README.md                       Task 3: hook and Codex paragraphs
.claude-plugin/marketplace.json     Task 3: software-development description
README.md                           Task 3: line 7
tests/test-hook.sh                  Tasks 1, 2, 3: assertions
docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md   Task 4: three one-line notes
docs/superpowers/specs/2026-09-04-session-start-hook-design.md                       Task 8: cutover results
```

---

### Task 1: Move the hook registration to a Claude-declared path

**Files:**
- Modify: `tests/test-hook.sh` (the file-existence checks near the top, and section "(3) wiring")
- Rename: `plugins/software-development/hooks/hooks.json` → `plugins/software-development/hooks/claude-hooks.json`
- Modify: `plugins/software-development/.claude-plugin/plugin.json`
- Modify: `plugins/software-development/.codex-plugin/plugin.json`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `hooks/claude-hooks.json` at the plugin root, declared by the Claude manifest; `hooks/hooks.json` absent. Task 2 and Task 3 edit `tests/test-hook.sh` on top of the version this task leaves.

- [ ] **Step 1: Cut the branch**

```bash
cd /home/eranr/agent-plugins
git checkout main && git pull --ff-only origin main
git checkout -b session-start-hook
bash tests/run.sh   # expect eight PASS lines; if not, stop and report
```

- [ ] **Step 2: Write the failing assertions**

In `tests/test-hook.sh`, replace this line near the top:

```bash
[ -f "$H/hooks.json" ] || fail "missing $H/hooks.json"
```

with:

```bash
[ -f "$H/claude-hooks.json" ] || fail "missing $H/claude-hooks.json"
```

Then replace the whole `# (3) wiring` block (four `[ ... ] || fail` lines) with:

```bash
# (3) wiring: the Claude manifest declares the hook file, and nothing sits at
# the path Codex loads by fallback when its manifest has no hooks key.
PLUGIN="$REPO_ROOT/plugins/software-development"
HJ="$H/claude-hooks.json"
[ ! -e "$H/hooks.json" ] || fail "hooks/hooks.json must not exist: Codex loads that path by fallback"
[ "$(jq -r '.hooks.SessionStart[0].matcher' "$HJ")" = 'startup|clear|compact' ] || fail "matcher"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$HJ")" = 'command' ] || fail "hook type"
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HJ")" = '"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"' ] || fail "hook command"
[ "$(jq -r 'keys | join(",")' "$HJ")" = 'hooks' ] || fail "claude-hooks.json top level must contain only 'hooks'"
[ "$(jq -r '.hooks' "$PLUGIN/.claude-plugin/plugin.json")" = './hooks/claude-hooks.json' ] || fail "Claude manifest must declare hooks: ./hooks/claude-hooks.json"
[ "$(jq -r '.version' "$PLUGIN/.claude-plugin/plugin.json")" = '0.2.0' ] || fail "Claude manifest version must be 0.2.0"
[ "$(jq -r '.version' "$PLUGIN/.codex-plugin/plugin.json")" = '0.2.0' ] || fail "Codex manifest version must be 0.2.0"
[ "$(jq 'has("hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'false' ] || fail "Codex manifest must not declare hooks"
[ "$(jq '.interface.capabilities | index("Lifecycle hooks")' "$PLUGIN/.codex-plugin/plugin.json")" = 'null' ] || fail "Codex manifest must not claim Lifecycle hooks"
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash tests/test-hook.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/software-development/hooks/claude-hooks.json`, exit 1.

- [ ] **Step 4: Rename the hook file and edit both manifests**

```bash
git mv plugins/software-development/hooks/hooks.json plugins/software-development/hooks/claude-hooks.json
```

Replace the whole of `plugins/software-development/.claude-plugin/plugin.json` with:

```json
{
  "name": "software-development",
  "version": "0.2.0",
  "description": "Glue over superpowers and mattpocock/skills for Claude Code and Codex.",
  "author": { "name": "Eran Roseman", "url": "https://github.com/eranroseman" },
  "homepage": "https://github.com/eranroseman/agent-plugins",
  "repository": "https://github.com/eranroseman/agent-plugins",
  "license": "MIT",
  "keywords": ["software-development", "superpowers", "skills", "workflow"],
  "dependencies": ["sensemaking", "superpowers"],
  "hooks": "./hooks/claude-hooks.json"
}
```

In `plugins/software-development/.codex-plugin/plugin.json` change exactly two values: `"version": "0.1.0"` becomes `"version": "0.2.0"`, and `"capabilities": ["Instructions", "Lifecycle hooks"]` becomes `"capabilities": ["Instructions"]`. Leave `longDescription` alone; Task 3 changes it.

- [ ] **Step 5: Run the hook test and both validators**

Run: `bash tests/test-hook.sh && bash tests/test-claude-validate.sh && bash tests/test-codex-validate.sh && bash tests/test-json-wellformed.sh`
Expected: four success lines, exit 0. If `claude plugin validate --strict` reports `hooks: Invalid input`, the manifest path lacks its leading `./`.

- [ ] **Step 6: Commit**

```bash
git add tests/test-hook.sh plugins/software-development
git commit -m "$(cat <<'MSG'
Declare the SessionStart hook in the Claude manifest and vacate Codex's fallback path

hooks/hooks.json becomes hooks/claude-hooks.json, named by the Claude
manifest. Codex loads hooks/hooks.json when its manifest has no hooks
key, and its validator forbids the key, so the file name is the only
lever; with nothing at that path Codex is offered no hook. Both
manifests move to 0.2.0 so installed copies refresh.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
MSG
)"
```

---

### Task 2: Append the authored rules file to the payload

**Files:**
- Modify: `tests/test-hook.sh` (top-of-file checks, section "(1)" gains a rules block after it, section "(2) envelope round-trip", section "(4)" control characters)
- Create: `plugins/software-development/hooks/payload-rules.md`
- Modify: `plugins/software-development/hooks/session-start` (header comment and the `payload=` line only)

**Interfaces:**
- Consumes: the `tests/test-hook.sh` Task 1 left.
- Produces: `hooks/payload-rules.md`; `session-start` emitting `payload.md` + blank line + `payload-rules.md`. Task 3 adds one loop to section "(3) wiring" of the same test.

- [ ] **Step 1: Write the failing assertions**

Near the top of `tests/test-hook.sh`, after the `payload.md` existence check, add:

```bash
[ -f "$H/payload-rules.md" ] || fail "missing $H/payload-rules.md"
```

Immediately after the `# (1) payload exactness` block (after the line that fails on `a superpowers:brainstorming reference survived`), add:

```bash
# (1b) the authored rules file: non-empty, exactly one trailing newline, and
# every qualified superpowers reference names a skill the curated entry lists.
[ -s "$H/payload-rules.md" ] || fail "payload-rules.md is empty"
[ "$(tail -c 1 "$H/payload-rules.md" | wc -l)" -eq 1 ] || fail "payload-rules.md must end with a newline"
[ "$(tail -c 2 "$H/payload-rules.md" | wc -l)" -eq 1 ] || fail "payload-rules.md must end with exactly one newline"
grep -q 'worktree' "$H/payload-rules.md" || fail "payload-rules.md does not carry the worktree rule"
if grep -q 'superpowers:brainstorming' "$H/payload-rules.md"; then fail "payload-rules.md names superpowers:brainstorming"; fi
curated="$(jq -r '.plugins[] | select(.name == "superpowers") | .skills[]' "$MARKETPLACE" | sed 's#^\./##')"
while IFS= read -r name; do
  [ -z "$name" ] && continue
  printf '%s\n' "$curated" | grep -qx "$name" \
    || fail "payload-rules.md names superpowers:$name, which the curated entry does not list"
done < <(grep -o 'superpowers:[a-z-]*' "$H/payload-rules.md" | sed 's/^superpowers://' | sort -u)
```

In the `# (2) envelope round-trip` block, replace the `diff` command (the one ending `|| fail "additionalContext does not round-trip to payload.md"`) with:

```bash
diff <(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext') \
     <(cat "$H/payload.md"; printf '\n'; cat "$H/payload-rules.md") \
  || fail "additionalContext does not round-trip to payload.md + blank line + payload-rules.md"
len="$(printf '%s' "$out" | jq '.hookSpecificOutput.additionalContext | length')"
[ "$len" -lt 8000 ] || fail "additionalContext is $len code points; the tripwire is 8000"
```

In the `# (4)` control-character block, after the line `printf '%s' "$sample" > "$T/payload.md"`, add:

```bash
: > "$T/payload-rules.md"   # the script now reads it; empty keeps the expectation the sample alone
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-hook.sh`
Expected: `FAIL: missing /home/eranr/agent-plugins/plugins/software-development/hooks/payload-rules.md`, exit 1.

- [ ] **Step 3: Create the rules file**

Write `plugins/software-development/hooks/payload-rules.md` with exactly this content (three lines of text, one blank line between heading and paragraph, one trailing newline):

```markdown
# software-development: working rules

**Worktree cleanup.** `EnterWorktree` places worktrees under `.claude/worktrees/`. `superpowers:finishing-a-development-branch` recognises only `.worktrees/` and `worktrees/` as its own and declines to remove anything else. Once the branch is merged or abandoned, run `git worktree remove <path>` from the main checkout, then `git worktree prune`.
```

Check: `tail -c 2 plugins/software-development/hooks/payload-rules.md | wc -l` prints `1`.

- [ ] **Step 4: Make the script read both files**

In `plugins/software-development/hooks/session-start`, replace the header comment (lines 2 to 6, everything before `set -euo pipefail`) with:

```bash
# SessionStart hook for the software-development plugin, Claude Code only.
#
# Reads hooks/payload.md and hooks/payload-rules.md (next to this script),
# joins them with one blank line, and prints the result as the
# additionalContext of a SessionStart envelope, the shape Claude Code
# documents. Command substitution strips the final newline; the test
# accounts for it.
```

and replace the line

```bash
payload="$(cat "${SCRIPT_DIR}/payload.md")"
```

with

```bash
payload="$(cat "${SCRIPT_DIR}/payload.md"; printf '\n'; cat "${SCRIPT_DIR}/payload-rules.md")"
```

Nothing else in the script changes.

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/test-hook.sh`
Expected: `hook: payload exact, envelope round-trips, wiring correct, control characters escaped`, exit 0.

Then confirm the size the spec records: `CLAUDE_PLUGIN_ROOT=plugins/software-development plugins/software-development/hooks/session-start | jq '.hookSpecificOutput.additionalContext | length'` prints `3718`.

- [ ] **Step 6: Commit**

```bash
git add tests/test-hook.sh plugins/software-development/hooks
git commit -m "$(cat <<'MSG'
Append the plugin's working rules to the SessionStart payload

payload.md stays upstream's text, unchanged and drift-tested. A second
file, payload-rules.md, follows it after one blank line and carries the
one rule with evidence behind it, worktree cleanup, moved out of the
author's user file.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
MSG
)"
```

---

### Task 3: Retire "bridge rules" from the catalog surfaces and rewrite the READMEs

**Files:**
- Modify: `tests/test-hook.sh` (end of section "(3) wiring")
- Modify: `.claude-plugin/marketplace.json` (the `software-development` entry's `description`)
- Modify: `plugins/software-development/.codex-plugin/plugin.json` (`interface.longDescription`)
- Modify: `plugins/software-development/README.md`
- Modify: `README.md` (line 7)

**Interfaces:**
- Consumes: the `tests/test-hook.sh` Task 2 left.
- Produces: catalog strings and READMEs matching §5 and §6. Nothing later depends on the wording.

- [ ] **Step 1: Write the failing assertion**

At the end of the `# (3) wiring` block in `tests/test-hook.sh`, add:

```bash
for f in "$PLUGIN/.codex-plugin/plugin.json" "$MARKETPLACE"; do
  if grep -q 'bridge rules' "$f"; then fail "$f still advertises bridge rules"; fi
done
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-hook.sh`
Expected: `FAIL: /home/eranr/agent-plugins/plugins/software-development/.codex-plugin/plugin.json still advertises bridge rules`, exit 1.

- [ ] **Step 3: Change the two catalog strings**

In `.claude-plugin/marketplace.json`, the `software-development` entry's `description` becomes:

```json
"description": "Glue over superpowers and mattpocock/skills: narrowed brainstorming, plus a SessionStart hook on Claude Code.",
```

In `plugins/software-development/.codex-plugin/plugin.json`, `interface.longDescription` becomes:

```json
"longDescription": "Narrowed brainstorming front door over the superpowers spine and mattpocock's engineering skills.",
```

- [ ] **Step 4: Rewrite the plugin README**

Replace the whole of `plugins/software-development/README.md` with:

```markdown
# software-development

The glue plugin of Eran Roseman's software-development harness. It is a thin
layer over two upstream skill packs, not a home for copies of them.

What it ships:

- `skills/brainstorming/`: obra/superpowers' `brainstorming` skill, vendored
  at a pinned commit with one change, a narrowed `description` so that it
  fires on build requests and no longer competes with `grilling`. The
  provenance header at the top of `SKILL.md` names the commit. Do not
  hand-edit the skill; re-vendor from upstream to update it.
- `hooks/session-start`, Claude Code only: a SessionStart hook that injects
  `hooks/payload.md`, upstream's `using-superpowers` text with its one
  `superpowers:brainstorming` reference repointed at
  `software-development:brainstorming`, followed by `hooks/payload-rules.md`,
  this plugin's own working rules. The Claude manifest declares the hook as
  `hooks/claude-hooks.json`.

What it depends on (Claude Code installs both automatically):

- `sensemaking@eranroseman`: shared skills, starting with `rethink-audit`.
- `superpowers@eranroseman`: obra/superpowers taken straight from upstream,
  13 of its 14 skills. `brainstorming` is the one left out.

## Install

Claude Code:

    claude plugin marketplace add eranroseman/agent-plugins
    claude plugin install software-development@eranroseman

Codex (no dependency concept; superpowers arrives by symlink, see the
repository README):

    codex plugin marketplace add https://github.com/eranroseman/agent-plugins.git
    codex plugin add software-development@eranroseman
    codex plugin add sensemaking@eranroseman

Codex gets the skills and no hook, by design. Codex follows the skills
without a session-start injection: obra/superpowers removed its own Codex hook
in v6.1.0 for that reason, and the reference machine ran two months of Codex
sessions with superpowers and no injection. Nothing exists at the path Codex
loads by fallback, `hooks/hooks.json`, so no hook is offered on any Codex
build. The design spec in the repository records the evidence.

## Environment

The brainstorming skill's Visual Companion fetches a logo from an external
site unless `SUPERPOWERS_DISABLE_TELEMETRY` or `DISABLE_TELEMETRY` is set.
Set one of them in your shell profile.

## License

MIT. The vendored `skills/brainstorming/` is MIT, © 2025 Jesse Vincent. See
`LICENSE`.
```

- [ ] **Step 5: Edit the repository README**

In `README.md`, line 7 reads `  skill vendored with a narrowed description, plus a SessionStart hook.`. Change it to:

```markdown
  skill vendored with a narrowed description, plus a SessionStart hook on
  Claude Code (Codex is offered none, by design).
```

- [ ] **Step 6: Run the full suite**

Run: `bash tests/run.sh`
Expected: eight `PASS` lines, exit 0.

- [ ] **Step 7: Commit**

```bash
git add tests/test-hook.sh .claude-plugin/marketplace.json plugins/software-development README.md
git commit -m "$(cat <<'MSG'
Stop advertising bridge rules and state the Codex posture in the READMEs

Neither catalog surface may claim what the payload does not carry. The
plugin README replaces its "Codex does not load the hook" paragraph with
the decision: no Codex hook, by design.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
MSG
)"
```

---

### Task 4: Annotate the parent spec where the layout moved

**Files:**
- Modify: `docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md` (lines 176, 235, 421)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing code-facing. Documentation only.

- [ ] **Step 1: Append the §6.1 note**

Line 176 ends with `Hooks load from the default path `hooks/hooks.json`.` Append one sentence after it, same line:

```markdown
 *Amended 2026-09-04: the hook file is now `hooks/claude-hooks.json`, declared in this manifest; see the [hook spec](2026-09-04-session-start-hook-design.md) §5.*
```

- [ ] **Step 2: Insert the §8 note**

Line 235 is exactly `` `hooks/hooks.json`: ``. Insert one line before it:

```markdown
*Amended 2026-09-04: this file is now `hooks/claude-hooks.json`, content unchanged, declared in the Claude manifest; see the [hook spec](2026-09-04-session-start-hook-design.md) §5.*
```

- [ ] **Step 3: Close the §13 item**

Line 421 is `- Why the `loader.rs` fallback did not fire, given that the source reads as §12 records (opened by G4, sub-project 3).` Replace it with:

```markdown
- ~~Why the `loader.rs` fallback did not fire, given that the source reads as §12 records (opened by G4, sub-project 3).~~ Closed 2026-09-04 as moot: the plugin no longer offers Codex a hook, so nothing exists for the fallback to load; see the [hook spec](2026-09-04-session-start-hook-design.md) §6.
```

- [ ] **Step 4: Verify the three lines and commit**

Run: `grep -c 'Amended 2026-09-04' docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`
Expected: `2`. Run: `grep -c 'Closed 2026-09-04 as moot' docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md`
Expected: `1`.

```bash
git add docs/superpowers/specs/2026-09-04-software-development-layout-and-tracer-design.md
git commit -m "$(cat <<'MSG'
Point the layout spec at the hook spec where the hook file moved

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
MSG
)"
```

---

### Task 5: Merge, push, and watch CI

**Files:** none new.

**Interfaces:**
- Consumes: the four commits above on `session-start-hook`.
- Produces: `main` at the merge commit, pushed, CI green. Tasks 6 and 7 install from it.

- [ ] **Step 1: Run the suite once more on the branch**

Run: `bash tests/run.sh`
Expected: eight `PASS` lines, exit 0.

- [ ] **Step 2: Fast-forward main and push**

```bash
git checkout main
git merge --ff-only session-start-hook
git push origin main
git branch -d session-start-hook
```

- [ ] **Step 3: Watch the workflow**

Run: `gh run list --branch main --limit 1` then `gh run watch <run-id> --exit-status`
Expected: the `validate` workflow concludes `success`. If it fails, read the failing test's `FAIL:` line with `gh run view <run-id> --log-failed`, fix on a new branch, and repeat this task.

---

### Task 6: HUMAN-RUN. Claude Code cutover, G3 rerun, G7 baseline

> **Amended 2026-09-05.** The version shipped is **0.3.0**, not 0.2.0. The payload still carries exactly one rule, worktree cleanup: a task-reports rule was admitted and withdrawn the same day, because its destination clause is repository-specific and it belongs beside each repository's tracker declaration instead (hook spec §10, [setup and drift spec](../specs/2026-09-05-setup-and-drift-design.md) §8). So one paragraph leaves `~/.claude/CLAUDE.md`, not two, and the task-reports paragraph stays in **both** global files until the scaffolding skill ships. And the verification step moved **before** the deletion, so you prove the hook carries the rule before you delete its only other copy.

> **Do not dispatch an implementer for this task.** It restarts Claude Code and edits files under `~`. The controller hands the steps below to the user and records what they report.

**Files:**
- Modify (by the user): `~/.claude/CLAUDE.md`, `~/harness-backup/claude/CLAUDE.md`

- [ ] **Step 1: Refresh the plugin**

```bash
claude plugin marketplace update eranroseman
claude plugin update software-development@eranroseman
claude plugin details software-development@eranroseman
```

Expected in the details output: version `0.3.0`, `Hooks (1) SessionStart`. Quit every Claude Code instance and start a new one.

- [ ] **Step 2: G3 rerun. Verify before you delete anything.**

In a fresh Claude Code session in any directory, ask:

> Count the standalone lines in your context that are exactly `You have superpowers.` Then print the first line that begins `**Worktree cleanup.**`.

Expected: `1`, and the paragraph printed back. Run `/clear`, ask again: `1` and the paragraph. Then produce enough conversation to compact (several substantial exchanges), run `/compact`, and ask again: `1` and the paragraph. If `/compact` answers "Not enough messages to compact", the compact leg has not run; add history and retry.

A count of `1` without the paragraph means the old cache is still loaded: check that `claude plugin details` reports `0.3.0` and restart. **Do not proceed to Step 3 until the paragraph comes back**, because until then `~/.claude/CLAUDE.md` is its only carrier.

- [ ] **Step 3: Move the worktree rule out of the user file**

Only after Step 2 passes. Delete the paragraph beginning `**Worktree cleanup.**` from the `## Tool routing` section of `~/.claude/CLAUDE.md`; it now arrives by injection. **Leave everything else in both global files alone**, including the task-reports paragraphs: they move to each repository's `AGENTS.md` when the scaffolding skill ships, not now.

Then refresh the backup, which also captures the CLI-owned Codex marketplace timestamps that a 2026-09-05 investigation refreshed:

```bash
cd ~/harness-backup
cp ~/.claude/CLAUDE.md ~/.claude/settings.json claude/
cp ~/.codex/AGENTS.md ~/.codex/config.toml codex/
cp ~/.agents/.skill-lock.json agents/
git status
git add -A && git commit -m "Move the worktree cleanup rule into the software-development hook payload"
```

- [ ] **Step 4: G7 baseline**

Two fresh sessions in a scratch directory that has a git repository and no `docs/superpowers/`:

1. Prompt: `Let's build a small CLI that prints the current git branch.` Record the first skill the session invokes. Expected: `software-development:brainstorming`.
2. Prompt: `Fix this bug: the tests fail with "AssertionError" in the branch printer.` Record the first skill invoked. Expected: `superpowers:systematic-debugging`.

Record pass or fail per prompt, with the skill actually invoked. A fail is a finding, not a defect (spec §8).

- [ ] **Step 5: Report**

Report to the controller: the three G3 counts and whether each carried the worktree paragraph, and the two G7 results.

---

### Task 7: HUMAN-RUN. Codex refresh and G6

> **Do not dispatch an implementer for this task.** It changes the user's Codex installation.

- [ ] **Step 1: Refresh the marketplace snapshot and reinstall**

```bash
codex plugin marketplace upgrade
codex plugin remove software-development@eranroseman
codex plugin add software-development@eranroseman
ls ~/.codex/plugins/cache/eranroseman/software-development/
ls ~/.codex/plugins/cache/eranroseman/software-development/0.3.0/hooks/
```

Expected: the cache directory `0.3.0` exists; its `hooks/` listing shows `claude-hooks.json`, `payload.md`, `payload-rules.md`, `session-start`, and no `hooks.json`. No trust prompt appears on `add`.

- [ ] **Step 2: G6**

Start a Codex session in any trusted directory and run `/hooks`. Expected: no entry for `software-development@eranroseman`. Then:

```bash
grep -c 'software-development@eranroseman' ~/.codex/config.toml   # expected: 1, the [plugins] entry only
grep -A1 'hooks.state."software-development' ~/.codex/config.toml  # expected: no output
```

Note for the record whether the session showed any injection from this plugin (expected none; not discriminating, spec §8).

- [x] **Step 3: Report** — run by the agent 2026-09-05, except the one leg needing a TUI

Observed, real machine, codex-cli 0.147.0:

- `codex plugin marketplace upgrade` moved the snapshot from `1ea3f72` to `84b0b75`. `remove` then `add` reported success; **no trust prompt appeared**.
- Cache holds `0.3.0` only. Its `hooks/` listing is `claude-hooks.json`, `payload-rules.md`, `payload.md`, `session-start`. **No `hooks.json` anywhere under the plugin cache.**
- `[hooks.state]` holds four entries, all `ponytail@ponytail`; none for `software-development@eranroseman`.
- `config.toml` diff against a pre-run snapshot: only `last_updated` and `last_revision` for the marketplace, plus the two `[plugins.*]` tables swapping order because `remove` then `add` re-appends. Nothing else.
- `sensemaking@eranroseman` still installed at `0.1.0`, one config entry.
- All 13 superpowers symlinks resolve; none dangling.
- The Codex copy of `payload-rules.md` carries the worktree rule and nothing else, matching the shipped 0.3.0.

**Outstanding, needs a TUI:** run `/hooks` in a Codex session and confirm no entry for `software-development@eranroseman`. Every other G6 leg passes.

---

### Task 8: Record the cutover results in the spec

**Files:**
- Modify: `docs/superpowers/specs/2026-09-04-session-start-hook-design.md` (append a section)

**Interfaces:**
- Consumes: the user's reports from Tasks 6 and 7.
- Produces: the spec's results section; the plan closes.

- [ ] **Step 1: Append the results section**

At the end of the hook spec add, filling every `<…>` from the reports (no field may stay unfilled):

```markdown
## 13. Cutover results, <date>

Cutover performed on this machine per §9. Claude Code <version>, codex-cli <version>. `claude plugin details software-development@eranroseman` reported version 0.3.0 and one SessionStart hook.

| Gate | Result | Evidence |
| --- | --- | --- |
| G3 rerun | <PASS or FAIL> | Standalone-line count of `You have superpowers.`: <n> at startup, <n> after `/clear`, <n> after `/compact`; the worktree paragraph was read back at <which legs> |
| G6 Codex | <PASS or FAIL> | Cache `0.3.0/hooks/` listed <files>; `/hooks` listed <nothing or what>; `[hooks.state]` had <no entry or what>; injection observed: <none or what> (informational) |
| G7 baseline | <recorded> | "Let's build" invoked `<skill>` first; "Fix this bug" invoked `<skill>` first |

Observations carried forward: <one bullet per surprise, or "none">.
```

- [ ] **Step 2: Commit and push**

```bash
git add docs/superpowers/specs/2026-09-04-session-start-hook-design.md
git commit -m "$(cat <<'MSG'
Record the hook cutover results

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
MSG
)"
git push origin main
```
